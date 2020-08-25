#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json
from pathlib import Path
import sys

# common

# ---------------------------------------------------------
# get_value_from_key_value_dict
# extract value from specified Key.
# usage get_value_from_key_value_dict(dictionary, key)
#
# example
#    get_value_from_key_value_dict(d, Name) -> MainDISK
#      from dictionary below
#      { Key : Name, Value: MainDISK },{ Key : SIZE, Value : 1GB }
def get_value_from_key_value_dict(d, val):
    for t in d:
        if ([v for k, v in t.items() if v == val]):
            return(t.get('Value'))
# ---------------------------------------------------------

# Input JSON directory
args = sys.argv
dir = args[1] + '/EKS'
p = Path(dir)

# print header
print('# Security Deep Assessment (EKS編）')

# create instance dictionary
for f in list(p.glob('*_describe-instances_*.json')):
    with open(f) as j:
        instance_dict = json.load(j)

# EKS01
# ワーカーノードIAMロールの権限が必要最小限
# (https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/worker_node_IAM_role.html)である。
# このチェックはEC2にて実施するため、ワーカーノードのインスタンスプロファイルの一覧を表示する。


# EKS02
# ワーカーノードのインスタンスプロファイルへのアクセスが制限
#  (https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/restrict-ec2-credential-access.html)してある。
# インスタンス内のiptable設定となるため、APIでは確認ができないためスキップ。

# EKS03
# Kubernatesクラスターのバージョンが最新ないし、受容可能なバージョンである。
# インスタンス内の設定となるため、APIでは確認ができないためスキップ。
# kubectl version --short

# EKS03
# ワーカーノードのAMIのバージョンが最新ないし、受容可能なバージョンである。
print('### 1.ワーカーノードのAMIのバージョンが最新ないし、受容可能なバージョンである')
print('')
print('')

# check AMI for the instance
# print header
print('| Instance Name  | InstanceId | ImageId | IAM role | Cluster Name | Check Status | comment |')
print('| :--- | :--- | :--- | :--- | :--- | :--- | :--- |')


def print_instances():

    for k in instance_dict['Reservations']:
        instance_name_prev = 'none'
        for i in (k.get('Instances')):
            instance_id = i.get('InstanceId')
            image_id = i.get('ImageId')
            instance_name = get_value_from_key_value_dict(i['Tags'], 'Name')
            
            cluster_of_the_instance = get_value_from_key_value_dict(i['Tags'], 'alpha.eksctl.io/cluster-name')
            if cluster_of_the_instance is None :
                cluster_of_the_instance = 'None'
            
            profile_of_the_instance = i.get('IamInstanceProfile', {}).get('Arn')
            if profile_of_the_instance is None :
                profile_of_the_instance = 'None'

            if instance_name != instance_name_prev:
                # collectorのバグのため、describe-imagesの取り込みロジックは未実装。
                # AMIに関しては、手作業で確認する。
                # ここでは、AMIのリストのみを表示する。
                describe_image_file = '*' + image_id + '_describe-images_*.json'
                # for f2 in list(p.glob(describe_image_file)):
                #    with open(f2) as j2:
                #          dict = json.load(j)
                #         （イメージ情報の取得）
                #
                print('| ' + instance_name + ' | ' + instance_id + ' | ' + image_id  + ' | ' + profile_of_the_instance + ' | ' + cluster_of_the_instance + ' |')
                # print('| ' + instance_name + ' | ' + instance_id + ' | ' + image_id  + ' |')
            instance_name_prev = instance_name

print_instances()


print('### 2.クラスターがNW上、適切に保護されている')
print('')
print('')


# check clusters status
# print header
print('| cluster_name               | cluster_status              | clusterLogging              | endpointPublicAccess    | endpointPrivateAccess       | publicAccessCidrs      | securityGroupIds    | clusterSecurityGroupId | comment |')
print('| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |')

# EKS05
# ログがCloudWatch Logsに配信されている。

cluster_name_list = []
for f in list(p.glob('*_describe-cluster_*.json')):
    with open(f) as j:
        d = json.load(j)
        cluster_dict = d.get('cluster')

        cluster_name = cluster_dict.get('name')
        cluster_name_list.append(cluster_name)

        cluster_status = cluster_dict.get('status')
        for loging_dict in cluster_dict.get('logging', {}).get('clusterLogging'):
            logging_status = str(loging_dict.get('enabled'))

        # EKS08
        # EKSコントロールプレーン、クラスター、ワーカーノードのSGを必要最小限の範囲で設定する。
        #
        # check network settings
        # SecurityGroupIds : Allow communication between your worker nodes and the Kubernetes control plane
        # clusterSecurityGroupId : Managed node groups use this security group for control-plane-to-data-plane communication.
        sg_ids = cluster_dict.get(
            'resourcesVpcConfig', {}).get('securityGroupIds')
        cluster_sg_id = cluster_dict.get(
            'resourcesVpcConfig', {}).get('clusterSecurityGroupId')

        # EKS09
        # クラスターエンドポイントをプライベートにする。
        #  (https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/cluster-endpoint.html)
        pub_access = cluster_dict.get(
            'resourcesVpcConfig', {}).get('endpointPublicAccess')
        private_access = cluster_dict.get(
            'resourcesVpcConfig', {}).get('endpointPrivateAccess')
        pub_cdirs = cluster_dict.get(
            'resourcesVpcConfig', {}).get('publicAccessCidrs')

        # print
        print('| ' + str(cluster_name) + ' | ' + str(cluster_status) + ' | ' + str(logging_status) + ' | ' + str(pub_access) +
              ' | ' + str(private_access) + ' | ' + str(pub_cdirs) + ' | ' + str(sg_ids) + ' | ' + str(cluster_sg_id) + ' |   |')



# Security Groupの設定内容を表示
# Security Groupに問題があるかどうかは、マニュアルチェックする
# 基本的には自アカウント内SGとの通信であれば問題無しとする。

def print_security_group():
    print('### Appendix Security Group')
    for f in list(p.glob('EKS08_*_describe-security-groups_*json')):
        with open(f) as j:
            d = json.load(j)
            for vpc_dict in d.get('SecurityGroups'):
                print('-----------------------------')
                print('GroupName : ' + vpc_dict.get('GroupName'))
                print('GroupId   : ' + vpc_dict.get('GroupId'))
                print('')
                print('Ingress')
                print('```json')
                for ingress in vpc_dict.get('IpPermissions'):
                    print(ingress)
                print('```')
                print('Egress')
                print('```json')
                for egress in vpc_dict.get('IpPermissionsEgress'):
                    print(egress)
                print('```')


# print_security_group()

