#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "requests",
# ]
# ///

"""
chomyk.py - chomikuj.pl downloader

This script allows downloading files and directories from chomikuj.pl file sharing platform.
It supports both single file and directory downloads with proper authentication.

Examples:
    Download a single file:
        python chomik.py -u username -p password -i "https://chomikuj.pl/path/to/file" -d "/download/path"

    Download directory content:
        python chomik.py -u username -p password -i "https://chomikuj.pl/path/to/directory" -d "/download/path"

    Download with custom number of threads:
        python chomik.py -u username -p password -i "https://chomikuj.pl/path/to/content" -t 3 -d "/download/path"
"""
# Source: from GitHub - can't find the original source anymore
import contextlib
import getopt
import hashlib
import os
import re
import sys
import threading
import time
from collections import OrderedDict
from getpass import getpass
from pathlib import Path
from xml.etree import ElementTree as et

import requests


class DownloadItem(threading.Thread):
    """Thread for downloading a file with progress tracking.

    This class handles file downloads with support for resuming interrupted downloads
    and displaying progress information.
    """

    def __init__(self, directory="", name="", url="", item_number=1):
        """Initialize the download thread with required parameters.

        Args:
            directory (str): Directory where the file will be saved
            name (str): Name of the file
            url (str): URL to download the file from
            item_number (int): Position in the download queue
        """
        super().__init__()
        self.id = 0
        self.agreement_info = "own"
        self.real_id = 0
        self.name = name
        self.url = url
        self.num = item_number
        self.status = "open"
        self.directory = directory
        self.progress = None

    def get_progress(self):
        """Return a formatted string showing download progress or waiting status."""
        if self.progress is None:
            return f"{self.num:>2}. {self.name[:20]:<20} : Oczekuje..."
        return self.progress

    def run(self):
        """Download the file, tracking progress and handling resume functionality."""
        self.status = "inprogress"
        path = Path(self.directory) / self.name

        # Get existing file size if available
        try:
            file_size = path.stat().st_size
        except (OSError, FileNotFoundError):
            file_size = 0

        # Initial request to get file information
        response = requests.get(
            self.url, stream=True, verify=False, allow_redirects=True
        )

        total_length = int(response.headers.get("content-length", 0))
        file_mode = "wb"

        # Set up resume download if we already have part of the file
        if total_length > file_size > 0:
            file_mode = "ab"
            resume_header = {"Range": f"bytes={file_size}-"}
            response = requests.get(
                self.url,
                headers=resume_header,
                stream=True,
                verify=False,
                allow_redirects=True,
            )

        # Download the file if needed
        if file_size < total_length:
            with open(path, file_mode) as file:
                dl_size = file_size
                for chunk in response.iter_content(chunk_size=128):
                    dl_size += len(chunk)
                    progress = dl_size * 100.0 / total_length
                    progress_bar = "#" * int(progress / 4)

                    self.progress = (
                        f"{self.num:>2}. {self.name[:20]:<20} "
                        f"{dl_size // 1024:>10d}KB {int(progress):>3d}% "
                        f"[{progress_bar:<25}]"
                    )

                    file.write(chunk)
            self.status = "done"
        elif file_size == total_length:
            self.progress = (
                f"{self.num:>2}. {self.name[:20]:<20} : Plik istnieje na dysku"
            )
            self.status = "done"


