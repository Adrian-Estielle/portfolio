#!/usr/bin/env python3
"""
tools/render_html_to_pdf.py

Render a small subset of HTML (the portfolio evidence pages) into a PDF.

Why this exists:
- Some environments can't run a headless browser (Edge/Chrome) for print-to-PDF.
- This script uses ReportLab to generate a readable PDF from the sanitized HTML page
  content (no hidden/original text).

Supported elements (within the first <section class="card">):
- h1 (title), h2 headings
- p paragraphs
- ul/li bullet lists
- table/tr/th/td tables (simple)

The PDF is intentionally plain and print-friendly.
"""

from __future__ import annotations

import argparse
import html
import re
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
from typing import List, Optional
from xml.sax.saxutils import escape as xml_escape

from reportlab.lib import colors
from reportlab.lib.pagesizes import LETTER
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    ListFlowable,
    ListItem,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


@dataclass
class Block:
    kind: str  # "h1" | "h2" | "p" | "ul" | "table"
    text: str = ""
    items: Optional[List[str]] = None
    rows: Optional[List[List[str]]] = None


class EvidenceHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.title: Optional[str] = None
        self.blocks: List[Block] = []

        self._in_card: bool = False
        self._card_depth: int = 0

        self._capture_tag: Optional[str] = None
        self._buf: List[str] = []

        self._in_ul: bool = False
        self._list_items: List[str] = []
        self._in_li: bool = False
        self._li_buf: List[str] = []

        self._in_table: bool = False
        self._table_rows: List[List[str]] = []
        self._in_tr: bool = False
        self._row: List[str] = []
        self._in_cell: bool = False
        self._cell_buf: List[str] = []

        self._in_style_or_script: bool = False

    def _flush_capture(self) -> None:
        tag = self._capture_tag
        if not tag:
            return
        text = " ".join(self._buf).strip()
        text = re.sub(r"\\s+", " ", text).strip()
        self._buf = []
        self._capture_tag = None
        if not text:
            return
        if tag == "h1":
            if not self.title:
                self.title = text
            if self._in_card:
                self.blocks.append(Block(kind="h1", text=text))
        elif tag == "h2":
            self.blocks.append(Block(kind="h2", text=text))
        elif tag == "p":
            self.blocks.append(Block(kind="p", text=text))

    def handle_starttag(self, tag: str, attrs) -> None:
        attrs_dict = dict(attrs or [])

        if tag in {"style", "script"}:
            self._in_style_or_script = True
            return

        if tag == "section":
            classes = attrs_dict.get("class", "")
            if not self._in_card and "card" in classes.split():
                self._in_card = True
                self._card_depth = 1
            elif self._in_card:
                self._card_depth += 1

        if tag == "h1" and self.title is None:
            self._capture_tag = "h1"
            self._buf = []
            return

        if not self._in_card:
            return

        if tag in {"h2", "p"}:
            self._capture_tag = tag
            self._buf = []
            return

        if tag == "ul":
            self._in_ul = True
            self._list_items = []
            return

        if tag == "li" and self._in_ul:
            self._in_li = True
            self._li_buf = []
            return

        if tag == "table":
            self._in_table = True
            self._table_rows = []
            return

        if tag == "tr" and self._in_table:
            self._in_tr = True
            self._row = []
            return

        if tag in {"th", "td"} and self._in_tr:
            self._in_cell = True
            self._cell_buf = []
            return

    def handle_endtag(self, tag: str) -> None:
        if tag in {"style", "script"}:
            self._in_style_or_script = False
            return

        if self._capture_tag == tag:
            self._flush_capture()
            return

        if not self._in_card:
            return

        if tag == "li" and self._in_li:
            self._in_li = False
            text = " ".join(self._li_buf).strip()
            text = re.sub(r"\\s+", " ", text).strip()
            self._li_buf = []
            if text:
                self._list_items.append(text)
            return

        if tag == "ul" and self._in_ul:
            self._in_ul = False
            if self._list_items:
                self.blocks.append(Block(kind="ul", items=self._list_items))
            self._list_items = []
            return

        if tag in {"th", "td"} and self._in_cell:
            self._in_cell = False
            text = " ".join(self._cell_buf).strip()
            text = re.sub(r"\\s+", " ", text).strip()
            self._cell_buf = []
            self._row.append(text)
            return

        if tag == "tr" and self._in_tr:
            self._in_tr = False
            if any(c.strip() for c in self._row):
                self._table_rows.append(self._row)
            self._row = []
            return

        if tag == "table" and self._in_table:
            self._in_table = False
            if self._table_rows:
                self.blocks.append(Block(kind="table", rows=self._table_rows))
            self._table_rows = []
            return

        if tag == "section" and self._in_card:
            self._card_depth -= 1
            if self._card_depth <= 0:
                self._in_card = False
                self._card_depth = 0

    def handle_data(self, data: str) -> None:
        if self._in_style_or_script:
            return
        text = html.unescape(data)
        if not text or not text.strip():
            return

        if self._capture_tag:
            self._buf.append(text)
            return

        if not self._in_card:
            return

        if self._in_cell:
            self._cell_buf.append(text)
            return

        if self._in_li:
            self._li_buf.append(text)
            return


