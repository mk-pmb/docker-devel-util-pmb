#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function docker_list_images_by_size () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly

  local LIST=()
  local COLUMN_NAMES=(
    Size__
    ID__________
    CreatedAt_____________________
    Repository
    Tag
    )

  local ITEM=
  printf -v ITEM -- "%s\t" "${COLUMN_NAMES[@]}"
  echo "${ITEM%$'\t'}"

  readarray -t LIST < <(docker images --all --format "$(
    printf -- '{{.%s}}\t' "${COLUMN_NAMES[@]//_/}")")
  local SIZE=
  local TABLE=()
  for ITEM in "${LIST[@]}"; do
    SIZE="${ITEM%%$'\t'*}"
    ITEM="${ITEM#*$'\t'}"
    SIZE="$(units --terse "$SIZE" MB)"
    printf -v ITEM -- '% 6.0f\t%s' "$SIZE" "$ITEM"
    TABLE+=( "$ITEM" )
  done
  printf -- '%s\n' "${TABLE[@]}" | sort --general-numeric-sort --reverse
}










docker_list_images_by_size "$@"; exit $?
