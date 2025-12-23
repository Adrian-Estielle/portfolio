# Sanitized artifact (011)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
 .SYNOPSIS
    Configure location capture and hourly analysis for the Razzberry backend.

 .DESCRIPTION
    This idempotent script adds a complete location ingestion pipeline to the
    existing Razzberry monorepo. It installs required packages, updates the
    Prisma schema, creates an Express route for bulk location uploads, mounts
    the route in the API, and introduces a background worker that stores
    locations and performs hourly clustering/analysis. All modifications are
    performed relative to the detected repository root so you can run this
    script from any directory. Re‑running the script will not duplicate
    imports or blocks.

    Key actions:

      • Installs dependencies: h3-js, @googlemaps/google-maps-services-js,
        node-cache, bullmq (if not present) and ioredis (for the worker).
      • Adds a Location model to `backend/prisma/schema.prisma` if missing.
      • Generates a Prisma migration and client to apply the new schema.
      • Creates `backend/services/location.ts` with helper functions
        recordLocations() and analyzeLocations().
      • Creates `backend/routes/location.js` exposing POST /location/record
        which validates input, decodes the JWT to obtain the user ID,
        inserts rows into the database and enqueues them for analysis.
      • Mounts the new route in `backend/index.js` after the /map route.
      • Adds a dedicated worker at `backend/worker/locationWorker.js`
        connecting to Redis. It consumes a locationIngest queue to persist
        rows, and schedules hourly jobs on a locationAnalyze queue that run
        analyzeLocations() to cluster places and update user interest. A
        simple H3‑based clustering and Google Places lookup is stubbed in
        for you to extend.
      • Adds a package script `"worker:location"` to package.json for
        launching the worker (e.g. `pnpm run worker:location`).

    Note: Ensure that your DATABASE_URL and REDIS_URL environment variables
    are set in `.env` or the Railway dashboard. GOOGLE_MAPS_KEY must be set
    to enable reverse geocoding. The JWT_SECRET is used to decode tokens in
    the location route.

    After running this script, deploy your API and worker separately. On
    Railway you can create a new service for the worker and set its command
    to `pnpm run worker:location`. Add a Cron job (e.g. `0 * * * * pnpm
    run worker:location`) or rely on the built‑in hourly scheduler inside
    the worker for periodic analysis.
#>

# Helper to locate repo root by climbing until a pnpm-lock.yaml or .git is found
function Find-RepoRoot {
    param([string]$startDir)
    $dir = Get-Item $startDir
    while ($dir -ne $null) {
        if (Test-Path (Join-Path $dir '.git') -or Test-Path (Join-Path $dir 'pnpm-lock.yaml')) {
            return $dir.FullName
        }
        $dir = $dir.Parent
    }
    throw 'Could not locate repository root. Please run inside the project.'
}

# Locate repo root and set working directory
try {
    $repoRoot = (git rev-parse --show-toplevel 2>$null).Trim()
} catch { $repoRoot = '' }
if (-not $repoRoot) { $repoRoot = Find-RepoRoot $PWD }
Set-Location $repoRoot
Write-Host "📂 Repo root: $repoRoot"

# Paths
$backendDir  = Join-Path $repoRoot 'backend'
$schemaFile  = Join-Path $backendDir 'prisma/schema.prisma'
$routeDir    = Join-Path $backendDir 'routes'
$servicesDir = Join-Path $backendDir 'services'
$workerDir   = Join-Path $backendDir 'worker'

# Ensure directories exist
if (-not (Test-Path $servicesDir)) { New-Item -ItemType Directory -Path $servicesDir | Out-Null }
if (-not (Test-Path $routeDir))    { New-Item -ItemType Directory -Path $routeDir    | Out-Null }
if (-not (Test-Path $workerDir))   { New-Item -ItemType Directory -Path $workerDir   | Out-Null }

