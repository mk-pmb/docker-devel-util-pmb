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
  local D_TASK=( "$1" ); shift

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

  case "${D_TASK[0]}" in
    build )
      # ENV_OPTNAME='--build-arg'
      # ^-- nope, docker-compose doesn't support this
      ENV_OPTNAME=;;
  esac

  [ -n "${CFG[project_name]}" ] || CFG[project_name]="$(basename -- "$PWD")"
  [ -n "${CFG[inside_prefix]}" ] \
    || CFG[inside_prefix]="/code/${CFG[project_name]}"

  local D_OPT=(
    --volume="$SOK:$SOK:rw"
    --volume="${PWD:-/proc/E/err_no_pwd}:${CFG[inside_prefix]}:rw"
    --env COMPOSE_PROJECT_NAME="${CFG[project_name]}"
    --rm
    --name "${CFG[project_name]}_compose_$$"
    --workdir "${CFG[inside_prefix]}"
    )
  doco_cfg_compo_file__insert_inside_prefix || return $?
  doco_proxy || return $?

  tty --silent && D_OPT+=( --interactive --tty )
  D_OPT+=(
    docker/compose:latest
    )

  [ "$DBGLV" -lt 2 ] || echo "D: docker run ${D_OPT[*]} ${D_TASK[*]} $*" >&2
  docker run "${D_OPT[@]}" "${D_TASK[@]}" "$@" || return $?
}


function doco_cfg_compo_file__insert_inside_prefix () {
  local SPEC="$COMPOSE_FILE"
  [ -n "$SPEC" ] || return 0
  SPEC=":$SPEC"
  SPEC="${SPEC//:/:"${CFG[inside_prefix]}/"}"
  SPEC="${SPEC#:}"
  D_OPT+=( --env COMPOSE_FILE="$SPEC" )
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
