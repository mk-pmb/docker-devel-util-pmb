#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_find_subdir_files () {
  local ITEM= FEXT="$1"; shift
  for ITEM in "$@"; do
    for ITEM in "$ITEM"{,.site,.local,.@"$HOSTNAME"}/*."$FEXT"; do
      [ ! -f "$ITEM" ] || echo "$ITEM"
    done
  done
}


return 0
