#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_lint_sect () {
  ( devdock_lint_sect_fallible "$@" 2>&1 || echo "E: Linter failure, rv=$?"
  ) | sed -rf <(echo '
    : multiline
    /\r$/{N; s~\r\n\s*~~; b multiline}
    s~\r$~~
    ')
}


function devdock_lint_sect_fallible () {
  local CUR_SECT="$1"
  local INPUT="$(cat)"
  [ -n "$CUR_SECT" ] || return 4$(echo "E: Missing section name." >&2)

  [[ "$INPUT" == *['A-Za-z:#']* ]] || return 7$(
    echo 'E: There seems to be no useful content, not even comments.' >&2)

  local FUNC="${FUNCNAME}__$CUR_SECT"
  [ "$(type -t "$FUNC")" != function ] || "$FUNC" <<<"$INPUT" || return $?

  local SED_FILE="$DD_PROGDIR/lint.funcs/sect_$CUR_SECT.sed"
  if [ -x "$SED_FILE" ]; then
    LANG=C "$SED_FILE" <<<"$INPUT" || return $?
  elif [ -f "$SED_FILE" ]; then
    LANG=C sed -rf "$SED_FILE" <<<"$INPUT" || return $?
  fi
}


return 0
