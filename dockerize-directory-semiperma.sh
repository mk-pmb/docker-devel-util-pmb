#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function dkdirsemi_cli_main () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFFILE="$(readlink -m -- "$BASH_SOURCE")"
  local SELFPATH="$(dirname -- "$SELFFILE")"
  local SELFNAME="$(basename -- "$SELFFILE" .sh)"
  local SELFABBR="${FUNCNAME%%_*}"
  local DBGLV="${DEBUGLEVEL:-0}"
  # cd -- "$SELFPATH" || return $?
  case "$1" in
    /* | ./* | ../* ) cd -- "$1" || return $?; shift;;
    . ) shift;;
    '~'/* ) cd -- "$HOME${1:1}" || return $?; shift;;
  esac

  local -A CFG=()
  dkdirsemi_cfg_defaults
  # Set early options to be used in rc files:
  while [[ "$1" == [a-z]*=* ]]; do CFG["${1%%=*}"]="${1#*=}"; shift; done

  local VAL=
  if [ "$1" == --rc ]; then
    # The rc files are run on the host, so only use this option if you can
    # fully trust the project! Even if you checked them at first run,
    # programs inside the container may be able to modify and thus trick
    # you into running the modified rc files later!
    shift
    for VAL in .{git/,}{"$SELFABBR","$SELFNAME"}/{rc.,*.rcd/}*.sh; do
      [ -f "$VAL" ] || continue
      in_func source -- "$VAL" --rc || return $?$(
        echo E: "Failed to source rc file (rv=$?): $VAL" >&2)
    done
  fi

  # Set late options to maybe override what the rc files did:
  while [[ "$1" == [a-z]*=* ]]; do CFG["${1%%=*}"]="${1#*=}"; shift; done
  dkdirsemi_fill_cfg_slots || return $?

  local CNAME="${CFG[ctnr:name:pre]}${CFG[ctnr:name]}${CFG[ctnr:name:suf]}"
  CNAME="${CNAME//[^A-Za-z0-9_-]/}"
  CNAME="${CNAME:0:63}"
  [ -n "$CNAME" ] || return 4$(
    echo E: 'Effective container name is empty!' >&2)

  local DK_OPT=()
  while [ "$#" -ge 1 ]; do case "$1" in
    -- ) shift; break;;
    --help ) shift; dkdirsemi_cli_help "$@"; return $?;;
    -* ) DK_OPT+=( "$1" ); shift;;
    * ) break;;
  esac; done
  case "$1" in
    '' )
      echo E: "No command given. You could try one of:" \
        "init reinit stop exec pwd ls sh" >&2
      return 4;;

    exec ) shift;;

    init | \
    reinit | \
    stop | \
    _* )
      VAL="${1#_}"
      shift
      dkdirsemi_"$VAL" "$@" || return $?$(echo E: "$VAL failed, rv=$?" >&2)
      return 0;;

    sh )
      shift
      tty --silent && DK_OPT+=( --interactive --tty ) || true
      set -- bash "$@";;

    help ) shift; dkdirsemi_cli_help "$@"; return $?;;
  esac

  VAL="$(docker inspect --format='{{.Name}}' -- "$CNAME")"
  [ "$VAL" == "/$CNAME" ] || return 4$(
    echo E: "Cannot find docker container named '$CNAME'. Try 'init'." >&2)

  set -- docker exec "${DK_OPT[@]}" "$CNAME" \
    ${CFG[cmd:default_exec_pre]} "$@"
  dkdirsemi_debugdump_list 2 'D: effective docker command:' "$@"
  exec "$@" || return $?
}


function dkdirsemi_cfg_defaults () {
  CFG=(
    [cmd:default_exec_pre]=''
    [cmd:keepalive]='sleep 9009009d'
    [cmd:symlink]='ln -sfT --'
    [ctnr:cpu-count]='1'
    [ctnr:hostname]=''
    [ctnr:image]=''   # Empty = guess.
    [ctnr:memory]='512M'
    [ctnr:name:pre]=''
    [ctnr:name:suf]='-<dir:basename>'
    [ctnr:name]='dkdir'
    [ctnr:net]='hdi'  # or use 'host' for fully shared connectivity
    [ctnr:workdir]='/app'
    [libdir:"$SELFPATH"]=:
    [vol:/app]='.:rw'
    )
}


function dkdirsemi_cli_help () {
  echo 'CLI arguments: [path] [option=value [option=value …]]' \
    '[--docker-option [--docker-option …]]' \
    '[--] action [argument [argument …]]'
  echo
  echo 'The default options are:'
  local IMG="${CFG[ctnr:image]}"
  sed -nre '/^function dkdirsemi_cfg_defaults /,/^\}/p' -- "$BASH_SOURCE" |
    sed -zre 's~\\\n\s+~~g' |
    sed -nre 's~^\s+\[~~p' | sed -nre 's~\]~~p' |
    sed -re '/^ctnr:image=/s~$~ Currently, the guess would be: '"'$IMG'~" |
    sed -re 's:"\$SELFPATH":'"'$SELFPATH':" |
    sed -re 's~^~  • ~'
  echo
}


function in_func () { "$@"; }


function dkdirsemi_debugdump_list () {
  [ "$DBGLV" -ge "$1" ] || return 0
  shift
  echo -n "$1"; shift
  local Q="${CFG[debug:quotes]}"
  case "$Q" in
    '' ) Q=' ‹%s›';;
    *%s* | *%q* ) ;;
    * ) Q="${Q//%/%%}"; Q=" ${Q/ /%s}";;
  esac
  printf -- "$Q" "$@"
  echo
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


function cfg_auto_guess_image () {
  local IMG="${CFG[ctnr:image]}"
  if [ -z "$IMG" ]; then
    cfg_auto_guess_image__inner || return $?
    CFG[ctnr:image]="$IMG"
    echo D: "Guessing [ctnr:image]='$IMG'"
  fi
  case "$IMG" in
    *:'<auto-versnum>'* ) cfg_auto_guess_image__auto_versnum || return $?;;
  esac
}


function cfg_auto_guess_image__inner () {
  if [ -f package.json -a -s package.json ]; then
    IMG='node:<auto-versnum>highest|20'
    return 0
  fi

  IMG="ubuntu:$(lsb_release --short --codename)"
}


function cfg_auto_guess_image__auto_versnum () {
  local VAL="$IMG" REV= VER= IMG=
  IMG="${VAL%%':<auto-versnum>'*}"
  [ "$IMG" != "$VAL" ] || return 4$(echo E: "Split failed in $FUNCNAME" >&2)
  VAL="${VAL#*':<auto-versnum>'}|"
  case "$VAL" in
    highest'|'* ) VAL="${VAL#*'|'}";;
    lowest'|'* ) VAL="${VAL#*'|'}"; REV='--reverse';;
    * ) echo E: $FUNCNAME: "Expexted 'highest' or 'lowest'" >&2; return 4;;
  esac
  VER="${VAL%'|'}"
  VAL="$(docker images --format '{{.Tag}}' -- node | sort --version-sort)"
  VAL="${VAL##*$'\n'}"
  [ -z "$VAL" ] || VER="$VAL"

  IMG+=":$VER"
  CFG[ctnr:image]="$IMG"
  echo D: "Adjusting [ctnr:image] version to: '$IMG'"
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

  VAL="${CFG[ctnr:net]}"
  case "$VAL" in
    '' ) ;;
    'hdi' ) DK_CMD+=( --add-host=host.docker.internal:host-gateway );;
    * ) DK_CMD+=( --net="$VAL" )
  esac

  cfg_parse_libdirs || return $?
  cfg_scan_bindvol_dirs || return $?
  cfg_parse_volumes || return $?
  cfg_auto_guess_image || return $?

  DK_CMD+=(
    ${CFG[ctnr:run_opts]}
    "${CFG[ctnr:image]}"
    ${CFG[cmd:keepalive]}
    )
  dkdirsemi_debugdump_list 2 'D: effective docker command:' "${DK_CMD[@]}"
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
    [ "${OUTER/:/}" == "$OUTER" ] || return 4$(echo E: $FUNCNAME: >&2 \
      "Host-side path must not contain a colon: '$OUTER'")
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


function cfg_scan_bindvol_dirs () {
  # Example usecase: node_modules; see `dockerize-directory-semiperma.md`
  local BV_DIRS=(
    {.,.[A-Za-z@]*/,[A-Za-z@]*/.}{"$SELFABBR","$SELFNAME"}/bindvol
    )
  local BV_LINKS=()
  local BV_DIR= BV_OVL= BV_LINK= BV_MPNT=
  for BV_DIR in "${BV_DIRS[@]}"; do
    [ -d "$BV_DIR" ] || continue
    [ -L "$BV_DIR" ] && return 4$(
      echo E: "$SELFNAME: bindvol directory must not be a symlink," \
        "because docker cannot use that as a mountpoint: $BV_DIR" >&2)
    BV_OVL="$BV_DIR"/.tmp.overlay
    [ -L "$BV_OVL" ] && rm -- "$BV_OVL" || true
    [ -d "$BV_OVL" ] && rm --one-file-system --recursive -- "$BV_OVL" || true
    mkdir -- "$BV_OVL" || return 4$(echo E: "$SELFNAME: Failed to" >&2 \
      "re-create bindvol overlay directory to ensure it's empty: $BV_OVL")
    cfg_set_derived "vol:/app/$BV_DIR" "$BV_OVL:rw" \
      'bindvol directory overlay basedir' || return $?
    BV_LINKS=()
    readarray -t BV_LINKS < <(
      cd -- "$BV_DIR" && find -mount -type l | LANG=C sort -V)
    for BV_LINK in "${BV_LINKS[@]}" ; do
      case "$BV_LINK" in
        '' | . | ./ ) continue;;
        ./* ) BV_LINK="${BV_LINK:2}";;
        * )
          echo E: "$SELFNAME: Found an unexpected bindvol directory entry:" \
            "'$BV_DIR' / '$BV_LINK'" >&2
          return 4;;
      esac
      mkdir --parents -- "$BV_OVL/$BV_LINK"
      # ^-- Docker would auto-create them as root if we don't, in which case
      #     the `reinit` action may be unable to cleanly rmdir them.
      cfg_set_derived "vol:/app/$BV_DIR/$BV_LINK" "$BV_DIR/$BV_LINK:ro" \
        'bindvol directory entry' || return $?
    done
  done
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
  # CFG[sym:inside-link]=inside-target
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
