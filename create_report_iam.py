#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json
from pathlib import Path
import sys

args = sys.argv

dir = args[1] + '/IAM'
p = Path(dir)


# create User list
user_list = []
for f in list(p.glob('*_list-users_*.json')):
    with open(f) as j:
        key_dict = json.load(j)
        for k in key_dict['Users']:
            user_list.append(k.get('UserName'))


# 1. list user pemissions
# create header

def report_user_permissions():
    # print('# IAM')
    print('### x.Userの権限付与状況')
    print('')
    print('')
    print('| UserName | Group | Attached Policy | Inline Policy | comment |')
    print('|:----------|:------------|:-----------------|:-------------|---------|')

    for u in user_list:

        # 1-1. list inline policy
        inline_p = ''
        file_name = '*' + u + '_list-user-policies_*.json'
        for f in list(p.glob(file_name)):
            with open(f) as j:
                d = json.load(j)
                inline_p = str(d.get('PolicyNames'))
        
        # 1-2. list attached policy
        attached_p = ''
        file_name = '*' + u + '_list-attached-user-policies_*.json'
        for f in list(p.glob(file_name)):
            with open(f) as j:
                d = json.load(j)
                attached_p = str(d.get('AttachedPolicies'))
        
        # 1.3. list group 
        groups = []
        file_name = '*' + u + '_list-groups-for-user_*.json'
        for f in list(p.glob(file_name)):
            with open(f) as j:
                d = json.load(j)
                for g in d['Groups']:
                    groups.append(g['GroupName'])
                groups = str(groups)
        
        print('| ' + u + ' | ' + groups + ' | ' + attached_p + ' | ' + inline_p + '| |' )


report_user_permissions()






