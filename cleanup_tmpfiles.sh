#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function docker_cleanup_tmpfiles () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local TOPIC= CMD=
  for TOPIC in system volume ; do
    CMD="docker $TOPIC prune"
    echo -n "$CMD: "
    $CMD --force
  done
}


docker_cleanup_tmpfiles "$@"; exit $?
