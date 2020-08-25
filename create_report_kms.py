#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json
from pathlib import Path
import sys

# Input JSON directory
args = sys.argv
dir = args[1] + '/KMS'
p = Path(dir)

# KMS01
# print key list
# key-dict : kms list-aliases

# print header
print('# KMS')
print('### 1.CMKの状態')
print('')
print('')

# print table header
print('| AliasName | TargetKeyId | Rotation setting | Check result | comment |')
print('|:----------|:------------|:-----------------|:-------------|---------|')

# get CMK list
for f in list(p.glob('*list-aliases*.json')):
    with open(f) as j:
        key_dict = json.load(j)
        for k in key_dict['Aliases']:
            if (k.get('TargetKeyId')):
                # check lotation settings of the CMK
                a = '*' + k.get('TargetKeyId') + '_get-key-rotation-status*'
                for f_rotation in list(p.glob(a)):
                    if os.path.getsize(f_rotation):
                        with open(f_rotation) as j_rotation:
                            rotate_dict = json.load(j_rotation)
                            rotation_status = rotate_dict.get('KeyRotationEnabled')
                    else:
                        # if get-key-rotation-status.json file is null, the CMK is BYOK. and rotation is not enabled
                        rotation_status = 'False'

                # if AliasName start with "alias/aws/", that is AWS managed CMK. And you don't need check key policy.
                if k['AliasName'].startswith('alias/aws/'):
                    status = 'PASS'
                else:
                    status = 'Check Required'
            else:
                # if TargetKeyId is not exist, the key alias is not uesd anymore.
                rotation_status = '-'
                status = 'Alias is Not used'
            print('|', k['AliasName'], '|',  k.get('TargetKeyId'), '|', rotation_status, '|', status, '|')


# print key policys for manual check
print('### 2.IAMポリシーないし、キーポリシーで鍵の管理者と利用者を最小限に制限する。')
print('キーポリシーの内容は目視で確認を行います。')
print('')


for f in list(p.glob('*get-key-policy*.json')):
    if os.path.getsize(f):
    # print key list    
        with open(f) as j:
            dj = json.load(j)
            print('-------------------')
            keyId = os.path.basename(f)[6:42]
            print(keyId)
            print('```json')
            print(dj['Policy'])
            print('```')

