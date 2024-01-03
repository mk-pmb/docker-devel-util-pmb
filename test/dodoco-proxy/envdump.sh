#!/bin/sh
# -*- coding: utf-8, tab-width: 2 -*-
eval "$EVAL_BEFORE"
echo ">>> env summary @ $1 >>>"
env | sed -nre 's~^user|_proxy|docker|dodoco~&~ip' | sort
echo "<<< env summary @ $1 <<<"
eval "$EVAL_AFTER"
