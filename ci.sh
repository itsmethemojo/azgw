#!/bin/bash

case "$1" in
"test")
  if [ ! -d tests/bats ];
  then
    echo "INFO downloading bats test framework"
    docker run --rm -v "$(pwd)":/app -w /app buildpack-deps:stretch bash -c "
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
    docker run --rm -v "$(pwd)":/app -w /app buildpack-deps:stretch bash -c "
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
"lint-js")
  if [ ! -d node_modules ];
  then
    echo "INFO npm install"
    docker run --rm --entrypoint npm -w /app -v "$(pwd)":/app node install
  else
    echo "INFO skip npm install"
  fi
  docker run --rm -w /app -v "$(pwd)":/app cytopia/eslint src/*.js
  exit $?
  ;;
"fix-js")
  if [ ! -d node_modules ];
  then
    echo "INFO npm install"
    docker run --rm --entrypoint npm -w /app -v "$(pwd)":/app node install
  else
    echo "INFO skip npm install"
  fi
  docker run --rm -w /app -v "$(pwd)":/app cytopia/eslint --fix src/*.js
  exit $?
  ;;
"clear")
  rm -rf tests/bats tests/debug tests/shellcheck-stable node_modules
  exit 0
  ;;
esac

HELP_TEXT="Usage: ci [COMMAND]

Commands:
  test                      runs test suite with bats
  lint-bash                 lints bash scripts
  lint-js                   lints javascript files
  fix-js                    lints and auto-fixes javascript files
"
echo -e "${HELP_TEXT}"
exit 0
