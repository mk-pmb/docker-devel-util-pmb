#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function do_in_func () { "$@"; }


function dockerized_docker_compose () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local DBGLV="${DEBUGLEVEL:-0}"
  local APP_NAME="${FUNCNAME//_/-}"
  local SOK='/var/run/docker.sock'
  [ -w "$SOK" ] || return 4$(
    echo "E: No write access to $SOK – is user '$USER' in group docker?" >&2)
  local ENV_OPTNAME='--env'
  local D_TASK="$1"; shift
  local D_EARLY_OPT=()
  local STERN_WARNINGS=

  local COMPOSE_FILE="$COMPOSE_FILE"
  [ -n "$COMPOSE_FILE" ] || for COMPOSE_FILE in docker-compose.y{a,}ml ''; do
    [ -f "$COMPOSE_FILE" ] && break
  done

  local -A CFG=(
    [inside_prefix]="$COMPOSE_INSIDE_PREFIX"
    [project_name]="$COMPOSE_PROJECT_NAME"
    )
  local ITEM=
  for ITEM in "$FUNCNAME".rc; do
    [ -f "$ITEM" ] || continue
    do_in_func source -- "$ITEM" --rc || return $?$(
      echo "E: $FUNCNAME: Failed to source $ITEM" >&2)
  done

  case "$D_TASK" in
    build )
      # ENV_OPTNAME='--build-arg'
      # ^-- nope, docker-compose doesn't support this
      ENV_OPTNAME=;;
  esac

  [ -n "${CFG[project_name]}" ] || CFG[project_name]="$(basename -- "$PWD")"
  [ -n "${CFG[inside_prefix]}" ] \
    || CFG[inside_prefix]="/code/${CFG[project_name]}"

  local TTY_OPT=()
  tty --silent && TTY_OPT+=( --interactive --tty )

  local OUTER_RUN=(
    docker
    run
    --volume="$SOK:$SOK:rw"
    --volume="${PWD:-/proc/E/err_no_pwd}:${CFG[inside_prefix]}:rw"
    --env COMPOSE_PROJECT_NAME="${CFG[project_name]}"
    "${TTY_OPT[@]}"
    --rm
    --name "${CFG[project_name]}_compose_$$"
    --workdir "${CFG[inside_prefix]}"
    )
  doco_cfg_compo_file__insert_inside_prefix || return $?
  doco_proxy || return $?

  OUTER_RUN+=(
    docker/compose:latest
    )

  doco_fallible_actually_do_stuff; local D_RV=$?

  [ -z "$STERN_WARNINGS" ] || echo "W: $APP_NAME:" \
    "In case there was a lot of output above," \
    "you may have missed these earlier warnings:" \
    "${STERN_WARNINGS//$'\n'/$'\n  • '}" >&2

  return "$D_RV"
}


function sternly_warn () {
  STERN_WARNINGS+=$'\n'"$*"
  echo "W: $APP_NAME: $*" >&2
}


function doco_fallible_actually_do_stuff () {
  local D_CMD=(
    "${OUTER_RUN[@]}"
    "$D_TASK"
    "${D_EARLY_OPT[@]}"
    "$@"
    )
  [ "$DBGLV" -lt 2 ] || echo "D: ${D_CMD[*]}" >&2
  "${D_CMD[@]}" || return $?
}


function doco_cfg_compo_file__insert_inside_prefix () {
  local SPEC="$COMPOSE_FILE"
  [ -n "$SPEC" ] || return 0
  SPEC=":$SPEC"
  SPEC="${SPEC//:/:"${CFG[inside_prefix]}/"}"
  SPEC="${SPEC#:}"
  OUTER_RUN+=( --env COMPOSE_FILE="$SPEC" )
}


function doco_proxy () {
  local KEY= VAL=
  for KEY in http{s,}_proxy; do
    VAL=
    eval 'VAL="$'"$KEY"'"'
    [ -n "$VAL" ] || continue
    [ -n "$ENV_OPTNAME" ] || continue$(echo "W: $APP_NAME:" >&2 \
      "Env var $KEY is set but is not yet supported for this task!")
    D_OPT+=( $ENV_OPTNAME "$KEY=$VAL" )
    D_OPT+=( $ENV_OPTNAME "${KEY^^}=$VAL" )
    # ^-- DoCo wants the proxy variables in uppercase
  done
}










dockerized_docker_compose "$@"; exit $?
