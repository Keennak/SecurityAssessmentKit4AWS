#!/usr/bin/env bash
#
# Security report creator
# IAM

# Common

usage() {
    echo "USAGE"
    echo "    ./create_report.sh <json file directory>"
    echo "    example:"
    echo "       ./create_report.sh ./results/SAK_20200325-163924"
    echo ""
}

crete_result_directory() {
    current_dir=$(pwd)
    RESULT_DIR=${current_dir}/report/$(basename ${1})
    mkdir -p ${RESULT_DIR}
}

# main

if [ $# != 1 ]; then
    usage
    exit 1
fi
crete_result_directory ${1}
BIN_DIR=$(dirname ${0})
INPUT_DIR=${1}

# create report
#> ${RESULT_DIR}/iam_report.md
#> ${RESULT_DIR}/kms_report.md
#> ${RESULT_DIR}/s3_report.md
#> ${RESULT_DIR}/eks_report.md
#> ${RESULT_DIR}/sec_report.md
#> ${RESULT_DIR}/ec2_report.md
#> ${RESULT_DIR}/config_report.md
> ${RESULT_DIR}/cost_report.md

# create IAM report
# echo "create_report_iam started"
# ${BIN_DIR}/create_report_iam.sh ${INPUT_DIR} >> ${RESULT_DIR}/iam_report.md
# ${BIN_DIR}/create_report_iam.py ${INPUT_DIR} >> ${RESULT_DIR}/iam_report.md
# echo "create_report_iam created. Report: ${RESULT_DIR}/iam_report.md"

# create KMS report
# echo "create_report_kms started"
# ${BIN_DIR}/create_report_kms.py ${INPUT_DIR} >> ${RESULT_DIR}/kms_report.md
# echo "create_report_kms created. Report: ${RESULT_DIR}/kms_report.md"

# # create S3 report
# echo "create_report_s3 started"
# ${BIN_DIR}/create_report_s3.py ${INPUT_DIR} >> ${RESULT_DIR}/s3_report.md
# echo "create_report_s3 created. Report: ${RESULT_DIR}/s3_report.md"

# # create EKS report
# echo "create_report_eks started"
# ${BIN_DIR}/create_report_eks.py ${INPUT_DIR} >> ${RESULT_DIR}/eks_report.md
# echo "create_report_eks created. Report: ${RESULT_DIR}/eks_report.md"

# # create Security Services report
# echo "create_report of security services started"
# echo "create_report_sec started"
# ${BIN_DIR}/create_report_sec.py ${INPUT_DIR} >> ${RESULT_DIR}/sec_report.md
# echo "create_report_cwl started"
# ${BIN_DIR}/create_report_logs.py ${INPUT_DIR} >> ${RESULT_DIR}/sec_report.md
# echo "create_report_trail started"
# ${BIN_DIR}/create_report_trail.py ${INPUT_DIR} >> ${RESULT_DIR}/sec_report.md
# echo "report created. Report: ${RESULT_DIR}/sec_report.md"

# create EC2 report
# echo "create_report_ec2 started"
# ${BIN_DIR}/create_report_ec2.py ${INPUT_DIR} >> ${RESULT_DIR}/ec2_report.md
# echo "create_report_ec2 created. Report: ${RESULT_DIR}/ec2_report.md"

# # create Config report
# echo "create_report_config started"
# ${BIN_DIR}/create_report_config.py ${INPUT_DIR} >> ${RESULT_DIR}/config_report.md 
# echo "create_report_config created. Report: ${RESULT_DIR}/config_report.md"

# create COST report
echo "create_report_cost started"
${BIN_DIR}/create_report_cost.py ${INPUT_DIR} >> ${RESULT_DIR}/cost_report.md 
echo "create_report_cost created. Report: ${RESULT_DIR}/cost_report.md"