#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function docker_list_tags__cli_main () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")" # busybox
  local PROGNAME="${FUNCNAME%%__*}"
  case "$1" in
    --func ) shift; docker_list_tags__"$@"; return $?;;
  esac
  local IMAGE="$1"; shift
  [ "${IMAGE%/*}" != "$IMAGE" ] || IMAGE="library/$IMAGE"
  [ "${IMAGE//[A-Za-z0-9_-]/}" == / ] || return 4$(
    echo E: $PROGNAME: "Unsupported image name syntax: '$IMAGE'" >&2)
  local TAGS_URL='https://registry.hub.docker.com/v2/namespaces/'
  TAGS_URL+="${IMAGE%%/*}/repositories/${IMAGE#*/}/tags"

  local NEXT_TAGS="$TAGS_URL?page_size=9009009"
  # ^-- Registry will auto-limit page size, so we'll have to pagianate anyway.

  [ -n "$XDG_CACHE_HOME" ] || local XDG_CACHE_HOME="$HOME/.cache"
  local CACHE_DIR="$XDG_CACHE_HOME/docker/$PROGNAME"
  mkdir --parents -- "$CACHE_DIR" || return $?
  cd -- "$CACHE_DIR" || return $?
  find -maxdepth 1 -type f '(' \
    -name 'tags.*.json' \
    -o -name 'tags.*.prep' \
    ')' -mtime +1 -delete
  while [ -n "$NEXT_TAGS" ]; do
    docker_list_tags__download_more_tags || return $?
  done
}


function docker_list_tags__download_more_tags  () {
  case "$NEXT_TAGS" in
    "$TAGS_URL?"* ) ;;
    * )
      echo E: $PROGNAME: "Flinching: Unexpected URL pattern: '$NEXT_TAGS'" >&2
      return 3;;
  esac
  local QUERY="&${NEXT_TAGS##*'?'}"
  local PGNR=1
  case "$QUERY" in
    *'&page='[1-9]* ) PGNR="${QUERY#'&page='}"; PGNR="${PGNR%%[^0-9]*}";;
  esac
  printf -v PGNR -- '%04d' "$PGNR"
  local SAVE_AS="tags.${IMAGE//'/'/.}.pg-$PGNR.json"
  docker_list_tags__cached_wget "$SAVE_AS" "$NEXT_TAGS" || return $?
  NEXT_TAGS=

  local PREP="tags.${IMAGE//'/'/.}.pg-$PGNR.prep" # pre-parsed
  [ -s "$PREP" ] || docker_list_tags__pre_parse_results "$SAVE_AS" \
    >"$PREP" || return $?
  docker_list_tags__scan_results "$PREP" || return $?
  NEXT_TAGS="$(docker_list_tags__find_next_url "$PREP")"
}


function docker_list_tags__cached_wget () {
  local SAVE_AS="$1"; shift
  local DL_URL="$1"; shift
  local PART="tmp.$SAVE_AS.$$.part"
  if [ -s "$SAVE_AS" ]; then
    # echo D: "Skip download: have: '$SAVE_AS'" >&2
    return 0
  fi
  wget --quiet --output-document="$PART" "$DL_URL" || return $?
  mv --no-target-directory -- "$PART" "$SAVE_AS" || return $?
}


function docker_list_tags__pre_parse_results () {
  # We want to filter out the long and boring images list, but  sed has a
  # length restriction on matches, so we cannot use a single regexp for it.
  # Thus, we make it easy to match the start and end of lists…
  sed -re 's~\[|\]|\{|\}~\n&\n~g' -- "$@" |
    sed -re 's~,?"[a-z]+":$~\n&~' |
  # … and then use a range match to delete that part.
    sed -re '/^,?"images":/,/^\]$/d' |
  # Finally, let's normalize whitespace:
    sed -zre 's~\r~~g; s~\t|\f|\a~ ~g; s~\n,~,\n~g' |
    sed -re 's~\s+$~~; /^$/d'
}


function docker_list_tags__scan_results () {
  local MOVE_TO_FRONT='; s~^([^\n]*)\n([^\n]*)\n~\2\t\1~'
  sed -zre 's~\n~~g; s~\}|$~\n&\n~g' -- "$@" | sed -re 's~^,~&\n~' |
    sed -re 's~"(name)":\s*("[^"]+"),?~\n\1 \2\n~'"$MOVE_TO_FRONT" |
    sed -re 's~"(digest)":\s*("[^"]+"),?~\n\1 \2\n~'"$MOVE_TO_FRONT" |
    sed -nre 's~^digest "([^^]+)"\tname "([^^]+)"\t.*$~\1\t\2~p' |
    LANG=C sort -Vk 2
}


function docker_list_tags__find_next_url () {
  local URL="$(head --bytes=2K -- "$@" | head --lines=5 | tr , '\n' |
    sed -nre 's~^"next":\s*~~p')"
  case "$URL" in
    null | '""' ) return 0;;
    '' )
      echo E: $FUNCNAME: "Cannot find next URL in '$*'" >&2
      return 3;;
  esac
  URL="${URL//$'\x22'/}"
  URL="${URL//'\u0026'/'&'}"
  echo "$URL"
}










docker_list_tags__cli_main "$@"; exit $?
