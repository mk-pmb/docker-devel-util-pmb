#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_source_in_func () { source -- "$@"; }


function devdock_cli_preload () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local DD_PROGABS="$(readlink -m -- "$BASH_SOURCE")"
  local DD_PROGDIR="$(dirname -- "$DD_PROGABS")"
  local DBGLV="${DEBUGLEVEL:-0}"
  local ITEM=
  for ITEM in "$DD_PROGDIR"/*.funcs/*.sh; do
    devdock_source_in_func "$ITEM" --lib || return $?
  done
  devdock_cli_main "$@"; return $?
}


function devdock_recompose__one_enab () {
  local YAML="$(cat -- "$ENAB_FILE")"
  local NECK=$'\nservices:\n'
  local HEAD="${YAML%%$NECK*}"
  [ "$HEAD" != "$YAML" ] || return 4$(
    echo "E: Cannot find 'services:' line in $ENAB_FILE" >&2)
  YAML="${YAML:${#HEAD}}"
  YAML="${YAML:${#NECK}}"

  HEAD="$(<<<"$HEAD" "$DD_PROGDIR"/src/denoise_yaml_header.sed)"

  case "$HEAD" in
    'version:3' ) ;;

    '' )
      echo "E: Template $ENAB_FILE" \
        "must declare at least the docker-compose version used," \
        "which must be exactly $DOCO_VER." >&2
      return 7;;

    * )
      echo "E: Unsupported header line(s) in $ENAB_FILE:" \
        "'${HEAD//$'\n'/¶ }'" >&2
      return 7;;
  esac

  YAML="${YAML%$'\n'}"
  YAML="${YAML%$'\n...'}"
  if [[ "$YAML"$'\n' == *$'\n...\n'* ]]; then
    echo "E: Unexpected '...' line in $ENAB_FILE" >&2
    return 4
  fi
  if [[ "$YAML" == *'${#env_secret}'* ]]; then
    echo "E: Your project uses the deprecated ENV_SECRETS feature." >&2
    return 4
  fi

  YAML="${YAML#$'\n'}"
  YAML="${YAML%$'\n'}"
  YAML="$(<<<"$YAML" "$DD_PROGDIR"/src/highlight_slots.sed)"

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

  local MISS=()
  readarray -t MISS < <(grep -oPe '\f<[^<>]+>' <<<"$YAML" \
    | cut --bytes=2- | LANG=C sort --unique)
  [ "${#MISS[@]}" == 0 ] || return 4$(
    echo "E: Unsolved slots in $ENAB_FILE: ${MISS[*]}" >&2)

  C_GEN+=$'\n\n'
  C_GEN+="# >>> services from $ENAB_FILE >>>"$'\n'
  C_GEN+="$YAML"$'\n'
  C_GEN+="# <<< services from $ENAB_FILE <<<"$'\n'
}











devdock_cli_preload "$@"; exit $?
