#!/usr/bin/env bash
#
# Security Accessment Kit
# Collecter
#
# usage
usage() {
    echo "USAGE"
    echo "    ./SAK_collect.sh <region name>"
    echo "    example:"
    echo "       ./create_report.sh us-west-2"
    echo ""
}

# check input
if [ $# != 1 ]; then
  usage
  exit 1
else
  aws sts get-caller-identity --region ${1} > /dev/null 2>&1
  if [ $? != 0 ]; then
    usage
    exit 1
  fi
fi

TARGET_REGION=${1}

# caws command
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
caws() {
  SDA_ID=${1}
  SDA_SERVICE=${2}
  SDA_COMMAND=${3}
  SDA_PARAM=${4}

  echo aws ${SDA_SERVICE} ${SDA_COMMAND} --region ${SDA_REGION} ${SDA_PARAM}
  aws ${SDA_SERVICE} ${SDA_COMMAND} --region ${SDA_REGION} ${SDA_PARAM} >>${SDA_ID}_${SDA_COMMAND}_${SDA_REGION}.json
}

# COMMON Environment variable
#
# Specify the region to be surveyed.
# Security services settings are surveyed in all region regardless of this setting.
SDA_REGION=${TARGET_REGION}

CURRENT_DIR=$(pwd)
COMMAND_DIR=$(dirname ${0})
RESULT_DIR=./result/SAK_$(date "+%Y%m%d-%H%M%S")
mkdir -p ${RESULT_DIR}

# Run collector for each service

. ${COMMAND_DIR}/collect_rds.sh 2>&1 | tee ${RESULT_DIR}/RDS.log          # AGW


# Archive the result files and delete the temporary files

echo "FINISHED result file : ${RESULT_DIR}"

# END
