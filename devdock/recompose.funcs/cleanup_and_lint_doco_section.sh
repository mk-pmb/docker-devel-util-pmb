#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_recompose__cleanup_and_lint_doco_section () {
  local SECT_TRACE="$1"; shift
  local CLEANUP='
    s~\s+$~~
    '
  local TEXT=$'\n'"$(sed -rf <(echo "$CLEANUP"))"$'\n'

  while [[ "$TEXT" == $'\n'* ]]; do TEXT="${TEXT#$'\n'}"; done
  while [[ "$TEXT" == *$'\n' ]]; do TEXT="${TEXT%$'\n'}"; done

  local LINT="$(devdock_lint_sect "$CUR_SECT" <<<"$TEXT")"
  [ -z "$LINT" ] || return 5$(
    echo "E: Found lint in section $SECT_TRACE:" >&2
    echo "$LINT" >&2)

  echo "  # >>> $SECT_TRACE >>>"
  echo "$TEXT"
  echo "  # <<< $SECT_TRACE <<<"
}


return 0
