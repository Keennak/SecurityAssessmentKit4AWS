#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# CloudWatch Logs collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=CWL

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# CWL COMMON
# get log group list
GROUP_LIST=$(aws logs describe-log-groups --query logGroups[*].logGroupName --output text)

# CWL01
# Encrypt the log group with KMS, if the log contains sensitive information,
caws "CWL01" "logs" "describe-log-groups" ""

# CWL02
# Use VPC endpoint when referencing Trail from private subnet.
# Check in EC2 Section.
# aws ec2 describe-vpc-endpoints

# CWL03
# Monitor log S3 export API.
# This item is not checked in this script. Please check on the console.
# In this section, the script checks the settings of the export task.
caws "CWL03" "logs" "describe-export-tasks" ""

# CWL04
# Monitor usage of log streams to other accounts.
for name in ${GROUP_LIST}; do
    caws "CWL04" "logs" "describe-subscription-filters" "--log-group-name ${name}"
done
caws "CWL04" "logs" "describe-destinations" ""

# END
echo "FINISHED ${SDA_TAG}"
cd -
