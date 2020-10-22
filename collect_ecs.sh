#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# ECS collector
#
# -----------------------------------------------------------


# The script creates directories and logs with this tag
SDA_TAG=ECS

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


# ECS01
# collect cluster list & information

caws "ECS01_${SDA_REGION}" "ecs" "list-clusters" ""
CLUSTER_ARNS=$(aws ecs list-clusters --query clusterArns[] --output text --region ${SDA_REGION})

for cluster_arn in ${CLUSTER_ARNS}; do
    cluster_name=$(basename ${cluster_arn})
    caws "ECS01_${SDA_REGION}_${cluster_name}" "ecs" "describe-clusters" "--clusters ${cluster_arn}"

    # ECS02
    # collect service list & information
    caws "ECS02_${SDA_REGION}_${cluster_name}" "ecs" "list-services" "--cluster ${cluster_arn}"

    SERVICE_ARNS=$(aws ecs list-services --cluster ${cluster_arn} --query serviceArns[] --output text --region ${SDA_REGION})
    for service_arn in ${SERVICE_ARNS}; do
        service_name=$(basename ${service_arn})
        caws "ECS02_${SDA_REGION}_${cluster_name}_${service_name}" "ecs" "describe-services" "--services ${service_arn} --cluster ${cluster_arn}"
    done

    # ECS03
    # collect task list & information
    caws "ECS03_${SDA_REGION}_${cluster_name}" "ecs" "list-tasks" "--cluster ${cluster_arn}"

    TASK_ARNS=$(aws ecs list-tasks --cluster ${cluster_arn} --query taskArns[] --output text --region ${SDA_REGION})
    for task_arn in ${TASK_ARNS}; do
        task_name=$(basename ${task_arn})
        caws "ECS03_${SDA_REGION}_${cluster_name}_${task_name}" "ecs" "describe-tasks" "--tasks ${task_arn} --cluster ${cluster_arn}"
    done
done

# ECS04
# collect task definition
caws "ECS04" "ecs" "list-task-definitions" ""
TASK_DEFINITION_ARNS=$(aws ecs list-task-definitions  --query taskDefinitionArns[] --output text --region ${SDA_REGION})
for task_definition_arn in ${TASK_DEFINITION_ARNS}; do
    def_name=$(basename ${task_definition_arn})
    caws "ECS04_${SDA_REGION}_${def_name}" "ecs" "describe-task-definition" "--task-definition ${task_definition_arn}"
done



cd -