class Chomyk:
    def __init__(self, username, password, maxThreads, directory):
        self.isLogged = True
        self.lastLoginTime = 0
        self.hamsterId = 0
        self.token = ""
        self.items = 0
        self.threads = []
        self.accBalance = None
        self.maxThreads = int(maxThreads)
        self.directory = directory
        self.threadsChecker = None
        self.totalItems = 0
        self.username = username
        self.password = hashlib.md5(password.encode("utf-8")).hexdigest()
        self.cls()
        self.check_threads()
        self.login()

    def cls(self):
        os.system("cls" if os.name == "nt" else "clear")

    def print_line(self, line, text):
        sys.stdout.write("\x1b7\x1b[%d;%df%s\x1b8" % (line, 2, text))
        sys.stdout.flush()

    def check_threads(self):
        threadsInprogress = 0
        threadsOpen = 0
        threadsDone = 0

        for it in self.threads:
            self.print_line(it.num + 3, it.get_progress())
            if it.status == "inprogress":
                threadsInprogress += 1
            if it.status == "open":
                threadsOpen += 1
                if threadsInprogress < self.maxThreads:
                    threadsInprogress += 1
                    threadsOpen -= 1
                    it.start()
                    # it.join()
            if it.status == "done":
                threadsDone += 1

        if threadsDone == self.totalItems and threadsDone > 0 and threadsOpen == 0:
            self.threadsChecker.cancel()
            self.cls()
            print("\r\nWszystkie pliki zostaly pobrane")
            print("\r")
        else:
            self.threadsChecker = threading.Timer(1.0, self.check_threads)
            self.threadsChecker.start()

    def post_data(self, postVars):
        url = "http://box.chomikuj.pl/services/ChomikBoxService.svc"
        body = postVars.get("body")
        headers = {
            "SOAPAction": postVars.get("SOAPAction"),
            "Content-Encoding": "identity",
            "Content-Type": "text/xml;charset=utf-8",
            "Content-Length": str(len(body)),
            "Connection": "Keep-Alive",
            "Accept-Encoding": "identity",
            "Accept-Language": "pl-PL,en,*",
            "User-Agent": "Mozilla/5.0",
            "Host": "box.chomikuj.pl",
        }

        response = requests.post(url, data=body, headers=headers)
        self.parse_response(response.content)

    def dl(self, url):
        fileUrl = re.search("[http|https]://chomikuj.pl(.*)", url).group(1)

        rootParams = {
            "xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
            "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/",
        }

        root = et.Element("s:Envelope", rootParams)

        body = et.SubElement(root, "s:Body")
        downloadParams = {"xmlns": "http://chomikuj.pl/"}
        download = et.SubElement(body, "Download", downloadParams)
        downloadSubtree = OrderedDict(
            [
                (
                    "token",
                    self.token,
                ),
                ("sequence", [("stamp", "123456789"), ("part", "0"), ("count", "1")]),
                ("disposition", "download"),
                (
                    "list",
                    [
                        (
                            "DownloadReqEntry",
                            [
                                ("id", fileUrl),
                            ],
                        )
                    ],
                ),
            ]
        )

        self.add_items(download, downloadSubtree)

        xmlDoc = """<?xml version="1.0" encoding="UTF-8"?>"""
        xmlDoc += et.tostring(root, encoding="unicode", method="xml")

        dts = {
            "body": xmlDoc,
            "SOAPAction": "http://chomikuj.pl/IChomikBoxService/Download",
        }
        self.post_data(dts)

    def dl_step_2(self, idx, agreementInfo, cost=0):
        rootParams = {
            "xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
            "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/",
        }
        root = et.Element("s:Envelope", rootParams)

        body = et.SubElement(root, "s:Body")
        downloadParams = {"xmlns": "http://chomikuj.pl/"}
        download = et.SubElement(body, "Download", downloadParams)
        downloadSubtree = OrderedDict(
            [
                (
                    "token",
                    self.token,
                ),
                ("sequence", [("stamp", "123456789"), ("part", "0"), ("count", "1")]),
                ("disposition", "download"),
                (
                    "list",
                    [
                        (
                            "DownloadReqEntry",
                            [
                                ("id", idx),
                                (
                                    "agreementInfo",
                                    [
                                        (
                                            "AgreementInfo",
                                            [
                                                ("name", agreementInfo),
                                                ("cost", cost),
                                            ],
                                        )
                                    ],
                                ),
                            ],
                        )
                    ],
                ),
            ]
        )

        self.add_items(download, downloadSubtree)

        xmlDoc = """<?xml version="1.0" encoding="UTF-8"?>"""
        xmlDoc += et.tostring(root, encoding="unicode", method="xml")

        dts = {
            "body": xmlDoc,
            "SOAPAction": "http://chomikuj.pl/IChomikBoxService/Download",
        }

        self.post_data(dts)

    def login(self):

        rootParams = {
            "xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
            "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/",
        }
        root = et.Element("s:Envelope", rootParams)

        body = et.SubElement(root, "s:Body")
        authParams = {"xmlns": "http://chomikuj.pl/"}
        auth = et.SubElement(body, "Auth", authParams)

        authSubtree = OrderedDict(
            [
                (
                    "name",
                    self.username,
                ),
                (
                    "passHash",
                    self.password,
                ),
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

        self.add_items(auth, authSubtree)

        xmlDoc = """<?xml version="1.0" encoding="UTF-8"?>"""
        xmlDoc += et.tostring(root, encoding="unicode", method="xml")

        dts = {
            "body": xmlDoc,
            "SOAPAction": "http://chomikuj.pl/IChomikBoxService/Auth",
        }
        self.post_data(dts)

    def add_items(self, root, items):
        if type(items) is OrderedDict:
            for name, text in items.items():
                if type(text) is str:
                    elem = et.SubElement(root, name)
                    elem.text = text
                if type(text) is list:
                    subroot = et.SubElement(root, name)
                    self.add_items(subroot, text)
        elif type(items) is list:
            for name, text in items:
                if type(text) is str:
                    elem = et.SubElement(root, name)
                    elem.text = text
                if type(text) is list:
                    subroot = et.SubElement(root, name)
                    self.add_items(subroot, text)

    def parse_response(self, resp):
        self.print_line(3, f"Maks watkow: {self.maxThreads!s}")
        respTree = et.fromstring(resp)

        # Autoryzacja
        for dts in respTree.findall(
            ".//{http://chomikuj.pl/}AuthResult/{http://chomikuj.pl}status"
        ):
            status = dts.text
            if status.upper() == "OK":
                self.isLogged = True
                self.lastLoginTime = time.time()
                self.token = respTree.findall(
                    ".//{http://chomikuj.pl/}AuthResult/{http://chomikuj.pl}token"
                )[0].text
                self.hamsterId = respTree.findall(
                    ".//{http://chomikuj.pl/}AuthResult/{http://chomikuj.pl}hamsterId"
                )[0].text
                self.print_line(1, "Login: OK")

            else:
                self.isLogged = False
                self.print_line(1, f"Login: {status}")

        # Pobieranie urli plikow
        accBalance = respTree.find(
            ".//{http://chomikuj.pl/}DownloadResult/{http://chomikuj.pl}accountBalance/{http://chomikuj.pl/}transfer/{http://chomikuj.pl/}extra"
        )
        if accBalance is not None:
            self.accBalance = accBalance.text

        for dts in respTree.findall(
            ".//{http://chomikuj.pl/}DownloadResult/{http://chomikuj.pl}status"
        ):
            status = dts.text
            if status.upper() == "OK":
                dlfiles = respTree.findall(
                    ".//{http://chomikuj.pl/}files/{http://chomikuj.pl/}FileEntry"
                )
                if len(dlfiles) > self.totalItems:
                    self.totalItems = len(dlfiles)
                    self.print_line(2, f"Plikow: {self.totalItems}")
                for dlfile in dlfiles:
                    url = dlfile.find("{http://chomikuj.pl/}url")
                    idx = dlfile.find("{http://chomikuj.pl/}id").text
                    cost = dlfile.find("{http://chomikuj.pl/}cost")
                    if url.text is None:
                        agreementInfo = dlfile.find(
                            "{http://chomikuj.pl/}agreementInfo/{http://chomikuj.pl/}AgreementInfo/{http://chomikuj.pl/}name"
                        ).text
                        costInfo = dlfile.find(
                            "{http://chomikuj.pl/}agreementInfo/{http://chomikuj.pl/}AgreementInfo/{http://chomikuj.pl/}cost"
                        )

                        cost = 0 if costInfo.text is None else costInfo.text
                        if int(self.accBalance) >= int(cost):
                            self.dl_step_2(idx, agreementInfo, cost)
                        else:
                            self.print_line(
                                2, "Blad: brak wystarczajacego limitu transferu"
                            )
                    else:
                        self.items += 1
                        it = DownloadItem(
                            directory=self.directory,
                            name=dlfile.find("{http://chomikuj.pl/}name").text,
                            url=url.text,
                            item_number=self.items,
                        )
                        it.id = idx
                        it.daemon = True
                        self.threads.append(it)


def main(argv):
    url = ""
    username = ""
    password = ""
    threads = 5
    directory = f"{os.getcwd()}/"
    try:
        opts, args = getopt.getopt(
            argv, "h:u:p:i:t:d", ["help", "username", "password", "ifile"]
        )
    except getopt.GetoptError:
        print_usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt == "-h":
            print("Help:")
            print_usage()
            sys.exit()
        elif opt in ("-i", "--ifile"):
            url = arg
        elif opt in ("-u", "--username"):
            username = arg
        elif opt in ("-p", "--password"):
            password = arg
        elif opt in ("-t", "--threads"):
            threads = arg
        elif opt in ("-d", "--directory"):
            directory = arg

    if len(username) == 0:
        username = os.getenv("CHOMIKUJ_USER") or input("Login: ")

    if len(password) == 0:
        password = os.getenv("CHOMIKUJ_PASSWORD") or getpass("Haslo: ")

    if len(url) == 0:
        url = input("URL: ")

    if len(password) > 0 and len(username) > 0 and len(url) > 0:
        with contextlib.suppress(OSError):
            os.makedirs(directory)
        ch = Chomyk(username, password, threads, directory)
        ch.dl(str(url))
    else:
        print_usage()


def print_usage():
    print("chomyk.py --u username --p password --i <url>")
    sys.exit(2)


if __name__ == "__main__":
    main(sys.argv[1:])
