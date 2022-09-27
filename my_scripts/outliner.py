#!/usr/bin/env python3
import sys
from urllib.request import urlopen
from bs4 import BeautifulSoup

if __name__ == "__main__":
    # take url as command line argument use sys.argv
    try:
        url = sys.argv[1]
    except IndexError:
        print("Usage: python3 scrapper.py URL")
        sys.exit(1)

    html = urlopen(url)
    bs = BeautifulSoup(html, "html.parser")
    titles = bs.find_all(["h1", "h2", "h3", "h4", "h5", "h6"])

    # iterate over the titles and print them with indentation:
    # h1 with no indentation, h2 with 1 tab, h3 with 2 tabs, etc.
    for title in titles:
        txt = title.get_text().strip()
        if txt:
            print("\t" * (int(title.name[1]) - 1) + txt)
