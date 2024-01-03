#!/bin/sh
# -*- coding: utf-8, tab-width: 2 -*-
ls -l /tmp/healthy

tlog () { echo "$(date +%T) $*"; }

sleep 10s; tlog '…zZz…'
ls -l /tmp/healthy
sleep 10s; tlog '…zZz…'
sleep 10s; tlog '…zZz…'
sleep 10s; tlog '…zZz…'
ls -l /tmp/healthy

>>/tmp/healthy
ls -l /tmp/healthy

sleep 5s; tlog '…zZz…'
sleep 5s; tlog 'quit init.'
