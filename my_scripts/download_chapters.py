# source: https://stackoverflow.com/a/78215570/3247880
# author: https://stackoverflow.com/users/10215038/qzdl
import json
import re
import sys
from html import unescape

import requests


def rget(d, *k):
    dd = d.get(k[0], {})
    return dd if len(k) < 2 else rget(dd, *k[1:])


def chapters(id):
    return [
        {
            "title": rget(dd, "title", "simpleText"),
            "time_hs": rget(dd, "timeDescription", "simpleText"),
            "time_s": rget(dd, "onTap", "watchEndpoint", "startTimeSeconds"),
            "thumbnails": rget(dd, "thumbnail", "thumbnails"),
        }
        for d in rget(
            json.loads(
                unescape(requests.get(f"https://youtu.be/{id}").text)
                .split("ytInitialData = ")[1]
                .split(";</script")[0]
            )["engagementPanels"][1],
            "engagementPanelSectionListRenderer",
            "content",
            "macroMarkersListRenderer",
            "contents",
        )
        if (dd := d.get("macroMarkersListItemRenderer"))
    ]


if __name__ == "__main__":
    # get url as cli argument
    try:
        url = sys.argv[1]
    except IndexError:
        print("Usage: python download_chapters.py <youtube_url>")
        sys.exit(1)

    # extract video id from youtube url
    # https://www.youtube.com/watch?v=g68qlo9Izf0
    # https://www.youtube.com/watch?v=g68qlo9Izf0&t=3164s
    # or shortened
    # https://youtu.be/g68qlo9Izf0
    # or accept just the id
    # g68qlo9Izf0

    if "youtube.com" in url:
        # use regex
        video_id = re.search(r"v=([^&]+)", url).group(1)
    elif "youtu.be" in url:
        video_id = url.split("/")[-1]
    else:
        video_id = url

    ch = chapters(video_id)
    # loop over all chapters (items in the list) and return list of chapter titles
    for idx, s in enumerate(ch):
        print(f"{idx}.\t{s['title']}")
