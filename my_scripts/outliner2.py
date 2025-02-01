#!/usr/bin/env python3
import sys
from html.parser import HTMLParser
from urllib.request import urlopen


class TitleParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.indent_level = 0
        self.indent = "\t"

    def is_heading_tag(self, tag):
        return tag in ["h1", "h2", "h3", "h4", "h5", "h6"]

    def handle_starttag(self, tag, attrs):
        if self.is_heading_tag(tag):
            self.indent_level = int(tag[1]) - 1
            self.indent = "\t" * self.indent_level

    def handle_endtag(self, tag):
        if self.is_heading_tag(tag):
            self.indent_level = 0
            self.indent = "\t"

    def handle_data(self, data):
        data = data.strip()
        if data:
            print(self.indent + data)


if __name__ == "__main__":
    # take url as command line argument use sys.argv
    try:
        url = sys.argv[1]
    except IndexError:
        print("Usage: python3 outliner.py URL")
        sys.exit(1)

    # read html from url using urlopen and pass it to the TitleParser to parse the titles
    with urlopen(url) as response:
        html = response.read().decode("utf-8")

    parser = TitleParser()
    parser.feed(html)
