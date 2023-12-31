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

  [ -n "$COMPOSE_PROJECT_NAME" ] || local COMPOSE_PROJECT_NAME="$(
    basename -- "$PWD")"
  local INSIDE_PREFIX="/code/$COMPOSE_PROJECT_NAME"

  local D_OPT=(
    --volume="$SOK:$SOK:rw"
    --volume="${PWD:-/proc/E/err_no_pwd}:$INSIDE_PREFIX:rw"
    --env COMPOSE_PROJECT_NAME
    --rm
    --name "${COMPOSE_PROJECT_NAME}_compose_$$"
    --workdir "$INSIDE_PREFIX"
    )

  doco_compofile || return $?
  doco_proxy || return $?

  tty --silent && D_OPT+=( --interactive --tty )
  D_OPT+=(
    docker/compose:latest
    )

  [ "$DBGLV" -lt 2 ] || echo "D: docker run ${D_OPT[*]} ${D_TASK[*]} $*" >&2
  docker run "${D_OPT[@]}" "${D_TASK[@]}" "$@" || return $?
}


function doco_compofile () {
  local SPEC="$COMPOSE_FILE"
  [ -n "$SPEC" ] || return 0
  SPEC=":$SPEC"
  SPEC="${SPEC//:/:"$INSIDE_PREFIX/"}"
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
