#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json
from pathlib import Path
import re
import sys

# Input JSON directory
args = sys.argv
dir = args[1] + '/SEC'
p = Path(dir)


# 1. GuardDuty status
# create header
print('')
print('---------------------')
print('### 1.すべてのリージョンでGuardDutyを有効にする')
print('')
print('')
print('| region | DetectorIds | Check Status  | comment |')
print('| :---------- | :------------ | :----------------- | :------------- |')

for f in list(p.glob('*_list-detectors_*.json')):
    detector_ids = []
    region = re.findall('SEC04_(.*)_list-detectors_(.*).json',
                        os.path.basename(f))[0][0]
    if os.path.getsize(f):
        with open(f) as j:
            d = json.load(j)
            detector_ids = d.get('DetectorIds')
    
    if len(detector_ids) != 0 :
        result = 'PASS'
        detector_id = str(detector_ids)
    else:
        result = 'FAIL'
        detector_id = 'None'

    print('| ' + region + ' | ' + detector_id + ' | ' + result + ' | ')

# 2. GuardDuty settings
# create header
print('')
print('---------------------')
print('### 2. GuardDutyの設定状況')
print('')
print('')
print('| GuardDuty region| Destination Settings |　Check Status  | comment |')
print('| :---------- | :------------ | :----------------- | :------------- |')

for f in list(p.glob('*list-publishing-destinations*json')):
    destination_settings = []
    region = re.findall('SEC05_(.*)_list-publishing-destinations_(.*).json',
                        os.path.basename(f))[0][1]
    if os.path.getsize(f):
        with open(f) as j:
            d = json.load(j)
            destination_settings = d.get('Destinations')
    
    if len(destination_settings) != 0 :
        result = 'PASS'
        destination_setting = str(destination_settings)
    else:
        result = 'FAIL'
        destination_setting = 'None'

    print('| ' + region + ' | ' + destination_setting+ ' | ' + result + ' | |')



# 3. Security Hub status
# create header
print('')
print('---------------------')
print('### 3.すべてのリージョンでSecurity Hubを有効にする')
print('')
print('')
print('| region | Secury Hub Subscribed Date | Check Status  | comment |')
print('| :---------- | :------------ | :----------------- | :------------- |')

for f in list(p.glob('*_describe-hub_*.json')):
    sechub_date = ''
    region = re.findall('SEC07_(.*)_describe-hub_(.*).json',
                        os.path.basename(f))[0][0]
    if os.path.getsize(f):
        with open(f) as j:
            d = json.load(j)
            sechub_date = d.get('SubscribedAt')
    
    if sechub_date  != '' :
        result = 'PASS'
    else:
        result = 'FAIL'

    print('| ' + region + ' | ' + sechub_date  + ' | ' + result + ' | |')


# 4. Security Hub status
# create header
print('')
print('---------------------')
print('### 4. Security Hubの結果の統合状況')
print('')
print('')
print('| region | Secury Hub Members | Check Status  | comment |')
print('| :---------- | :------------ | :----------------- | :------------- |')

for f in list(p.glob('*_list-members_*.json')):
    params = []
    region = re.findall('SEC08_(.*)_list-members_(.*).json',
                        os.path.basename(f))[0][0]
    if os.path.getsize(f):
        with open(f) as j:
            d = json.load(j)
            params = d.get('Members')
    
    if len(params) != 0 :
        result = 'PASS'
        param = str(params)
    else:
        result = 'FAIL'
        param = 'None'

    print('| ' + region + ' | ' + param  + ' | ' + result + ' | |')


# 4. CloudWatch Events Rules
# create header
print('')
print('---------------------')
print('### 5. CloudWatch Events Rules List')
print('')
print('')
print('| region | Ebent Rule Name | Description | comment |')
print('| :---------- | :------------ | :----------------- | :------------- |')

for f in list(p.glob('*_list-rules_*.json')):
    params = []
    region = re.findall('SEC06_(.*)_list-rules_(.*).json',
                        os.path.basename(f))[0][0]
    if os.path.getsize(f):
        with open(f) as j:
            d = json.load(j)
            rules = d.get('Rules')

    if len(rules) == 0 :
        rule = 'None'
        print('| '
            + region + ' | '
            + rule + ' | '
            + ' | |'
        )
    else:
        for r in rules:

            print('| '
                + region + ' | '
                + r.get('Name') + ' | '
                + str(r.get('Description')) + ' | '
                + ' |'
            )




