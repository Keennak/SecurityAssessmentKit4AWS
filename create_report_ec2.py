#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json
import re
from pathlib import Path
import sys

# Input JSON directory
args = sys.argv
dir = args[1] + '/EC2'
p = Path(dir)

dir2 = args[1] + '/EKS'
p2 = Path(dir2)


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

# get reion list from file name (not aws)
def get_regions():
    file_names = os.listdir(p)
    regions = set()
    for file_name in file_names:
        region = re.search('[^_]*.json', file_name)
        regions.add(file_name[region.start(): region.end()-5])
    regions = list(regions)
    return regions


def get_resource_object(command, region):
    for f in list(p.glob('*'+command+'_'+region+'.json')):
        with open(f) as j:
            resource_object = json.load(j)
            return resource_object


def get_ami_ids(region):
    file_names = os.listdir(p)
    ami_ids = set()
    for file_name in file_names:
        ami_id = re.search(
            'ami-[a-f0-9]+_describe-image-attribute_'+region+'.json', file_name)
        if ami_id != None:
            ami_ids.add(file_name[6: 27])
    ami_ids = list(ami_ids)
    return ami_ids


def get_loadbalancer_ids(region):
    file_names = os.listdir(p)
    lb_ids = set()
    for file_name in file_names:
        lb_id = re.search(
            '_[a-f0-9]+_describe-load-balancer-attributes_'+region+'.json', file_name)
        if lb_id != None:
            lb_ids.add(file_name[6:22])
    lb_ids = list(lb_ids)
    return lb_ids


def get_images():
    # -------
    # AMIの情報DICTを作成する
    # ami_dict = { <ImageId> : [ <Name>, <CreationDate> ], <ImageId> : [],,,}
    
    d = {}
    for f in list(p.glob('*_describe-images_*.json')):
        with open(f) as j:
            d = json.load(j)
            for k in d['Images']:
                ami_dict[k.get('ImageId')] = []
                ami_dict[k.get('ImageId')].append(k.get('Name'))
                ami_dict[k.get('ImageId')].append(k.get('CreationDate'))

def get_interfaces():
    # -------
    # AMIの情報DICTを作成する
    # ami_dict = { <ImageId> : [ <Name>, <CreationDate> ], <ImageId> : [],,,}
    
    d = {}
    for f in list(p.glob('*_describe-network-interfaces_*.json')):
        with open(f) as j:
            d = json.load(j)
            for k in d['NetworkInterfaces']:
                try:
                    nw_interfaces[k.get('NetworkInterfaceId')]
                except KeyError:
                    nw_interfaces[k.get('NetworkInterfaceId')] = []         
                # nw_interfaces[k.get('NetworkInterfaceId')].append(k.get('PrivateIpAddresses'))
                nw_interfaces[k.get('NetworkInterfaceId')].append(k.get('SubnetId'))
                nw_interfaces[k.get('NetworkInterfaceId')].append(k.get('Groups'))



def print_security_group():
    print('### Appendix Security Group')
    for f in list(p.glob('*_describe-security-groups_*json')):
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


