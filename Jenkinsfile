pipeline {
  agent { label "win-agent" }

  options { timestamps() }

  stages {
    stage("Build") {
      steps {
        dir("projects/HelloBuild") {
          powershell 'pwsh -NoProfile -ExecutionPolicy Bypass -File ./scripts/build.ps1'
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: "projects/HelloBuild/artifacts/**", fingerprint: true, allowEmptyArchive: true
    }
  }
}