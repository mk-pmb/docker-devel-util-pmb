#!/bin/sed -nrf
# -*- coding: utf-8, tab-width: 2 -*-

/^\s*#/b
s~^\S~Unexpected unindented line: &~p

/^\s*restart:/{
  s~^\s*restart:\s*~~
  s~^"?no"?$~Use single quotes for restart policy 'no'.~p
  /^('no'|always|on-failure|unless-stopped)$/b
  s~^never$~Docker restart policy doesn't allow "&". Use single-quoted 'no'.~p
}
