#!/bin/bash

HELP_TEXT="Usage: azgw [OPTIONS]
login against heptio gangway service with azure AD credentials
Example: azgw --gangway-url=https://gangway.mydomain --azure-email surname.name@mailprovider.com

Parameters:
  --gangway-url             [PROMPTED] url of the gangway server
  --azure-email             [PROMPTED] azure account email for the login
  --azure-password          [PROMPTED] azure account password
  --docker-run-options      [OPTIONAL] pass in additional docker run options like --add-host
  --local-build             [OPTIONAL] if set to 'true' the needed docker image will be build locally from sources
  --docker-tag              [OPTIONAL] set a specific tag of the itsmethemojo/azgw image to be used
  --debug-input             [OPTIONAL] if set to 'true' prints out all parameters that will be given to the puppeteer container

All parameters above can also be passed in via environment or .env file. In this case use uppercase-lowdash syntax

Example: export GANGWAY_URL=https://gangway.mydomain

With [PROMPTED] marked parametes will be prompted when not given in on any other way.
"
PATH_GANGWAY_KUBECONFIG=/tmp/GANGWAY_KUBECONFIG

read_key_value_line () {
  KEY_VALUE_LINE="$1"
  if [ "$(echo "${KEY_VALUE_LINE}" | xargs )" == "" ];
  then
    return 0
  fi
  # if cli parameter cut off leading --
  if [ "$(echo "${KEY_VALUE_LINE}" | cut -c -2 )" == "--" ];
  then
    KEY_VALUE_LINE="$(echo "${KEY_VALUE_LINE}" | cut -c 3- )"
  fi
  KEY=$(echo "${KEY_VALUE_LINE}" | awk -F'=' '{print $1}' | tr  '[:lower:]' '[:upper:]' | tr '-' '_')
  if [ "${KEY}" == "HELP" ];
  then
    echo -e "${HELP_TEXT}"
    exit 0
  fi
  VALUE=$(echo "${KEY_VALUE_LINE}" | awk '{sub(/=/,"§")}1' | awk -F'§' '{print $2}')
  if [ "${VALUE}" == "" ];
  then
    echo -e "given parameter ${KEY} is empty"
    exit 1
  fi
  export "${KEY}"="${VALUE}"
}

# read .env
if [ -f .env ];
then
  while read -r DOT_ENV_LINE; do
    read_key_value_line "${DOT_ENV_LINE}"
  done < ".env"
fi

# read cli parameters
for CLI_PARAM in "$@"
do
  read_key_value_line "${CLI_PARAM}"
done

# ask for still missing parameters
if [[ -z "${GANGWAY_URL}" ]];
then
  # shellcheck disable=SC2162
  read -p "GANGWAY_URL=" GANGWAY_URL
fi

if [[ -z "${AZURE_EMAIL}" ]];
then
  # shellcheck disable=SC2162
  read -p "AZURE_EMAIL=" AZURE_EMAIL
fi

if [[ -z "${AZURE_PASSWORD}" ]];
then
  # shellcheck disable=SC2162
  read -sp "AZURE_PASSWORD=" AZURE_PASSWORD
fi
echo ""

# set default values

if [[ -z "${DOCKER_RUN_OPTIONS}" ]];
then
  DOCKER_RUN_OPTIONS=""
fi

if [[ -z "${DOCKER_TAG}" ]];
then
  DOCKER_TAG="latest"
fi

USED_IMAGE="itsmethemojo/azgw:${DOCKER_TAG}"

if [[ "${LOCAL_BUILD}" == "true" ]];
then
  USED_IMAGE="itsmethemojo/azgw-local:latest"
  docker build -t ${USED_IMAGE} .
fi

if [[ -n "${DEBUG_INPUT}" ]];
then
  echo "GANGWAY_URL=${GANGWAY_URL}"
  echo "AZURE_EMAIL=${AZURE_EMAIL}"
  echo "AZURE_PASSWORD=${AZURE_PASSWORD}"
  exit 0
fi

# shellcheck disable=SC2086
docker run \
${DOCKER_RUN_OPTIONS} \
-e "GANGWAY_URL=${GANGWAY_URL}" \
-e "AZURE_EMAIL=${AZURE_EMAIL}" \
-e "AZURE_PASSWORD=${AZURE_PASSWORD}" \
${USED_IMAGE} > ${PATH_GANGWAY_KUBECONFIG}

if [ "$(grep -c 'BEGIN CERTIFICATE' ${PATH_GANGWAY_KUBECONFIG})" == "0" ];
then
  echo -e "something went wrong\n\n"
  cat ${PATH_GANGWAY_KUBECONFIG}
  exit 1
fi

chmod +x ${PATH_GANGWAY_KUBECONFIG} && \
bash ${PATH_GANGWAY_KUBECONFIG} && \
rm ${PATH_GANGWAY_KUBECONFIG}
