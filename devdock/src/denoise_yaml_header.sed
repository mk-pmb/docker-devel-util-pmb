#!/bin/sed -urf
# -*- coding: UTF-8, tab-width: 2 -*-

s~\s+$~~
1{/^%YAML /d}
/^\-{3}$/d
/^#/d
/^$/d
s~^(version:) *[\x22\x27]?([0-9]+)[\x22\x27]?$~\1\2~