def ec2_01():
    print('# EC2')
    print('### 1. Security Group で最小限の inbound/outbound に絞る')
    print('#### ここでは 0.0.0.0/0 のSecurity Group をリストする')
    print('|   N    | Region | GroupName | GID | Description | Name | Ingress | Egress | attached resources | Comment |')
    print('| :----- | :----- | :-------- | :-- | :---------- | :--- | :------ | :----- | :----------------- | :------ |')
    n=1
    for region in regions:
        # -------
        # セキュリティグループを使用している、インスタンス、クラスター、ELBのリストを作成する
        # sg_use_dict = { <security group id> : [ <instance_id>, <cluster_id>, <elb_id> ], <security_group_id2> : [],,,}
        sg_use_dict = {}
        for sg in security_groups[region].get('SecurityGroups'):
            sg_use_dict[sg.get('GroupId')] = []

        for rsv in ec2_instances[region]['Reservations']:
            for inst in rsv['Instances']:
                for interface in inst.get('NetworkInterfaces'):
                    for groups in interface.get('Groups'):
                        sg_use_dict[groups.get('GroupId')].append(
                            inst.get('InstanceId'))

        # EKSの設定だけ別ディレクトリなので、個別にリストを取得する。
        for f in list(p2.glob('*_describe-cluster_'+region+'.json')):
            with open(f) as j:
                d = json.load(j)
                for sg in d.get('cluster').get('resourcesVpcConfig').get('securityGroupIds'):
                    sg_use_dict[sg].append(d.get('cluster').get('name'))

        # ELBについては、collectorでデータが取得されていないので、未コード化。
        # -------
        for sg in security_groups[region].get('SecurityGroups'):
            group_name = sg.get('GroupName')
            description = sg.get('Description')
            gid = sg.get('GroupId')
            name = ''
            ingress = ''
            egress = ''
            if sg.get('Tags'):
                for tag in sg.get('Tags'):
                    if tag.get('Key') == 'Name':
                        name = tag.get('Value')
            # get Ingress Filter
            for permission in sg.get('IpPermissions'):
                for ip_range in permission.get('IpRanges'):
                    if ip_range.get('CidrIp') == '0.0.0.0/0':
                        ingress = 'FAIL'
            # get Egress Filter
            for permission in sg.get('IpPermissionsEgress'):
                for ip_range in permission.get('IpRanges'):
                    if ip_range.get('CidrIp') == '0.0.0.0/0':
                        egress = 'FAIL'
            use_list = str(sg_use_dict.get(gid))
            print('| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |' % (
                n, region, group_name, gid, description, name, ingress, egress, use_list, ''))
            n+=1
    print('')


def ec2_02():
    print('### 2. すべてのVolume を暗号化する')
    print('| N | Region | Volume ID | Instance ID | Instance Name | Device | Encrypted | Check Result | Comment |')
    print('|:--|:-------|:----------|:------------|:--------------|:-------|:----------|:-------------|:--------|')
    n=1
    for region in regions:
        # create instance dictionaly
        # { <instanceId> : { name: <instance_name> }, <instanceId2> : { name : <instance_name2> }, ,,, }
        inst_to_join = {}
        for rsv in ec2_instances[region]['Reservations']:
            for inst in rsv['Instances']:
                name = ''
                if inst.get('Tags'):
                    for tag in inst['Tags']:
                        if tag.get('Key') == 'Name':
                            name = tag.get('Value')
            inst_to_join[inst['InstanceId']] = {'name': name}

        # print(json.dumps(ebs_volumes[region],indent=2))
        for obj in ebs_volumes[region]['Volumes']:
            # print(obj)
            volume_id = obj['VolumeId']
            if len(obj['Attachments']) == 0:
                instance_id = 'not attached'
                instance_name = ''
                device = ''
            else:
                instance_id = obj['Attachments'][0]['InstanceId']
                instance_name = inst_to_join.get(
                    instance_id, {}).get('name', '')
                device = obj['Attachments'][0]['Device']
            is_encrypted = obj['Encrypted']
            if is_encrypted:
                check_result = 'PASS'
            else:
                check_result = 'FAIL'
            comment = ''
            print('| %s | %s | %s | %s | %s | %s | %s | %s | %s |' % (n, region, volume_id,
                                                                 instance_id, instance_name, device, is_encrypted, check_result, comment))

            n+=1
    print('')
    print('')


