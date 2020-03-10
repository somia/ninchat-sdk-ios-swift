#!/bin/bash

if lsof -Pi :8585 -sTCP:LISTEN -t >/dev/null; then
  echo "port is already open and in use"
else
  echo "opening the env..."
  nohup python ../ninchat-dev/bin/httpd --no-tls -p 8585 &
fi
