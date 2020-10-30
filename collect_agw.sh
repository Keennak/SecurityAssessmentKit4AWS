#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# Api Gateway collector
#
# -----------------------------------------------------------


# The script creates directories and logs with this tag
SDA_TAG=AGW

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


# AGW01
# collect gateway list
#   AGW01-001
#   collect http & socket apis
caws "AGW01" "apigatewayv2" "get-apis" ""
H_APIS=$(aws apigatewayv2 get-apis --query Items[].ApiId --output text --region ${SDA_REGION})

#   AGW01-002
#   collect rest apis
caws "AGW01" "apigateway" "get-rest-apis" ""
R_APIS=$(aws apigateway get-rest-apis --query items[].id --output text --region ${SDA_REGION})

# This checks also
#   Internetwork traffic privacy (private REST APIs)

# This checks also
#   resource-based policy



# Best Practice 01: 
#    Minimal access privilege
#    check IAM result
#
# AGW02
# Best Practice 02:
#    Implement logging
#
# Addtional Security Settings 01
#   Data encryption at rest in Amazon API Gateway(REST-API only)

for id in ${H_APIS}; do
    caws "AGW02_${SDA_REGION}_${id}" "apigatewayv2" "get-stages" "--api-id ${id} --region ${SDA_REGION}"
done

for id in ${R_APIS}; do
    caws "AGW02_${SDA_REGION}_${id}" "apigateway" "get-stages" "--rest-api-id ${id} --region ${SDA_REGION}"
done

# Best Practice 03:
#   Implement Amazon CloudWatch alarms
#   ！！！あとでまとめて実装！！！
#
# Best Practice 04:
#   Enable AWS CloudTrail
#   ！！！あとでまとめて実装！！！
#
# Best Practice 05:
#   Enable AWS Config
#   ！！！あとでまとめて実装！！！
#




cd -
