#!/usr/bin/env python3

import os
import sys
import subprocess
from pathlib import Path

DEFAULT_TEMPLATE = Path.home() / ".md2pdf" / "techspec.typ"
DEFAULT_OUTPUT_DIR = "build"


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("Usage: md2pdf.py input.md [output.pdf]")
        print()
        print("Environment variables:")
        print("  MD2PDF_TEMPLATE   Path to typst template (default: ~/.md2pdf/techspec.typ)")
        print("  MD2PDF_OUTPUT_DIR Output directory (default: build)")
        sys.exit(0)

    input_file = Path(sys.argv[1])

    if not input_file.exists():
        print(f"Error: {input_file} not found")
        sys.exit(1)

    template = Path(os.environ.get("MD2PDF_TEMPLATE", str(DEFAULT_TEMPLATE)))

    if not template.exists():
        print(f"Error: Template '{template}' not found")
        print("Hint: Place your .typ template at ~/.md2pdf/techspec.typ")
        sys.exit(1)

    output_dir = Path(os.environ.get("MD2PDF_OUTPUT_DIR", DEFAULT_OUTPUT_DIR))
    output_dir.mkdir(parents=True, exist_ok=True)

    if len(sys.argv) > 2:
        output_file = Path(sys.argv[2])
    else:
        output_file = output_dir / (input_file.stem + ".pdf")

    cmd = [
        "pandoc",
        str(input_file),
        "--pdf-engine=typst",
        "--template", str(template),
        "--standalone",
        "-o", str(output_file),
    ]

    # Auto-detect bibliography
    bib_candidates = [Path("refs.bib"), Path("references.bib"), Path("bibliography.bib")]
    for bib in bib_candidates:
        if bib.exists():
            cmd += ["--citeproc", f"--bibliography={bib}"]
            break

    print(f"Converting {input_file} → {output_file}")
    print(f"Using template: {template}")
    print("Running:", " ".join(cmd))

    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error: pandoc exited with code {e.returncode}")
        sys.exit(e.returncode)
    except FileNotFoundError:
        print("Error: pandoc not found. Install it: brew install pandoc")
        sys.exit(1)

    print(f"Done: {output_file}")


if __name__ == "__main__":
    main()
