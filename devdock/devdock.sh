#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_up () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFFILE="$(readlink -m -- "$BASH_SOURCE")"
  local SELFPATH="$(dirname -- "$SELFFILE")"

  # Ensure the PATH variable is initialized properly:
  </dev/null source -- "$HOME"/.profile || return $?

  local COMPOSE_FILE='cache/composed.gen.yaml'
  export COMPOSE_FILE

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
    recompose | \
    terminalize ) devdock_"$TASK"; return $?;;
  esac

  ps -C dockerd &>/dev/null || sudo service docker restart || return $?

  local DD_PROJ="$DEVDOCK_PROJ"
  if [ -z "$DD_PROJ" ]; then
    DD_PROJ="$DD_DIR"
    DD_PROJ="${DD_PROJ%[./_-]devdock}"
    DD_PROJ="${DD_PROJ%[./_-]}"
    DD_PROJ="$(basename -- "$DD_PROJ" | LANG=C grep -oPe '[A-Za-z0-9]+')"
    DD_PROJ="${DD_PROJ//$'\n'/_}"
  fi
  [ -n "$DD_PROJ" ] || DD_PROJ="devdock_p$$"
  export COMPOSE_PROJECT_NAME="$DD_PROJ"
  echo "D: project '$DD_PROJ' @ $DD_DIR"

  case "$TASK" in
    up )
      if [ -f "$COMPOSE_FILE" ]; then
        echo "D: before 'up', 'down' potential old container:"
        docompose down || return $?
      fi
      devdock_recompose || return $?
      ;;
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


function devdock_source_in_func () { source -- "$@"; }


function devdock_recompose () {
  exec </dev/null
  local C_DIR="$(dirname -- "$COMPOSE_FILE")"
  mkdir --parents -- "$C_DIR"
  local C_DEST="$COMPOSE_FILE"
  local C_TMP="$C_DIR/tmp.next.$(basename -- "$C_DEST")"

  local DOCO_VER="'3'"
  local C_GEN="%YAML 1.1
    # -*- coding: UTF-8, tab-width: 4 -*-
    ---

    # This file is automatically generated by devdock.
    # Any manual edits will probably be lost some time soon.

    version: $DOCO_VER
    services:
    "
  C_GEN="$(sed -re 's!^\s+!!' <<<"$C_GEN")"

  local -A ENV_SECRETS=()
  local ITEM=
  for ITEM in secrets/*.rc; do
    devdock_source_in_func "$ITEM" || return $?$(
      echo "E: Failed to source $ITEM" >&2)
  done

  for ITEM in enabled/*.yaml; do
    ENAB_FILE="$ITEM" devdock_recompose__one_enab || return $?
  done

  C_GEN+=$'\n...'

  local C_HAVE="$(cat -- "$C_DEST")"
  if [ "$C_GEN" == "$C_HAVE" ]; then
    echo "D: compose file already is up-to-date: $C_DEST"
    return 0
  fi

  local CANT="E: Cannot = temporary file $C_TMP"
  >"$C_TMP" || return 5$(echo "${CANT/=/create}" >&2)
  chmod a=,u=rw -- "$C_TMP" || return 5$(echo "${CANT/=/chmod}" >&2)
  echo "$C_GEN" >"$C_TMP" || return 5$(echo "${CANT/=/write}" >&2)
  mv --no-target-directory \
    -- "$C_TMP" "$C_DEST" || return 5$(echo "${CANT/=/activate}" >&2)
  chmod a-w -- "$C_DEST" || return 5$(
    echo "E: Cannot write-protect compose file $C_DEST" >&2)

  echo "D: compose file was updated: $C_DEST"
}


function devdock_recompose__one_enab () {
  local YAML="$(cat -- "$ENAB_FILE")"
  local NECK=$'\nservices:\n'
  local HEAD="${YAML%%$NECK*}"
  [ "$HEAD" != "$YAML" ] || return 4$(
    echo "E: Cannot find 'services:' line in $ENAB_FILE" >&2)
  YAML="${YAML:${#HEAD}}"
  YAML="${YAML:${#NECK}}"

  HEAD="$(<<<"$HEAD" "$SELFPATH"/src/denoise_yaml_header.sed)"

  case "$HEAD" in
    'version:3' ) ;;

    '' )
      echo "E: Template $ENAB_FILE" \
        "must declare at least the docker-compose version used," \
        "which must be exactly $DOCO_VER." >&2
      return 7;;

    * )
      echo "E: Unsupported header line(s) in $ENAB_FILE:" \
        "'${HEAD//$'\n'/¶ }'" >&2
      return 7;;
  esac

  YAML="${YAML%$'\n'}"
  YAML="${YAML%$'\n...'}"
  if [[ "$YAML"$'\n' == *$'\n...\n'* ]]; then
    echo "E: Unexpected '...' line in $ENAB_FILE" >&2
    return 4
  fi

  YAML="${YAML#$'\n'}"
  YAML="${YAML%$'\n'}"
  YAML="$(<<<"$YAML" "$SELFPATH"/src/highlight_slots.sed)"

  YAML="${YAML//$'\f<var dd_dir >'/$DD_DIR/}"
  YAML="${YAML//$'\f<var dd_proj >'/$DD_PROJ/}"

  local KEY= VAL=
  for KEY in "${!ENV_SECRETS[@]}"; do
    VAL="${ENV_SECRETS[$KEY]}"
    YAML="${YAML//$'\f<env_secret '"$KEY >"/$VAL}"
  done

  local MISS=()
  readarray -t MISS < <(grep -oPe '\f<[^<>]+>' <<<"$YAML" \
    | cut --bytes=2- | LANG=C sort --unique)
  [ "${#MISS[@]}" == 0 ] || return 4$(
    echo "E: Unsolved slots in $ENAB_FILE: ${MISS[*]}" >&2)

  C_GEN+=$'\n\n'
  C_GEN+="# >>> services from $ENAB_FILE >>>"$'\n'
  C_GEN+="$YAML"$'\n'
  C_GEN+="# <<< services from $ENAB_FILE <<<"$'\n'
}











devdock_up "$@"; exit $?
