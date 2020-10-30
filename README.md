# Security Assessment Kit for AWS

# 1. Collector
## Overview
This script collects your aws account setting information and saves it in a JSON-formatted local file.
This script uses the privileges of the execution role assigned to the execution node to access AWS. ReadOnlyAccess equivalent permissions is required.


## Usage
```
 ./collect.sh *region* [*profile*]
```
 * Some services ignore the region specified by the argument and collect configuration information for all regions.
 * Result files will be output under the current directory.  
 ./result/SAK_YYYYMMDD-HHMMSS

# 2. Report Creater
## Overview
* The report generation script aggregates the JSON files collected by Collector into Markdown format for your assessment. 
* We recommend to use Prowler and this tool together. Items evaluated by Prowler are not evaluated by this script.

## Usage
Specify the Collector result directory in the argument.
```
./create_report.sh ./result/SAK_YYYYMMDD-HHMMSS
```
## System eequirements
bash, aws-cli, Python3  
I checked in bash(mac/Mojave), aws-cli/2.0.23, Python/3.7.4)


# Security Assessment Kit for AWS

1. Collector
- コレクタースクリプトは、AWS CLIを使用して、アカウントの設定情報を収集、JSON形式のローカルファイルへ保存します。
- 引数で指定されたプロファイルのロール権限を使用して、AWSへアクセスします。ReadOnlyAccess相当の権限が必要です。
- プロファイルを指定しない場合は現在のロールで設定情報が収集されます。
- 一部のサービスでは引数で指定されたregionを無視してすべてのregionの設定情報を収集します。

- 使用方法  
  ./collect.sh region_name [profile_name]

　　スクリプトを実行すると、カレントディレクトリ配下に結果ファイルが出力されます。  
　./result/SAK_YYYYMMDD-HHMMSS

2. Report generator
- レポート生成スクリプトは、Collectorで収集したJSONを、アセスメント用のMD形式に集計します。また、AWSベストプラクティスのうち、単純な評価項目については、評価結果を合わせて出力します。
- Prowlerをあわせて実施されると包括的なアセスメントが可能です。Prowlerで評価される項目は本スクリプトでは評価されません。

- 使用方法
 引数に、Collectorの結果ディレクトリを指定して実行します。
 ./create_report.sh ./result/SAK_YYYYMMDD-HHMMSS

 スクリプトを実行すると、カレントディレクトリ配下にレポートファイルが出力されます。  
 ./report/SAK_YYYYMMDD-HHMMSS

 3. 動作環境
 mac(Mojave)のbash, aws-cli/2.0.23, Python/3.7.4で動作確認をしました。  
  