def ec2_03():
    print('### 3. すべての Snapshot を暗号化する')
    print('| N  | Region | Snapshot ID | Volume ID | Start Time | Encrypted | Check Result | Description | Comment |')
    print('|:---|:---|:---|:---|:---|:---|:---|:---|:---|')
    n=1
    for region in regions:
        # print(json.dumps(ebs_snapshots[region],indent=2))
        sorted_objects = sorted(ebs_snapshots[region]['Snapshots'], key=lambda x: (
            x['VolumeId'], x['StartTime']))
        
        for obj in sorted_objects:
            # print(obj)
            snapshot_id = obj['SnapshotId']
            volume_id = obj['VolumeId']
            start_time = obj['StartTime']
            is_encrypted = obj['Encrypted']
            if is_encrypted:
                check_result = 'PASS'
            else:
                check_result = 'FAIL'
            comment = ''
            descript = obj['Description']
            print('| %s | %s | %s | %s | %s | %s | %s | %s | %s |' % (n, region, snapshot_id,
                                                                 volume_id, start_time, is_encrypted, check_result, descript, comment))
            n+=1
    print('')
    print('')


def ec2_04():
    print('### 4. 自作AMIの Launch Permission は必要最小限にする')
    print('|  N |Region | AMI ID | NAME   | Pulic | Launch Permission | AMI creation date | Check Result | Comment |')
    print('| :--|:----- | :----- | :----- | :---- | :---------------- | :---------------- | :----------- | :------ |')
    n=1
    for region in regions:
        if len(amis[region]):
            # print(json.dumps(amis[region],indent=2))
            for obj in amis[region]:
                # print(amis[region][obj])
                ami_id = amis[region][obj]['ImageId']
                launch_permissions = amis[region][obj]['LaunchPermissions']
                if len(launch_permissions) == 0:
                    check_result = 'PASS'
                    launch_permissions = '[]'
                else:
                    check_result = 'NEED CHECKED'
                name = ami_names[region][ami_id]['Name']
                public = str(ami_names[region][ami_id]['Public'])
                if public == 'True':
                    check_result = 'NEED CHECKED'

                # check AMI creation date
                creation_date = str(ami_names[region][ami_id]['CreationDate'])

                comment = ''
                print('| %s | %s | %s | %s | %s | %s | %s | %s | %s |' % (
                    n, region, ami_id, name, public, launch_permissions, creation_date, check_result, comment))
                ami_id = ''
                name = ''
                public = ''
                launch_permissions = ''
                check_result = ''
                n+=1
    print('')
    print('')


#def ec2_05():
# 未実装（EKS確認用モジュールに同様のロジックが実装済み）
#    print('### 5. インスタンスロールに割り当てる権限を最小化する')
#    print('| Region | Instance ID | IAM ARN | IAM ID| Check Result | Comment |')
#    print('|:-------|:------------|:--------|:------|:-------------|:--------|')
#    # for region in regions:
#        for obj in ec2_instances[region]:
#            resv =
#
#        #print('| %s | %s | %s | %s | %s |' % (region, ami_id, launch_permissions, check_result, comment))
#    print('')
#    print('')


def ec2_06():
    print('### 6. Linux インスタンスの SSH ログインに必要な Private Key を保護する。なお、当環境はすべてSSMの利用を想定しているため、SSHポートの開放とKeyPairは本来不要')
    print('')
    print('#### 6.1 Port#22 を開放している SecurityGroup の一覧')
    print('|  N |Region | Security Group ID | Group Name | Description | Comment |')
    print('|:---|:-------|:------------------|:-----------|:------------|:--------|')
    n=1
    for region in regions:
        for sg in security_groups[region]['SecurityGroups']:
            # eprint(sg)
            sg_id = sg.get('GroupId')
            sg_name = sg.get('GroupName')
            sg_desc = sg.get('Description')
            for ip_permission in sg['IpPermissions']:
                if ip_permission.get('ToPort') == 22:
                    print('| %s | %s | %s | %s | %s | %s |' %
                          (n, region, sg_id, sg_name, sg_desc, ''))
                    n+=1

    print('')
    print('#### 6.2 KeyPairが存在する Instance の一覧')
    print('|  N | Region | KeyPairId | KeyName | Comment |')
    print('|:---|:-------|:----------|:--------|:--------|')
    n=1
    for region in regions:
        for kp in ec2_key_pairs[region]['KeyPairs']:
            # print(kp)
            kp_id = kp.get('KeyPairId')
            kp_name = kp.get('KeyName')
            print('| %s | %s | %s | %s | %s |' % (n, region, kp_id, kp_name, ''))
            n+=1