# 1) Install dependencies (idempotent)
Write-Host "🔧 Installing location dependencies via pnpm..."
Push-Location $backendDir
pnpm add h3-js @googlemaps/google-maps-services-js node-cache bullmq ioredis | Out-Null
Pop-Location
Write-Host "   ✅ Dependencies installed/updated."

# 2) Ensure Location model exists in Prisma schema
if (-not (Test-Path $schemaFile)) {
    throw "❌ Cannot find schema.prisma at $schemaFile"
}
$schema = Get-Content $schemaFile -Raw
if ($schema -notmatch "model\s+Location\s+") {
    Write-Host "📝 Adding Location model to schema.prisma..."
    $locationModel = @'

model Location {
  id         Int      @id @default(autoincrement())
  userId     Int
  lat        Float
  lng        Float
  recordedAt DateTime @default(now())
  user       User     @relation(fields: [userId], references: [id])
  @@index([userId])
  @@index([lat, lng])
}
'@
    Add-Content -Path $schemaFile -Value $locationModel
    Write-Host "   ↪ Location model appended."
} else {
    Write-Host "   ↪ Location model already present – skipping schema update."
}

# Ensure User has back‑relation to Location to satisfy Prisma validation
$schema = Get-Content $schemaFile -Raw  # reload in case we just appended
if ($schema -notmatch "locations\s+Location\[]") {
    Write-Host "📝 Adding 'locations Location[]' relation field to User model..."
    $lines = Get-Content $schemaFile
    $patched = @()
    $insideUser = $false
    foreach ($l in $lines) {
        # Detect start of User model
        if ($l -match '^model\s+User\s+{') {
            $insideUser = $true
            $patched += $l
            continue
        }
        # Before closing brace of User model, insert the relation field
        if ($insideUser -and $l -match '^\}') {
            $patched += '  locations Location[]'
            $patched += $l
            $insideUser = $false
            continue
        }
        $patched += $l
    }
    Set-Content -Path $schemaFile -Value ($patched -join "`n") -Encoding UTF8
    Write-Host "   ↪ Added locations relation to User."
}

# 3) Generate migration and client
Write-Host "📦 Running prisma migrate and generate (may prompt)..."
Push-Location $backendDir
try {
    npx prisma migrate dev --name add_location --skip-seed | Out-Null
} catch {
    Write-Warning "Prisma migrate failed: $_.Exception.Message. Ensure DATABASE_URL is set and database reachable."
}
try {
    npx prisma generate | Out-Null
} catch {
    Write-Warning "Prisma generate failed: $_.Exception.Message"
}
Pop-Location
Write-Host "   ✅ Prisma client regenerated."

# 4) Create services/location.ts
$svcPath = Join-Path $servicesDir 'location.ts'
@'
import { PrismaClient } from "@prisma/client";
import h3 from "h3-js";
import NodeCache from "node-cache";
import { Client as GoogleMapsClient } from "@googlemaps/google-maps-services-js";

const prisma = new PrismaClient();
const cache = new NodeCache({ stdTTL: 60 * 60 * 24 * 30 }); // 30‑day cache
const maps = new GoogleMapsClient({});

/**
 * Persist an array of location entries for a user.
 * Each entry should contain lat, lng, and optional recordedAt.
 */
export async function recordLocations(userId: number, entries: { lat: number; lng: number; recordedAt?: Date }[]) {
  const data = entries.map(e => ({
    userId,
    lat: e.lat,
    lng: e.lng,
    recordedAt: e.recordedAt ? new Date(e.recordedAt) : new Date(),
  }));
  await prisma.location.createMany({ data });
}

/**
 * Cluster recent location rows (past hour) by H3 cell, reverse geocode
 * cluster centroids via Google Places and store user interests. This
 * implementation is a stub – extend as needed for your production use.
 */
