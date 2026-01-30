#!/bin/bash -e

#Include all user options and dependencies
git_mirrors_dir="${0%/*}"
if [ ! -f "${git_mirrors_dir}/config.sh" ];then
  red_echo "config.sh missing!  Copy and customize from config.sh.SAMPLE.  Aborting." 1>&2
  exit 1
fi
. "${git_mirrors_dir}/config.sh"
. "${git_mirrors_dir}/lib/VERSION"
. "${git_mirrors_dir}/lib/functions.sh"

# Accept new SSH host keys without prompting (e.g. first connection to GitLab)
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o StrictHostKeyChecking=accept-new"
