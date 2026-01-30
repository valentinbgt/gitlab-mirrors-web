#COLORS DOCUMENTATION
# black - 30
# red - 31
# green - 32
# brown - 33
# blue - 34
# magenta - 35
# cyan - 36
# lightgray - 37
# 
# * 'm' character at the end of each of the following sentences is used as a stop character, where the system should stop and parse the \033[ sintax.
# 
# \033[0m - is the default color for the console
# \033[0;#m - is the color of the text, where # is one of the codes mentioned above
# \033[1m - makes text bold
# \033[1;#m - makes colored text bold**
# \033[2;#m - colors text according to # but a bit darker
# \033[4;#m - colors text in # and underlines
# \033[7;#m - colors the background according to #
# \033[9;#m - colors text and strikes it
# \033[A - moves cursor one line above (carfull: it does not erase the previously written line)
# \033[B - moves cursor one line under
# \033[C - moves cursor one spacing to the right
# \033[D - moves cursor one spacing to the left
# \033[E - don't know yet
# \033[F - don't know yet
# 
# \033[2K - erases everything written on line before this.

#Colors variables
SETCOLOR_GREEN="echo -en \\033[0;32m"
SETCOLOR_RED="echo -en \\033[0;31m"
SETCOLOR_YELLOW="echo -en \\033[0;33m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"
SETSTYLE_BOLD="echo -en \\033[1m"
SETSTYLE_UNDERLINE="echo -en \\033[4m"
SETSTYLE_NORMAL="echo -en \\033[0m"

enable_colors="${enable_colors:-true}"

#same as echo function except the whole text line is red
function red_echo() {
  #in order for the -n functionality to work properly $2 must be quoted when called in case of spaces
  if "${enable_colors}";then
    if [ "$1" = "-n" ];then
      ${SETCOLOR_RED} && echo -n "$2" && ${SETCOLOR_NORMAL}
    else
      ${SETCOLOR_RED} && echo "$*" && ${SETCOLOR_NORMAL}
    fi
  else
    if [ "$1" = "-n" ];then
      echo -n "$2"
    else
      echo "$*"
    fi
  fi
}

#same as echo function except the whole text line is green
function green_echo() {
  #in order for the -n functionality to work properly $2 must be quoted when called in case of spaces
  if "${enable_colors}";then
    if [ "$1" = "-n" ];then
      ${SETCOLOR_GREEN} && echo -n "$2" && ${SETCOLOR_NORMAL}
    else
      ${SETCOLOR_GREEN} && echo "$*" && ${SETCOLOR_NORMAL}
    fi
  else
    if [ "$1" = "-n" ];then
      echo -n "$2"
    else
      echo "$*"
    fi
  fi
}

#same as echo function except the whole text line is yellow
function yellow_echo() {
  #in order for the -n functionality to work properly $2 must be quoted when called in case of spaces
  if "${enable_colors}";then
    if [ "$1" = "-n" ];then
      ${SETCOLOR_YELLOW} && echo -n "$2" && ${SETCOLOR_NORMAL}
    else
      ${SETCOLOR_YELLOW} && echo "$*" && ${SETCOLOR_NORMAL}
    fi
  else
    if [ "$1" = "-n" ];then
      echo -n "$2"
    else
      echo "$*"
    fi
  fi
  return 0
}

#same as echo function except output bold text
function bold_echo() {
  #in order for the -n functionality to work properly $2 must be quoted when called in case of spaces
  if "${enable_colors}";then
    if [ "$1" = "-n" ];then
      ${SETSTYLE_BOLD} && echo -n "$2" && ${SETSTYLE_NORMAL}
    else
      ${SETSTYLE_BOLD} && echo "$*" && ${SETSTYLE_NORMAL}
    fi
  else
    if [ "$1" = "-n" ];then
      echo -n "$2"
    else
      echo "$*"
    fi
  fi
  return 0
}

#same as echo function except output underlined text
function underline_echo() {
  #in order for the -n functionality to work properly $2 must be quoted when called in case of spaces
  if "${enable_colors}";then
    if [ "$1" = "-n" ];then
      ${SETSTYLE_UNDERLINE} && echo -n "$2" && ${SETSTYLE_NORMAL}
    else
      ${SETSTYLE_UNDERLINE} && echo "$*" && ${SETSTYLE_NORMAL}
    fi
  else
    if [ "$1" = "-n" ];then
      echo -n "$2"
    else
      echo "$*"
    fi
  fi
  return 0
}

# Ensure the current user's SSH key is registered on GitLab so SSH (git push/fetch)
# works without prompt. If SSH test fails, upload the public key via API and retry.
# No-op when http_remote is true. Requires gitlab_url and gitlab_user_token_secret.
ensure_gitlab_ssh_key() {
  [ "${http_remote:-false}" = "true" ] && return 0

  local host url_without_proto
  url_without_proto="${gitlab_url#*://}"
  host="${url_without_proto%%/*}"
  [ -z "${host}" ] && return 1

  _ensure_gitlab_ssh_key_test() {
    ssh -T -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "git@${host}" 2>/dev/null
  }

  if _ensure_gitlab_ssh_key_test; then
    return 0
  fi

  local pubkey key_title
  if [ -f "${HOME}/.ssh/id_ed25519.pub" ]; then
    pubkey=$(cat "${HOME}/.ssh/id_ed25519.pub")
  elif [ -f "${HOME}/.ssh/id_rsa.pub" ]; then
    pubkey=$(cat "${HOME}/.ssh/id_rsa.pub")
  else
    red_echo "No SSH public key found (~/.ssh/id_ed25519.pub or id_rsa.pub). Cannot register key on GitLab." 1>&2
    return 1
  fi

  key_title="gitlab-mirrors-$(hostname)-$(date +%Y%m%d)"
  local curl_opts=(--request POST --silent --show-error --fail -L
    --header "PRIVATE-TOKEN: ${gitlab_user_token_secret}"
    --url "${gitlab_url%/}/api/v4/user/keys"
    --data "title=${key_title}"
    --data "key=${pubkey}")

  if [ "${ssl_verify:-true}" != "true" ]; then
    curl_opts+=(--insecure)
  fi

  if ! curl "${curl_opts[@]}" 2>/dev/null; then
    red_echo "Failed to register SSH key on GitLab via API." 1>&2
    return 1
  fi

  if ! _ensure_gitlab_ssh_key_test; then
    red_echo "SSH key was uploaded but SSH test to GitLab still fails." 1>&2
    return 1
  fi
  return 0
}
