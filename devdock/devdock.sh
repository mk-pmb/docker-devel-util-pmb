#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function devdock_source_in_func () { source -- "$@"; }

function devdock_cli_preload () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local DD_PROGABS="$(readlink -m -- "$BASH_SOURCE")"
  local DD_PROGDIR="$(dirname -- "$DD_PROGABS")"
  local DBGLV="${DEBUGLEVEL:-0}"
  local ITEM=
  for ITEM in "$DD_PROGDIR"/*.funcs/*.sh; do
    devdock_source_in_func "$ITEM" --lib || return $?
  done
  devdock_cli_main "$@"; return $?
}

devdock_cli_preload "$@"; exit $?
