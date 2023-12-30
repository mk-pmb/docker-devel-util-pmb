#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function devdock_detect_project_name () {
  local PN="$DEVDOCK_PROJ"
  if [ -n "$PN" ]; then echo "$PN"; return $?; fi

  PN="$DD_DIR"
  PN="${PN%[./_-]devdock}"
  PN="${PN%[./_-]}"
  PN="$(basename -- "$PN" | LANG=C grep -oPe '[A-Za-z0-9]+')"
  PN="${PN//$'\n'/_}"
  if [ -n "$PN" ]; then echo "$PN"; return $?; fi
}


return 0
