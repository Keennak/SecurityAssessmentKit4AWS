#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json
from pathlib import Path
import re
import sys

# Input JSON directory
# メモ：CollectorがS3に入っているので、一旦仮で。要修正。
args = sys.argv
dir = args[1] + '/S3'
p = Path(dir)

# 1. GuardDuty status
# create header
print('')
print('---------------------')
print('### 1.Config Rulesの設定状況をリストする')
print('')
print('')
print('| region      | Name        | Status      | Owner       | Source ID   | Created by  | Description |')
print('| :---------- | :---------- | :---------- | :---------- | :---------- | :---------- | :---------- |')


for f in list(p.glob('*_describe-config-rules_*.json')):
    config_rules = []
    region = re.findall(
        'SSS05_describe-config-rules_(.*).json', os.path.basename(f))[0]
    with open(f) as j:
        d = json.load(j)
        for rule in d.get('ConfigRules'):
            print('| %s | %s | %s | %s | %s | %s | %s |' % (region, rule.get('ConfigRuleName'), rule.get('ConfigRuleState'), rule.get(
                'Source').get('Owner'), rule.get('Source').get('SourceIdentifier'), rule.get('CreatedBy'), rule.get('Description')))
