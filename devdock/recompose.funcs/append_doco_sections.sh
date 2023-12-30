#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_recompose__append_doco_sections () {
  local LIST=()
  readarray -t LIST < <(
    printf -- '%s\n' "${!DOCO_SECTIONS[@]}" | LANG=C sort --version-sort)
  LIST=(
    services
    volumes
    networks
    "${LIST[@]}"
    )
  local SECT= TEXT=
  for SECT in "${LIST[@]}"; do
    TEXT="${DOCO_SECTIONS["$SECT"]}"
    DOCO_SECTIONS["$SECT"]=
    [ -n "$TEXT" ] || continue
    C_GEN+="$SECT:"$'\n'"$TEXT"$'\n'
  done
}


return 0
