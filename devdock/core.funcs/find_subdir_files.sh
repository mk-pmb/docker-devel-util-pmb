#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_find_subdir_files () {
  local FEXT="$1"; shift
  local SUFFIXES=( # generic s. go first, most specific s. goes last
    ''
    .site
    .local
    .@"$HOSTNAME"
    )
  local CATEG= ITEM= SUBDIR=
  local FOUND=() IGNORE=
  for CATEG in "$@"; do
    FOUND=()
    IGNORE=$'\n'
    for ITEM in "${SUFFIXES[@]}"; do
      for ITEM in "$CATEG$ITEM"/*."$FEXT"; do
        if [ -L "$ITEM" ] && [ "$ITEM" -ef /dev/null ]; then
          IGNORE+="$(basename -- "$ITEM")"$'\n'
        elif [ -f "$ITEM" ]; then
          FOUND+=( "$ITEM" )
        fi
      done
    done
    for ITEM in "${FOUND[@]}"; do
      [[ "$IGNORE" == *$'\n'"$(basename -- "$ITEM")"$'\n'* ]] || echo "$ITEM"
    done
  done
}


return 0
