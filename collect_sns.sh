#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# SNS collector
#
# -----------------------------------------------------------


# The script creates directories and logs with this tag
SDA_TAG=SNS

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------


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


# SNS01
# Get Topics
TOPICS=$(aws sns list-topics --query Topics[].TopicArn --output text --region ${SDA_REGION})
caws "SNS01" "sns" "list-topics" ""

# SNS02 Get Topic Attributes. Check SSE settings and topic policy
for TPC in ${TOPICS}; do
    caws "SNS02_${TPC}" "sns" "get-topic-attributes" "--topic-arn ${TPC} --region ${SDA_REGION}"
done

cd -
