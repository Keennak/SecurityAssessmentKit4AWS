#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# SSM Logs collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=SSM

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# SSM COMMON
# get KEY list
KEY_LIST=$(aws ssm describe-parameters --query Parameters[*].KeyId --region ${SDA_REGION} --output text)

# SSM01
caws "SSM01" "ssm" "describe-parameters" ""

# SSM02
for name in ${KEY_LIST}; do
    KEYID=$(aws kms describe-key --key-id ${name} --query KeyMetadata.KeyId --region ${SDA_REGION} --output text)
    bname=`basename ${name}`
    caws "SSM02_${bname}" "kms" "describe-key" "--key-id ${name}" 
    caws "SSM03_${KEYID}" "kms" "get-key-policy" "--key-id ${KEYID} --policy-name default"
done

# END
echo "FINISHED ${SDA_TAG}"
cd -
