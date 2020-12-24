#!/usr/bin/env bash
#
# Security report creator 
# IAM

# Common
# RESULT_FILE=report_$(date "+%Y%m%d-%H%M%S").html


# INPUT_DIR="/Users/myname/Documents/SDA/productiondata/SDA_20200325-163924/IAM"  # sample
INPUT_DIR="${1}/IAM"


# HTML renderer
# あとでここはPythonで書き直し

create_md_header() {
    echo -e "| CHECK ID | DESCRIPTION,確認方法 | 対象 | 確認結果 | 内容 |" 
    echo -e "| :------- | :---------- | :------ | :----- | :--- |" 
}

create_md_header2() {
    echo -e ""
    echo -e "## ${ID}"
    echo -e "${DESCRIPTION}"
    echo -e ""
    echo -e "| 対象 | 確認結果 | 内容 |" 
    echo -e "| :------ | :----- | :--- |" 
}

checker_out() {
    # output result file
    OUT=$(echo ${OUTPUT})
    echo -e "| ${ID} | ${DESCRIPTION} | ${CHECK_METHOD} | ${RESULT} | ${OUT} |"


    # echo -e "${ID}\t${DESCRIPTION}\t${CHECK_METHOD}\t${RESULT}\t${OUTPUT}"
    ID=""
    DESCRIPTION=""
    CHECK_METHOD=""
    RESULT=""
    OUTPUT=""

}

checker_out2() {
    # output result file
    OUT=$(echo ${OUTPUT})

    echo -e "| ${CHECK_METHOD} | ${RESULT} | ${OUT} |"



    # echo -e "${ID}\t${DESCRIPTION}\t${CHECK_METHOD}\t${RESULT}\t${OUTPUT}"
    ID=""
    DESCRIPTION=""
    CHECK_METHOD=""
    RESULT=""
    OUTPUT=""

}

#
# IAM02
#
ID=IAM02
echo "##IAM02"
echo "個々の IAM ユーザーの作成"
echo "複数の作業者でIAMユーザを共用ししていないことを確認する"

for file in $(ls -1 ${INPUT_DIR}/${ID}*); do
    cat "${file}" | jq '.Users | sort_by(.PasswordLastUsed)' | jq -c '.[] | [.UserName , .PasswordLastUsed]'
done

# main
# ファイルシステムのデータを扱うので、シェルで書く
create_md_header

users=$(cat ${INPUT_DIR}/IAM02_list-users_*.json | jq -r .Users[].UserName)
roles=$(cat ${INPUT_DIR}/IAM04_list-roles_*.json | jq -r .Roles[].RoleName)
groups=$(cat ${INPUT_DIR}/IAM04_list-groups_*.json | jq -r .Groups[].GroupName)


#
# section
#


#
# section
#
ID=IAM03
DESCRIPTION="IAM ユーザーへのアクセス許可を割り当てるためにグループを使用する<br>本ユーザにグループが割り当てられているか確認する"

for file in $(ls -1 ${INPUT_DIR}/${ID}*); do
    OUTPUT=$(cat "${file}" | jq .Groups[].GroupName)
    if [ -z "${OUTPUT}" ]; then
        RESULT="FAIL"
        OUTPUT="none"
    else
        RESULT="PASS"
    fi
    username=$(echo ${file} | cut -d "_" -f 3)
    CHECK_METHOD="${username}"
    checker_out
done

# IAM04
ID=IAM04
DESCRIPTION="最小の権限を付与する（IAMロール）<br>本ロールに割り当てられたポリシーが適切であることを確認する"
json_directory="${INPUT_DIR}/${ID}_"

# Section 1 list permissions of Roles
#