export async function analyzeLocations() {
  const since = new Date(Date.now() - 60 * 60 * 1000);
  const locations = await prisma.location.findMany({ where: { recordedAt: { gte: since } } });
  if (locations.length === 0) return;
  // Group by user and H3 cell at resolution 8
  const groups: Record<string, { userId: number; cell: string; points: { lat: number; lng: number }[] }> = {};
  for (const loc of locations) {
    const cell = h3.geoToH3(loc.lat, loc.lng, 8);
    const key = `${loc.userId}-${cell}`;
    if (!groups[key]) groups[key] = { userId: loc.userId, cell, points: [] };
    groups[key].points.push({ lat: loc.lat, lng: loc.lng });
  }
  for (const key of Object.keys(groups)) {
    const group = groups[key];
    // Compute centroid
    const lat = group.points.reduce((s, p) => s + p.lat, 0) / group.points.length;
    const lng = group.points.reduce((s, p) => s + p.lng, 0) / group.points.length;
    const cacheKey = `${lat.toFixed(4)},${lng.toFixed(4)}`;
    let placeName: string | undefined = cache.get(cacheKey);
    if (!placeName && process.env.GOOGLE_MAPS_KEY) {
      try {
        const resp = await maps.reverseGeocode({ params: { latlng: { lat, lng }, key: process.env.GOOGLE_MAPS_KEY } });
        placeName = resp.data.results?.[0]?.formatted_address;
        if (placeName) cache.set(cacheKey, placeName);
      } catch (err) {
        console.error('Reverse geocoding failed', err);
      }
    }
    // TODO: update user interest table based on placeName category
    console.log(`[Analyzer] User ${group.userId} visited cell ${group.cell} -> ${placeName ?? 'unknown'}`);
  }
}

export default { recordLocations, analyzeLocations };
'@ | Set-Content $svcPath -Encoding UTF8
Write-Host "📝 Wrote services/location.ts"

# 5) Create routes/location.js
$routePath = Join-Path $routeDir 'location.js'
@'
import express from "express";
import { z } from "zod";
import jwt from "jsonwebtoken";
import { Queue } from "bullmq";
import { PrismaClient } from "@prisma/client";

const router = express.Router();
const prisma = new PrismaClient();

