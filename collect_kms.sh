#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# CloudWatch Logs collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=KMS

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# KMS COMMON
# get CMK list
CMK_LIST=$(aws kms list-keys --query Keys[*].KeyId --region ${SDA_REGION} --output text)

# KMS01
# Minimize the permissions of key administrators and users with IAM policies or key policies.
caws "KMS01" "kms" "list-aliases" ""

for name in ${CMK_LIST}; do
    caws "KMS01_${name}" "kms" "get-key-policy" "--key-id ${name} --policy-name default"
done

# KMS02
# Rotete CMK
for name in ${CMK_LIST}; do
    caws "KMS02_${name}" "kms" "get-key-rotation-status" "--key-id ${name}"
done

# KMS03
# In a use case where the priviredge of the IAM administrator is to be suppressed, 
# the root priviredge of the key policy is deleted, 
# and the priviredge is given to the administrator and the user only by the key policy.
# This item will be checked in KMS02

# END
echo "FINISHED ${SDA_TAG}"
cd -
