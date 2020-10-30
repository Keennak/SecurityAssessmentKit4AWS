#!/usr/bin/env bash
#
# Security Accessment Kit
# Collecter
#
# usage
usage() {
    echo "USAGE"
    echo "    ./SAK_collect.sh <region name>  [<profile name>]"
    echo "    example:"
    echo "       ./create_report.sh us-west-2 myProfile"
    echo ""
}

# check input
case $# in
  1 ) 
    aws sts get-caller-identity --region ${1} > /dev/null 2>&1
    if [ $? != 0 ]; then
      usage
      exit 1
    fi
    TARGET_REGION=${1}
    TARGET_PROFILE=""
  ;;
  2 )
    aws sts get-caller-identity --region ${1} --profile ${2} > /dev/null 2>&1
    if [ $? != 0 ]; then
      usage
      exit 1
    fi
    TARGET_REGION=${1}
    TARGET_PROFILE=${2}
  ;;
  * ) 
    usage
    exit 1
  ;;
esac

echo TARGET_PROFILE: ${TARGET_PROFILE}

# caws command
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
caws() {
  SDA_ID=${1}
  SDA_SERVICE=${2}
  SDA_COMMAND=${3}
  SDA_PARAM=${4}

  echo aws ${SDA_SERVICE} ${SDA_COMMAND} --region ${SDA_REGION} ${SDA_PARAM}
  aws ${SDA_SERVICE} ${SDA_COMMAND} --region ${SDA_REGION} ${SDA_PARAM} >>${SDA_ID}_${SDA_COMMAND}_${SDA_REGION}.json
}

change_role(){
  if [ -n "${TARGET_PROFILE}" ]; then
    role_arn="$(aws configure get role_arn --profile ${TARGET_PROFILE})"
    tokens=$(aws sts assume-role --role-arn ${role_arn} --role-session-name "AssessmentKit" --query Credentials)

    export AWS_ACCESS_KEY_ID=`echo $tokens     |jq -r .AccessKeyId`
    export AWS_SECRET_ACCESS_KEY=`echo $tokens |jq -r .SecretAccessKey`
    export AWS_SESSION_TOKEN=`echo $tokens     |jq -r .SessionToken`
    
    echo "Collected by ${role_arn}"

    else
      echo "Collect by current role"

  fi
}

# COMMON Environment variable
#
# Specify the region to be surveyed.
# Security services settings are surveyed in all region regardless of this setting.
SDA_REGION=${TARGET_REGION}

CURRENT_DIR=$(pwd)
COMMAND_DIR=$(dirname ${0})
RESULT_DIR=./result/SAK_$(date "+%Y%m%d-%H%M%S")
mkdir -p ${RESULT_DIR}

# Run collector for each service

# use role in profile
change_role

. ${COMMAND_DIR}/collect_agw.sh 2>&1 | tee ${RESULT_DIR}/AGW.log          # API Gateway
. ${COMMAND_DIR}/collect_athena.sh 2>&1 | tee ${RESULT_DIR}/ATN.log       # Athena
. ${COMMAND_DIR}/collect_codepipeline.sh 2>&1 | tee ${RESULT_DIR}/CDP.log # CodePipeline
. ${COMMAND_DIR}/collect_cw.sh 2>&1 | tee ${RESULT_DIR}/CW.log          # CloudWatch
# . ${COMMAND_DIR}/collect_cwl.sh 2>&1 | tee ${RESULT_DIR}/CWL.log          # CloudWatch Logs is checked in collect_cw.sh
. ${COMMAND_DIR}/collect_ddb.sh 2>&1 | tee ${RESULT_DIR}/DDB.log          # Dynamo DB
. ${COMMAND_DIR}/collect_codedeploy.sh 2>&1 | tee ${RESULT_DIR}/DPL.log   # CodeDeploy
. ${COMMAND_DIR}/collect_ec2.sh 2>&1 | tee ${RESULT_DIR}/EC2.log          # EC2
. ${COMMAND_DIR}/collect_ecr.sh 2>&1 | tee ${RESULT_DIR}/ECR.log          # ECR
. ${COMMAND_DIR}/collect_ecs.sh 2>&1 | tee ${RESULT_DIR}/ECS.log          # ECS
. ${COMMAND_DIR}/collect_eks.sh 2>&1 | tee ${RESULT_DIR}/EKS.log          # EKS
. ${COMMAND_DIR}/collect_elb.sh 2>&1 | tee ${RESULT_DIR}/ELB.log          # ELB
. ${COMMAND_DIR}/collect_iam.sh 2>&1 | tee ${RESULT_DIR}/IAM.log          # IAM
. ${COMMAND_DIR}/collect_kms.sh 2>&1 | tee ${RESULT_DIR}/KMS.log          # KMS
. ${COMMAND_DIR}/collect_kinesis.sh 2>&1 | tee ${RESULT_DIR}/KNS.log      # Kinesis
. ${COMMAND_DIR}/collect_lambda.sh 2>&1 | tee ${RESULT_DIR}/LMD.log       # Lambda
. ${COMMAND_DIR}/collect_route53.sh 2>&1 | tee ${RESULT_DIR}/R53.log      # Route53
. ${COMMAND_DIR}/collect_rds.sh 2>&1 | tee ${RESULT_DIR}/RDS.log          # RDS
. ${COMMAND_DIR}/collect_s3.sh 2>&1  | tee ${RESULT_DIR}/S3.log           # S3
. ${COMMAND_DIR}/collect_sec.sh 2>&1 | tee ${RESULT_DIR}/SEC.log          # GuardDuty Security Hub
. ${COMMAND_DIR}/collect_sm.sh 2>&1  | tee ${RESULT_DIR}/SM.log           # Secretsmanager
. ${COMMAND_DIR}/collect_sns.sh 2>&1 | tee ${RESULT_DIR}/SNS.log          # SNS
. ${COMMAND_DIR}/collect_sqs.sh 2>&1 | tee ${RESULT_DIR}/SQS.log          # SQS
. ${COMMAND_DIR}/collect_ssm.sh 2>&1 | tee ${RESULT_DIR}/SSM.log          # SSM
. ${COMMAND_DIR}/collect_trail.sh 2>&1 | tee ${RESULT_DIR}/TRAIL.log      # CloudTrail

# Archive the result files and delete the temporary files

echo "FINISHED result file : ${RESULT_DIR}"

# END
