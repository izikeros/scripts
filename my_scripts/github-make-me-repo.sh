#!/usr/bin/env bash

set -e

verbose=false
private=true
branch="main"

print_verbose() {
    if [ "$verbose" = true ]; then
        echo "$@"
    fi
}

init_git_repo() {
    if [ ! -d .git ]; then
        print_verbose "Initializing Git repository"
        git init
        echo "Git repository initialized."
    fi
}

create_gitignore() {
    if [ ! -f .gitignore ]; then
        print_verbose "Creating .gitignore file"
        curl -s https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore -o .gitignore
        echo ".gitignore file created with Python template."
    fi
}

create_readme() {
    if [ ! -f README.md ]; then
        print_verbose "Creating README.md file"
        echo "# Project Title

Add a brief description of your project here." > README.md
        echo "README.md file created."
    fi
}

set_repo_visibility() {
    local visibility="private"
    if [ "$private" = false ]; then
        visibility="public"
    fi
    print_verbose "Setting repository visibility to $visibility"
    gh repo edit --visibility "$visibility"
    echo "Repository visibility set to $visibility."
}

create_github_repo() {
    local repo_name="$1"
    local visibility="--private"
    if [ "$private" = false ]; then
        visibility="--public"
    fi
    print_verbose "Creating GitHub repository: $repo_name"
    if gh repo create "$repo_name" "$visibility" --source=. --remote=origin --push; then
        echo "GitHub repository '$repo_name' created and set as remote 'origin'."
        echo "Initial files pushed to the repository."
        return 0
    else
        echo "Error creating GitHub repository."
        echo "Make sure you have installed the GitHub CLI (gh) and are authenticated."
        echo "You can authenticate by running: gh auth login"
        return 1
    fi
}

get_repo_url() {
    print_verbose "Getting repository URL"
    gh repo view --json url -q .url
}

usage() {
    echo "Usage: $0 [--public] [--verbose] [--branch <branch_name>]"
    echo "  --public    Make the repository public (default is private)"
    echo "  --verbose   Enable verbose output"
    echo "  --branch    Set the initial branch name (default is 'main')"
    exit 1
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --public) private=false ;;
        --verbose) verbose=true ;;
        --branch) branch="$2"; shift ;;
        --help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

# Main script
init_git_repo
create_gitignore
create_readme

print_verbose "Setting initial branch to $branch"
git checkout -b "$branch"

if ! git remote | grep -q .; then
    repo_name=$(basename "$(pwd)")
    if create_github_repo "$repo_name"; then
        repo_url=$(get_repo_url)
        if [ -n "$repo_url" ]; then
            echo "You can visit the repo under this URL: $repo_url"
        else
            echo "Unable to retrieve the repository URL. Please check your GitHub configuration."
        fi
    else
        echo "Failed to create GitHub repository. Exiting."
        exit 1
    fi
else
    set_repo_visibility
    repo_url=$(get_repo_url)
    if [ -n "$repo_url" ]; then
        echo "You can visit the repo under this URL: $repo_url"
    else
        echo "Unable to retrieve the repository URL. Please check your GitHub configuration."
    fi
fi

echo "Repository setup complete."