#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# Security Services collector 
# This Scripts collect configurations of these services.
#   GuardDuty
#   Security Hub
#   Inspector
#
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=SEC

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# COMMON
# get region list
# This script collects security configurations for all AWS Regions.
REGION_LIST=$(aws ec2 describe-regions --query Regions[*].RegionName --output text)

# SEC01
# Only the minimum required members can access the GuardDuty findings.
# This item will be checked in IAM04

# SEC02
# Only the minimum required members can access the Security Hub findings.
# This item will be checked in IAM04

# SEC03
# Only the minimum required members can access the Inspector findings.
# This item will be checked in IAM04

for region in ${REGION_LIST}; do
    SDA_REGION=${region}

    # SEC04
    # Enable GuardDuty in all regions.
    caws "SEC04_${region}" "guardduty" "list-detectors" ""
    for detector in $(aws guardduty list-detectors --region ${region} --query DetectorIds[*] --output text); do
        caws "SEC04_${region}_${detector}" "guardduty" "get-detector" "--detector-id ${detector}"

        # SEC05
        # Guard Duty results are exported to a dedicated AWS account for monitoring.
        caws "SEC05_${region}_${detector}" "guardduty" "list-publishing-destinations" "--detector-id ${detector}"
    done

    # SEC06
    # CWE Rules are defined for GuardDuty and Seuciryt Hub results that need to be monitored.
    caws "SEC06_${region}" "events" "list-rules" ""

    # SEC07
    # Enable Security Hub in all regions where the system is located.
    caws "SEC07_${region}" "securityhub" "describe-hub" ""
    caws "SEC07_${region}" "securityhub" "describe-standards" ""

    # SEC08
    # Security Hub is integrated into a dedicated AWS account for monitoring.
    caws "SEC08_${region}" "securityhub" "list-members" ""

done

# END
echo "FINISHED ${SDA_TAG}"
cd -
