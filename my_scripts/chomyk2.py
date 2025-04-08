#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "requests",
# ]
# ///

"""
Chomikuj.pl Downloader

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

import hashlib
import os
import re
import sys
import threading
import time
from collections import OrderedDict
from xml.etree import ElementTree as et

import requests

requests.packages.urllib3.disable_warnings()


class Item(threading.Thread):
    """Class representing a downloadable item from chomikuj.pl"""

    def __init__(self) -> None:
        """Initialize download item thread"""
        threading.Thread.__init__(self)
        self.id: int = 0
        self.AgreementInfo: str = "own"
        self.realId: int = 0
        self.name: str = ""
        self.url: str = ""
        self.num: int = 1
        self.status: str = "open"
        self.directory: str = ""
        self.progress: str | None = None

    def get_progress(self) -> str:
        """Return formatted progress string for the download

        Returns:
            str: Formatted progress string
        """
        if self.progress is None:
            return "{:>2s}. {: <20s} : {}".format(
                str(self.num),
                self.name[:20],
                "Waiting...",
            )
        return self.progress

    def run(self) -> None:
        """Execute download thread"""
        self.status = "inprogress"
        path = os.path.join(self.directory, self.name)
        try:
            file_size = os.path.getsize(path)
        except Exception:
            file_size = 0

        r = requests.get(self.url, stream=True, verify=False, allow_redirects=True)
        total_length = int(r.headers.get("content-length", 0))
        file_attr = "wb"

        if total_length > file_size > 0:
            file_attr = "ab"
            resume_header = {"Range": f"bytes={file_size}-"}
            r = requests.get(
                self.url,
                headers=resume_header,
                stream=True,
                verify=False,
                allow_redirects=True,
            )

        if file_size < total_length:
            with open(path, file_attr) as fd:
                dl_size = file_size
                for chunk in r.iter_content(chunk_size=128):
                    dl_size += len(chunk)
                    progress = dl_size * 100.0 / total_length
                    self.progress = (
                        "{:>2s}. {: <20s} {: >10d}KB {: >3d}% [{: <25s}]".format(
                            str(self.num),
                            self.name[:20],
                            dl_size // 1024,
                            int(progress),
                            "#" * int(progress / 4),
                        )
                    )
                    fd.write(chunk)
            self.status = "done"
        elif file_size == total_length:
            self.progress = "{:>2s}. {: <20s} : {}".format(
                str(self.num), self.name[:20], "File already exists"
            )
            self.status = "done"


class Chomik:
    """Main class for handling chomikuj.pl downloads"""

    def __init__(self, username: str, password: str, max_threads: int, directory: str):
        """Initialize Chomik downloader"""
        self.is_logged: bool = False
        self.last_login_time: float = 0
        self.hamster_id: int = 0
        self.token: str = ""
        self.items: int = 0
        self.threads: list[Item] = []
        self.acc_balance: str | None = None
        self.max_threads: int = int(max_threads)
        self.directory: str = directory
        self.threads_checker: threading.Timer | None = None
        self.total_items: int = 0
        self.username: str = username
        self.password: str = hashlib.md5(password.encode("utf-8")).hexdigest()
        self.cls()
        self.check_threads()
        self.login()

    def cls(self) -> None:
        """Clear console screen"""
        os.system("cls" if os.name == "nt" else "clear")

    def print_line(self, line: int, text: str) -> None:
        """Print text at specific console line"""
        sys.stdout.write(f"\x1b7\x1b[{line};{2}f{text}\x1b8")
        sys.stdout.flush()

    def check_threads(self) -> None:
        """Check and manage download threads status"""
        threads_inprogress = 0
        threads_open = 0
        threads_done = 0

        for it in self.threads:
            self.print_line(it.num + 3, it.get_progress())
            if it.status == "inprogress":
                threads_inprogress += 1
            if it.status == "open":
                threads_open += 1
                if threads_inprogress < self.max_threads:
                    threads_inprogress += 1
                    threads_open -= 1
                    it.start()
            if it.status == "done":
                threads_done += 1

        if threads_done == self.total_items and threads_done > 0 and threads_open == 0:
            if self.threads_checker:
                self.threads_checker.cancel()
            self.cls()
            print("\r\nAll files downloaded")
            print("\r")
        else:
            self.threads_checker = threading.Timer(1.0, self.check_threads)
            self.threads_checker.start()

    def post_data(self, post_vars: dict) -> None:
        """Send POST request to chomikuj.pl API"""
        url = "http://box.chomikuj.pl/services/ChomikBoxService.svc"
        body = post_vars.get("body")
        headers = {
            "SOAPAction": post_vars.get("SOAPAction"),
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

    def dl(self, url: str) -> None:
        """Initiate download process for given URL"""
        file_url = re.search("[http|https]://chomikuj.pl(.*)", url).group(1)

        root_params = {
            "xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
            "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/",
        }

        root = et.Element("s:Envelope", root_params)
        body = et.SubElement(root, "s:Body")
        download_params = {"xmlns": "http://chomikuj.pl/"}
        download = et.SubElement(body, "Download", download_params)

        download_subtree = OrderedDict(
            [
                ("token", self.token),
                ("sequence", [("stamp", "123456789"), ("part", "0"), ("count", "1")]),
                ("disposition", "download"),
                (
                    "list",
                    [
                        (
                            "DownloadReqEntry",
                            [
                                ("id", file_url),
                            ],
                        ),
                    ],
                ),
            ]
        )

        self.add_items(download, download_subtree)

        xml_doc = """<?xml version="1.0" encoding="UTF-8"?>"""
        xml_doc += et.tostring(root, encoding="unicode", method="xml")

        dts = {
            "body": xml_doc,
            "SOAPAction": "http://chomikuj.pl/IChomikBoxService/Download",
        }
        self.post_data(dts)

    def dl_step_2(
        self, idx: str, agreement_info: str, cost: int | str = 0
    ) -> None:
        """Handle second step of download process"""
        root_params = {
            "xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
            "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/",
        }
        root = et.Element("s:Envelope", root_params)
        body = et.SubElement(root, "s:Body")
        download_params = {"xmlns": "http://chomikuj.pl/"}
        download = et.SubElement(body, "Download", download_params)

        download_subtree = OrderedDict(
            [
                ("token", self.token),
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
                                                ("name", agreement_info),
                                                ("cost", str(cost)),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ]
        )

        self.add_items(download, download_subtree)

        xml_doc = """<?xml version="1.0" encoding="UTF-8"?>"""
        xml_doc += et.tostring(root, encoding="unicode", method="xml")

        dts = {
            "body": xml_doc,
            "SOAPAction": "http://chomikuj.pl/IChomikBoxService/Download",
        }
        self.post_data(dts)

    def login(self) -> None:
        """Authenticate with chomikuj.pl"""
        root_params = {
            "xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
            "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/",
        }
        root = et.Element("s:Envelope", root_params)
        body = et.SubElement(root, "s:Body")
        auth_params = {"xmlns": "http://chomikuj.pl/"}
        auth = et.SubElement(body, "Auth", auth_params)

        auth_subtree = OrderedDict(
            [
                ("name", self.username),
                ("passHash", self.password),
                ("ver", "4"),
                (
                    "client",
                    OrderedDict(
                        [
                            ("name", "chomikbox"),
                            ("version", "2.0.5.0"),
                        ]
                    ),
                ),
            ]
        )

        self.add_items(auth, auth_subtree)

        xml_doc = """<?xml version="1.0" encoding="UTF-8"?>"""
        xml_doc += et.tostring(root, encoding="unicode", method="xml")

        dts = {
            "body": xml_doc,
            "SOAPAction": "http://chomikuj.pl/IChomikBoxService/Auth",
        }
        self.post_data(dts)

    def add_items(self, root: et.Element, items: OrderedDict | list) -> None:
        """Add items to XML tree"""
        if isinstance(items, OrderedDict):
            for name, text in items.items():
                if isinstance(text, str):
                    elem = et.SubElement(root, name)
                    elem.text = text
                if isinstance(text, list):
                    subroot = et.SubElement(root, name)
                    self.add_items(subroot, text)
                if isinstance(text, OrderedDict):
                    subroot = et.SubElement(root, name)
                    self.add_items(subroot, text)
        elif isinstance(items, list):
            for name, text in items:
                if isinstance(text, str):
                    elem = et.SubElement(root, name)
                    elem.text = text
                if isinstance(text, list):
                    subroot = et.SubElement(root, name)
                    self.add_items(subroot, text)

    def parse_response(self, resp: bytes) -> None:
        """Parse API response"""
        self.print_line(3, f"Max threads: {self.max_threads!s}")
        resp_tree = et.fromstring(resp)

        # Authentication
        for dts in resp_tree.findall(
            ".//{http://chomikuj.pl/}AuthResult/{http://chomikuj.pl}status"
        ):
            status = dts.text
            if status and status.upper() == "OK":
                self.is_logged = True
                self.last_login_time = time.time()
                self.token = resp_tree.findall(
                    ".//{http://chomikuj.pl/}AuthResult/{http://chomikuj.pl}token"
                )[0].text
                self.hamster_id = resp_tree.findall(
                    ".//{http://chomikuj.pl/}AuthResult/{http://chomikuj.pl}hamsterId"
                )[0].text
                self.print_line(1, "Login: OK")
            else:
                self.is_logged = False
                self.print_line(1, f"Login: {status}")

        # Download handling
        acc_balance = resp_tree.find(
            ".//{http://chomikuj.pl/}DownloadResult/{http://chomikuj.pl}accountBalance/{http://chomikuj.pl/}transfer/{http://chomikuj.pl/}extra"
        )
        if acc_balance is not None:
            self.acc_balance = acc_balance.text

        for dts in resp_tree.findall(
            ".//{http://chomikuj.pl/}DownloadResult/{http://chomikuj.pl}status"
        ):
            status = dts.text
            if status and status.upper() == "OK":
                dl_files = resp_tree.findall(
                    ".//{http://chomikuj.pl/}files/{http://chomikuj.pl/}FileEntry"
                )
                if len(dl_files) > self.total_items:
                    self.total_items = len(dl_files)
                    self.print_line(2, f"Files: {self.total_items}")

                for dl_file in dl_files:
                    url = dl_file.find("{http://chomikuj.pl/}url")
                    idx = dl_file.find("{http://chomikuj.pl/}id").text
                    cost = dl_file.find("{http://chomikuj.pl/}cost")

                    if url.text is None:
                        agreement_info = dl_file.find(
                            "{http://chomikuj.pl/}agreementInfo/{http://chomikuj.pl/}AgreementInfo/{http://chomikuj.pl/}name"
                        ).text
                        cost_info = dl_file.find(
                            "{http://chomikuj.pl/}agreementInfo/{http://chomikuj.pl/}AgreementInfo/{http://chomikuj.pl/}cost"
                        ).text
                        self.dl_step_2(idx, agreement_info, cost_info)
