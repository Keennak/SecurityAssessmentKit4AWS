#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# Lambda collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=LMD

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# Lambda_COMMON
# create lambda function list for this program

FUNCTION_LIST=$(aws lambda list-functions --query 'Functions[].[ FunctionName ]' --region ${SDA_REGION} --output text)
ROLE_LIST=$(aws lambda list-functions --query 'Functions[].[ Role ]' --region ${SDA_REGION} --output text)

# LMD01 Lambda Function List
caws "LMD01" "lambda" "list-functions" ""

for FUNCTION_NAME in ${FUNCTION_LIST}; do
# LMD02 Get Function
  caws "LAM02_${FUNCTION_NAME}" "lambda" "get-function" "--function-name ${FUNCTION_NAME}"
# LMD03 Get Function policy
  caws "LAM03_${FUNCTION_NAME}" "lambda" "get-policy" "--function-name ${FUNCTION_NAME}"
done

for ROLE_NAME in ${ROLE_LIST}; do
  rolename=`basename ${ROLE_NAME}`
  caws "LMD04_${rolename}" "iam" "get-role" "--role-name ${rolename}"
  caws "LMD05_${rolename}" "iam" "list-attached-role-policies" "--role-name ${rolename}"
  for POLICY_LIST in $(aws iam list-attached-role-policies --role-name ${rolename} --query 'AttachedPolicies[].PolicyName' --region ${SDA_REGION} --output text)
    do
      caws "LMD06_${rolename}_${POLICY_LIST}" "iam" "get-role-policy" "--role-name ${rolename} --policy-name ${POLICY_LIST}"
    done

    for INLINE_POLICY_NAME in $(aws iam list-role-policies --role-name ${rolename} --query PolicyNames --region ${SDA_REGION} --output text)
    do
      caws "LMD07_${rolename}_${INLINE_POLICY_NAME}" "iam" "get-role-policy" "--role-name ${rolename} --policy-name ${INLINE_POLICY_NAME}"
    done
done

# END
echo "FINISHED ${SDA_TAG}"
cd -
