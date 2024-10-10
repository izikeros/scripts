#!/usr/bin/env python3
import os
import sys
import subprocess
import argparse
import urllib.request
import urllib.error

def run_command(command, verbose=False):
    if verbose:
        print(f"Running: {' '.join(command)}")
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)
    return result.stdout.strip()

def is_git_repo():
    return os.path.isdir('.git')

def init_git_repo(verbose=False):
    if not is_git_repo():
        run_command(['git', 'init'], verbose)
        print("Git repository initialized.")

def create_gitignore():
    if not os.path.exists('.gitignore'):
        url = "https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore"
        try:
            with urllib.request.urlopen(url) as response:
                content = response.read().decode('utf-8')
            with open('.gitignore', 'w') as f:
                f.write(content)
            print(".gitignore file created with Python template.")
        except urllib.error.URLError as e:
            print(f"Failed to fetch .gitignore template: {e}. Please create it manually.")

def create_readme():
    if not os.path.exists('README.md'):
        with open('README.md', 'w') as f:
            f.write("# Project Title\n\nAdd a brief description of your project here.")
        print("README.md file created.")

def set_repo_visibility(private, verbose=False):
    visibility = 'private' if private else 'public'
    run_command(['gh', 'repo', 'edit', '--visibility', visibility], verbose)
    print(f"Repository visibility set to {visibility}.")

def create_github_repo(name, private=True, verbose=False):
    visibility = '--private' if private else '--public'
    try:
        output = run_command(['gh', 'repo', 'create', name, visibility, '--source=.', '--remote=origin', '--push'], verbose)
        print(f"GitHub repository '{name}' created and set as remote 'origin'.")
        print("Initial files pushed to the repository.")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error creating GitHub repository: {e}")
        print("Make sure you have installed the GitHub CLI (gh) and are authenticated.")
        print("You can authenticate by running: gh auth login")
        return False

def get_repo_url(verbose=False):
    try:
        url = run_command(['gh', 'repo', 'view', '--json', 'url', '-q', '.url'], verbose)
        return url
    except subprocess.CalledProcessError:
        return None

def main():
    parser = argparse.ArgumentParser(description="Initialize and configure a Git repository.")
    parser.add_argument('--public', action='store_true', help="Make the repository public (default is private)")
    parser.add_argument('--verbose', action='store_true', help="Enable verbose output")
    parser.add_argument('--branch', default='main', help="Set the initial branch name (default is 'main')")
    args = parser.parse_args()

    verbose = args.verbose
    private = not args.public

    # Initialize Git repository if not already initialized
    init_git_repo(verbose)

    # Create .gitignore file
    create_gitignore()

    # Create README.md file
    create_readme()

    # Set the initial branch name
    run_command(['git', 'checkout', '-b', args.branch], verbose)

    # Check if a remote repository already exists
    remote_exists = run_command(['git', 'remote'], verbose)

    if not remote_exists:
        # Create GitHub repository
        repo_name = os.path.basename(os.getcwd())
        repo_created = create_github_repo(repo_name, private, verbose)
        if not repo_created:
            print("Failed to create GitHub repository. Exiting.")
            sys.exit(1)
    else:
        # Set repository visibility
        set_repo_visibility(private, verbose)

    # Get and display the repository URL
    repo_url = get_repo_url(verbose)
    if repo_url:
        print(f"\nYou can visit the repo under this URL: {repo_url}")
    else:
        print("\nUnable to retrieve the repository URL. Please check your GitHub configuration.")

    print("Repository setup complete.")

if __name__ == "__main__":
    main()