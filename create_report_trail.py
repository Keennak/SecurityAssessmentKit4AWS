#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json
from pathlib import Path
import re
import sys

# Input JSON directory
args = sys.argv
dir = args[1] + '/TRAIL'
p = Path(dir)


# 1. CloudTrailの設定状況
# create header
print('')
print('---------------------')
print('### 1.CloudTrailの設定状況')
print('')
print('')
print('| Trail Name | region | multi region | KMS  | validation | Check Status | bucket  | CloudWatch Logs  | comment  |')
print('| :--------- | :----- | :----------- | :--- | :--------- | :----------- | :------ | :------ | :--------------- |')

for f in list(p.glob('*_list-trails_*.json')):
    trail = ''
    region = ''
    multi_region = ''
    kms_enabled = ''
    bucket = ''
    cwl = ''
    validation = ''
    result = ''
    kms_enabled = 'False'

    if os.path.getsize(f):
        with open(f) as j:
            d = json.load(j)
            for f in d.get('Trails'):
                trail = f.get('Name')
                region = f.get('HomeRegion')

                # get trail settings
                trail_file = '*_' + trail + '_get-trail_*.json'
                for tf in list(p.glob(trail_file)):
                    with open(tf) as tj:
                        td = json.load(tj)
                        multi_region = str(
                            td.get('Trail').get('IsMultiRegionTrail'))
                        kms_key_id = td.get('Trail').get('KmsKeyId')
                        validation = str(td.get('Trail').get(
                            'LogFileValidationEnabled'))
                        bucket = td.get('Trail').get('S3BucketName')
                        cwl = td.get('Trail').get('CloudWatchLogsLogGroupArn')

    # マルチリージョン、暗号化、整合性チェックのすべてが有効、になっているTrailはOKとする。
    if kms_key_id != '' :
        kms_enabled = 'True'

    if multi_region == 'True' and kms_enabled == 'True' and validation == 'True':
        result = 'PASS'
    else:
        result = 'FAIL'

    print('| ' + trail + ' | ' + region + ' | ' + multi_region + ' | ' + kms_enabled +
          ' | ' + str(validation) + ' | ' + str(result) + ' | ' + str(bucket) + ' | |')
