#!/bin/bash
set -e

# Rails 再起動時に残ることがある PID ファイルを除去
if [ -f /app/tmp/pids/server.pid ]; then
  rm /app/tmp/pids/server.pid
fi

exec "$@"
