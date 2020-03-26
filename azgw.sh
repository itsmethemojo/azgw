#!/bin/bash

HELP_TEXT="Usage: azgw [OPTIONS]
login against heptio gangway service with azure AD credentials
Example: azgw --gangway-url=https://gangway.mydomain --azure-email surname.name@mailprovider.com

Parameters:
  --gangway-url             [PROMPTED] url of the gangway server
  --azure-email             [PROMPTED] azure account email for the login
  --azure-password          [PROMPTED] azure account password
  --docker-run-options      [OPTIONAL] pass in additional docker run options like --add-host

All parameters above can also be passed in via environment or .env file. In this case use uppercase-lowdash syntax

Example: export GANGWAY_URL=https://gangway.mydomain

With [PROMPTED] marked parametes will be prompted when not given in on any other way.
"
PATH_GANGWAY_KUBECONFIG=/tmp/GANGWAY_KUBECONFIG
DOCKER_IMAGE=itsmethemojo/azgw

read_key_value_line () {
  KEY_VALUE_LINE=$1
  # if cli parameter cut off leading --
  if [ "$(echo ${KEY_VALUE_LINE} | cut -c -2 )" == "--" ];
  then
    KEY_VALUE_LINE="$(echo "${KEY_VALUE_LINE}" | cut -c 3- )"
  fi
  KEY=$(echo "${KEY_VALUE_LINE}" | awk -F'=' '{print $1}' | tr  '[:lower:]' '[:upper:]' | tr '-' '_')
  if [ "${KEY}" == "HELP" ];
  then
    echo -e "$HELP_TEXT"
    exit 1
  fi
  VALUE=$(echo "${KEY_VALUE_LINE}" | awk '{sub(/=/,"§")}1' | awk -F'§' '{print $2}')
  export ${KEY}="${VALUE}"
}

# read .env
if [ -f .env ];
then
  while read -r dot_env_line; do
    read_key_value_line "$dot_env_line"
  done < ".env"
fi

# read cli parameters
for cli_param in "$@"
do
  read_key_value_line "$cli_param"
done

# ask for still missing parameters
if [[ -z "${GANGWAY_URL}" ]];
then
  read -p 'GANGWAY_URL=' GANGWAY_URL
fi

if [[ -z "${AZURE_EMAIL}" ]];
then
  read -p 'AZURE_EMAIL=' AZURE_EMAIL
fi

if [[ -z "${AZURE_PASSWORD}" ]];
then
  read -sp 'AZURE_PASSWORD=' AZURE_PASSWORD
fi

if [[ -z "${DOCKER_RUN_OPTIONS}" ]];
then
  DOCKER_RUN_OPTIONS=""
fi
echo ""

# TODO this should be removed when automatic build are in place
# TODO add option to use local build container
docker build -t ${DOCKER_IMAGE} . > /dev/null 2>&1
docker run \
${DOCKER_RUN_OPTIONS} \
-e "AZURE_EMAIL=${AZURE_EMAIL}" \
-e "AZURE_PASSWORD=${AZURE_PASSWORD}" \
-e "GANGWAY_URL=${GANGWAY_URL}" \
${DOCKER_IMAGE} > ${PATH_GANGWAY_KUBECONFIG}

if [ "grep 'BEGIN CERTIFICATE' $PATH_GANGWAY_KUBECONFIG | wc -l" == "0" ];
then
  echo -e "something went wrong\n\n"
  cat ${PATH_GANGWAY_KUBECONFIG}
  exit 1
fi

chmod +x ${PATH_GANGWAY_KUBECONFIG} && \
bash ${PATH_GANGWAY_KUBECONFIG} && \
rm ${PATH_GANGWAY_KUBECONFIG}
