#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# ELB collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=ELB

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# ELB_COMMON
# create elb function list for this program

LBARN_LIST=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[].[ LoadBalancerArn ]' --region ${SDA_REGION} --output text)

# ELB01 Load Balancer List
caws "ELB01" "elbv2" "describe-load-balancers" ""

for LBARN_NAME in ${LBARN_LIST}; do
# ELB02 LoadBalancer Listener List
  base=`basename ${LBARN_NAME}`
  caws "ELB02_${base}" "elbv2" "describe-listeners" "--load-balancer-arn ${LBARN_NAME}"
  caws "ELB03_${base}" "elbv2" "describe-load-balancer-attributes" "--load-balancer-arn ${LBARN_NAME}"
done
caws "ELB04" "elbv2" "describe-ssl-policies" ""

# END
echo "FINISHED ${SDA_TAG}"
cd -
