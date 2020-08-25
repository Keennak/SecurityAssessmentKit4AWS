#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json
from pathlib import Path
import re
import sys

# Input JSON directory
args = sys.argv
dir = args[1] + '/CWL'
p = Path(dir)


# 1. CloudWatch Logs の設定状況
print('')
print('---------------------')
print('### 1.CloudWatch Logsの設定状況')
print('')
print('')


# create unique exported log group list
for f in list(p.glob('*_describe-export-tasks_*.json')):
    group_name = ''
    destination = ''
    task_list = []

    if os.path.getsize(f):
        with open(f) as j:
            d = json.load(j)
            for f in d.get('exportTasks'):
                group_name = f.get('logGroupName')
                destination = f.get('destination')
                ad = {'Name': group_name, 'DST': destination}
                task_list.append(ad)

# get unique
task_list.sort(key=lambda x: x['Name'])
tasked_logs_list = []
prev = ''
for l in task_list:
    if l.get('Name') != prev:
        tasked_logs_list.append(l.get('Name'))
        prev = l.get('Name')
    else:
        prev = l.get('Name')

# report log group status
#
# create header
print('')
print('| Log Group Name | encrypted | exported | comment  |')
print('| :------------- | :-------- | :------- | :------- |')

for f in list(p.glob('*_describe-log-groups_*.json')):
    group_name = ''
    key_id = ''

    if os.path.getsize(f):
        with open(f) as j:
            d = json.load(j)
            for f in d.get('logGroups'):
                group_name = f.get('logGroupName')

                key_id = f.get('kmsKeyId')
                if not key_id:
                    key_id = 'None'
                if group_name in tasked_logs_list:
                    exported = 'True'
                else:
                    exported = 'False'

                print('|' + group_name + '|' + key_id +
                      '|' + exported + '|' + '|')
