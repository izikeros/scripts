#!/usr/bin/env python3
"""Check if git repos in given location are clean (no uncommitted changes, all commits pushed).

Usage:
    ron_100_check_if_repos_are_clean.py [OPTIONS] [DIRECTORIES...]

If no directories provided, defaults to ~/dotfiles, ~/projects/priv/*, ~/projects/ai/*
"""

import argparse
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

try:
    from rich.console import Console
    from rich.table import Table
    from rich.progress import Progress, SpinnerColumn, TextColumn

    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False


@dataclass
class RepoInfo:
    path: str
    status: str  # "clean", "dirty", "norepo"
    hosting: str
    email: str
    commits_ahead: int
    size: str
    has_remote: bool = True


def get_default_directories() -> list[tuple[str, bool]]:
    """Get default directories to scan.
    
    Returns list of (path, expand) tuples where expand indicates
    whether to scan subdirectories or check the path itself.
    """
    home = Path.home()
    dirs = []

    # Single repos (not expanded) - check these as-is
    for single_repo in ["dotfiles", "scripts"]:
        repo_path = home / single_repo
        if repo_path.exists():
            dirs.append((str(repo_path), False))

    # Directories to expand (scan all subdirs)
    for subdir in ["priv", "ai"]:
        parent = home / "projects" / subdir
        if parent.exists():
            dirs.append((str(parent), True))

    return dirs


def get_repos_from_location(dir_name: str, expand: bool = False) -> list[str]:
    """Get list of directories to check.
    
    Args:
        dir_name: Directory path to check
        expand: If True, return all immediate subdirectories.
                If False, return just this directory.
    
    Returns all directories (git or not). Non-git dirs will be
    classified as 'norepo' by analyze_repo().
    """
    repos = []
    base = Path(dir_name)

    if not base.exists():
        return repos

    if not expand:
        # Just check this single directory
        repos.append(str(base))
        return repos

    # Expand: return all immediate subdirectories
    try:
        for entry in sorted(base.iterdir()):
            # Skip hidden directories
            if entry.name.startswith("."):
                continue
            if entry.is_dir():
                repos.append(str(entry))
    except PermissionError:
        pass

    return repos


def parse_git_config(repo_dir: str) -> tuple[str, str]:
    """Parse .git/config to extract hosting URL and user email in one pass."""
    config_path = Path(repo_dir) / ".git" / "config"
    hosting = ""
    email = ""

    try:
        with open(config_path) as f:
            in_remote_origin = False
            in_user = False

            for line in f:
                line_stripped = line.strip()

                if line_stripped.startswith('[remote "origin"]'):
                    in_remote_origin = True
                    in_user = False
                    continue
                elif line_stripped.startswith("[user]"):
                    in_user = True
                    in_remote_origin = False
                    continue
                elif line_stripped.startswith("["):
                    in_remote_origin = False
                    in_user = False
                    continue

                if in_remote_origin and line_stripped.startswith("url"):
                    parts = line_stripped.split("=", 1)
                    if len(parts) > 1:
                        url = parts[1].strip()
                        hosting = _clean_hosting_url(url)

                if in_user and line_stripped.startswith("email"):
                    parts = line_stripped.split("=", 1)
                    if len(parts) > 1:
                        email = parts[1].strip()

                if hosting and email:
                    break
    except (OSError, IOError):
        pass

    return hosting, email


def _clean_hosting_url(url: str) -> str:
    """Extract hostname from git URL (supports https and ssh formats)."""
    url = url.strip()

    # https://github.com/user/repo.git -> github.com/user
    if url.startswith("https://") or url.startswith("http://"):
        url = url.split("://", 1)[1]
        parts = url.split("/")
        if len(parts) >= 2:
            return f"{parts[0]}/{parts[1]}"
        return parts[0] if parts else ""

    # git@github.com:user/repo.git -> github.com/user
    if "@" in url and ":" in url:
        host_part = url.split("@", 1)[1]
        host, path = host_part.split(":", 1)
        user = path.split("/")[0] if "/" in path else path.split(".")[0]
        return f"{host}/{user}"

    # github:user/repo -> github/user
    if ":" in url:
        parts = url.split(":")
        host = parts[0]
        user = parts[1].split("/")[0] if len(parts) > 1 else ""
        return f"{host}/{user}"

    return url


