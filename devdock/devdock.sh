#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_up () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFFILE="$(readlink -m -- "$BASH_SOURCE")"
  local SELFPATH="$(dirname -- "$SELFFILE")"

  # Ensure the PATH variable is initialized properly:
  </dev/null source -- "$HOME"/.profile || return $?

  # Now with profile loaded, find the DevDock dir:
  local DD_DIR="$DEVDOCK_DIR"
  case "$DD_DIR" in
    '' ) DD_DIR="$HOME/.config/docker/devdock";;
    '~' | '~/'* ) DD_DIR="$HOME${DD_DIR:1}";;
  esac
  cd -- "$DD_DIR" || return $?

  local TASK="$1"; shift
  local TASK_OPT=()
  case "$TASK" in
    '' ) TASK='up'; TASK_OPT=( --force-recreate );;
    terminalize ) devdock_"$TASK"; return $?;;
  esac

  ps -C dockerd &>/dev/null || sudo service docker restart || return $?

  local COMPOSE_FILE="$(printf '%s:' enabled/*.yaml)"
  COMPOSE_FILE="${COMPOSE_FILE%:}"
  export COMPOSE_FILE

  local DD_PROJ="$DEVDOCK_PROJ"
  if [ -z "$DD_PROJ" ]; then
    DD_PROJ="$(basename -- "$DD_DIR" | LANG=C grep -oPe '[A-Za-z0-9]+')"
    DD_PROJ="${DD_PROJ//$'\n'/_}"
  fi
  [ -n "$DD_PROJ" ] || DD_PROJ="devdock_p$$"
  export COMPOSE_PROJECT_NAME="$DD_PROJ"
  echo "D: project '$DD_PROJ' @ $DD_DIR"

  case "$TASK" in
    up )
      echo "D: before 'up', 'down' potential old container:"
      docompose down || return $?;;
  esac

  echo "D: docompose $TASK ${TASK_OPT[*]} $*"
  docompose "$TASK" "${TASK_OPT[@]}" "$@"
  return $?
}


function devdock_terminalize () {
  source -- "$HOME"/lib/wmutils-pmb/wmsess_util_pmb.sh --lib || return $?
  local WSP='Video'
  local TA_TITLE='DevDock'
  local TA_GEOM='150x35'
  local TA_ICON='other-driver'
  local TA_CWD="$SELFPATH"
  local SELF_CMD=(
    env
    DEVDOCK_DIR="$PWD"
    "$SELFFILE"
    )
  wmsess__ensure_terminal_app "$LT_TITLE" "$WSP" "${SELF_CMD[@]}"
  return $?
}










devdock_up "$@"; exit $?