def ec2_07():
    print('### 7 各VPCは VPC Flow Log を取得していて、それが正しいs3バケットに書き込まれている')
    print('')
    print('#### 7.1 VPC FLow Log の一覧')
    print('|  N | Region | FlowLogId | VpcId | LogDestinationType | LogDestination | Comment |')
    print('|:---|:-------|:----------|:------|:-------------------|:---------------|:--------|')
    n=1
    # print(vpc_flow_logs)
    for region in regions:
        for fl in vpc_flow_logs[region].get('FlowLogs'):
            fl_id = fl.get('FlowLogId')
            fl_vpc_id = fl.get('ResourceId')
            fl_ldt = fl.get('LogDestinationType')
            fl_ld = fl.get('LogDestination')
            print('| %s | %s | %s | %s | %s | %s | %s |' %
                  (n, region, fl_id, fl_vpc_id, fl_ldt, fl_ld, ''))
            n+=1
    print('')

    print('#### 7.2 VPC Flow Log が設定されていない VPC の一覧')
    print('| N  | Region | VpcId | Check Result | Comment |')
    print('|:---|:-------|:------|:-------------|:--------|')
    n=1
    for region in regions:
        vpcs_with_flowlog = set()
        for fl in vpc_flow_logs[region].get('FlowLogs'):
            vpcs_with_flowlog.add(fl.get('ResourceId'))
        vpcs = set(vpc_ids[region])
        for vpc in vpcs - vpcs_with_flowlog:
            print('| %s | %s | %s | %s | %s |' % (n, region, vpc, 'FAIL', ''))
            n+=1


def ec2_08():
    print('### 8 可能なかぎり IMDSv2を利用する')
    print('')
    print('| N | Region | InstancdId | Name | HttpTokens | Check Result | Comment |')
    print('|:--|:-------|:-----------|:-----|:-----------|:-------------|:--------|')
    n=1
    # print(ec2_instances)
    for region in regions:
        for rsv in ec2_instances[region]['Reservations']:
            for inst in rsv['Instances']:
                if inst['MetadataOptions']['HttpTokens'] == 'optional':
                    instance_id = inst['InstanceId']
                    name = ''
                    if inst.get('Tags'):
                        for tag in inst['Tags']:
                            if tag['Key'] == 'Name':
                                name = tag['Value']
                    http_tokens = inst['MetadataOptions']['HttpTokens']
                    result = 'FAIL'
                    print('| %s | %s | %s | %s | %s | %s | %s |' %
                          (n, region, instance_id, name, http_tokens, result, ''))
                    n+=1


def ec2_09():
    print('### 9 EIP, IGW, VGW, NAT-GW は必要な場ににのみ作成し限定的に利用する')
    print('')
    print('#### 9.1 EIP')
    print('| N |  Region | Name | AssociationId | Eni | PublicIp | Comment |')
    print('|:--| :-------|:-----|:--------------|:----|:---------|:--------|')
    n=1
    for region in regions:
        for addr in elastic_ips[region]['Addresses']:
            name = ''
            if addr.get('Tags') != None:
                for tag in addr.get('Tags'):
                    if tag.get('Key') == 'Name':
                        name = tag.get('Value')
            asc_id = addr.get('AssociationId')
            eni_id = addr.get('NetworkInterfaceId')
            public_ip = addr.get('PublicIp')
            print('| %s | %s | %s | %s | %s | %s | %s |' %
                  (n, region, name, asc_id, eni_id, public_ip, ''))
            n+=1
    print('')

    print('#### 9.2 Public IPアドレスを持つ EC2 Instance')
    print('|  N | Region | InstanceId | Name | PublicIp | Comment |')
    print('|:---|:-------|:-----------|:-----|:---------|:--------|')
    n=1
    for region in regions:
        for rsv in ec2_instances[region].get('Reservations'):
            for inst in rsv.get('Instances'):
                if inst.get('PublicIpAddress'):
                    inst_id = inst.get('InstanceId')
                    public_ip = inst.get('PublicIpAddress')
                    name = ''
                    if inst.get('Tags'):
                        for tag in inst.get('Tags'):
                            if tag.get('Key') == 'Name':
                                name = tag.get('Value')
                    print('| %s | %s | %s | %s | %s | %s |' %
                          (n, region, inst_id, name, public_ip, ''))
                    n+=1
    print('')

    print('#### 9.3 IGW')
    print('| Region | IgwId | Name | VpcId | Comment |')
    print('|:-------|:------|:-----|:------|:--------|')
    for region in regions:
        for igw in internet_gws[region].get('InternetGateways'):
            # print(igw)
            igw_id = igw['InternetGatewayId']
            name = ''
            if igw.get('Tags') != None:
                for tag in igw.get('Tags'):
                    if tag['Key'] == 'Name':
                        name = tag['Value']

            if len(igw.get('Attachments')) == 0:
                vpc_id = ''
            else:
                vpc_id = igw.get('Attachments')[0]['VpcId']
            print('| %s | %s | %s | %s | %s |' % (region, igw_id, name, vpc_id, ''))
    print('')

