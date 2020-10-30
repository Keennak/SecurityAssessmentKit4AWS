#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# DynamoDB collector
#
# -----------------------------------------------------------


# The script creates directories and logs with this tag
SDA_TAG=DDB

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


# DDB01
# collect queue list
caws "DDB01" "dynamodb" "list-tables" ""

TABLES=$(aws dynamodb list-tables --query TableNames --output text --region ${SDA_REGION})

# DDB02
# get queue attribute
# Best Practice 01: 
#    Encript DDB table
#
# Best Practice 02: 
#    Minimal access privilege
#    check IAM result
#
# Best Practice 03:
#    Don't use access key
#    check IAM result
#
# Best Practice 04:
#   Use VPC endpoint for ddb
#   check EC2 result
#
# Best Practice 05:
#   Use Client Side Encription
#   This script cannot check CSE.
#   Check your application manually.
#
# Best Practice 06:
#   Consider using DynamoDB Streams to monitor modify/update data-plane operations
#   This script get information of your DDB stream, but not stream consumer application(eg. Lambda).
#   Check your consumer application manually.

for name in ${TABLES}; do
    caws "DDS02_${SDA_REGION}_${name}" "dynamodb" "describe-table" "--table-name ${name} --region ${SDA_REGION}"
done

# Best Practice 07:
#   Monitor KMS operation by CloudTrail
#   ！！！あとでまとめて実装！！！
#
# Best Practice 08:
#   Monitor DynamoDB configuration with AWS Config and Config Rules
#   ！！！あとでまとめて実装！！！
#
# DDB03
# Best Practice 09:
#   Tag your DynamoDB resources for identification and automation

for name in ${TABLES}; do
    arn=$(aws dynamodb describe-table --table-name ${name} --query Table.TableArn| sed 's/"//g')
    caws "DDS03_${SDA_REGION}_${name}" "dynamodb" "list-tags-of-resource" "--resource-arn ${arn} --region ${SDA_REGION}"
done

cd -
