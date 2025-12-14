#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function addc_cli_main () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local QUOT='"' APOS="'" NL=$'\n'
  local EDDJ="/etc/docker/daemon.json"
  local HINTS=
  local SUGGESTED_DAEMON_JSON=
  addc_advise_all || addc_hint E "Internal error (rv=$?)" \
    'while trying to advise. Some advice may be missing.'
  HINTS="${HINTS%$NL}"
  [ -n "$HINTS" ] || return 0
  echo "$HINTS"
}


function addc_hint () {
  local LEVEL="$1"; shift
  HINTS+="$LEVEL: $*$NL"
}


function addc_advise_all () {
  addc_advise_logging || return $?
  addc_suggest_daemon_json_file || return $?
}


function addc_advise_logging () {
  addc_suggest_daemon_json_opt log-driver '"none"'
  addc_suggest_daemon_json_opt storage-driver '"overlay2"'
}


function addc_suggest_daemon_json_opt () {
  local KEY="$1"; shift
  local VAL="$1"; shift
  SUGGESTED_DAEMON_JSON+="$QUOT$KEY$QUOT: $VAL$NL"
  grep -qPe '"$KEY"\s*:' -- "$EDDJ" && return 0
  addc_hint W "In your $EDDJ you have no $QUOT$KEY$QUOT setting." \
    "Consider setting it to $VAL."
}


function addc_suggest_daemon_json_file () {
  local JSON="$SUGGESTED_DAEMON_JSON"
  JSON="${JSON%$NL}"
  [ -n "$JSON" ] || return 0
  JSON="{ ${JSON//$NL/,$NL  }$NL}"
  # echo "$JSON"
}










addc_cli_main "$@"; exit $?
