# Security Assessment Kit for AWS

## Usage

1. Collector
- コレクタースクリプトは、AWS CLIを使用して、アカウントの設定情報を収集、JSON形式のローカルファイルへ保存します。
- 本スクリプトの実行ノードに割り当てられたロールの権限を使用して、AWSへアクセスします。ReadOnlyAccess相当の権限が必要です。
- 一部のサービスでは引数で指定されたregionを無視してすべてのregionの設定情報を収集します。
- 使用方法
  ./collect.sh <region name>

　　スクリプトを実行すると、カレントディレクトリ配下に結果ファイルが出力されます。
　./result/SAK_YYYYMMDD-HHMMSS

2. Report Creater
- レポート生成スクリプトは、Collectorで収集したJSONを、アセスメント用のMD形式に集計します。また、AWSベストプラクティスのうち、単純な評価項目については、評価結果を合わせて出力します。
- Prowlerをあわせて実施されると包括的なアセスメントが可能です。Prowlerで評価される項目は本スクリプトでは評価されません。

- 使用方法
 引数に、Collectorの結果ディレクトリを指定して実行します。
 ./create_report.sh ./result/SAK_YYYYMMDD-HHMMSS

 スクリプトを実行すると、カレントディレクトリ配下にレポートファイルが出力されます。
 ./report/SAK_YYYYMMDD-HHMMSS

 3. 動作環境
  mac(Mojave)のbash, aws-cli/2.0.23, Python/3.7.4で動作確認をしました。
  