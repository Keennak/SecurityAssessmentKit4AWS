#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# Route53: collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=R53

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# List Host Zones 
caws "R5301" "route53" "list-hosted-zones" ""

# List Route53 cloudwatch metrics
caws "R5302" "cloudwatch" "list-metrics" "--namespace AWS/Route53Resolver"

# List Data Catalogs
caws "R5303" "route53" "list-query-logging-configs" ""


# END
echo "FINISHED ${SDA_TAG}"
cd -

