#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_recompose__one_enab_file () {
  local ENAB_FILE="$1"
  local LNUM=0 CONTENT_START_LNUM= YAML=
  devdock_recompose__unwrap_doco_yaml < <(sed -rf <(echo '
    1s~^%YAML .*$~~
    s~\s+$~~
    ') -- "$ENAB_FILE") || return $?$(
    echo "E: There was an error in line $LNUM of template $ENAB_FILE" >&2)

  [ -n "$YAML" ] || return 7$(
    echo "E: Found no content section in template $ENAB_FILE" >&2)
  YAML="$(<<<"$YAML" "$DD_PROGDIR"/src/highlight_slots.sed)"
  [ -n "$YAML" ] || return 7$(
    echo "E: Failed to highlight variable slots in template $ENAB_FILE" >&2)

  local ENAB_BFN="$(basename -- "$ENAB_FILE")"
  YAML="${YAML//$'\f<var dd_dir >'/$DD_DIR/}"
  YAML="${YAML//$'\f<var dd_proj >'/$DD_PROJ}"
  YAML="${YAML//$'\f<var dd_tpl >'/$ENAB_BFN}"
  YAML="${YAML//$'\f<var dd_tpl_bn >'/${ENAB_BFN%.yaml}}"

  local KEY= VAL=
  for KEY in "${!CFG[@]}"; do
    VAL="${CFG[$KEY]}"
    YAML="${YAML//$'\f<dd_cfg '"$KEY >"/$VAL}"
  done
  KEY= VAL= # forget potential secrets

  local MISS=()
  readarray -t MISS < <(grep -oPe '\f<[^<>]+>' <<<"$YAML" \
    | cut --bytes=2- | LANG=C sort --unique)
  [ "${#MISS[@]}" == 0 ] || return 4$(
    echo "E: Unsolved slots in template $ENAB_FILE: ${MISS[*]}" >&2)

  LNUM="$CONTENT_START_LNUM"
  devdock_recompose__split_doco_sections <<<"$YAML" || return $?$(
    echo "E: There was an error in line $LNUM of template $ENAB_FILE" >&2)
}


return 0