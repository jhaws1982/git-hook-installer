[![License](https://img.shields.io/github/license/jhaws1982/git-hook-installer.svg)](https://github.com/jhaws1982/git-hook-installer/blob/master/LICENSE)

# git-hook-installer

I needed a script to easily install new git hooks to any repository, including submodules. All that is required is to download the script to a known location (I like to keep all my hooks together in one location) and run this script, pointing it at the script, the name of the hook, and the repository.

This script also supports installing hooks globally if that is desired.

Personally, I use this to install a git-pre-commit-format script to run verify code formatting using clang-format (https://github.com/barisione/clang-format-hooks) and Commitizen (https://github.com/commitizen/cz-cli) to prepare and format my commit logs per Conventional Commits (https://www.conventionalcommits.org).