def check_repo_status(repo_dir: str) -> tuple[str, int]:
    """Check if repo is clean and count commits ahead of remote."""
    try:
        # Run git status --porcelain (empty = clean)
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=repo_dir,
            capture_output=True,
            text=True,
            timeout=10,
        )
        is_clean = result.returncode == 0 and not result.stdout.strip()
        status = "clean" if is_clean else "dirty"

        # Count commits ahead of upstream
        commits_ahead = 0
        result = subprocess.run(
            ["git", "rev-list", "--count", "@{u}..HEAD"],
            cwd=repo_dir,
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            try:
                commits_ahead = int(result.stdout.strip())
            except ValueError:
                pass

        return status, commits_ahead
    except subprocess.TimeoutExpired:
        return "timeout", 0
    except Exception:
        return "error", 0


def get_repo_size(repo_dir: str) -> str:
    """Get repository size (fast approximation)."""
    try:
        result = subprocess.run(
            ["du", "-sh", repo_dir],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0:
            return result.stdout.split()[0]
    except Exception:
        pass
    return "?"


def analyze_repo(path: str) -> RepoInfo:
    """Analyze a single repository (designed for parallel execution)."""
    git_dir = Path(path) / ".git"

    if not git_dir.is_dir():
        return RepoInfo(
            path=path,
            status="norepo",
            hosting="",
            email="",
            commits_ahead=0,
            size=get_repo_size(path),
            has_remote=False,
        )

    hosting, email = parse_git_config(path)
    status, commits_ahead = check_repo_status(path)
    size = get_repo_size(path)
    has_remote = bool(hosting)

    return RepoInfo(
        path=path,
        status=status,
        hosting=hosting,
        email=email,
        commits_ahead=commits_ahead,
        size=size,
        has_remote=has_remote,
    )


def analyze_repos_parallel(repos: list[str], max_workers: int = 8) -> list[RepoInfo]:
    """Analyze multiple repos in parallel."""
    results = []

    if RICH_AVAILABLE:
        console = Console(stderr=True)
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
            transient=True,
        ) as progress:
            task = progress.add_task(f"Scanning {len(repos)} repos...", total=len(repos))

            with ThreadPoolExecutor(max_workers=max_workers) as executor:
                futures = {executor.submit(analyze_repo, repo): repo for repo in repos}
                for future in as_completed(futures):
                    results.append(future.result())
                    progress.advance(task)
    else:
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            results = list(executor.map(analyze_repo, repos))

    return results


def _sort_key(info: RepoInfo) -> tuple:
    """Sort key: dirty first, then local-only, then norepo, then clean."""
    priority = {
        "dirty": 0,
        "error": 1,
        "timeout": 1,
    }
    status_priority = priority.get(info.status, 3)
    # Local-only repos (has .git but no remote) get priority 2
    if info.status not in priority and info.status != "norepo" and not info.has_remote:
        status_priority = 2
    # norepo gets priority 2.5 (after local-only)
    if info.status == "norepo":
        status_priority = 2.5
    return (status_priority, info.path)


def _needs_attention(info: RepoInfo) -> bool:
    """Check if repo needs attention (not fully clean)."""
    if info.status != "clean":
        return True
    if info.commits_ahead > 0:
        return True
    if not info.has_remote:
        return True
    return False


def print_results_rich(results: list[RepoInfo], home: str, dirty_only: bool = False, actionable: bool = False):
    """Print results using rich table."""
    console = Console()

    table = Table(show_header=True, header_style="bold")
    table.add_column("Status", width=8)
    table.add_column("Size", width=6)
    table.add_column("Repository", min_width=30)
    table.add_column("Hosting", min_width=20)
    table.add_column("Email", min_width=20)
    table.add_column("Ahead", width=6)

    status_styles = {
        "clean": "[green]clean[/green]",
        "dirty": "[bold red]dirty[/bold red]",
        "norepo": "[yellow]norepo[/yellow]",
        "error": "[red]error[/red]",
        "timeout": "[red]timeout[/red]",
    }

    for info in sorted(results, key=_sort_key):
        # Filter logic
        if actionable and not _needs_attention(info):
            continue
        if dirty_only and info.status == "clean" and info.has_remote:
            continue

        display_path = info.path.replace(home + "/", "~/")
        status_text = status_styles.get(info.status, info.status)
        ahead_text = f"[bold red]+{info.commits_ahead}[/bold red]" if info.commits_ahead > 0 else ""

        # Determine hosting display with warnings
        if info.status == "norepo":
            hosting_text = "[bold yellow]NOT A GIT REPO[/bold yellow]"
        elif not info.has_remote:
            hosting_text = "[bold magenta]LOCAL ONLY[/bold magenta]"
        else:
            hosting_text = info.hosting

        table.add_row(
            status_text,
            info.size,
            display_path,
            hosting_text,
            info.email,
            ahead_text,
        )

    console.print(table)

    # Summary
    total = len(results)
    clean = sum(1 for r in results if r.status == "clean" and r.has_remote)
    dirty = sum(1 for r in results if r.status == "dirty")
    norepo = sum(1 for r in results if r.status == "norepo")
    local_only = sum(1 for r in results if r.status != "norepo" and not r.has_remote)
    with_commits = sum(1 for r in results if r.commits_ahead > 0)

    summary_parts = [
        f"[green]{clean} clean[/green]",
        f"[red]{dirty} dirty[/red]",
    ]
    if local_only:
        summary_parts.append(f"[bold magenta]{local_only} local-only[/bold magenta]")
    if norepo:
        summary_parts.append(f"[yellow]{norepo} not git[/yellow]")
    if with_commits:
        summary_parts.append(f"[bold red]{with_commits} unpushed[/bold red]")

    console.print(f"\n[bold]Summary:[/bold] {total} dirs: " + ", ".join(summary_parts))


def print_results_plain(results: list[RepoInfo], home: str, dirty_only: bool = False, actionable: bool = False):
    """Print results without rich (fallback)."""
    print(f"{'STATUS':<8} {'SIZE':<6} {'REPOSITORY':<40} {'HOSTING':<25} {'EMAIL':<25} {'AHEAD':<6}")
    print("-" * 110)

    for info in sorted(results, key=_sort_key):
        # Filter logic
        if actionable and not _needs_attention(info):
            continue
        if dirty_only and info.status == "clean" and info.has_remote:
            continue

        display_path = info.path.replace(home + "/", "~/")
        ahead_text = f"+{info.commits_ahead}" if info.commits_ahead > 0 else ""

        # Determine hosting display with warnings
        if info.status == "norepo":
            hosting_text = "[NO GIT]"
        elif not info.has_remote:
            hosting_text = "[LOCAL]"
        else:
            hosting_text = info.hosting

        print(f"{info.status:<8} {info.size:<6} {display_path:<40} {hosting_text:<25} {info.email:<25} {ahead_text:<6}")

    total = len(results)
    clean = sum(1 for r in results if r.status == "clean" and r.has_remote)
    dirty = sum(1 for r in results if r.status == "dirty")
    norepo = sum(1 for r in results if r.status == "norepo")
    local_only = sum(1 for r in results if r.status != "norepo" and not r.has_remote)
    with_commits = sum(1 for r in results if r.commits_ahead > 0)

    summary_parts = [f"{clean} clean", f"{dirty} dirty"]
    if local_only:
        summary_parts.append(f"{local_only} local-only")
    if norepo:
        summary_parts.append(f"{norepo} not git")
    if with_commits:
        summary_parts.append(f"{with_commits} unpushed")

    print(f"\nSummary: {total} dirs: " + ", ".join(summary_parts))


def main():
    parser = argparse.ArgumentParser(
        description="Check if git repos are clean (no uncommitted changes, all commits pushed)."
    )
    parser.add_argument(
        "directories",
        nargs="*",
        help="Directories to scan (defaults to ~/dotfiles, ~/projects/priv/*, ~/projects/ai/*)",
    )
    parser.add_argument(
        "-d", "--dirty-only",
        action="store_true",
        help="Show only dirty repos (legacy, use -a for more comprehensive filter)",
    )
    parser.add_argument(
        "-a", "--actionable",
        action="store_true",
        help="Show only repos needing attention (dirty, unpushed, local-only, not git)",
    )
    parser.add_argument(
        "-j", "--jobs",
        type=int,
        default=8,
        help="Number of parallel workers (default: 8)",
    )
    parser.add_argument(
        "--no-color",
        action="store_true",
        help="Disable colored output",
    )

    args = parser.parse_args()

    # Get directories to scan
    if args.directories:
        # CLI args: expand each directory to find subdirs
        dir_specs = [(d, True) for d in args.directories]
    else:
        dir_specs = get_default_directories()

    if not dir_specs:
        print("No directories to scan.", file=sys.stderr)
        sys.exit(1)

    # Collect all repos/dirs to check
    repos = []
    for d, expand in dir_specs:
        expanded = os.path.expanduser(d)
        repos.extend(get_repos_from_location(expanded, expand=expand))

    if not repos:
        print("No repositories found.", file=sys.stderr)
        sys.exit(1)

    # Analyze repos in parallel
    results = analyze_repos_parallel(repos, max_workers=args.jobs)

    # Print results
    home = str(Path.home())
    if RICH_AVAILABLE and not args.no_color:
        print_results_rich(results, home, args.dirty_only, args.actionable)
    else:
        print_results_plain(results, home, args.dirty_only, args.actionable)

    # Exit with error code if any dirty repos
    dirty_count = sum(1 for r in results if r.status == "dirty" or r.commits_ahead > 0)
    sys.exit(1 if dirty_count > 0 else 0)


if __name__ == "__main__":
    main()
