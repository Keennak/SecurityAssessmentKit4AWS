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


# 1. Report Encryption settings
# 重要なバケット内の情報が他アカウント等へ意図せず開示されないようCMKによる暗号化を行う。
print('## 1.バケットの暗号化状況')
print('| Bucket Name | Encription Settings |')
print('| :---------- | :------------------ |')

for f in list(p.glob('*_get-bucket-encryption_*.json')):
    bucket = re.findall('SSS03_(.*).json', os.path.basename(f))[0]
    bucket_name = re.findall('(.*)_', bucket)[0]
    if os.path.getsize(f):
        with open(f) as j:
            d = json.load(j)
            for rules in d.get('ServerSideEncryptionConfiguration', {}).get('Rules'):
                enc_setting = str(
                    rules.get('ApplyServerSideEncryptionByDefault'))
                print('| ' + bucket_name + ' | ' + enc_setting + ' |')
    else:
        print('| ' + bucket_name + ' | None |')


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


# 3. ACLの利用状況を確認する
# OWNERのみがGranteeであればPASS
# OWNER以外のGranteeが存在したらCheck Requiredとする。

# print header
print('')
print('## ３.ACLの利用状況')
print('OWNER以外のGranteeが存在するかどうかの確認')
print('| ConfigRuleName | Description |')
print('| :---------- | :------------------ |')


def report_acl():
    for f in list(p.glob('*_get-bucket-acl_*.json')):
        bucket = re.findall('SSS07_(.*).json', os.path.basename(f))[0]
        bucket_name = re.findall('(.*)_', bucket)[0]

        if os.path.getsize(f):
            # print key list
            with open(f) as j:
                d = json.load(j)

                # aclよりオーナー情報を取得
                owner = d.get('Owner').get('ID')
                for grant in d.get('Grants'):
                    # オーナー情報とGranteeを比較し、オーナー以外のものが一つでもあればCheck requiredとする
                    if grant.get('Grantee').get('ID') == owner:
                        result = 'PASS'
                    else:
                        result = 'Check Required'
                        break
        else:
            result = 'Access Denyed'
        print('| ' + bucket_name + ' | ' + result + ' |')


report_acl()


# Appendix  print bucket policy

# print header
print('')
print('## Appendix.バケットポリシー')
print('')


def print_bucket_policy():
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
            print('None ')
            print('')


print_bucket_policy()