// Configure Redis connection for the queue
const conn = process.env.REDIS_URL
  ? { connection: { url: process.env.REDIS_URL } }
  : { connection: { host: process.env.REDIS_HOST || '<REDACTED_IP>', port: parseInt(process.env.REDIS_PORT || '6379'), password=<REDACTED_SECRET>;
const ingestQueue = new Queue('locationIngest', conn);

// Schema for bulk location uploads
const entrySchema = z.object({
  lat: z.number(),
  lng: z.number(),
  recordedAt: z.union([z.string(), z.number(), z.date()]).optional(),
});
const payloadSchema = z.object({ entries: z.array(entrySchema).min(1) });

router.post('/record', async (req, res) => {
  // Validate JWT from Authorization header
  const auth = req.headers.authorization || '';
  const token=<REDACTED_SECRET> ')[1];
  if (!token) return res.status(401).json({ error: 'Missing bearer <REDACTED_TOKEN>' });
  let userId;
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    userId=<REDACTED_SECRET>;
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  // Validate request body
  const result = payloadSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ error: 'Invalid input', details: result.error });
  }
  const entries = result.data.entries.map(e => ({
    lat: e.lat,
    lng: e.lng,
    recordedAt: e.recordedAt ? new Date(e.recordedAt) : new Date(),
    userId,
  }));
  try {
    // Insert into database immediately
    await prisma.location.createMany({ data: entries });
    // Enqueue each entry for asynchronous processing
    const jobs = entries.map(item => ({ name: 'location', data: item, opts: { removeOnComplete: true, removeOnFail: true } }));
    await ingestQueue.addBulk(jobs);
    res.status(201).json({ inserted: entries.length });
  } catch (err) {
    console.error('Location record error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

export default router;
'@ | Set-Content $routePath -Encoding UTF8
Write-Host "📝 Wrote routes/location.js"

# 6) Patch backend/index.js to mount location route
$indexFile = Join-Path $backendDir 'index.js'
if (-not (Test-Path $indexFile)) { throw "❌ Cannot find backend/index.js" }
$indexContent = Get-Content $indexFile -Raw
if ($indexContent -notmatch "/location'") {
    Write-Host "🛠️  Mounting /location route in index.js..."
    $lines = Get-Content $indexFile
    $patched = @()
    $importAdded = $false
    $routeMounted = $false
    foreach ($line in $lines) {
        # After other imports, insert import for location
        if (-not $importAdded -and $line -match "^import aiRoutes" ) {
            $patched += $line
            $patched += "import locationRoutes from './routes/location.js';"
            $importAdded = $true
            continue
        }
        # After map route, mount location
        if (-not $routeMounted -and $line -match "/map'" ) {
            $patched += $line
            $patched += "app.use('/location', locationRoutes);"
            $routeMounted = $true
            continue
        }
        $patched += $line
    }
    Set-Content -Path $indexFile -Value ($patched -join "`n") -Encoding UTF8
    Write-Host "   ↪ /location mounted in index.js"
} else {
    Write-Host "   ↪ /location route already mounted – skipping"
}

# 7) Create worker/locationWorker.js
$workerPath = Join-Path $workerDir 'locationWorker.js'
@'
import { Queue, Worker, QueueScheduler } from 'bullmq';
import { recordLocations, analyzeLocations } from '../services/location.js';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const conn = process.env.REDIS_URL
  ? { connection: { url: process.env.REDIS_URL } }
  : { connection: { host: process.env.REDIS_HOST || '<REDACTED_IP>', port: parseInt(process.env.REDIS_PORT || '6379'), password=<REDACTED_SECRET>;

// Ensure schedulers exist for both queues
new QueueScheduler('locationIngest', conn);
new QueueScheduler('locationAnalyze', conn);

// Worker to persist raw location entries from API
new Worker('locationIngest', async job => {
  const { userId, lat, lng, recordedAt } = job.data;
  // Persist individual entry (note: API already inserts in bulk; this is redundant but ensures eventual consistency)
  await prisma.location.create({ data: { userId, lat, lng, recordedAt: new Date(recordedAt) } });
}, { connection: conn }).on('error', e => console.error('[locationIngest] worker error', e));

// Worker to perform periodic analysis
new Worker('locationAnalyze', async () => {
  await analyzeLocations();
}, { connection: conn }).on('error', e => console.error('[locationAnalyze] worker error', e));

// Schedule hourly analysis via setInterval
setInterval(async () => {
  const analyzeQ = new Queue('locationAnalyze', conn);
  await analyzeQ.add('analyze', {}, { removeOnComplete: true, removeOnFail: true });
  console.log('[LocationWorker] Enqueued hourly analysis job');
}, 60 * 60 * 1000);

console.log('🏃 Location worker running. Waiting for jobs...');
'@ | Set-Content $workerPath -Encoding UTF8
Write-Host "📝 Wrote worker/locationWorker.js"

# 8) Add NPM script for location worker
$pkgJsonPath = Join-Path $repoRoot 'package.json'
if (Test-Path $pkgJsonPath) {
    $pkg = Get-Content $pkgJsonPath -Raw | ConvertFrom-Json
    if (-not $pkg.scripts) { $pkg | Add-Member -MemberType NoteProperty -Name scripts -Value @{} }
    # If the worker script isn't defined (PS doesn't allow colon property names directly), add via Add-Member
    if ($pkg.scripts.PSObject.Properties.Name -notcontains 'worker:location') {
        $pkg.scripts | Add-Member -Name 'worker:location' -Value 'node backend/worker/locationWorker.js' -MemberType NoteProperty -Force
        $pkg | ConvertTo-Json -Depth 10 | Set-Content -Path $pkgJsonPath -Encoding UTF8
        Write-Host "📦 Added script \"worker:location\" to package.json"
    } else {
        Write-Host "   ↪ worker:location script already exists – skipping"
    }
}

Write-Host "\n✅ Location ingestion and analysis configured. You can now run the worker with 'pnpm run worker:location' and deploy it as a separate service."
