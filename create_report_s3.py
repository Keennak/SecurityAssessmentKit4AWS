#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json
from pathlib import Path
import re
import sys

# Input JSON directory
args = sys.argv
dir = args[1] + '/S3'
p = Path(dir)

# common

# --------------------------------------------------------------
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
# --------------------------------------------------------------


# main
# print header
print('# Security Deep Assessment (S3編）')
print('')


def get_encription_status():
    # 1. Report Encryption settings
    # 重要なバケット内の情報が他アカウント等へ意図せず開示されないようCMKによる暗号化を行う。

    for f in list(p.glob('*_get-bucket-encryption_*.json')):
        bucket = re.findall('SSS03_(.*).json', os.path.basename(f))[0]
        bucket_name = re.findall('(.*)_get-bucket-encryption', bucket)[0]
        if os.path.getsize(f):
            with open(f) as j:
                d = json.load(j)
                for rules in d.get('ServerSideEncryptionConfiguration', {}).get('Rules'):
                    enc_setting = str(
                        rules.get('ApplyServerSideEncryptionByDefault'))
                    encription_statuses[bucket_name] = enc_setting
        else:
            encription_statuses[bucket_name] = 'Not Configured'


def get_acl_status():
    # 3. ACLの利用状況を確認する
    # OWNERのみがGranteeであればPASS
    # OWNER以外のGranteeが存在したらCheck Requiredとする。
    for f in list(p.glob('*_get-bucket-acl_*.json')):
        bucket = re.findall('SSS07_(.*).json', os.path.basename(f))[0]
        bucket_name = re.findall('(.*)_get-bucket-acl', bucket)[0]

        if os.path.getsize(f):
            # print key list
            with open(f) as j:
                d = json.load(j)

                # aclよりオーナー情報を取得
                owner = d.get('Owner').get('ID')
                for grant in d.get('Grants'):
                    # オーナー情報とGranteeを比較し、オーナー以外のものが一つでもあればCheck requiredとする
                    if grant.get('Grantee').get('ID') == owner:
                        result = 'OK'
                    else:
                        result = 'Check Required'
                        break
        else:
            result = 'Access Denyed'
        acl_statuses[bucket_name] = result


def get_public_access_block():
    for f in list(p.glob('*_get-public-access-block_*.json')):
        bucket = re.findall('SSS01_(.*).json', os.path.basename(f))[0]
        bucket_name = re.findall('(.*)_get-public-access-block', bucket)[0]
        if os.path.getsize(f):
            with open(f) as j:
                d = json.load(j)
                public_accesses[bucket_name] = d.get('PublicAccessBlockConfiguration')
        else:
            public_accesses[bucket_name] = 'Not Configured'

def print_bucket_policy():
    # Appendix  print bucket policy
    # print header
    print('')
    print('## Appendix.バケットポリシー')
    print('')

    for f in list(p.glob('*_get-bucket-policy_*.json')):
        bucket = re.findall('SSS04_(.*).json', os.path.basename(f))[0]
        bucket_name = re.findall('(.*)_', bucket)[0]

        if os.path.getsize(f):
            # print key list
            with open(f) as j:
                dj = json.load(j)
                print('-------------------')
                print(bucket_name)
                print('```json')
                print(dj['Policy'])
                print('```')

        else:
            print('-------------------')
            print(bucket_name)
            print('')
            print('Not Configured')
            print('')

def get_logging_statuses():
    for f in list(p.glob('*_get-bucket-logging_*.json')):
        bucket = re.findall('SSS08_(.*).json', os.path.basename(f))[0]
        bucket_name = re.findall('(.*)_get-bucket-logging', bucket)[0]
        if os.path.getsize(f):
            with open(f) as j:
                d = json.load(j)
                logging_statuses[bucket_name] = d.get('LoggingEnabled')
        else:
            logging_statuses[bucket_name] = 'Not Configured'

def get_versioning_statuses():
    for f in list(p.glob('*_get-bucket-versioning_*.json')):
        bucket = re.findall('SSS09_(.*).json', os.path.basename(f))[0]
        bucket_name = re.findall('(.*)_get-bucket-versioning', bucket)[0]
        if os.path.getsize(f):
            with open(f) as j:
                d = json.load(j)
                versioning_statuses[bucket_name] = d.get('Status')
                mfadelete_statuses[bucket_name] = d.get('MFADelete')
        else:
            versioning_statuses[bucket_name] = 'Not Configured'  
            mfadelete_statuses[bucket_name] = 'Not Configured'

def get_objectlock_statuses():
    for f in list(p.glob('*_get-object-lock-configuration_*.json')):
        bucket = re.findall('SSS09_(.*).json', os.path.basename(f))[0]
        bucket_name = re.findall('(.*)_get-object-lock-configuration', bucket)[0]
        if os.path.getsize(f):
            with open(f) as j:
                d = json.load(j)
                objectlock_statuses[bucket_name] = d.get('ObjectLockConfiguration')
        else:
            objectlock_statuses[bucket_name] = 'Not Configured'   


# Initiarise Dictionary
encription_statuses = {}
acl_statuses = {}
public_accesses = {}
logging_statuses = {}
versioning_statuses = {}
objectlock_statuses = {}
mfadelete_statuses = {}

# collect data
get_encription_status()
get_acl_status()
get_public_access_block()
get_logging_statuses()
get_versioning_statuses()
get_objectlock_statuses()

# print report
#
# print header
print('')
print('')
print('')
print('')
print('|   N    | bucket name | encription | acl_status | public_access | logging | versioning | MFA delete | object lock |')
print('| :----- | :---------- | :--------- | :--------- | :------------ | :------ | :--------- | :--------- | :---------- |')

# create report
n=1
for d in encription_statuses:
    bucket_name = d
    encription_status = encription_statuses.get(bucket_name)
    acl_status = acl_statuses.get(bucket_name)
    public_access = public_accesses.get(bucket_name)
    logging_status = logging_statuses.get(bucket_name)
    versioning_status = versioning_statuses.get(bucket_name)
    mfadelete_status = mfadelete_statuses.get(bucket_name)
    objectlock_status = objectlock_statuses.get(bucket_name)

    print('| %s | %s | %s | %s | %s | %s | %s | %s | %s |' % (
    n, bucket_name , encription_status , acl_status , public_access, logging_status, versioning_status, mfadelete_status, objectlock_status))
    n+=1

print('')
print('')

# 2. Config Rulesの設定状況を一覧にする

# print header
print('')
print('## 2.Config Rules による監視状況')
print('| ConfigRuleName | Description |')
print('| :---------- | :------------------ |')

for f in list(p.glob('*_describe-config-rules_*.json')):
    if os.path.getsize(f):
        with open(f) as j:
            d = json.load(j)
            for rules in d.get('ConfigRules'):
                print('| ' + rules.get('ConfigRuleName') +
                      ' | ' + rules.get('Description') + ' |')

print('')
print('')
print_bucket_policy()
