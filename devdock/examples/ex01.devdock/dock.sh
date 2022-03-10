#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
export DEVDOCK_DIR="$(readlink -m -- "$BASH_SOURCE"/..)"
exec docker-devdock "$@"; exit $?
