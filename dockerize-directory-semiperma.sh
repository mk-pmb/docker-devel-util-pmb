#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function dkdirsemi_cli_main () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  local DBGLV="${DEBUGLEVEL:-0}"
  # cd -- "$SELFPATH" || return $?
  case "$1" in
    /* | ./* | ../* ) cd -- "$1" || return $?; shift;;
    . ) shift;;
    '~'/* ) cd -- "$HOME${1:1}" || return $?; shift;;
  esac
  local -A CFG=(
    [cmd:default_exec_pre]=''
    [cmd:keepalive]='sleep 9009009d'
    [cmd:symlink]='ln -sfT --'
    [ctnr:hostname]=''
    [ctnr:image]='ubuntu:<lsb_release:codename>'
    [ctnr:name:pre]=''
    [ctnr:name:suf]='-<dir:basename>'
    [ctnr:name]='dkdir'
    [ctnr:workdir]='/app'
    [libdir:"$SELFPATH"]=:
    [vol:/app]='.:rw'
    )
  while [[ "$1" == *=* ]]; do CFG["${1%%=*}"]="${1#*=}"; shift; done
  dkdirsemi_fill_cfg_slots || return $?

  local CNAME="${CFG[ctnr:name:pre]}${CFG[ctnr:name]}${CFG[ctnr:name:suf]}"
  CNAME="${CNAME//[^A-Za-z0-9_-]/}"
  CNAME="${CNAME:0:63}"
  [ -n "$CNAME" ] || return 4$(
    echo E: 'Effective container name is empty!' >&2)

  local DK_OPT=()
  while [ "$#" -ge 1 ]; do case "$1" in
    -- ) shift; break;;
    -* ) DK_OPT+=( "$1" ); shift;;
    * ) break;;
  esac; done
  local VAL=
  case "$1" in
    exec ) shift;;

    init | \
    reinit | \
    stop | \
    _* ) VAL="dkdirsemi_${1#_}"; shift; "$VAL" "$@"; return $?;;
  esac

  set -- docker exec "${DK_OPT[@]}" "$CNAME" \
    ${CFG[cmd:default_exec_pre]} "$@"
  exec "$@" || return $?
}


function dkdirsemi_fill_cfg_slots () {
  local SLOT_NAMES=( $( <<<"${CFG[*]}" grep -oPe '<\w+:\w+>' \
    | tr -d '<>' | LANG=C sort --unique ) )
  local SLOTS_SED=
  local SK= SS= SV= CK= CV= USED=
  for SK in "${SLOT_NAMES[@]}"; do
    SV=
    SS="${SK#*:}"
    case "$SK" in
      dir:basename ) SV="$("$SS" -- "$PWD")";;
      lsb_release:* ) SV="$(lsb_release --short --"$SS")";;
    esac
    USED=
    for CK in "${!CFG[@]}"; do
      CV="${CFG[$CK]}"
      [[ "$CV" == *"<$SK>"* ]] || continue
      CFG["$CK"]="${CV//<$SK>/$SV}"
      USED+=" '$CK'"
    done
    [ -n "$SV" ] || return 8$(
      echo E: 'Unable to determine config value slot' \
        "<$SK>, used in these option(s):${USED:- (none)}" >&2)
  done
}


function dkdirsemi_find_ctnr_id () {
  docker inspect --format '{{.ID}}' -- "$CNAME" | grep .
}

function dkdirsemi_find_ka_pid () {
  docker inspect --format '{{.State.Pid}}' -- "$CNAME" | grep .
}


function dkdirsemi_must_find_ka_pid () {
  dkdirsemi_find_ka_pid || return 4$(
    echo E: "Cannot find host system's PID for the keep-alive process!" >&2)
}


function dkdirsemi_stop () {
  local KA_PID="$(dkdirsemi_must_find_ka_pid)"
  [ -n "$KA_PID" ] || return 4
  local VERIFY="$(ps ho pid,comm "$KA_PID" | tr -s ' ' ' ')"
  [ "${VERIFY# }" == "$KA_PID sleep" ] || return 4$(echo E: >&2 \
    "Flinching: Host system's process ID $KA_PID is not a sleep comnmand!")
  echo D: "Killing host PID $KA_PID:"
  sudo kill -KILL "$KA_PID"
  sleep 0.2s
  local CID=
  SECONDS=0
  while [ "$SECONDS" -lt 5 ]; do
    sleep 0.5s
    CID="$(dkdirsemi_find_ctnr_id 2>/dev/null)"
    [ -z "$CID" ] || continue
    echo D: "Container '$CNAME' seems to have vanished."
    return 0
  done
  echo E: "Container '$CNAME' seems to still be running! (ID ${CID:0:8})" >&2
  return 4
}


function dkdirsemi_reinit () {
  dkdirsemi_stop || true
  dkdirsemi_init || return $?
}


function dkdirsemi_init () {
  local DK_CMD=(
    docker
    run
    --detach
    --rm --restart=no
    --name="$CNAME"
    )

  local KEY= VAL=
  for KEY in hostname workdir ; do
    VAL="${CFG[ctnr:$KEY]}"
    [ -z "$VAL" ] || DK_CMD+=( "--$KEY=$VAL" )
  done

  cfg_parse_libdirs || return $?
  cfg_parse_volumes || return $?

  DK_CMD+=(
    ${CFG[ctnr:run_opts]}
    "${CFG[ctnr:image]}"
    ${CFG[cmd:keepalive]}
    )
  [ "$DBGLV" -lt 2 ] || echo D: "effective docker command:$(
    printf -- ' ‹%s›' "${DK_CMD[@]}")"
  local CTNR_ID= # pre-declare so `local` doesn't hide the return value of $()
  CTNR_ID="$("${DK_CMD[@]}")" || return $?$(
    echo E: 'Failed to create the docker container!' >&2)
  echo D: "Created the docker container. ID: $CTNR_ID"

  cfg_create_symlinks || return $?

  if [ -n "${CFG[cmd:init]}" ]; then
    echo D: "Run init hook: ${CFG[cmd:init]}"
    docker exec "$CNAME" ${CFG[cmd:init]} || return $?$(
      echo E: "The init hook failed, rv=$?" >&2)
  fi
}


function cfg_set_derived () {
  local SETKEY="$1" SETVAL="$2" FROM="${3:-option '$KEY'}"
  local OLDVAL="${CFG[$SETKEY]}"
  [ "$OLDVAL" != "$SETVAL" ] || return 0
  if [ -z "$OLDVAL" ]; then
    CFG["$SETKEY"]="$SETVAL"
    return 0
  fi
  printf -- 'D: %s value: "%s"\n' Current "$OLDVAL" Derived "$SETVAL"
  echo E: "Cannot set derived value for config option '$SETKEY':" \
    "conflicts with $FROM" >&2
  return 4
}


function cfg_parse_libdirs () {
  # libdir:host-path=inside-path (with ':' magic)
  local KEY= SUB= OUTER= INNER= PROG=
  for KEY in "${!CFG[@]}"; do
    [[ "$KEY" == libdir:* ]] || continue
    SUB="${KEY#*:}"
    INNER="${CFG[$KEY]}"
    OUTER="$SUB"
    PROG=
    [[ "$OUTER" == */* ]] || dkdirsemi_cfgkey_libdir__which || return $?
    OUTER="${OUTER%/}"
    [ "$INNER" == = ] && INNER="$SUB"
    [[ "$INNER" == *:* ]] && INNER="${INNER//:/$(basename -- "$OUTER")}"
    [[ "$INNER" == */* ]] || INNER="/usr/lib/$INNER"
    cfg_set_derived "vol:$INNER" "$OUTER:ro" || return $?
    [ -z "$PROG" ] || cfg_set_derived "sym:/bin/${PROG%%=*}" \
      "$INNER/${PROG#*=}" || return $?
  done
}

function dkdirsemi_cfgkey_libdir__which () {
  local FOUND="$(which -- "$OUTER")"
  [ -x "$FOUND" ] || return 4$(echo E: >&2 \
    "Failed to look up command name '$OUTER' for libdir volume '$INNER'.")
  local ABSO="$(readlink -m -- "$FOUND")"
  local PAR="$(dirname -- "$ABSO")"
  [ -d "$PAR" ] || return 4$(echo E: >&2 \
    "Found command name '$OUTER' for libdir volume '$INNER' as '$FOUND'" \
    "but failed to resolve its parent directory.")
  PROG="$OUTER=$(basename -- "$ABSO")"
  OUTER="$PAR"
}


function cfg_parse_volumes () {
  local KEY= MODE= INNER= OUTER=
  for KEY in "${!CFG[@]}"; do
    # {ro,rw}:inner-path=host-path
    MODE="${KEY%%:*}"
    [ "$MODE" == rw ] || [ "$MODE" == ro ] || continue
    INNER="${KEY#*:}"
    OUTER="${CFG[$KEY]}"
    cfg_set_derived "vol:$INNER" "$OUTER:$MODE" || return $?
  done
  for KEY in "${!CFG[@]}"; do
    [[ "$KEY" == vol:* ]] || continue
    INNER="${KEY#*:}"
    OUTER="${CFG[$KEY]}"
    MODE=ro
    case "$OUTER" in
      *:ro | *:rw ) MODE="${OUTER##*:}"; OUTER="${OUTER%:*}";;
    esac
    OUTER="${OUTER/#'~/'/$HOME/}"
    [ "$OUTER" == = ] && OUTER="$INNER"
    [ -e "$OUTER" ] || return 4$(echo E: "Path to be mounted as" \
      "$INNER ($MODE) does not exist: $OUTER" >&2)
    OUTER="$(readlink -m -- "$OUTER")"
    DK_CMD+=( "--volume=$OUTER:$INNER:$MODE" )
  done
}


function cfg_create_symlinks () {
  # sym:inside-link=inside-target
  local KEY= LNK= TGT=
  for KEY in "${!CFG[@]}"; do
    [[ "$KEY" == sym:* ]] || continue
    LNK="${KEY#*:}"
    TGT="${CFG[$KEY]}"
    docker exec "$CNAME" ${CFG[cmd:symlink]} "$TGT" "$LNK" || return $?$(
      echo E: "Failed to create symlink inside container: $LNK -> $TGT" >&2)
  done
}












dkdirsemi_cli_main "$@"; exit $?
