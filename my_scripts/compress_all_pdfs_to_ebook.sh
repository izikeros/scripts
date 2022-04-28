#!/usr/bin/env bash

# loop over all pdfs in the current directory
mkdir -p ./output_ebook_quality_pdfs
for pdf in *.pdf
do
    # convert pdf to e-book
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS='/ebook' -dNOPAUSE -dQUITET -dBATCH -sOutputFile=output_ebook_quality_pdfs/$pdf $pdf
done
