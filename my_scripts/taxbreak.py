#!/usr/bin/env python3
"""
Please note that the git log and git whatchanged commands are commented out because they may not work correctly
if there are no commits or added files. You can uncomment them when you're ready to use them.
Also, this script assumes that all directories in ~/projects/eyproj are intended to be Git repositories.
If this is not the case, you may need to modify the script to only check certain directories.
"""
import os
import subprocess
from datetime import datetime, timedelta

# Set variables
date = datetime.now().strftime("%Y_%m")
git_date = datetime.now().strftime("%Y-%m")
tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
author_name = "Krystian Safjan"
reports_dir = os.path.join(os.getenv("HOME"), "Documents", "copyrights", date)

# Create reports directory if it doesn't exist
os.makedirs(reports_dir, exist_ok=True)


# Define function to run shell commands and return their output
def run_command(command):
    return subprocess.check_output(command, shell=True).decode()


# Find added and modified files in ~/Documents/EY
print(f"Looking for modified files in ~/Documents/EY")
for file_type in ["Modified"]:
    print(f"{file_type} in {os.getenv('HOME')}/Documents/EY")
    files = run_command(
        f"find ~/Documents/EY -type f -ctime -30 -exec stat -c '%w %n' {{}} \; | grep '{date}' | cut -d' ' -f1,4-"
    )
    with open(
        os.path.join(reports_dir, f"{date}_taxbreak_{file_type.lower()}_docs.txt"), "w"
    ) as f:
        f.write(files)
    lines = len(files.split("\n"))
    print(f"- {lines} {file_type.lower()} files saved to: {reports_dir}/{date}_taxbreak_{file_type.lower()}_docs.txt")

print("Looking for added and modified files in git projects in ~/projects/eyproj")
# Check each project in ~/projects/eyproj
for dir in os.listdir(os.path.join(os.getenv("HOME"), "projects", "eyproj")):
    # check if dir is a directory
    if not os.path.isdir(os.path.join(os.getenv("HOME"), "projects", "eyproj", dir)):
        continue
    dir_path = os.path.join(os.getenv("HOME"), "projects", "eyproj", dir)
    os.chdir(dir_path)
    # Check if directory is a git repository
    try:
        is_git = run_command("git rev-parse --is-inside-work-tree").strip() == "true"
    except Exception:
        is_git = False
    if is_git:
        file_commits = os.path.join(reports_dir, f"{date}_{dir}_git_commits.txt")
        files_added = os.path.join(reports_dir, f"{date}_{dir}_git_added_files.txt")
        # Run git log on that dir and save to file
        try:
            commits = run_command(
                f"git log --pretty=format:'%h %ad %d %s [%cn]' --date=short --since='{git_date}-01' | grep '{author_name}' | grep '{git_date}'"
            )
        except Exception:
            commits = ""
        # count lines

        if commits:
            print(f"\n--- {dir_path} ------")
            with open(file_commits, "w") as f:
                f.write(commits)
            lines = len(commits.split("\n"))
            print(f"- {lines} commits to git repo saved to: {file_commits}")

        try:
            added_files = run_command(
                f"git whatchanged --since '{git_date}-01' --until '{tomorrow}' --oneline --name-status --pretty=format: | sort | uniq"
            )
        except Exception as e:
            added_files = ""
            print(e)

        if added_files:
            with open(files_added, "w") as f:
                f.write(added_files)
            lines = len(added_files.split("\n"))
            print(f"- {lines} added files to git repo saved to: {files_added}")
    else:
        # print(f"{dir} - Not a git repository, skipping...")
        pass
