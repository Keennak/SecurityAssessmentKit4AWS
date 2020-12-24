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
dir = args[1] + '/EC2'
p = Path(dir)

dir2 = args[1] + '/EKS'
p2 = Path(dir2)

ami_dict = {}

# print header
print('# Security Deep Assessment (EC2編-2）')

# create instance dictionary
for f in list(p2.glob('*_describe-instances_*.json')):
    with open(f) as j:
        instance_dict = json.load(j)

# EC2 101
# ワーカーノードのAMIのバージョンが最新ないし、受容可能なバージョンである。
print('### 1.ワーカーノードのAMIのバージョンが最新ないし、受容可能なバージョンである')
print('')
print('')

# check AMI for the instance
# print header
print('| Instance Name  | InstanceId | ImageId | IAM role | Cluster Name | Check Status | ami_info | comment |')
print('| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |')


def get_images():
    # -------
    # セキュリティグループを使用している、インスタンス、クラスター、ELBのリストを作成する
    # sg_use_dict = { <security group id> : [ <instance_id>, <cluster_id>, <elb_id> ], <security_group_id2> : [],,,}
    
    d = {}
    for f in list(p.glob('*_describe-images_*.json')):
        with open(f) as j:
            d = json.load(j)
            for k in d['Images']:
                ami_dict[k.get('ImageId')] = []
                ami_dict[k.get('ImageId')].append(k.get('Name'))
                ami_dict[k.get('ImageId')].append(k.get('CreationDate'))

def print_instances():
    # AMI情報を読み込む
    get_images()

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
                # AMI情報を取得する
                ami_info = str(ami_dict.get(image_id))

                # 集めた情報を出力する
                print('| ' + instance_name + ' | ' + instance_id + ' | ' + image_id  + ' | ' + profile_of_the_instance + ' | ' + cluster_of_the_instance + ' |' + ami_info + ' |')
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
for f in list(p2.glob('*_describe-cluster_*.json')):
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
    for f in list(p2.glob('EKS08_*_describe-security-groups_*json')):
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



