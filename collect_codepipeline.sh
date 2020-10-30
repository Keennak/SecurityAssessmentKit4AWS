#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# CodePipeline: collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=CDP

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# CodePipeline_Common
PIPELINE_LIST=$(aws codepipeline list-pipelines --query 'pipelines[].name' --region ${SDA_REGION} --output text)

# Get Pipeline 
caws "CDP01" "codepipeline" "list-pipelines" ""
for LIST in ${PIPELINE_LIST}; do
  caws "CDP02_${LIST}" "codepipeline" "get-pipeline" "--name ${LIST}"
  SERVICEROLE=$(aws codepipeline get-pipeline --name ${LIST} --query 'pipeline.roleArn' --region ${SDA_REGION} --output text)
  ROLENAME=`basename ${SERVICEROLE}`
  caws "CDP03_${ROLENAME}" "iam" "get-role" "--role-name ${ROLENAME}"
  caws "CDP04_${ROLENAME}" "iam" "list-attached-role-policies" "--role-name ${ROLENAME}"
  for POLICY_LIST in $(aws iam list-attached-role-policies --role-name ${ROLENAME} --query 'AttachedPolicies[].PolicyName' --region ${SDA_REGION} --output text)
    do
      caws "CDP05_${ROLENAME}_${POLICY_LIST}" "iam" "get-role-policy" "--role-name ${ROLENAME} --policy-name ${POLICY_LIST}"
    done
  for INLINE_POLICY_NAME in $(aws iam list-role-policies --role-name ${ROLENAME} --query PolicyNames --region ${SDA_REGION} --output text)
  do
    caws "CDP06_${ROLENAME}_${INLINE_POLICY_NAME}" "iam" "get-role-policy" "--role-name ${ROLENAME} --policy-name ${INLINE_POLICY_NAME}"
  done
done

# END
echo "FINISHED ${SDA_TAG}"
cd -

