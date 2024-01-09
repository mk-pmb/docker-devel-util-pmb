#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_doco_section_defaults () {
  local SECT="$1"; shift
  if [ "$(type -t "$FUNCNAME"__"$SECT")" == function ]; then
    "$FUNCNAME"__"$SECT" "$@"; return $?
  fi
}


function devdock_doco_section_defaults__networks () {
  echo "
    default:
        driver: 'bridge'
        driver_opts:
            'com.docker.network.bridge.name': '${CFG[default_network_bridge_name]}'
    "
}






return 0
