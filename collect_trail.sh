#!/usr/bin/env bash
#
# HD Security Accessment Collector
# CloudTrail collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag 
SDA_TAG=TRAIL

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------


# CloudTrail COMMON
# get trail list

TRAIL_LIST_JSON=$(aws cloudtrail list-trails --region ap-northeast-1 --query 'Trails[*].{NAME:Name,REGION:HomeRegion}' --output json)
TRAIL_LEN=$(echo ${TRAIL_LIST_JSON} | jq length)

# TRAIL01
# check IAM permissions
# SDA IAM04

# TRAIL02
# Encript Trail by KMS

for i in $(seq 0 $((${TRAIL_LEN} - 1))); do
    name=$(echo ${TRAIL_LIST_JSON} | jq -r .[$i].NAME)
    SDA_REGION=$(echo ${TRAIL_LIST_JSON} | jq -r .[$i].REGION)
    caws "TRAIL02_${name}" "cloudtrail" "get-trail" "--name ${name}"
done

# TRAIL03
# Use Malti-Resion Trail
# checked in TRAIL02
# aws cloudtrail get-trail --name trail-name --region region --query Trail.IsMultiRegionTrail

 caws "TRAIL03" "cloudtrail" "list-trails" ""

# check trail S3 bucket setting

for i in $(seq 0 $((${TRAIL_LEN} - 1))); do
    name=$(echo ${TRAIL_LIST_JSON} | jq -r .[$i].NAME)
    region=$(echo ${TRAIL_LIST_JSON} | jq -r .[$i].REGION)
    bucket=$(aws cloudtrail get-trail --name ${name} --region ${region} --query Trail.S3BucketName --output text)

    # TRAIL04
    # Separate log strage(s3) accounts
    # In this section, you can collect your all trail's S3 bucket settings
    caws "TRAIL04_${name}_${bucket}" "s3api" "get-bucket-acl" "--bucket ${bucket}"

    # TRAIL05
    # Protect Trail S3 buckets with a bucket policy.
    caws "TRAIL05_${name}_${bucket}" "s3api" "get-bucket-policy" "--bucket ${bucket}"

    # TRAIL06
    # Trail buckets can be identified separately from normal buckets and their access status audited. Tagging buckets makes it easier.
    # Because there are multiple monitoring implementation patterns, it is difficult to determine if monitoring is running, you will respond by hearing.
    # This section checks the acquisition status of the object-level log,
    # which is the premise of monitoring, and the presence of tags that facilitate monitoring.
    SDA_REGION=${region}
    caws "TRAIL06_${name}" "cloudtrail" "get-event-selectors" "--trail-name ${name}"
    caws "TRAIL06_${name}_${bucket}" "s3api" "get-bucket-logging" "--bucket ${bucket}"
    caws "TRAIL06_${name}_${bucket}" "s3api" "get-bucket-tagging" "--bucket ${bucket}"

    # TRAIL07
    # Enable the object lifecycle of Trail S3 bucket.
    caws "TRAIL07_${name}_${bucket}" "s3api" "get-bucket-lifecycle-configuration" "--bucket ${bucket}"

    # TRAIL08
    # Enable MFA Delete on Trail's S3 bucket.
    caws "TRAIL08_${name}_${bucket}" "s3api" "get-bucket-versioning" "--bucket ${bucket}"

done

# TRAIL09
# Enable Trail consistency check.
# checked in TRAIL02

# TRAIL10
# Monitor special events, such as sign-ins.
# Because there are multiple monitoring implementation patterns,
# it is difficult to determine if monitoring is running by program.
# In TRAIL02, you can check the status of the link to CWL, which is the premise of monitoring.
# aws cloudtrail get-trail --name <TRAIL_NAME> --query Trail.CloudWatchLogsLogGroupArn

# TRAIL11
# Use VPC endpoint when referencing Trail from private subnet.
# Check in EC2 Section.
# aws ec2 describe-vpc-endpoints

# END
echo "FINISHED ${SDA_TAG}"
cd -

