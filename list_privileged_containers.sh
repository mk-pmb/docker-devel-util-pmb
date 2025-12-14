#!/bin/sh
# -*- coding: utf-8, tab-width: 2 -*-
docker inspect --format='{{.HostConfig.Privileged}} {{.Name}}' -- $(
  docker ps --all --quiet --no-trunc) | sed -nre 's~^true /~~p'
