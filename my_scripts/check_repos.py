#!/usr/bin/env python3

import os

# Define function to check if there are any uncommitted changes
def has_uncommitted_changes(repo_path):
    cmd = 'cd {} && git status --porcelain'.format(repo_path)
    output = os.popen(cmd).read()
    return bool(output.strip())

# Define function to check if there are any commits to push
def has_commits_to_push(repo_path):
    cmd = 'cd {} && git log origin/HEAD..HEAD'.format(repo_path)
    output = os.popen(cmd).read()
    return bool(output.strip())

# Define function to check if the branch is outdated
def is_branch_outdated(repo_path):
    cmd = 'cd {} && git status -sb'.format(repo_path)
    output = os.popen(cmd).read()
    if 'behind' in output:
        return True
    else:
        return False

# Main function to check all repos in a directory
def check_repos(directory):
    for item in os.listdir(directory):
        if os.path.isdir(os.path.join(directory, item)):
            repo_path = os.path.join(directory, item)
            if os.path.isdir(os.path.join(repo_path, '.git')):
                print(repo_path)
                if has_uncommitted_changes(repo_path):
                    print('  Uncommitted changes')
                if has_commits_to_push(repo_path):
                    print('  Commits to push')
                if is_branch_outdated(repo_path):
                    print('  Branch is outdated')

# Call main function with directory name
check_repos(os.getcwd())
