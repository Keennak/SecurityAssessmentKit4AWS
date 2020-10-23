#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# CW collector
#
# -----------------------------------------------------------


# The script creates directories and logs with this tag
SDA_TAG=CW

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

# CloudWatch Logs
# CWL01
# collect cloudwatch logs resource policies

caws "CWL01_${SDA_REGION}" "logs" "describe-resource-policies" ""

# CWL02
# collect log group information

caws "CWL02_${SDA_REGION}" "logs" "describe-log-groups" ""
LOG_GROUPS=$(aws logs describe-log-groups --query logGroups[].logGroupName --output text --region ${SDA_REGION})
for n in ${LOG_GROUPS}; do
    # replace / to - of Log Group Name
    name=$(echo ${n}|sed 's/\//-/g')

    caws "CWL02_${SDA_REGION}_${name}" "logs" "describe-metric-filters" "--log-group-name ${n}"
    caws "CWL02_${SDA_REGION}_${name}" "logs" "describe-subscription-filters" "--log-group-name ${n}"
    caws "CWL02_${SDA_REGION}_${name}" "logs" "describe-log-streams" "--log-group-name ${n}"

done

# CWL03
# collect destination

caws "CWL03_${SDA_REGION}" "logs" "describe-destinations" ""

# CloudWatch Events
# CWE01
# collect rules information
caws "CWE01_${SDA_REGION}" "events" "list-rules" ""


# CWE02
# collect target information
RULES=$(aws events list-rules --query Rules[].Name --output text --region ${SDA_REGION})
for n in ${RULES}; do
    caws "CWE02_${SDA_REGION}_${n}" "events" "list-targets-by-rule" "--rule ${n}"
done

# CWE03
# collect events bus
caws "CWE03_${SDA_REGION}" "events" "list-event-buses" ""

cd -
