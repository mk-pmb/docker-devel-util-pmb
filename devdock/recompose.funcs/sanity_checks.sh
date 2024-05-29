#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_sanck () {
  local PADDED_YAML=
  printf -v PADDED_YAML '% *s' "$CONTENT_START_LNUM" ''
  PADDED_YAML="${PADDED_YAML// /$'\n'}$YAML"

  local ERR_CNT=0
  devdock_sanck__volume_entry_expect_file || return $?
  # [ "$ERR_CNT" == 0 ] || echo E: "Found $ERR_CNT errors."
  return "$ERR_CNT"
}


function devdock_sanck__volume_entry_expect_file () {
  local ITEM="${FUNCNAME##*__}"
  local SED='
    s!^([0-9]+)-\s*\-\s*!\1 @!p
    s!^([0-9]+):\s*#\!\^# '"$ITEM"':\s*!\1 !p
    '
  local LIST=()
  readarray -t LIST < <( <<<"$PADDED_YAML" grep -nFe '#!^#'" $ITEM: -" -B 1 \
    | sed -nrf <(echo "$SED") )
  local LNUM= VOL_LNUM='(no volume entry yet)' VOL_PATH=
  for ITEM in "${LIST[@]}"; do
    LNUM="${ITEM%% *}"
    ITEM="${ITEM#* }"
    ITEM="${ITEM//$APOS/}"
    ITEM="${ITEM//$QUOT/}"
    case "$ITEM" in
      @/*:/* )
        VOL_LNUM="$LNUM"
        VOL_PATH="${ITEM:1}"
        VOL_PATH="${VOL_PATH%%:*}"
        if [ -z "$VOL_PATH" ]; then
          (( ERR_CNT += 1 ))
          echo E: "Line $LNUM: empty volume path" >&2
          continue
        fi
        ;;

      @* )
        VOL_LNUM="$LNUM"
        (( ERR_CNT += 1 ))
        echo E: "Line $LNUM:" \
          "Both volume path and mountpoint must be absolute paths." >&2
        ;;

      -[a-z]*…* | …* )
        ITEM="test ${ITEM//…/$VOL_PATH}"
        if [ -z "$VOL_PATH" ]; then
          ITEM='Cannot test file without volume path.'
        elif eval "$ITEM"; then
          continue
        else
          ITEM="'$ITEM' failed."
        fi
        (( ERR_CNT += 1 ))
        echo E: "Line $LNUM: $ITEM" >&2
        echo D: "^-- The offending volume entry was in line $VOL_LNUM: $(
          sed -nre "$VOL_LNUM"'{s~^\s*~~p;q}' -- "$ENAB_FILE")"
        ;;

      * )
        (( ERR_CNT += 1 ))
        echo E: "Line $LNUM: unsupported syntax: $ITEM" >&2
        return 4;;
    esac
  done
}





















return 0
