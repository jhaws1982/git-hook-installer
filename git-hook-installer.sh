#!/bin/bash
# Install script as a git hook to a given repo or global hooks directory

# Saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset
trap 'echo "An error occurred ($?); aborting." 1>&2' ERR

! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo "getopt --test failed in this environment. getopt enhanced version is required to run this script."
    exit 1
fi

# Create red error messages
RED='\033[0;31m'
GRN='\033[0;32m'
NC='\033[0m' # No Color

usage()
{
  echo -e ""
  echo -e " ** Install git hook"
  echo -e " ** Install a script as a named git hook in a given git repository"
  echo -e " ** Optionally install the script for all submodules in the repository"
  echo -e " ** Optionally install the script to a particular global hooks folder"
  echo -e ""
  echo -e " ** USAGE: $0 <script> <hook-name> <directory/repository> [options]"
  echo -e ""
  echo -e "      Example: $0 git-pre-commit-format pre-commit ../zRPC"
  echo -e ""
  echo -e "      Optional arguments:"
  echo -e "        -s, --no-submodules  Do not install git hook for each submodule in the repository"
  echo -e ""
  echo -e "        -g, --global         Provided folder is a global hooks folder, not a repository"
  echo -e ""
  echo -e "        -v, --verbose"
  echo -e ""
}

###############################################################################
# Handle optional arguments
###############################################################################
# Call getopt to validate the provided input.
SHORTOPTS=s,g,v
LONGOPTS=no-submodules,global,verbose

# -use ! and PIPESTATUS to get exit code with errexit set
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$SHORTOPTS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    # then getopt has complained about wrong arguments to stdout
    usage
    exit 3
fi

# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

# Check proper usage
if [[ $# -lt 4 ]]; then
  usage
  exit 2
fi

# Set defaults
SUBMODULES=1
GLOBAL=0
VERBOSE=0

VALID_HOOKS=("pre-applypatch" "applypatch-msg" "post-applypatch" "pre-commit" "prepare-commit-msg" "commit-msg" "post-commit" "pre-merge-commit" "pre-push" "pre-rebase" "post-checkout" "post-merge" "pre-receive" "update" "post-receive" "post-update" "pre-auto-gc")

while true; do
  case "$1" in
    -g|--global)
      GLOBAL=1
      ;;
    -v|--verbose)
      VERBOSE=1
      ;;
    -s|--no-submodules)
      SUBMODULES=0
      ;;
    --)
      shift;
      break;
      ;;
    *)
      echo -e "${RED} !! Invalid Arguments ${NC}"
      usage
      exit 4
      ;;
    esac
  shift
done

# Grab arguments
SCRIPT=$1
HOOK=$2
REPO=$3
CWD=$(pwd)

# Validate hook name
if [[ ! " ${VALID_HOOKS[*]} " =~ " ${HOOK} " ]]; then
	echo -e "${RED} !! Specified hook '${HOOK}' is invalid. Supported hooks are:${NC}"
    for h in ${VALID_HOOKS[@]}; do
	  echo -e "${RED}            $h${NC}"
	done
	exit 5
fi

install_hook()
{  
  if [ 0 = $GLOBAL ]; then
    HOOK_PATH=`git rev-parse --git-path hooks`
  else
    HOOK_PATH=$REPO
  fi
  if [ 1 = $VERBOSE ]; then
    echo -e " -> Installing '${SCRIPT}' as '${HOOK}' to '${HOOK_PATH}'"
	echo ""
  fi
  ln -sf ${CWD}/${SCRIPT} ${HOOK_PATH}/${HOOK}
}

cd $REPO
if [ 0 = $GLOBAL ]; then
  
  # Validate git repository (if GLOBAL=0)
  if [[ true = $(git rev-parse --is-inside-work-tree) ]]; then
  
    # Install hooks by creating symlink from script to hook
    echo -e "${GRN} -> Installing hook into repository at '${REPO}'... ${NC}"
    install_hook
	
	if [ 1 = $SUBMODULES ]; then
      echo -e "${GRN} -> Installing hook into repository's submodules... ${NC}"
      cd $REPO
  	  git submodule foreach --quiet --recursive '
        HOOK_PATH=`git rev-parse --git-path hooks`
		if [ 1 = '$VERBOSE' ]; then
          echo " -> Installing '${SCRIPT}' as '${HOOK}' to ${HOOK_PATH}"
		  echo ""
		fi
        ln -sf '${CWD}'/'${SCRIPT}' ${HOOK_PATH}/'${HOOK}'
        '
	fi
  else
    echo -e "${RED} !! ${REPO} is not a git repository! ${NC}"
  fi

else
  # Install hooks to global hook directory and setup global git configuration
  echo -e "${GRN} -> Installing hook into global hook directory at '${REPO}'... ${NC}"
  install_hook
  
  echo -e "${GRN} -> Configuring global git core.hooksPath setting... ${NC}"
  git config --global core.hooksPath $REPO
fi
