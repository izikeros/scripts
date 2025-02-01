#!/usr/bin/env python3
import argparse
import logging
import multiprocessing as mp
import os
import sys
from datetime import datetime, timedelta

DEFAULT_IGNORES = {
    ".git",
    ".venv",
    "__pycache__",
    ".pytest_cache",
    "*.pyc",
    "*.pyo",
    "*.pyd",
    "*.egg-info",
}

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def should_ignore(path, ignores):
    path_parts = path.split(os.sep)
    return any(
        any(
            part.startswith(ignore.strip("*")) or part.endswith(ignore.strip("*"))
            for part in path_parts
        )
        for ignore in ignores
    )


def process_directory(args):
    dirpath, filenames, root_dir, cutoff, ignores = args
    try:
        rel_path = os.path.relpath(dirpath, root_dir)
        if rel_path == ".":
            rel_path = ""

        if should_ignore(rel_path, ignores):
            return None

        modified_files = []
        for filename in filenames:
            if should_ignore(filename, ignores):
                continue

            full_path = os.path.join(dirpath, filename)
            try:
                mod_time = datetime.fromtimestamp(os.path.getmtime(full_path))

                if mod_time > cutoff:
                    modified_files.append((filename, mod_time))
            except OSError as e:
                logging.warning(f"Error accessing {full_path}: {e}")
            except Exception as e:
                logging.error(f"Unexpected error processing {full_path}: {e}")

        return (rel_path, modified_files) if modified_files else None
    except Exception as e:
        logging.error(f"Error processing directory {dirpath}: {e}")
        return None


def get_modified_files(root_dir, days, sort_by, ignores):
    now = datetime.now()
    cutoff = now - timedelta(days=days)

    pool = mp.Pool(processes=mp.cpu_count())

    args_list = []
    for dirpath, dirnames, filenames in os.walk(root_dir, followlinks=False):
        args_list.append((dirpath, filenames, root_dir, cutoff, ignores))

    results = pool.map(process_directory, args_list)
    pool.close()
    pool.join()

    modified_files = {k: v for result in results if result for k, v in [result]}

    # Sort the results
    if sort_by == "alpha":
        return dict(sorted(modified_files.items()))
    elif sort_by == "date":
        return dict(
            sorted(
                modified_files.items(),
                key=lambda x: max(file[1] for file in x[1]),
                reverse=True,
            )
        )

    return modified_files


def main():
    parser = argparse.ArgumentParser(
        description="List files modified in the last N days grouped by directory."
    )
    parser.add_argument("root_dir", help="The root directory to analyze")
    parser.add_argument("days", type=int, help="Number of days to look back")
    parser.add_argument(
        "--dirs-only", action="store_true", help="List only directory names"
    )
    parser.add_argument(
        "--top-dirs-only",
        action="store_true",
        help="List only top-level directory names",
    )
    parser.add_argument(
        "--sort",
        choices=["alpha", "date"],
        default="alpha",
        help="Sort output by directory name (alpha) or modification date (date)",
    )
    parser.add_argument(
        "--ignored-add", nargs="*", help="Additional patterns to ignore"
    )
    parser.add_argument(
        "--ignore", nargs="*", help="Patterns to ignore (overrides defaults)"
    )

    args = parser.parse_args()

    if args.ignore:
        ignores = set(args.ignore)
    else:
        ignores = DEFAULT_IGNORES.copy()
        if args.ignored_add:
            ignores.update(args.ignored_add)

    try:
        modified_files = get_modified_files(
            args.root_dir, args.days, args.sort, ignores
        )

        if args.top_dirs_only:
            top_dirs = set(
                dir_path.split(os.sep)[0] for dir_path in modified_files.keys()
            )
            for dir_path in sorted(top_dirs):
                print(dir_path)
        else:
            for dir_path, files in modified_files.items():
                if args.dirs_only:
                    print(dir_path)
                else:
                    print(f"\n{dir_path}:")
                    for filename, mod_time in files:
                        print(
                            f"  {filename} (Modified: {mod_time.strftime('%Y-%m-%d %H:%M:%S')})"
                        )
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
