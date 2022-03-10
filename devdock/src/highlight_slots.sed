#!/bin/sed -urf
# -*- coding: UTF-8, tab-width: 2 -*-

# /^\s*(#|$)/d
s~\f~~g
s~\s+$~~

s~^([ \#\-]+)\$\{($\
  |dd_dir|$\
  |dd_proj|$\
  )\}(\x22|\x27)~\1\3\f<var \2 >~

s~^([ \#\-]+)\$\{(env_secret)\}(\x22|\x27|$\
  )([A-Za-z0-9_]+)=([A-Za-z0-9_]*)(\x22|\x27|$\
  )~\1\3\4=\f<\2 \f<fallback_id \5 \4 > >\6~

s~\f<fallback_id (\S+) \S+ >~\1~g
s~\f<fallback_id  (\S+) >~\1~g
