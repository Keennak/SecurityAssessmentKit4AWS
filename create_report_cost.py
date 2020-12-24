#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json
import re
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
dir = args[1] + '/COST'
p = Path(dir)



# print header
print('# Security Deep Assessment (COST）')

# ---------------------------------------------
# 共通関数
# ---------------------------------------------

# get reion list from file name (not aws)
def get_regions():
    file_names = os.listdir(p)
    regions = set()
    for file_name in file_names:
        region = re.search('[^_]*.json', file_name)
        regions.add(file_name[region.start(): region.end()-5])
    regions = list(regions)
    return regions

# 結果ファイルからリソースオブジェクトを収集する
def get_resource_object(command, region):
    for f in list(p.glob('*'+command+'_'+region+'.json')):
        with open(f) as j:
            resource_object = json.load(j)
            return resource_object


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


def get_check_headers():
    d = {}
    for f in list(p.glob('*describe-trusted-advisor-checks*')):
        with open(f) as j:
            d = json.load(j)
            for k in d['checks']:
                # check_headers[k.get('id')] = []
                # check_headers[k.get('id')].append(k.get('metadata'))
                check_headers[k.get('id')] = k.get('metadata')

def get_instance_tags(region):
    d ={}
    if ec2_instances[region] is not None:
        for k in ec2_instances[region].get('Reservations'):
            for k2 in k['Instances']:
                d[k2.get('InstanceId')] =[]
                d[k2.get('InstanceId')].append(k2.get('Tags')) 
    return d
        

def get_flagged_resources(command, tag_dict):
    metadatas = []
    d = {}
    for f in list(p.glob('*'+command+"*")):
        with open(f) as j:
            d = json.load(j)
            check_id = d.get('result').get('checkId')
            
            # create header
            header = check_headers.get(check_id)
            header.append('Tags')
            metadatas.append(header)

            # create records
            for k in d.get('result')['flaggedResources']:
                region=k.get('region')
                metadata=k.get('metadata')
                id=metadata[1]
                metadata.extend(tag_dict[region].get(id))
                metadatas.append(metadata)


    return metadatas

def print_markdown(output_list):
    for row in range(len(output_list)):
        for n in range(len(output_list[row])):
            print('| ', end='')
            print(output_list[row][n], end=' ')
        print('|')

        if row == 0:
            for n in range(len(output_list[row])):
                print('| ', end='')
                print( ' :--- ', end='')
            print('|')
    

# init resource objects
ec2_instances = {}
ec2_instance_tags = {}
ebs_volumes = {}
elastic_ips = {}
loadbalancers = {}
instance_dict = {}
check_headers = {}

# set resource objects for detected region
#
# get regions collected in the files
regions = get_regions()
#
for region in regions:
    ec2_instances[region] = get_resource_object('describe-instances', region)
    ec2_instance_tags[region] = get_instance_tags(region)
    ebs_volumes[region] = get_resource_object('describe-volumes', region)
    elastic_ips[region] = get_resource_object('describe-addresses', region)
    loadbalancers[region] = {}
    loadbalancer_ids = get_loadbalancer_ids(region)
    for lb_id in loadbalancer_ids:
        loadbalancers[region][lb_id] = get_resource_object(
            lb_id+'_describe-load-balancer-attributes', region)

# ------------------------------
# create report
# ------------------------------
# (1) Create header
get_check_headers()

# (2) create Low_Utilization_Amazon_EC2_Instances report
ec2_flagged_instances = get_flagged_resources('Low_Utilization_Amazon_EC2_Instances', ec2_instance_tags)
print_markdown(ec2_flagged_instances)










