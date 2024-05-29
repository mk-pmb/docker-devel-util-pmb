#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_recompose__unwrap_doco_yaml () {
  [ -n "$ENAB_FILE" ] || return 7$(
    echo "E: Cannot trace errors: ENAB_FILE is empty!" >&2)
  [ "$LNUM" == 0 ] || return 5$(echo "E: $FUNCNAME requires LNUM=0" >&2)
  local BUF= TRACE=
  while IFS= read -r BUF; do
    (( LNUM += 1 ))
    TRACE="in line $LNUM of template $ENAB_FILE"
    case "$BUF" in
      '' ) ;;
      '---' ) ;;
      '#'* ) ;;
      'version:'* )
        BUF="${BUF//[$' \x22\x27']/}"
        break;;
      * )
        echo "E: Unexpected YAML header $TRACE: $BUF" >&2
        return 7;;
    esac
  done

  [[ "$BUF" == version:[0-9]* ]] || return 7$(
    echo E: "Failed to detect file format version (at all) $TRACE" >&2)
  BUF="${BUF#*:}"
  [ -z "${BUF//[0-9.]/}" ] || return 7$(
    echo E: "Unsupported number format in format version $TRACE: '$BUF'" >&2)
  case "$DOCO_VER" in
    '' ) DOCO_VER="$BUF @ $ENAB_FILE";;
    "$BUF @ "* ) ;;
    * )
      echo "E: File format version '$BUF' $TRACE conflicts with the" \
        "file format version already established earlier: $DOCO_VER" >&2
      return 7;;
  esac

  CONTENT_START_LNUM="$LNUM"
  TRACE=
  while IFS= read -r BUF; do
    (( LNUM += 1 ))
    # echo D: $FUNCNAME: "$ENAB_FILE <$LNUM> $BUF" >&2
    case "$BUF" in
      '...' )
        grep -qPe '\S' || return 0
        echo 'E: Unexpected non-whitespace characters after the YAML' \
          'end-of-document marker line (i.e. three literal dots)' >&2
        return 7;;

      *'${#env_secret}'* )
        echo "E: Your project uses the deprecated ENV_SECRETS feature." >&2
        return 6;;

      [a-z]*: )
        YAML+="$BUF"$'\n'
        [ "${BUF//[a-z_]/}" == : ] && continue;;
      ' '* | \
      '# '* | \
      '' ) YAML+="$BUF"$'\n'; continue;;
    esac
    echo "E: $FUNCNAME: Unexpected unindented line: ‹$BUF›" >&2
    return 7
  done
}


return 0