for role in ${roles}; do
    # extract inline policies
    inline_policy_output=""
    inline_policy=$(cat ${json_directory}${role}_list-role-policies* | jq -r .PolicyNames[])
    if [ -z "${inline_policy}" ]; then
        inline_policy_output="none"
    else
        inline_policy_output=$(cat ${json_directory}${role}*_get-role-policy*)
    fi

    # extract attached policies
    attached_policy_output=""
    attached_policy=$(cat ${json_directory}${role}_list-attached-role-policies* | jq -r .AttachedPolicies[].PolicyArn)
    if [ -z "${attached_policy}" ]; then
        attached_policy_output="none"
    else
        for s in ${attached_policy}; do
            attached_policy_output+="${s}<br>"
        done
    fi

    # check result
    RESULT="Check required" # 基本的に、割り当てられたポリシーの適切さは目視で確認する。

    if [[ ${inline_policy_output} == *none* ]]; then
        for s in ${attached_policy}; do
            if [[ ${s} == *service-role* ]]; then
                # サービスロールのみで構成されている場合はPASSとする。
                RESULT="PASS"
            else
                RESULT="Check required"
                break
            fi
        done
    fi

    # output message
    CHECK_METHOD="${role}"
    OUTPUT="INLINE_POLICY_FILE:<br>${inline_policy_output}<br><br>ATTACHED_POLICY:<br>${attached_policy_output}"
    checker_out

done

# Section 2 list permissions of Users
# this Section moved to python code


# DESCRIPTION="最小の権限を付与する（IAMユーザ）<br>本ユーザに割り当てられたポリシーが適切であることを確認する"
#for user in ${users}; do
#    # extract inline_policy
#    inline_policy_output=""
#    inline_policy=$(cat ${json_directory}${user}_list-user-policies* | jq -r .PolicyNames[])
#    if [ -z "${inline_policy}" ]; then
#        inline_policy_output="none"
#    else
#        inline_policy_output=$(cat ${json_directory}${user}*_get-user-policy*)
#    fi
#
#    # extract attached policies
#    attached_policy_output=""
#    attached_policy=$(cat ${json_directory}${user}_list-attached-user-policies* | jq -r .AttachedPolicies[].PolicyArn)
#    if [ -z "${attached_policy}" ]; then
#        attached_policy_output="none"
#    else
#        for s in ${attached_policy}; do
#            attached_policy_output+="${s}<br>"
#        done
#    fi
#
#    attached_group=""
#    attached_group=$(cat ${INPUT_DIR}/IAM03_${user}_list-groups-for-user_* | jq .Groups[].GroupName)
#
#    # check result
#    RESULT="Check required" # 基本的に、割り当てられたポリシーの適切さは目視で確認する。
#
#    # output message
#    CHECK_METHOD="${user}"
#    OUTPUT="INLINE_POLICY_FILE:<br>${inline_policy_output}<br><br>ATTACHED_POLICY:<br>${attached_policy_output}<br><br>ATTACHED_GROUP:<br>${attached_group}"
#    checker_out
# done

# Section 3 list permissions of Groups

DESCRIPTION="最小の権限を付与する（IAMグループ）<br>本グループに割り当てられたポリシーが適切であることを確認する"
for group in ${groups}; do
    # extract inline_policy
    inline_policy_output=""
    inline_policy=$(cat ${json_directory}${group}_list-group-policies* | jq -r .PolicyNames[])
    if [ -z "${inline_policy}" ]; then
        inline_policy_output="none"
    else
        inline_policy_output=$(cat ${json_directory}${group}*_get-group-policy*)
    fi

    # extract attached policies
    attached_policy_output=""
    attached_policy=$(cat ${json_directory}${group}_list-attached-group-policies* | jq -r .AttachedPolicies[].PolicyArn)
    if [ -z "${attached_policy}" ]; then
        attached_policy_output="none"
    else
        for s in ${attached_policy}; do
            attached_policy_output+="${s}<br>"
        done
    fi

    # check result
    RESULT="Check required" # 基本的に、割り当てられたポリシーの適切さは目視で確認する。

    # output message
    CHECK_METHOD="${group}"
    OUTPUT="INLINE_POLICY_FILE:<br>${inline_policy_output}<br><br>ATTACHED_POLICY:<br>${attached_policy_output}"
    checker_out
done

# IAM05
# IAM04の結果でチェックする。
ID=IAM05
DESCRIPTION="マネージドポリシーを利用する"
CHECK_METHOD="AWSマネージドポリシー(arn:aws:iam::aws:policy/xxxxx)を使用していることを確認する"
RESULT="-"
OUTPUT="IAM04の結果にて、マネージドポリシーの利用状況を確認"
checker_out

