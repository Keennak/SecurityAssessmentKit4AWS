#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# S3 collector 
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=S3

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# S3 COMMON
# get bucket list

BUCKET_LIST=$(aws s3api list-buckets --query Buckets[*].Name --output text)

# SSS01
# For accounts that do not require public access, enable public access blocking.
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
caws "SSS01_${ACCOUNT_ID}" "s3control" "get-public-access-block" "--account-id ${ACCOUNT_ID}"

for name in ${BUCKET_LIST}; do
    caws "SSS01_${name}" "s3api" "get-public-access-block" "--bucket ${name}"
done

# SSS02
# aws ec2 describe-vpc-endpoints
# Access S3 using VPC endpoint
caws "SSS02" "ec2" "describe-vpc-endpoints" ""
caws "SSS02" "ec2" "describe-route-tables" ""

# SSS03
# Encrypt a bucket or object with KMS.
# The encryption state of each object is omitted because it is difficult to check by script.

for name in ${BUCKET_LIST}; do
    caws "SSS03_${name}" "s3api" "get-bucket-encryption" "--bucket ${name}"

    # If you want to check the encryption status of each Object for important data, do the following:
    # Beware that it takes time and aws usage.
    # for obj in $(aws s3api list-objects --bucket "${name}" --query Contents[*].Key --output text) ; do
    #   caws "SSS03_${name}_${obj}" "s3api" "head-object" "--bucket ${name} --key ${obj} --query SSEKMSKeyId"
    # done
done

# SSS04
# Set access conditions in bucket policy. (Principal conditions, VPC conditions, IP conditions, MFA conditions, etc.)
for name in ${BUCKET_LIST}; do
    caws "SSS04_${name}" "s3api" "get-bucket-policy" "--bucket ${name}"
done

# SSS05
# Monitor S3 vulnerable settings using Config Rules.
caws "SSS05" "configservice" "describe-config-rules" ""

# SSS06
# Enforce in-transit data encryption using the aws: SecureTransport condition in the bucket policy.
# This item will be checked in SSS04

# SSS07
# Do not use bucket ACL for any purpose other than granting permissions to log delivery group
for name in ${BUCKET_LIST}; do
    caws "SSS07_${name}" "s3api" "get-bucket-acl" "--bucket ${name}"
done

for name in ${BUCKET_LIST}; do

    # SSS08
    # Enable S3 data event log.
    caws "SSS08_${name}" "s3api" "get-bucket-logging" "--bucket ${name}"

    # SSS09
    # Enable versioning and object locking.
    caws "SSS09_${name}" "s3api" "get-bucket-versioning" "--bucket ${name}"
    caws "SSS09_${name}" "s3api" "get-object-lock-configuration" "--bucket ${name}"

    # SSS10
    # Enable MFA Delete on Trail's S3 bucket.
    # This item will be checked in SSS08

    # SSS11
    # Enable Closs region replication.
    caws "SSS11_${name}" "s3api" "get-bucket-replication" "--bucket ${name}"
    caws "SSS11_${name}" "s3api" "get-bucket-location" "--bucket ${name}"

    # SSS12
    # Disable it with SCP, if there is an unnecessary API such as website hosting.
    # This item is not checked in this script. Please check on the console.

    # SSS13
    # Monitor APIs (change of bucket policy, website hosting, endpoint policy, GW setting, sharing of CMK)
    # This item is not checked in this script. Please check on the console.
done

# END
echo "FINISHED ${SDA_TAG}"
cd -
