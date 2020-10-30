#!/usr/bin/env bash
#
# HD Security Accessment Collector
#
# Athena: collector
#
# -----------------------------------------------------------
SDA_REGION=${TARGET_REGION}

# The script creates directories and logs with this tag
SDA_TAG=ATN

mkdir ${RESULT_DIR}/${SDA_TAG}
cd ${RESULT_DIR}/${SDA_TAG}

# collector
# usage:
#  caws <AWS Service Name> <CLI_COMMAND> "<PARAMETER>"
# -----------------------------------------------------------

# Athena_Common
DATACATALOG_LIST=$(aws athena list-data-catalogs --query 'DataCatalogsSummary[].CatalogName' --region ${SDA_REGION} --output text)
WORKGROUP_LIST=$(aws athena list-work-groups --query 'WorkGroups[].Name' --region ${SDA_REGION} --output text)

# List WorkGroups
caws "ATN01" "athena" "list-work-groups" ""

# Get Work Group
for WORKGROUP in ${WORKGROUP_LIST}; do
  caws "ATN02_${WORKGROUP}" "athena" "get-work-group" "--work-group ${WORKGROUP}"
done

# List Data Catalogs
caws "ATN03" "athena" "list-data-catalogs" ""

# List Databases for datacatalogs
for DATACATALOG in ${DATACATALOG_LIST}; do
  caws "ATN04_${DATACATALOG}" "athena" "list-databases" "--catalog-name ${DATACATALOG}"
done

### QUERY result encryption status cannot assessed from CLI.

# END
echo "FINISHED ${SDA_TAG}"
cd -

