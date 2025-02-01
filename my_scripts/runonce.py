#!/usr/bin/env python3
import hashlib
import os
import sys
import time


def help_and_exit(exit_code: int = 0) -> None:
    """Prints the help message and exits the script."""
    print(
        f"""{os.path.basename(__file__)} [options] COMMAND

Run COMMAND but only once per interval. See '$HOME/.runonce-*' for lock files.

options:
    -h, -?      help
    -i MINS     interval in minutes (default 480)"""
    )
    sys.exit(exit_code)


def main() -> None:
    """Main function that executes the command only once within the specified interval."""

    # Default interval in minutes
    interval: int = 480

    # Parse command-line arguments
    try:
        i: int = 1
        while i < len(sys.argv):
            arg: str = sys.argv[i]
            if arg == "-h" or arg == "-?":
                help_and_exit()
            elif arg == "-i":
                interval = int(sys.argv[i + 1])
                i += 1
            i += 1
    except (IndexError, ValueError):
        help_and_exit(1)

    # Get the command to run
    command: str = " ".join(sys.argv[i:])
    if not command:
        help_and_exit(1)

    # Get the lock file path
    lock: str = os.path.expanduser(
        f"~/.runonce-{hashlib.md5(command.encode()).hexdigest()}"
    )

    # Check if the lock file exists
    if not os.path.exists(lock):
        os.system(command)
        open(lock, "w").close()
    else:
        lock_modified: float = os.path.getmtime(lock)
        current_time: float = time.time()
        if current_time - lock_modified >= interval * 60:
            os.system(command)
            os.utime(lock)


if __name__ == "__main__":
    main()
