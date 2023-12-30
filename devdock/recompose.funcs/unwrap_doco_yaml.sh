#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_recompose__unwrap_doco_yaml () {
  [ "$LNUM" == 0 ] || return 5$(echo "E: $FUNCNAME requires LNUM=0" >&2)
  local BUF=
  while IFS= read -r BUF; do
    (( LNUM += 1 ))
    case "$BUF" in
      '' ) ;;
      '---' ) ;;
      '#'* ) ;;
      'version:'* )
        BUF="${BUF//[$' \x22\x27']/}"
        break;;
      * )
        echo "E: Unexpected YAML header in line $LNUM of $ENAB_FILE: $BUF" >&2
        return 7;;
    esac
  done

  [ "$BUF" == "version:$DOCO_VER" ] || return 7$(
    echo "E: The content part must start with a line that says:" \
      "version: '$DOCO_VER'" >&2)

  CONTENT_START_LNUM="$LNUM"
  while IFS= read -r BUF; do
    (( LNUM += 1 ))
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
