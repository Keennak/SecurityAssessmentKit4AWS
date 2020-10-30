#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# Kinesis collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=KNS

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# Kinesis Data Streams Stream List
STREAM_LIST=$(aws kinesis list-streams --query 'StreamNames[]' --region ${SDA_REGION} --output text)
caws "KNS01" "kinesis" "list-streams" ""


# Check SSE settings "EncryptionType" in each data stream and check Key policy in KMS
for STREAM in ${STREAM_LIST}; do
  caws "KNS02_${STREAM}" "kinesis" "describe-stream" "--stream-name ${STREAM}"
done

# Check VPC Endpoint and its policy for Kinesis in EC2/VPC

# Kinesis Firehose Delivery Streams List
DELIVERY_LIST=$(aws firehose list-delivery-streams --query 'DeliveryStreamNames[]' --region ${SDA_REGION} --output text)
caws "KNS03" "firehose" "list-delivery-streams" ""

# Check "DeliveryStreamEncryptionConfiguration"
for STREAM in ${DELIVERY_LIST}; do
  caws "KNS04_${STREAM}" "firehose" "describe-delivery-stream" "--delivery-stream-name ${STREAM}"
done

# END
echo "FINISHED ${SDA_TAG}"
cd -

