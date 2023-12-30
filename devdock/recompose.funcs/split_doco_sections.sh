#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_recompose__split_doco_sections () {
  [ "${LNUM:-0}" -ge 2 ] || return 5$(
    echo "E: $FUNCNAME invoked with too-low LNUM=$LNUM" >&2)

  local -A SECT_TEXTS=()
  local CUR_SECT= SECT_HAD=
  local YAML_COMMENT_RGX='^[ ]*#( |$)'
  local BUF=
  while IFS= read -r BUF; do
    (( LNUM += 1 ))

    if [ -z "$BUF" ] || [[ "$BUF" =~ $YAML_COMMENT_RGX ]]; then
      [ -z "$CUR_SECT" ] \
        || [ -z "${SECT_TEXTS["$CUR_SECT"]}" ] \
        || SECT_TEXTS["$CUR_SECT"]+="$BUF"$'\n'
      continue
    fi

    case "$BUF" in
      [a-z]*: )
        CUR_SECT="${BUF%:}"
        [ -z "${CUR_SECT//[a-z_]/}" ] || return 7$(
          echo "E: Expected a section name but found: ‹$BUF›" >&2)
        # [[ " $SECT_HAD " == *" $CUR_SECT " ]] && return 7$(
        #   echo "E: Duplicate section name: $CUR_SECT" >&2)
        SECT_HAD+="$CUR_SECT "
        continue;;

      ' '* )
        [ -n "$CUR_SECT" ] || return 7$(
          echo "E: Expected the first section name but found: ‹$BUF›" >&2)
        SECT_TEXTS["$CUR_SECT"]+="$BUF"$'\n'
        continue;;

      [^' ']* )
        echo "E: $FUNCNAME: Unexpected unindented line: ‹$BUF›" >&2
        return 7;;

    esac

    echo 'E: Exotic control flow error. This is a bug.' >&2
    return 7
  done

  [ -n "$CUR_SECT" ] || return 7$(echo 'E: Found no top-level sections' >&2)

  for CUR_SECT in $SECT_HAD ; do
    BUF="${SECT_TEXTS["$CUR_SECT"]}"
    while [[ "$BUF" == $'\n'* ]]; do BUF="${BUF#$'\n'}"; done
    while [[ "$BUF" == *$'\n' ]]; do BUF="${BUF%$'\n'}"; done
    [[ "$BUF" == *['A-Za-z:#']* ]] || return 7$(
      echo "E: Section '$CUR_SECT' from template $ENAB_FILE" \
        "seems to not have actual content, not even comments." >&2)
    BUF="  # >>> $CUR_SECT from $ENAB_FILE >>>"$'\n'"$BUF"$'\n'
    BUF+="  # <<< $CUR_SECT from $ENAB_FILE <<<"$'\n\n'
    DOCO_SECTIONS["$CUR_SECT"]+="$BUF"
  done
}


return 0
