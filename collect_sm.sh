#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# Secret Manager Logs collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=SM

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# SM COMMON
# get KEY list
SECRET_LIST=$(aws secretsmanager list-secrets --query SecretList[*].Name --region ${SDA_REGION} --output text)
KEY_LIST=$(aws secretsmanager list-secrets --query SecretList[*].KmsKeyId --region ${SDA_REGION} --output text)

# SM01
caws "SM01" "secretsmanager" "list-secrets" ""

# SM02
for name in ${SECRET_LIST}; do
    caws "SM02_${name}" "secretsmanager" "get-resource-policy" "--secret-id ${name}"
done

# SM03
for name in ${KEY_LIST}; do
    kn=`basename ${name}`
    caws "SM03_${kn}" "kms" "get-key-policy" "--key-id ${name} --policy-name default"
done
# END

echo "FINISHED ${SDA_TAG}"
cd -
