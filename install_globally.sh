#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function install_globally () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local REPO_DIR="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$REPO_DIR" || return $?

  if [ "$1" == --skip-mv ]; then
    shift
  else
    echo "Taking ownership:"
    chown --recursive root:root . || return $?

    local DN="$(basename -- "$REPO_DIR")"
    local ULL="/usr/local/lib"
    local ULD="$ULL/$DN"
    echo -n "Move repo directory to $ULL: "
    if [ "$REPO_DIR" -ef "$ULD" ]; then
      echo 'skip: no action required.'
    else
      mv --target-directory="$ULL" -- "$REPO_DIR" || return $?
      echo 'done.'
    fi

    echo
    cd -- "$ULD" || return $?
  fi

  echo "Installing global CLI commands:"
  local LINK= DEST=
  while IFS= read -rs DEST; do
    case "$DEST" in
      [a-z]*' <- '[a-z]*.sh ) LINK="${DEST%% <- *}"; DEST="${DEST#* <- }";;
      * ) continue;;
    esac
    echo -n '    '
    LINK="/usr/local/bin/$LINK"
    [ ! -L "$LINK" ] || rm -- "$LINK"
    ln --verbose --symbolic --relative --no-target-directory \
      -- "$DEST" "$LINK" || return $?
  done <binlinks.cfg

  echo
  echo "Ok! Seems like all is well and $DN should be ready for use."
}










install_globally "$@"; exit $?
