#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# CodeDeploy: collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=DPL

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# CodeDeploy_Common
APPLICATION_LIST=$(aws deploy list-applications --query 'applications[]' --region ${SDA_REGION} --output text)

# List Applications
caws "DPL01" "deploy" "list-applications" ""

# Get Deployment Group
for LIST in ${APPLICATION_LIST}; do
  caws "DPL02_${LIST}" "deploy" "list-deployment-groups" "--application-name ${LIST}"
  DEPLOYMENT_LIST=$(aws deploy list-deployment-groups --application-name ${LIST} --query 'deploymentGroups[]' --region ${SDA_REGION} --output text)

  for DLIST in ${DEPLOYMENT_LIST}; do
    SERVICEROLE=$(aws deploy get-deployment-group --deployment-group-name ${DLIST} --application-name ${LIST}  --query 'deploymentGroupInfo.serviceRoleArn' --region ${SDA_REGION} --output text)
    ROLENAME=`basename ${SERVICEROLE}`
    caws "DPL03_${LIST}_${DLIST}" "deploy" "get-deployment-group" "--application-name ${LIST} --deployment-group-name ${DLIST}"
    caws "DPL04_${ROLENAME}" "iam" "get-role" "--role-name ${ROLENAME}"
    caws "DPL05_${ROLENAME}" "iam" "list-attached-role-policies" "--role-name ${ROLENAME}"
 
    for POLICY_LIST in $(aws iam list-attached-role-policies --role-name ${ROLENAME} --query 'AttachedPolicies[].PolicyName' --region ${SDA_REGION} --output text)
    do
      caws "DPL06_${ROLENAME}_${POLICY_LIST}" "iam" "get-role-policy" "--role-name ${ROLENAME} --policy-name ${POLICY_LIST}"
    done

    for INLINE_POLICY_NAME in $(aws iam list-role-policies --role-name ${ROLENAME} --query PolicyNames --region ${SDA_REGION} --output text)
    do
      caws "DPL07_${ROLENAME}_${INLINE_POLICY_NAME}" "iam" "get-role-policy" "--role-name ${ROLENAME} --policy-name ${INLINE_POLICY_NAME}"
    done

  done
done

# END
echo "FINISHED ${SDA_TAG}"
cd -

