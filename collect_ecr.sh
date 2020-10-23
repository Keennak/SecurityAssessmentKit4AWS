#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# ECR collector
#
# -----------------------------------------------------------


# The script creates directories and logs with this tag
SDA_TAG=ECR

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# COMMON

# get caller account id
# account_id=$(aws sts get-caller-identity --query "Account" --output text)

# get region list
# This script collects security configurations for all AWS Regions.
# REGION_LIST=$(aws ec2 describe-regions --query Regions[*].RegionName --output text)
# REGION_LIST=ap-northeast-1

# get user group and role list for this program
# USER_LIST=$(aws iam list-users --query Users[*].UserName --output text)
# ROLE_LIST=$(aws iam list-roles --query Roles[*].RoleName --output text)
# GROUP_LIST=$(aws iam list-groups --query Groups[*].GroupName --output text)


# ECR01
# collect repository list & information
#   encryptionConfiguration to check KMS Encription Status

caws "ECR01_${SDA_REGION}" "ecr" "describe-repositories" ""

# ECR02
# collect repository policy

REPOSITORIES=$(aws ecr describe-repositories --query repositories[].repositoryName --output text --region ${SDA_REGION})
for n in ${REPOSITORIES}; do
    caws "ECR02_${SDA_REGION}_${n}" "ecr" "get-repository-policy" "--repository-name ${n}"
done

cd -
