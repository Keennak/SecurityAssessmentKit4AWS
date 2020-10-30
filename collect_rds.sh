#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# RDS collector
#
# -----------------------------------------------------------


# The script creates directories and logs with this tag
SDA_TAG=RDS

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


# RDS01
# collect DB list & information
#   KmsKeyId to check KMS Encription Status
#   VpcSecurityGroupId to check network access
#   EnabledCloudwatchLogsExports to check DB log export to CWL

# db instance
caws "RDS01_${SDA_REGION}" "rds " "describe-db-instances" ""

# db cluster
caws "RDS01_${SDA_REGION}" "rds " "describe-db-clusters" ""

# RDS02
# collect DB parameters
#   to check DB log enablement

# db instance
caws "RDS02_${SDA_REGION}" "rds" "describe-db-parameter-groups" ""
DB_PGS=$(aws rds describe-db-parameter-groups --query DBParameterGroups[].DBParameterGroupName --output text --region ${SDA_REGION})
for n in ${DB_PGS}; do
    caws "RDS02_${SDA_REGION}_${n}" "rds" "describe-db-parameters" "--db-parameter-group-name ${n}"
done

# db cluster
caws "RDS02_${SDA_REGION}" "rds" "describe-db-cluster-parameter-groups" ""
DB_PGS=$(aws rds describe-db-cluster-parameter-groups --query DBClusterParameterGroups[].DBClusterParameterGroupName --output text --region ${SDA_REGION})
for n in ${DB_PGS}; do
    caws "RDS02_${SDA_REGION}_${n}" "rds" "describe-db-cluster-parameters" "--db-cluster-parameter-group-name ${n}"
done

# RDS03
# collect DB Security Groups

caws "RDS03_${SDA_REGION}" "rds" "describe-db-security-groups" ""

# VPC Security Groups are checked in EC2 tool.
# aws ec2 describe-security-groups

# RDS04
# collect certificates information

caws "RDS04_${SDA_REGION}" "rds" "describe-certificates" ""

# RDS05
# collect snapshot information
#   KmsKeyId to check KMS Encription Status
#   snapshot permission for cross account restoer

# DB instance snapshot
caws "RDS05_${SDA_REGION}" "rds" "describe-db-snapshots" ""
DB_SNAPSHOTS=$(aws rds describe-db-snapshots --query DBSnapshots[].DBSnapshotIdentifier --output text --region ${SDA_REGION})
for n in ${DB_SNAPSHOTS}; do
    caws "RDS05_${SDA_REGION}_${n}" "rds" "describe-db-snapshot-attributes" "--db-snapshot-identifier ${n}"
done

# DB cluster snapshot
caws "RDS05_${SDA_REGION}" "rds" "describe-db-cluster-snapshots" ""
CLUSTER_SNAPSHOTS=$(aws rds describe-db-cluster-snapshots --query DBClusterSnapshots[].DBClusterSnapshotIdentifier --output text --region ${SDA_REGION})
for n in ${CLUSTER_SNAPSHOTS}; do
    caws "RDS05_${SDA_REGION}_${n}" "rds" "describe-db-cluster-snapshot-attributes" "--db-cluster-snapshot-identifier ${n}"
done

cd -
