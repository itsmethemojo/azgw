#!/bin/bash

case "$1" in
"test")
  if [ ! -d tests/bats ];
  then
    docker run -v "$(pwd)":/app -w /app buildpack-deps:stretch bash -c "
    git clone --depth 1 https://github.com/sstephenson/bats.git /app/tests/bats &> /dev/null &&
    rm -r /app/tests/bats/.git &&
    chmod -R 777 /app/tests/bats
    ";
  fi
  tests/bats/bin/bats tests/tests.bats
  exit $?
  ;;
esac

HELP_TEXT="Usage: ci [COMMAND]

Commands:
  test                      runs test suite with bats
"
echo -e "${HELP_TEXT}"
exit 0
