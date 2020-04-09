#!/usr/bin/env bats

function setup {
  mkdir -p tests/debug
  rm -f tests/debug/$BATS_TEST_NAME.log
  mv .env .env.backup 2>/dev/null || true
  echo tests/data/$BATS_TEST_NAME >> /tmp/names
  cp tests/data/$BATS_TEST_NAME/.env . 2>/dev/null || true
}

function teardown {
  echo $output > tests/debug/$BATS_TEST_NAME.log
  rm .env 2>/dev/null || true
}

@test "azgw --help" {
  run ./azgw.sh --help
  [ "$status" -eq 0 ]
  [ "$(echo $output | grep -c 'Usage: azgw \[OPTIONS\]')" = "1" ]
}

@test "no cli, env parameters, only prompts" {
  run echo $(echo -e "url#\nemail#\npassword#" | ./azgw.sh --debug-input=true && echo FINAL_EXIT_CODE=$?)
  [ "$(echo $output | grep -c 'FINAL_EXIT_CODE=0')" = "1" ]
  [ "$(echo $output | grep -c 'GANGWAY_URL=url#')" = "1" ]
  [ "$(echo $output | grep -c 'AZURE_EMAIL=email#')" = "1" ]
  [ "$(echo $output | grep -c 'AZURE_PASSWORD=password#')" = "1" ]
}

@test "1 cli parameter, 2 prompts" {
  run echo $(echo -e "email#\npassword#" | ./azgw.sh --debug-input=true --gangway-url=url# && echo FINAL_EXIT_CODE=$?)
  [ "$(echo $output | grep -c 'FINAL_EXIT_CODE=0')" = "1" ]
  [ "$(echo $output | grep -c 'GANGWAY_URL=url#')" = "1" ]
  [ "$(echo $output | grep -c 'AZURE_EMAIL=email#')" = "1" ]
  [ "$(echo $output | grep -c 'AZURE_PASSWORD=password#')" = "1" ]
}

@test "1 cli parameter, 1 env parameter, 1 prompt" {
  run echo $(export AZURE_EMAIL=email# && echo -e "password#" | ./azgw.sh --debug-input=true --gangway-url=url# && echo FINAL_EXIT_CODE=$?)
  [ "$(echo $output | grep -c 'FINAL_EXIT_CODE=0')" = "1" ]
  [ "$(echo $output | grep -c 'GANGWAY_URL=url#')" = "1" ]
  [ "$(echo $output | grep -c 'AZURE_EMAIL=email#')" = "1" ]
  [ "$(echo $output | grep -c 'AZURE_PASSWORD=password#')" = "1" ]
}

@test "1 cli parameter, 1 env parameter, 1 .env entry, 1 prompt" {
  run echo $(export AZURE_EMAIL=email# && echo -e "password#" | ./azgw.sh --debug-input=true --gangway-url=url# && echo FINAL_EXIT_CODE=$?)
  [ "$(echo $output | grep -c 'FINAL_EXIT_CODE=0')" = "1" ]
  [ "$(echo $output | grep -c 'GANGWAY_URL=url#')" = "1" ]
  [ "$(echo $output | grep -c 'AZURE_EMAIL=email#')" = "1" ]
  [ "$(echo $output | grep -c 'AZURE_PASSWORD=password#')" = "1" ]
  [ "$(echo $output | grep -c 'PUPPETEER_CONFIG={}')" = "1" ]
}

@test ".env overrides env parameter, cli overrides .env parameter" {
  run echo $(export GANGWAY_URL=env# && export AZURE_EMAIL=env# && export AZURE_PASSWORD=env# && ./azgw.sh --debug-input=true --azure-password=cli# && echo FINAL_EXIT_CODE=$?)
  [ "$(echo $output | grep -c 'FINAL_EXIT_CODE=0')" = "1" ]
  [ "$(echo $output | grep -c 'GANGWAY_URL=env#')" = "1" ]
  [ "$(echo $output | grep -c 'AZURE_EMAIL=dotenv#')" = "1" ]
  [ "$(echo $output | grep -c 'AZURE_PASSWORD=cli#')" = "1" ]
}

@test "proceed with successful lookup" {
  run echo $(echo -e "url#\nemail#\npassword#" | ./azgw.sh --debug-input=true --lookup=github.com && echo FINAL_EXIT_CODE=$?)
  [ "$(echo $output | grep -c 'FINAL_EXIT_CODE=0')" = "1" ]
}

@test "fail with unsuccessful lookup" {
  run echo $(echo -e "url#\nemail#\npassword#" | ./azgw.sh --debug-input=true --lookup=this.domain.does.not.exist.xcnsdnfljrwem; echo FINAL_EXIT_CODE=$?)
  [ "$(echo $output | grep -c 'FINAL_EXIT_CODE=1')" = "1" ]
  [ "$(echo $output | grep -c 'could not find IPV4 with: nslookup ')" = "1" ]
}
