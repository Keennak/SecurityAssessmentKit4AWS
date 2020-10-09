#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# SQS collector
#
# -----------------------------------------------------------


# The script creates directories and logs with this tag
SDA_TAG=SQS

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


# SQS01
# collect queue list
caws "SQS01" "sqs" "list-queues" ""

QUEUES=$(aws sqs list-queues --query QueueUrls --output text --region ${SDA_REGION})

# SQS02
# get queue attribute
# Best Practice 01: 
#    Disable public queue policy
#
# Best Practice 02: 
#    Minimal access privilege
#    check IAM result
#
# Best Practice 03:
#    Don't use access key
#    check IAM result
#
# Best Practice  04:
#   Use Server Side Encription
#
# Best Practice  05:
#   Use TLS and aws:SecureTransport condition in que policy
#
# Best Practice  06:
#   Use VPC endpoint for sqs
#   check EC2 result

for queue_url in ${QUEUES}; do
    queue_name=$(basename ${queue_url})
    caws "SQS02_${SDA_REGION}_${queue_name}" "sqs" "get-queue-attributes" "--queue-url ${queue_url} --attribute-names All --region ${SDA_REGION}"
done

cd -
