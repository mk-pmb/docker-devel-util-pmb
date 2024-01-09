#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_recompose__split_doco_sections () {
  [ "${LNUM:-0}" -ge 2 ] || return 5$(
    echo "E: $FUNCNAME invoked with too-low LNUM=$LNUM" >&2)

  local -A SECT_TEXTS=()
  local CUR_SECT= SECT_HAD=
  local INDENT_RGX='^[ \t]*' INDENT= UNINDENTED=
  local BUF=
  while IFS= read -r BUF; do
    (( LNUM += 1 ))

    INDENT=
    [[ "$BUF" =~ $INDENT_RGX ]] && INDENT="${BASH_REMATCH[0]}"
    UNINDENTED="${BUF:${#INDENT}}"

    case "$UNINDENTED" in
      '' | '#' | '# '* )
        [ -n "$CUR_SECT" ] || continue
        [ -n "${SECT_TEXTS["$CUR_SECT"]}" ] || continue
        SECT_TEXTS["$CUR_SECT"]+="$BUF"$'\n'
        continue;;
    esac

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
    BUF="$(devdock_recompose__cleanup_and_lint_doco_section \
      "$CUR_SECT from $ENAB_FILE" <<<"$BUF")"$'\n\n' || return $?
    DOCO_SECTIONS["$CUR_SECT"]+="$BUF"
  done
}


return 0
