#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# EC2 collector
#
# -----------------------------------------------------------

SDA_REGION=${TARGET_REGION}
# get caller account id
account_id=$(aws sts get-caller-identity --query "Account" --output text)

# The script creates directories and logs with this tag
SDA_TAG=EC2

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# EC2_COMMON

# get region list
# This script collects security configurations for all AWS Regions.
REGION_LIST=$(aws ec2 describe-regions --query Regions[*].RegionName --output text)
# REGION_LIST=ap-northeast-1

## get user group and role list for this program

## USER_LIST=$(aws iam list-users --query Users[*].UserName --output text)
## ROLE_LIST=$(aws iam list-roles --query Roles[*].RoleName --output text)
## GROUP_LIST=$(aws iam list-groups --query Groups[*].GroupName --output text)

for region in ${REGION_LIST}; do
    SDA_REGION=${region}
    # EC201
    # collect relationships between security groups and ec2 instances
    # caws "EC201" "ec2" "describe-instances" "--query 'Reservations[*].instances[*].[InstanceId,SecurityGroups]'"
    caws "EC201" "ec2" "describe-instances" ""
    # collect security groups
    caws "EC201" "ec2" "describe-security-groups" ""

    # EC202
    # get the list of NOT encrypted volumes
    #    caws "EC202" "ec2" "describe-volumes" "--query 'Volumes[?Encrypted==\`false\`]'"
    caws "EC202" "ec2" "describe-volumes" ""

    # EC203
    # get the list of NOT encrypted snapshots
    #    caws "EC203" "ec2" "describe-snapshots" "--query 'Snapshots[?Encrypted==\`false\`]'"
    caws "EC203" "ec2" "describe-snapshots" "--owner-ids ${account_id}"

    # EC204

    # get the list of AMIs owned by the caller account id
    caws "EC204" "ec2" "describe-images" "--owner ${account_id}"
    # get ami list
    ami_list=$(aws ec2 describe-images --owner $(aws sts get-caller-identity --query "Account" --output text) --query "Images[*].[ImageId]" --region ${SDA_REGION} --output text)
    # check each ami's launch permission
    for amiid in ${ami_list}; do
        caws "EC204_${amiid}" "ec2" "describe-image-attribute" "--attribute launchPermission --image-id ${amiid}"
    done

    # EC205
    # get roles attached to inctances to check if they are minimum
    # caws "EC205" "ec2" "describe-instances" "--query 'Reservations[].Instances[].[InstanceId,IamInstanceProfile.Arn]'"
    caws "EC205" "ec2" "describe-instances" ""

    # EC206
    # get a list of security groups which contains FromPort==22 (ssh is open)
    #caws "EC206" "ec2" "describe-security-groups" "--query 'SecurityGroups[*].[GroupId,IpPermissions[?FromPort==\`22\`]]'"
    caws "EC206" "ec2" "describe-security-groups" ""
    # get keypairs (expected number is 0)
    caws "EC206" "ec2" "describe-key-pairs" ""

    # EC207
    # get the list of VPCs
    caws "EC207" "ec2" "describe-vpcs" ""
    # get the list of VPC Flow Logs
    #  caws "EC207" "ec2" "describe-flow-logs" "--query 'FlowLogs[*].[FlowLogId,ResourceId,LogDestinationType,LogDestination]'"
    caws "EC207" "ec2" "describe-flow-logs" ""

    # EC208
    # get the list of instances which is not set IMDSv2 required
    # caws "EC208" "ec2" "describe-instances" "--query 'Reservations[*].Instances[?MetadataOptions.HttpTokens==\`optional\`].[InstanceId,MetadataOptions.HttpTokens]'"
    caws "EC208" "ec2" "describe-instances" ""

    # EC209
    # get EIPs
    caws "EC209" "ec2" "describe-addresses" ""
    # get instances which have Public Ip Addresses
    # caws "EC209" "ec2" "describe-instances" "--query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]'"
    caws "EC209" "ec2" "describe-instances" ""
    # get IGWs
    caws "EC209" "ec2" "describe-internet-gateways" ""
    # get VGWs
    caws "EC209" "directconnect" "describe-virtual-gateways" ""
    # get VPN GWs
    caws "EC209" "ec2" "describe-vpn-gateways" ""
    # get NAT GWs
    caws "EC209" "ec2" "describe-nat-gateways" ""

    # EC210
    # check alb log bucket is correct
    caws "EC210" "elbv2" "describe-load-balancers" ""
    ALB_ARN_LIST=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --region ${SDA_REGION} --output text)
    echo ${ALB_ARN_LIST}
    for arn in ${ALB_ARN_LIST}; do
        name=$(basename ${arn})
        caws "EC210_${name}" "elbv2" "describe-load-balancer-attributes" "--load-balancer-arn ${arn}"
    done

    # 2020/4/23 added
    # EC2_EX1
    caws "EC2EX1" "ec2" "describe-network-interfaces" ""
    caws "EC2EX1" "ec2" "describe-vpc-endpoints" ""
    caws "EC2EX1" "ec2" "describe-route-tables" ""


    
done
cd -