# temp
    # print('### 9.4 VGW')
    # print('| Region | VgwId | Comment |')
    # print('|:-------|:------|:--------|')
    # for region in regions:
    #     for vgw in vgws[region].get('virtualGateways'):
    #         print('| %s | %s | %s |' %
    #               (region, vgw.get('virtualGatewayId'), ''))
    # print('')

    print('### 9.5 VPN Gateway')
    print('| Region | VpnGwId | VpcId | Name | Comment |')
    print('|:-------|:--------|:------|:-----|:--------|')
    for region in regions:
        for vpn_gw in vpn_gws[region].get('VpnGateways'):
            # print(vpn_gw)
            vpn_gw_id = vpn_gw.get('VpnGatewayId')
            vpc_id = vpn_gw.get('VpcAttachments')[0]['VpcId']
            name = ''
            for tag in vpn_gw.get('Tags'):
                if tag.get('Key') == 'Name':
                    name = tag.get('Value')
            print('| %s | %s | %s | %s | %s |' %
                  (region, vpn_gw_id, vpc_id, name, ''))
    print('')

    print('#### 9.6 NAT Gateway')
    print('| Region | NatGWId | VpcId | PublicIp | Name | Commment |')
    print('|:-------|:--------|:------|:---------|:-----|:---------|')
    for region in regions:
        for nat_gw in nat_gws[region].get('NatGateways'):
            # print(nat_gw)
            nat_gw_id = nat_gw.get('NatGatewayId')
            vpc_id = nat_gw.get('VpcId')
            public_ip = nat_gw.get('NatGatewayAddresses')[0].get('PublicIp')
            name = ''
            for tag in nat_gw.get('Tags'):
                if tag.get('Key') == 'Name':
                    name = tag.get('Value')
            print('| %s | %s | %s | %s | %s | %s |' %
                  (region, nat_gw_id, vpc_id, public_ip, name, ''))


def ec2_10():
    print('#### 10. VPC endpoint settings')
    print('| ServiceName | RouteTableIds | SubnetIds | PolicyDocument |')
    print('|:---------|:---------|:---------|:---------|')
    vpce_dict = {}
    for f in list(p.glob('*_describe-vpc-endpoints_*.json')):
        with open(f) as j:
            vpce_dict = json.load(j)
            for k in vpce_dict['VpcEndpoints']:
                print('| %s | %s | %s | %s |' %
                    (str(k.get('ServiceName')), str(k.get('RouteTableIds')), str(k.get('SubnetIds')), str(k.get('PolicyDocument'))))


