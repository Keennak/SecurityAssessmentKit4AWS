#!/usr/bin/env bash
#
# Security Deep Accessment Collector
#
# Security Services collector
# This Scripts collect configurations of these services.
#   EKS
#
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=EKS

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# COMMON
# get cluster list
# This script collects security configurations for all AWS Regions.
CLUSTER_LIST=$(aws eks list-clusters --region ${SDA_REGION} --query clusters --output text)

# EKS01
# Assign only minimal permissions to worker node IAM roles
# Permissions of the roles are checked in IAM04
caws "EKS01" "ec2" "describe-instances" ""

# EKS02
# Restrict access to worker node instance profiles.
# This item is not checked in this script. Please check instance iptables.
# https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/restrict-ec2-credential-access.html

# EKS03
# The version of the Kubernates cluster is the latest or acceptable version.
# This item is not checked in this script. Please check "kubectl version --short"

# EKS04
# The AMI version on the worker node is the latest or acceptable version.
for image in $(aws ec2 describe-instances --region ${SDA_REGION} --query 'Reservations[].Instances[].[ImageId]' --output text); do
    caws "EKS04" "ec2" "describe-images" "--image-ids ${image}"
done

# EKS05
# Cluster Logs are delivered to CloudWatch Logs.
for cluster in ${CLUSTER_LIST}; do
    caws "EKS05_${cluster}" "eks" "describe-cluster" "--name ${cluster}"
done

# EKS06
# Transfer worker node CNI privileges to service account
# This item is not checked in this script. Please check your woker instance settings.
# https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/iam-roles-for-service-accounts-cni-walkthrough.html

# EKS07
# Apply Pod Security Policy.
# This item is not checked in this script. Please check your woker instance settings.
# https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/pod-security-policy.html

# EKS08
# Set the Security Group of the EKS control plane, cluster, and worker nodes within the minimum necessary range.
for cluster in ${CLUSTER_LIST}; do
    for sg in $(aws eks describe-cluster --region ${SDA_REGION} --name ${cluster} --query 'cluster.resourcesVpcConfig.securityGroupIds' --output text); do
        caws "EKS08_${cluster}_${sg}" "ec2" "describe-security-groups" "--group-ids ${sg}"
    done
done

# EKS09
# Make the cluster endpoint private.
# This item will be checked in EKS05
# https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/cluster-endpoint.html

# END
echo "FINISHED ${SDA_TAG}"
cd -
