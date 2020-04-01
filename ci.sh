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
  if [ ! -d tests/shellcheck-stable ];
  then
    echo "INFO downloading shellcheck"
    docker run -v "$(pwd)":/app -w /app buildpack-deps:stretch bash -c "
    cd /app/tests &&
    wget -qO- 'https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.x86_64.tar.xz' | tar -xJ &&
    chmod -R 777 /app/tests/shellcheck-stable
    "
  else
    echo "INFO skip downloading shellcheck"
  fi
  tests/shellcheck-stable/shellcheck ./*.sh
  exit $?
  ;;
"clear")
  rm -rf tests/bats tests/debug tests/shellcheck-stable
  exit 0
  ;;
esac

HELP_TEXT="Usage: ci [COMMAND]

Commands:
  test                      runs test suite with bats
"
echo -e "${HELP_TEXT}"
exit 0
