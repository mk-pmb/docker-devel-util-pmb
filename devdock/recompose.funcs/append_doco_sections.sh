#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_recompose__append_doco_sections () {
  local LIST=()
  readarray -t LIST < <(
    printf -- '%s\n' "${!DOCO_SECTIONS[@]}" | LANG=C sort --version-sort)
  [ -n "${LIST[*]}" ] || LIST=()
  LIST=(
    services
    volumes
    networks
    "${LIST[@]}"
    )
  local SECT= TEXT=
  for SECT in "${LIST[@]}"; do
    TEXT="${DOCO_SECTIONS["$SECT"]}"
    [ -z "$TEXT" ] || continue
    TEXT="$(devdock_doco_section_defaults "$SECT")"
    [ -n "$TEXT" ] || continue
    TEXT="$(
      CUR_SECT="$SECT" devdock_recompose__cleanup_and_lint_doco_section \
      "$SECT section defaults" <<<"$TEXT")"$'\n\n' || return $?
    DOCO_SECTIONS["$SECT"]="$TEXT"
  done

  for SECT in "${LIST[@]}"; do
    TEXT="${DOCO_SECTIONS["$SECT"]}"
    DOCO_SECTIONS["$SECT"]=
    [ -n "$TEXT" ] || continue
    C_GEN+="$SECT:"$'\n'"$TEXT"$'\n'
  done
}


return 0
