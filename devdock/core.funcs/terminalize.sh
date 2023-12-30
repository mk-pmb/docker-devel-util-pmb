#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_terminalize () {
  local XT=(
    xterm_with_custom_icon # from terminal-util-pmb
    --title-and-class="DevDock $DD_PROJ"
    )

  local LIST=(
    "$DD_DIR"/icon.{png,svg}
    /usr/share/icons/Humanity/categories/48/applications-other.svg
    /usr/share/icons/hicolor/scalable/apps/other-driver.svg
    /usr/share/icons/Humanity/categories/48/applications-libraries.svg
    )
  local ICON=
  for ICON in "${LIST[@]}"; do
    [ -f "$ICON" ] || continue
    XT+=( --icon-file="$ICON" )
    break
  done

  XT+=(
    -geometry '200x40-0+0'
    -e
    env
    DEVDOCK_DIR="$DD_DIR"
    "$DD_PROGABS"
    )
  [ "$DBGLV" -lt 2 ] || echo "D: $FUNCNAME: run:$(
    printf -- ' ‹%s›' "${XT[@]}")" >&2
  "${XT[@]}" "$@" &
  disown $!
  return 0
}


return 0
