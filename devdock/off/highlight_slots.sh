#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_recompose__highlight_slots () {
  local SED='
    # /^\s*(#|$)/d
    s~\f~~g
    s~\s+$~~

    s~\$\{DD:(Æ+):=\}~\1=&~g
    s~\$\{DD:([æ:]+)\}~\f<var \1 >~
    '
  SED="${SED//Æ/[æ]}"
  SED="${SED//æ/A-Za-z0-9_}"
  LANG=C sed -urf <(echo "$SED")
}


[ "$1" == --lib ] && return 0; devdock_recompose__highlight_slots "$@"; exit $?