def ec2_11():
    print('#### 11. Instance list')

    # create instance dictionary
    for f in list(p2.glob('*_describe-instances_*.json')):
        with open(f) as j:
            instance_dict = json.load(j)
            

    # EC2 11
    print('インスタンスのAMIのバージョンが最新ないし、受容可能なバージョンである')
    print('')
    print('')

    # check AMI for the instance
    # print header
    print('| N |  Instance Name  | InstanceId | ImageId | IAM role | Cluster Name | ami_info |  nw_info |Check Status | comment |')
    print('|:--| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |')

    # インスタンスリストを出力する
    # AMI情報を読み込む
    get_images()
    get_interfaces()
    n=1
    for k in instance_dict['Reservations']:
        instance_name_prev = 'none'
        for i in (k.get('Instances')):
            instance_id = i.get('InstanceId')
            image_id = i.get('ImageId')
            instance_name = get_value_from_key_value_dict(i['Tags'], 'Name')
            nw_info = ''

            # get eni security groups
            eni_ids = []
            for eni in i.get('NetworkInterfaces'):
                eni_ids.append(eni.get('NetworkInterfaceId'))
            
            for eni in eni_ids:
                nw_info += str(nw_interfaces.get(eni))
            
            # get instance information
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
                print('| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |' %
                    (n, instance_name , instance_id , image_id  , profile_of_the_instance , cluster_of_the_instance , ami_info , nw_info , '', '' ))
            instance_name_prev = instance_name
            n+=1



# get regions collected in the files
regions = get_regions()

# init resource objects
ec2_instances = {}
security_groups = {}
ebs_volumes = {}
ebs_snapshots = {}
ami_images = {}
ec2_key_pairs = {}
vpc_flow_logs = {}
vpcs = {}
elastic_ips = {}
internet_gws = {}
nat_gws = {}
vpn_gws = {}
vgws = {}
amis = {}
ami_names = {}
loadbalancers = {}
clusters = {}
ami_dict = {}
instance_dict = {}
nw_interfaces = {}


# TEMP WORKAROUND FOR DESCRIBE VPCS FAILURE
vpc_ids = {}

# set resource objects
for region in regions:
    ec2_instances[region] = get_resource_object('describe-instances', region)
    security_groups[region] = get_resource_object(
        'describe-security-groups', region)
    ebs_volumes[region] = get_resource_object('describe-volumes', region)
    ebs_snapshots[region] = get_resource_object('describe-snapshots', region)
    ami_images[region] = get_resource_object('describe-images', region)
    ec2_key_pairs[region] = get_resource_object('describe-key-pairs', region)
    vpc_flow_logs[region] = get_resource_object('describe-flow-logs', region)
    vpcs[region] = get_resource_object('describe-vpcs', region)
    elastic_ips[region] = get_resource_object('describe-addresses', region)
    internet_gws[region] = get_resource_object(
        'describe-internet-gateways', region)
    nat_gws[region] = get_resource_object('describe-nat-gateways', region)
    vpn_gws[region] = get_resource_object('describe-vpn-gateways', region)
####    vgws[region] = get_resource_object('describe-virtual-gateways', region)

    # create AMI dictionarys
    amis[region] = {}
    ami_ids = get_ami_ids(region)
    for ami_id in ami_ids:
        amis[region][ami_id] = get_resource_object(
            ami_id+'_describe-image-attribute', region)
    ami_names[region] = {}

    for image in ami_images[region]['Images']:
        ami_names[region][image['ImageId']] = {
            'Name': image['Name'], 'Public': image['Public'], 'CreationDate': image['CreationDate']}

    loadbalancers[region] = {}
    loadbalancer_ids = get_loadbalancer_ids(region)
    for lb_id in loadbalancer_ids:
        loadbalancers[region][lb_id] = get_resource_object(
            lb_id+'_describe-load-balancer-attributes', region)

    # TEMP WORKAROUND FOR DESCRIBE VPCS FAILURE
    vpc_ids[region] = []
    for sg in security_groups[region]['SecurityGroups']:
        vpc_ids[region].append(sg['VpcId'])

# Execution
ec2_01()
ec2_02()
ec2_03()
ec2_04()
# ec2_05()
ec2_06()
ec2_07()
ec2_08()
ec2_09()
ec2_10()
ec2_11()
#print_security_group()
