#!/bin/bash
set -e

# ---- BUILD PHASE ----
function build() {
    echo "Build the application and produce a binary. Most likely you'll
        upload that binary somewhere"
    exit 1
}

function apiCompatibilityCheck() {
    echo "Execute api compatibility check step"
    exit 1
}

# ---- TEST PHASE ----

function testDeploy() {
    echo "Deploy binaries and required services to test environment"
    exit 1
}

function testRollbackDeploy() {
    echo "Deploy binaries and required services to test environment for rollback testing"
    exit 1
}

function prepareForSmokeTests() {
    echo "Prepares environment for smoke tests"
    exit 1
}

function runSmokeTests() {
    echo "Executes smoke tests "
    exit 1
}

# ---- STAGE PHASE ----

function stageDeploy() {
    echo "Deploy binaries and required services to stage environment"
    exit 1
}

function prepareForE2eTests() {
    echo "Prepares the environment for end to end tests. Most likely will download
    some binaries and upload them to the environment"
    exit 1
}

function runE2eTests() {
    echo "Executes end to end tests"
    exit 1
}

# ---- PRODUCTION PHASE ----

function performGreenDeployment() {
    echo "Will deploy the Green binary next to the Blue one, on the production environment"
    exit 1
}

function deleteBlueInstance() {
    echo "Deletes the old, Blue binary from the production environment"
    exit 1
}

# ---- COMMON ----

function projectType() {
    echo "Returns the type of the project basing on the cloned sources.
    Example: MAVEN, GRADLE etc."
    exit 1
}

function outputFolder() {
    echo "Returns the folder where the built binary will be stored.
    Example: 'target/' - for Maven, 'build/' - for Gradle etc."
    exit 1
}

function testResultsAntPattern() {
    echo "Returns the ant pattern for the test results.
    Example: '**/test-results/*.xml' - for Maven, '**/surefire-reports/*' - for Gradle etc."
    exit 1
}

# Finds the latest prod tag from git
function findLatestProdTag() {
    local LAST_PROD_TAG=$(git for-each-ref --sort=taggerdate --format '%(refname)' refs/tags/prod | head -n 1)
    LAST_PROD_TAG=${LAST_PROD_TAG#refs/tags/}
    echo "${LAST_PROD_TAG}"
}

# Extracts the version from the production tag
function extractVersionFromProdTag() {
    local tag="${1}"
    LAST_PROD_VERSION=${tag#prod/}
    echo "${LAST_PROD_VERSION}"
}

# For the given environment retrieves the contents of the variable.
# Example for TEST environment would be resolution of the
# TEST_SERVICES variable
function retrieveServices() {
    local services="${ENVIRONMENT}_SERVICES"
    local envServices="${!services}"
    echo "${envServices}"
}

# Checks for existence of pipeline.rc file that contains types and names of the
# services required to be deployed for the given environment
# example for TEST environment:
# export TEST_SERVICES="rabbitmq:rabbitmq-github-webhook mysql:mysql-github-webhook"
function pipelineRcExists() {
    if [ -f "pipeline.rc" ]
    then
        echo "true"
    else
        echo "false"
    fi
}

function deleteService() {
    local serviceType="${1}"
    local serviceName="${2}"
    echo "Should delete a service of type [${serviceType}] and name [${serviceName}]
    Example: deleteService mysql foo-mysql
    "
    exit 1
}

function deployService() {
    local serviceType="${1}"
    local serviceName="${2}"
    echo "Should deploy a service of type [${serviceType}] and name [${serviceName}]
    Example: deployService mysql foo-mysql
    "
    exit 1
}

function serviceExists() {
    local serviceType="${1}"
    local serviceName="${2}"
    echo "Should check if a service of type [${serviceType}] and name [${serviceName}] exists
    Example: serviceExists mysql foo-mysql
    Returns: 'true' if service exists and 'false' if it doesn't
    "
    exit 1
}

# Deploys services assuming that pipeline.rc exists
# For TEST environment first deletes, then deploys services
# For other environments only deploys a service if it wasn't there
function deployServices() {
  if [[ "$( pipelineRcExists )" == "true" ]]; then
    source "pipeline.rc"
    SERVICES=$( retrieveServices )
    PREVIOUS_IFS="${IFS}"
    for service in ${SERVICES}
    do
      IFS=:
      set ${service}
      serviceType=${1}
      serviceName=${2}
      echo "Found service of type [${serviceType}] and name [${serviceName}]"
      if [[ "${ENVIRONMENT}" == "TEST" ]]; then
        deleteService "${serviceType}" "${serviceName}"
        deployService "${serviceType}" "${serviceName}"
      else
        if [[ "$( serviceExists ${serviceType} ${serviceName} )" == "true" ]]; then
          echo "Skipping deployment since service is already deployed"
        else
          deployService "${serviceType}" "${serviceName}"
        fi
      fi
    done
    IFS="${PREVIOUS_IFS}"
  else
    echo "No pipeline.rc found - will not deploy any services"
  fi
}

__ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# CURRENTLY WE ONLY SUPPORT CF AS PAAS OUT OF THE BOX
export PAAS_TYPE="${PAAS_TYPE:-cf}"

echo "Picked PAAS is [${PAAS_TYPE}]"
echo "Current environment is [${ENVIRONMENT}]"

[[ -f "${__ROOT}/pipeline-${PAAS_TYPE}.sh" ]] && source "${__ROOT}/pipeline-${PAAS_TYPE}.sh" || \
    echo "No pipeline-${PAAS_TYPE}.sh found"

export OUTPUT_FOLDER=$( outputFolder )
export TEST_REPORTS_FOLDER=$( testResultsAntPattern )

echo "Output folder [${OUTPUT_FOLDER}]"
echo "Test reports folder [${TEST_REPORTS_FOLDER}]"