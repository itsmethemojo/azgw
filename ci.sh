#!/bin/bash

case "$1" in
"test")
  if [ ! -d tests/bats ];
  then
    echo "INFO downloading bats test framework"
    docker run -v "$(pwd)":/app -w /app buildpack-deps:stretch bash -c "
    git clone --depth 1 https://github.com/sstephenson/bats.git /app/tests/bats &> /dev/null &&
    rm -r /app/tests/bats/.git &&
    chmod -R 777 /app/tests/bats
    ";
  else
    echo "INFO skip downloading bats test framework"
  fi
  tests/bats/bin/bats tests/tests.bats
  exit $?
  ;;
"lint-bash")
  docker run -v "$(pwd)":/app/ -w /app koalaman/shellcheck-alpine shellcheck ./*.sh
  exit $?
  ;;
"clear")
  rm -rf tests/bats tests/debug
  exit 0
  ;;
esac

HELP_TEXT="Usage: ci [COMMAND]

Commands:
  test                      runs test suite with bats
"
echo -e "${HELP_TEXT}"
exit 0