# IAM06
# IAM04の結果でチェックする。
ID=IAM06
DESCRIPTION="インラインポリシーを使用しない"
CHECK_METHOD="カスタマー管理ポリシー(arn:aws:iam::111122223333:policy/xxxxx)を使用していることを確認する"
RESULT="-"
OUTPUT="IAM04の結果にて、マネージドポリシーの利用状況を確認"
checker_out

# IAM07
# Prowler [check15] -[check111]

# IAM08
#
ID=IAM08
DESCRIPTION="アカウントのすべてのユーザーに対して多要素認証 (MFA) を要求する<br>該当ユーザのMFAデバイスARNを取得、確認する"
json_directory="${INPUT_DIR}/${ID}_"

create_md_header2

# check MFA Usage for the user
for user in ${users}; do
    CHECK_METHOD="${user}"
    OUTPUT=$(cat ${json_directory}${user}_list-mfa-devices* | jq -r .MFADevices[].SerialNumber)
    if [ -z "${OUTPUT}" ]; then
        RESULT="FAIL"
        OUTPUT="none"
    else
        RESULT="PASS"
    fi
    checker_out2
done

# IAM09
# Prowler[check119]

# IAM10
ID=IAM10
DESCRIPTION="IAM ユーザーの不要な認証情報 (つまり、パスワードとアクセスキー) は削除する<br>該当ユーザにログインプロファイルが存在する場合はパスワードログインが可能<br>アクセスキーについては、Prowler[check121]にて確認する"
json_directory="${INPUT_DIR}/${ID}_"

create_md_header2

for user in ${users}; do
    CHECK_METHOD="${user}"
    OUTPUT=$(cat ${json_directory}${user}_get-login-profile*)
    if [ -z "${OUTPUT}" ]; then
        OUTPUT="no login profile"
    fi
    RESULT="Check required" # Prowlerの結果と、本結果を突き合わせて確認する。
    checker_out2
done

# IAM11
# rootアカウントやKMS管理者、IAM管理者、Org管理者等のログインを監視する。
# 複数の実装パターンがあるので、ヒアリングで確認する。

# IAM12
# インスタンスにロールを割り当てる場合、その権限が過剰でないか確認する。


ID=IAM12
DESCRIPTION="サービスロール/インスタンスロールに最小権限を付与する"

create_md_header2

CHECK_METHOD="インスタンスにロールを割り当てる場合、その権限が過剰でないか確認する。"
RESULT="-"
OUTPUT="IAM13の結果にて、ec2サービスを信頼しているポリシーに関しては、IAM04の結果にてポリシーの割当状況を改めて確認する"
checker_out2

# IAM13
# ロールの信頼関係が適切かどうか確認する
ID=IAM13
DESCRIPTION="ロールに最小の信頼関係を付与する<br>ロールの信頼されたエンティティには、必要最小限のAWSサービスかアカウントしか入っていないことを確認する。"
json_directory="${INPUT_DIR}/${ID}_"

create_md_header2

for role in ${roles}; do
    CHECK_METHOD="${role}"
    OUTPUT=$(cat ${INPUT_DIR}/IAM14_${role}_get-role* | jq -r '.Role.AssumeRolePolicyDocument.Statement[] | .Effect,.Principal')
    if [ -z "${OUTPUT}" ]; then
        OUTPUT="no AssumeRolePolicyDocument"
    fi
    RESULT="Check required" # 目視で確認する
    checker_out2
done

# IAM14
# 利用していない不要なロールがないことを確認する
ID=IAM14
DESCRIPTION="利用していない不要なロールがないことを確認する<br>ロールの利用状況を確認の上、長期間利用のないものは削除を検討する。（過去一度も使用していないものはFIAL）"
json_directory="${INPUT_DIR}/${ID}_"

create_md_header2

for role in ${roles}; do
    CHECK_METHOD="${role}"
    OUTPUT=$(cat ${json_directory}${role}_get-role* | jq -r .Role.RoleLastUsed.LastUsedDate)
    if [[ ${OUTPUT} == "null" ]]; then
        OUTPUT="no use record"
        RESULT="FAIL"
    else
        RESULT="Check required" # 目視で確認する
    fi

    checker_out2
done

# END
