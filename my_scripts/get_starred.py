#!/usr/bin/env python3
"""download github starred repos"""
import json

import requests

GITHUB_USER = "izikeros"


def download_paged_json():
    headers = {"Accept": "application/vnd.github.v3.star+json"}
    pages = []
    page = 0
    get_next_page = True
    while get_next_page:
        print(f"Downloading page {page}")
        url = f"https://api.github.com/users/{GITHUB_USER}/starred?per_page=100&page={page}"
        raw_response = requests.get(url, headers=headers)
        if raw_response.status_code != 200:
            return None
        response = json.loads(raw_response.content.decode("utf-8"))
        if response:
            pages.extend(response)
            page += 1
        else:
            get_next_page = False
    return pages


def extract_interesting_info(project_dict):
    try:
        if project_dict["repo"]["license"]:
            license_info = project_dict["repo"]["license"].get("key", "")
        else:
            license_info = ""
    except TypeError:
        license_info = ""

    if license_info == "":
        pass

    return {
        # "starred_at": project_dict["starred_at"],
        "name": project_dict["repo"]["name"],
        # "full_name": project_dict["repo"]["full_name"],
        "description": project_dict["repo"]["description"],
        # "created_at": project_dict["repo"]["created_at"][:10],
        # "updated_at": project_dict["repo"]["updated_at"][:10],
        # "homepage": project_dict["repo"]["homepage"],
        # "size": project_dict["repo"]["size"],
        "stargazers_count": project_dict["repo"]["stargazers_count"],
        "html_url": project_dict["repo"]["html_url"],
        # "language": project_dict["repo"]["language"],
        # "forks_count": project_dict["repo"]["forks_count"],
        # "archived": project_dict["repo"]["archived"],
        # "open_issues_count": project_dict["repo"]["open_issues_count"],
        # "license": license_info,
        "topics": ", ".join(project_dict["repo"]["topics"]),
    }


if __name__ == "__main__":
    res = download_paged_json()
    filtered_res = [extract_interesting_info(project_dict) for project_dict in res]
    jd = "export const orders = " + json.dumps(filtered_res, indent=2)
    file = (
        "/Users/krystian.safjan/projects/ext/filter-and-sort-dynamically-created-table-with"
        "-vanilla-javascript-demo/js/orders.js "
    )
    with open(file, "w") as f:
        write_res = f.write(jd)

    print(f"{len(filtered_res)} repos downloaded and saved to {file}")
