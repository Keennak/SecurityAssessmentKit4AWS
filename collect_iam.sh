#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# IAM collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=IAM

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# IAM_COMMON
# get user group and role list for this program

USER_LIST=$(aws iam list-users --query Users[*].UserName --output text)
ROLE_LIST=$(aws iam list-roles --query Roles[*].RoleName --output text)
GROUP_LIST=$(aws iam list-groups --query Groups[*].GroupName --output text)

# IAM01
# check access key of root account
# Prowler[checl112]

# IAM02
# collect IAM user list

caws "IAM02" "iam" "list-users" ""

# IAM03
# collect group list for the users

for USER_NAME in ${USER_LIST}; do
  caws "IAM03_${USER_NAME}" "iam" "list-groups-for-user" "--user-name ${USER_NAME}"
done

# IAM04
# collect privilege information of all principals

IAM04() {
  # (1) collect policy attached to roles

  caws "IAM04" "iam" "list-roles"

  for ROLE_NAME in ${ROLE_LIST}; do
    caws "IAM04_${ROLE_NAME}" "iam" "list-role-policies" "--role-name ${ROLE_NAME}"

    for INLINE_POLICY_NAME in $(aws iam list-role-policies --role-name ${ROLE_NAME} --query PolicyNames --output text); do
      caws "IAM04_${ROLE_NAME}_${INLINE_POLICY_NAME}" "iam" "get-role-policy" "--role-name ${ROLE_NAME} --policy-name ${INLINE_POLICY_NAME}"
    done
    caws "IAM04_${ROLE_NAME}" "iam" "list-attached-role-policies" "--role-name ${ROLE_NAME}"
  done

  # (2) collect policy attached to users

  for USER_NAME in ${USER_LIST}; do
    caws "IAM04_${USER_NAME}" "iam" "list-user-policies" "--user-name ${USER_NAME}"

    for INLINE_POLICY_NAME in $(aws iam list-user-policies --user-name ${USER_NAME} --query PolicyNames --output text); do
      caws "IAM04_${USER_NAME}_${INLINE_POLICY_NAME}" "iam" "get-user-policy" "--user-name ${USER_NAME} --policy-name ${INLINE_POLICY_NAME}"
    done
    caws "IAM04_${USER_NAME}" "iam" "list-attached-user-policies" "--user-name ${USER_NAME}"
  done

  # (3) collect policy attached to groups

  caws "IAM04" "iam" "list-groups"

  for GROUP_NAME in ${GROUP_LIST}; do
    caws "IAM04_${GROUP_NAME}" "iam" "list-group-policies" "--group-name ${GROUP_NAME}"

    for INLINE_POLICY_NAME in $(aws iam list-group-policies --group-name ${GROUP_NAME} --query PolicyNames --output text); do
      caws "IAM04_${GROUP_NAME}_${INLINE_POLICY_NAME}" "iam" "get-group-policy" "--group-name ${GROUP_NAME} --policy-name ${INLINE_POLICY_NAME}"
    done

    caws "IAM04_${GROUP_NAME}" "iam" "list-attached-group-policies" "--group-name ${GROUP_NAME}"

  done

  # (4) collect policy json
  # get policy arn list, without aws managed policy

  LIST=$(ls -1 *attach*policies*.json | while read FILE; do cat $FILE | jq .AttachedPolicies[].PolicyArn -r; done | grep -v "iam\:\:aws" | sort -u)
  # get policy json
  for POLICY_ARN in ${LIST}; do
    CURRENT_VERSION=$(aws iam get-policy --policy-arn ${POLICY_ARN} --query Policy.DefaultVersionId --output text)
    POLICY_NAME=$(echo ${POLICY_ARN} | cut -d / -f 2)
    caws "IAM04_${POLICY_NAME}" "iam" "get-policy-version" "--policy-arn ${POLICY_ARN} --version-id ${CURRENT_VERSION}"
  done

}
IAM04

# IAM05
# check managed policy usage
# This check is included in IAM04
# Managed policy is ”arn:aws:iam::aws:policy-name” in list-attached-xxxx-policies result.

# IAM06
# check no inline policies are used
# This check is included in IAM04
#

# IAM07
# check strong password policies and rotation are set for users
# Prowler [check15] -[check111]

# IAM08
# check multi-factor authentication (MFA) for all users in this account
# Prowler[check113] for root account
# checks below is for IAM users

for USER_NAME in ${USER_LIST}; do
  caws "IAM08_${USER_NAME}" "iam" "list-mfa-devices" "--user-name ${USER_NAME}"
done

# IAM09
# Use roles instead of access keys in EC2 instances.
# Prowler[check119]

# IAM10
# Remove unnecessary IAM user credentials (passwords and access keys)
# AccessKey is checked by Prowler[check121]
# checks below is for password

for USER_NAME in ${USER_LIST}; do
  caws "IAM10_${USER_NAME}" "iam" "get-login-profile" "--user-name ${USER_NAME}"
done

# IAM11
# Monitor the login of root account, KMS administrator, IAM administrator, Org administrator, etc.
# This check is not coded.

# IAM12
# Grant least privileges to instance roles
# This check is included in IAM04

# IAM13
# Grant least trust to roles
# This check is included in IAM04
# aws iam list-roles --query Roles[*].[RoleName,AssumeRolePolicyDocument]

# IAM14
# Delete unnecessary roles

for ROLE_NAME in ${ROLE_LIST}; do
  caws "IAM14_${ROLE_NAME}" "iam" "get-role" "--role-name ${ROLE_NAME}"
done


# END
echo "FINISHED ${SDA_TAG}"
cd -