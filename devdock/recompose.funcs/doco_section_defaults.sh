#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_doco_section_defaults () {
  local SECT="$1"; shift
  if [ "$(type -t "$FUNCNAME"__"$SECT")" == function ]; then
    "$FUNCNAME"__"$SECT" "$@"; return $?
  fi
}


function devdock_doco_section_defaults__networks () {
  local DF='default_network_bridge_'
  local BR_NAME="${CFG[${DF}name]:-br-$DD_PROJ}"
  BR_NAME="$(echo "${BR_NAME,,}" | tr -sc 'a-z0-9' -)"
  BR_NAME="${BR_NAME%-}"

  local MAX_IFACE_NAME_LENGTH=15
  # ^-- Error message if too long: "numerical result out of range"
  BR_NAME="${BR_NAME:0:$MAX_IFACE_NAME_LENGTH}"
  BR_NAME="${BR_NAME%-}"

  echo "
    default:
      driver: 'bridge'
      driver_opts:
        'com.docker.network.bridge.name': '$BR_NAME'
    "

  local BR_CIDR="${CFG[${DF}subnet]}"
  local BR_GW="${CFG[${DF}gateway]}"
  if [ -n "$BR_CIDR" ]; then
    echo "
      ipam:
        config:
          - subnet: '$BR_CIDR'"
    [ -z "$BR_GW" ] || echo "
            gateway: '$BR_GW'"
  elif [ -n "$BR_GW" ]; then
    echo E: $FUNCNAME: >&2 \
      "Option ${DF}gateway is only valid with ${DF}subnet!"
    return 4
  fi
}






return 0