def parse_evidence_html(path: Path) -> tuple[str, List[Block]]:
    parser = EvidenceHTMLParser()
    parser.feed(path.read_text(encoding="utf-8", errors="replace"))
    title = parser.title or path.stem
    return title, parser.blocks


def render_pdf(title: str, blocks: List[Block], out_path: Path) -> None:
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "EvidenceTitle",
        parent=styles["Title"],
        fontSize=18,
        leading=22,
        spaceAfter=12,
    )
    h2_style = ParagraphStyle(
        "EvidenceH2",
        parent=styles["Heading2"],
        fontSize=12.8,
        leading=16,
        spaceBefore=10,
        spaceAfter=6,
    )
    body_style = ParagraphStyle(
        "EvidenceBody",
        parent=styles["BodyText"],
        fontSize=10.5,
        leading=14,
        spaceAfter=6,
    )

    doc = SimpleDocTemplate(
        str(out_path),
        pagesize=LETTER,
        leftMargin=0.85 * inch,
        rightMargin=0.85 * inch,
        topMargin=0.8 * inch,
        bottomMargin=0.8 * inch,
        title=title,
        pageCompression=0,
    )

    flow = [Paragraph(xml_escape(title), title_style), Spacer(1, 6)]

    for b in blocks:
        if b.kind == "h1":
            continue
        if b.kind == "h2":
            flow.append(Paragraph(xml_escape(b.text), h2_style))
            continue
        if b.kind == "p":
            flow.append(Paragraph(xml_escape(b.text), body_style))
            continue
        if b.kind == "ul" and b.items:
            items = [
                ListItem(Paragraph(xml_escape(it), body_style), leftIndent=14)
                for it in b.items
            ]
            flow.append(ListFlowable(items, bulletType="bullet", leftIndent=18))
            flow.append(Spacer(1, 6))
            continue
        if b.kind == "table" and b.rows:
            rows = [[c.strip() for c in r] for r in b.rows]
            max_cols = max(len(r) for r in rows)
            for r in rows:
                while len(r) < max_cols:
                    r.append("")

            table = Table(rows, repeatRows=1)
            table.setStyle(
                TableStyle(
                    [
                        ("GRID", (0, 0), (-1, -1), 0.5, colors.lightgrey),
                        ("BACKGROUND", (0, 0), (-1, 0), colors.whitesmoke),
                        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                        ("VALIGN", (0, 0), (-1, -1), "TOP"),
                        ("LEFTPADDING", (0, 0), (-1, -1), 6),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                        ("TOPPADDING", (0, 0), (-1, -1), 4),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                    ]
                )
            )
            flow.append(table)
            flow.append(Spacer(1, 10))
            continue

    doc.build(flow)


def main() -> int:
    ap = argparse.ArgumentParser(description="Render evidence HTML pages to PDF (ReportLab).")
    ap.add_argument("html", nargs="+", help="HTML file(s) to render.")
    ap.add_argument("--out-dir", default="", help="Optional output directory (defaults next to HTML).")
    args = ap.parse_args()

    out_dir = Path(args.out_dir).resolve() if args.out_dir else None

    for html_path_str in args.html:
        html_path = Path(html_path_str).resolve()
        if not html_path.exists():
            raise FileNotFoundError(html_path)

        title, blocks = parse_evidence_html(html_path)
        pdf_path = (out_dir / (html_path.stem + ".pdf")) if out_dir else html_path.with_suffix(".pdf")
        pdf_path.parent.mkdir(parents=True, exist_ok=True)
        render_pdf(title, blocks, pdf_path)
        print(f"Wrote {pdf_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

