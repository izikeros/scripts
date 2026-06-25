#!/usr/bin/env python3
"""Normalize .git/config in repositories: fix remote URLs and author info.

- Converts git@github.com:izikeros/... to github:izikeros/...
- Sets user.name and user.email for izikeros repos only
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional

TARGET_NAME = "Krystian Safjan"
TARGET_EMAIL = "ksafjan@gmail.com"
TARGET_USER = "izikeros"


def run_git(repo_dir: str, args: list[str], capture: bool = True) -> tuple[int, str]:
    """Run git command in repo directory."""
    try:
        result = subprocess.run(
            ["git"] + args,
            cwd=repo_dir,
            capture_output=capture,
            text=True,
            timeout=10,
        )
        return result.returncode, result.stdout.strip() if capture else ""
    except Exception as e:
        return 1, str(e)


def get_remote_url(repo_dir: str) -> str:
    """Get origin remote URL."""
    code, output = run_git(repo_dir, ["config", "--get", "remote.origin.url"])
    return output if code == 0 else ""


def get_config(repo_dir: str, key: str) -> str:
    """Get git config value."""
    code, output = run_git(repo_dir, ["config", "--local", "--get", key])
    return output if code == 0 else ""


def set_config(repo_dir: str, key: str, value: str, dry_run: bool = False) -> bool:
    """Set git config value."""
    if dry_run:
        return True
    code, _ = run_git(repo_dir, ["config", "--local", key, value])
    return code == 0


def set_remote_url(repo_dir: str, url: str, dry_run: bool = False) -> bool:
    """Set origin remote URL."""
    if dry_run:
        return True
    code, _ = run_git(repo_dir, ["remote", "set-url", "origin", url])
    return code == 0


def is_izikeros_repo(url: str) -> bool:
    """Check if URL points to izikeros's repo."""
    patterns = [
        rf"git@github\.com:/?{TARGET_USER}/",
        rf"https://github\.com/{TARGET_USER}/",
        rf"github:{TARGET_USER}/",
    ]
    return any(re.search(p, url) for p in patterns)


def normalize_url(url: str) -> Optional[str]:
    """Convert various GitHub URL formats to github:izikeros/...
    
    Handles:
    - git@github.com:izikeros/repo.git
    - git@github.com:/izikeros/repo.git (malformed)
    - https://github.com/izikeros/repo.git
    - https://github.com/izikeros/repo (without .git)
    
    Returns normalized URL or None if no change needed.
    """
    # Already normalized
    if url.startswith(f"github:{TARGET_USER}/"):
        return None
    
    # SSH format: git@github.com:izikeros/... or git@github.com:/izikeros/...
    match = re.match(rf"git@github\.com:/?({TARGET_USER}/.+)", url)
    if match:
        return f"github:{match.group(1)}"
    
    # HTTPS format: https://github.com/izikeros/...
    match = re.match(rf"https://github\.com/({TARGET_USER}/.+)", url)
    if match:
        return f"github:{match.group(1)}"
    
    return None


def process_repo(repo_dir: str, dry_run: bool = False) -> dict:
    """Process a single repository. Returns dict with changes made."""
    repo_name = Path(repo_dir).name
    changes = {"name": repo_name, "url": None, "user_name": None, "user_email": None, "skipped": False}
    
    url = get_remote_url(repo_dir)
    
    if not url:
        changes["skipped"] = "no remote"
        return changes
    
    if not is_izikeros_repo(url):
        changes["skipped"] = f"not izikeros repo ({url})"
        return changes
    
    # Check and fix URL
    new_url = normalize_url(url)
    if new_url:
        changes["url"] = (url, new_url)
        set_remote_url(repo_dir, new_url, dry_run)
    
    # Check and fix user.name
    current_name = get_config(repo_dir, "user.name")
    if current_name != TARGET_NAME:
        changes["user_name"] = (current_name or "(not set)", TARGET_NAME)
        set_config(repo_dir, "user.name", TARGET_NAME, dry_run)
    
    # Check and fix user.email
    current_email = get_config(repo_dir, "user.email")
    if current_email != TARGET_EMAIL:
        changes["user_email"] = (current_email or "(not set)", TARGET_EMAIL)
        set_config(repo_dir, "user.email", TARGET_EMAIL, dry_run)
    
    return changes


def find_repos(base_dir: str) -> list[str]:
    """Find all git repos in directory (non-recursive, single level)."""
    repos = []
    base = Path(base_dir)
    
    if not base.exists():
        return repos
    
    # Check if base itself is a repo
    if (base / ".git").is_dir():
        repos.append(str(base))
        return repos
    
    # Check immediate children
    for entry in sorted(base.iterdir()):
        if entry.is_dir() and (entry / ".git").is_dir():
            repos.append(str(entry))
    
    return repos


def main():
    parser = argparse.ArgumentParser(
        description="Normalize git configs: fix remote URLs and author info for izikeros repos."
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default="~/projects/priv",
        help="Directory to scan (default: ~/projects/priv)",
    )
    parser.add_argument(
        "-n", "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )
    
    args = parser.parse_args()
    base_dir = os.path.expanduser(args.directory)
    
    if args.dry_run:
        print("DRY RUN - no changes will be made\n")
    
    print(f"Scanning {base_dir}...\n")
    
    repos = find_repos(base_dir)
    if not repos:
        print("No repositories found.", file=sys.stderr)
        sys.exit(1)
    
    stats = {"updated": 0, "skipped": 0, "unchanged": 0}
    
    for repo in repos:
        changes = process_repo(repo, args.dry_run)
        name = changes["name"]
        
        if changes["skipped"]:
            print(f"[{name}] Skipped: {changes['skipped']}")
            stats["skipped"] += 1
            continue
        
        has_changes = any([changes["url"], changes["user_name"], changes["user_email"]])
        
        if not has_changes:
            print(f"[{name}] Already correct")
            stats["unchanged"] += 1
            continue
        
        stats["updated"] += 1
        
        if changes["url"]:
            old, new = changes["url"]
            print(f"[{name}] Remote URL: {old} -> {new}")
        
        if changes["user_name"]:
            old, new = changes["user_name"]
            print(f"[{name}] user.name: {old} -> {new}")
        
        if changes["user_email"]:
            old, new = changes["user_email"]
            print(f"[{name}] user.email: {old} -> {new}")
    
    print(f"\nSummary: {stats['updated']} updated, {stats['skipped']} skipped, {stats['unchanged']} already correct")
    
    if args.dry_run and stats["updated"] > 0:
        print("\nRun without --dry-run to apply changes.")


if __name__ == "__main__":
    main()
