#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "requests",
# ]
# ///

import getopt
import hashlib
import sys
from collections import OrderedDict
from getpass import getpass
from xml.etree import ElementTree as et

import requests


class ChomikDownloader:
    def __init__(self, username, password):
        self.username = username
        self.password = hashlib.md5(password.encode("utf-8")).hexdigest()
        self.token = None
        self.hamsterId = None

    def login(self):
        url = "http://box.chomikuj.pl/services/ChomikBoxService.svc"

        root_params = {
            "xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
            "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/",
        }
        root = et.Element("s:Envelope", root_params)

        body = et.SubElement(root, "s:Body")
        auth = et.SubElement(body, "Auth", {"xmlns": "http://chomikuj.pl/"})

        auth_data = OrderedDict(
            [
                ("name", self.username),
                ("passHash", self.password),
                ("ver", "4"),
                (
                    "client",
                    OrderedDict(
                        [
                            ("name", "chomikbox"),
                            ("version", "2.0.5"),
                        ]
                    ),
                ),
            ]
        )

        self.add_items(auth, auth_data)

        xml_doc = """<?xml version="1.0" encoding="UTF-8"?>""" + et.tostring(
            root, encoding="unicode"
        )

        headers = {
            "SOAPAction": "http://chomikuj.pl/IChomikBoxService/Auth",
            "Content-Type": "text/xml;charset=utf-8",
            "User-Agent": "Mozilla/5.0",
        }

        response = requests.post(url, data=xml_doc, headers=headers)
        tree = et.fromstring(response.content)

        status = tree.find(".//{http://chomikuj.pl/}status")
        if status is not None and status.text.upper() == "OK":
            self.token = tree.find(".//{http://chomikuj.pl/}token").text
            return True
        return False

    def download_file(self, file_url):
        url = "http://box.chomikuj.pl/services/ChomikBoxService.svc"
        file_path = file_url.split("chomikuj.pl")[1]

        root = et.Element(
            "s:Envelope",
            {
                "xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
                "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/",
            },
        )

        body = et.SubElement(root, "s:Body")
        download = et.SubElement(body, "Download", {"xmlns": "http://chomikuj.pl/"})

        download_data = OrderedDict(
            [
                ("token", self.token),
                ("sequence", [("stamp", "123456789"), ("part", "0"), ("count", "1")]),
                ("disposition", "download"),
                ("list", [("DownloadReqEntry", [("id", file_path)])]),
            ]
        )

        self.add_items(download, download_data)

        xml_doc = """<?xml version="1.0" encoding="UTF-8"?>""" + et.tostring(
            root, encoding="unicode"
        )

        headers = {
            "SOAPAction": "http://chomikuj.pl/IChomikBoxService/Download",
            "Content-Type": "text/xml;charset=utf-8",
            "User-Agent": "Mozilla/5.0",
        }

        response = requests.post(url, data=xml_doc, headers=headers)
        tree = et.fromstring(response.content)

        file_url = tree.find(".//{http://chomikuj.pl/}url")
        if file_url is not None and file_url.text:
            filename = file_path.split("/")[-1]
            print(f"Downloading {filename}...")
            file_response = requests.get(file_url.text, stream=True, verify=False)

            with open(filename, "wb") as f:
                for chunk in file_response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
            print(f"Downloaded successfully to {filename}")
            return True
        return False

    def add_items(self, root, items):
        if isinstance(items, OrderedDict):
            for name, text in items.items():
                if isinstance(text, str):
                    elem = et.SubElement(root, name)
                    elem.text = text
                elif isinstance(text, list):
                    subroot = et.SubElement(root, name)
                    self.add_items(subroot, text)
        elif isinstance(items, list):
            for name, text in items:
                if isinstance(text, str):
                    elem = et.SubElement(root, name)
                    elem.text = text
                elif isinstance(text, list):
                    subroot = et.SubElement(root, name)
                    self.add_items(subroot, text)


def print_usage():
    print("Usage: python script.py -u <username> -p <password> <chomikuj_file_url>")
    print("Options:")
    print("  -u, --username    Chomikuj username")
    print("  -p, --password    Chomikuj password")
    print("  -h, --help        Show this help message")
    sys.exit(1)


def main(argv):
    username = ""
    password = ""

    try:
        opts, args = getopt.getopt(argv, "hu:p:", ["help", "username=", "password="])
    except getopt.GetoptError:
        print_usage()

    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print_usage()
        elif opt in ("-u", "--username"):
            username = arg
        elif opt in ("-p", "--password"):
            password = arg

    if not args:
        print("Error: Missing file URL")
        print_usage()

    file_url = args[0]

    # If username or password not provided in CLI, prompt for them
    if not username:
        username = input("Username: ")
    if not password:
        password = getpass("Password: ")

    downloader = ChomikDownloader(username, password)

    if downloader.login():
        print("Login successful")
        if downloader.download_file(file_url):
            print("File downloaded successfully")
        else:
            print("Failed to download file")
    else:
        print("Login failed")


if __name__ == "__main__":
    main(sys.argv[1:])
