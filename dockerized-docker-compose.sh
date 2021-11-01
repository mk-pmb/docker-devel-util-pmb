#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function dockerized_docker_compose () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local DBGLV="${DEBUGLEVEL:-0}"
  local SOK='/var/run/docker.sock'
  [ -w "$SOK" ] || return 4$(
    echo "E: No write access to $SOK – is user '$USER' in group docker?" >&2)
  local INSIDE_PREFIX='/code'
  local D_OPT=(
    --volume="$SOK:$SOK:rw"
    --volume="${PWD:-/proc/E/err_no_pwd}:$INSIDE_PREFIX:rw"
    --env COMPOSE_PROJECT_NAME
    --rm
    )

  doco_compofile || return $?
  doco_proxy || return $?

  [ "$#" != 0 ] || D_OPT+=( --interactive --tty )
  D_OPT+=(
    docker/compose:latest
    )
  [ "$DBGLV" -ge 2 ] && echo "D: docker run ${D_OPT[*]} $*" >&2

  local D_TASK=( "$1" ); shift
  case "${D_TASK[0]}" in
    build ) ;;
  esac

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
  # DoCo wants the proxy variables in uppercase
  local KEY= VAL=
  for KEY in http{s,}_proxy; do
    VAL=
    eval 'VAL="$'"$KEY"'"'
    D_OPT+=( --env "${KEY^^}=$VAL" )
  done
}


function doco_proxy_via_build_arg () {
  echo "E: stub!" >&2
  return 8
}










dockerized_docker_compose "$@"; exit $?
