# AWS FinOps IaC Templates (slack notification)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

AWSアカウント全体のコスト管理・監視（FinOps）基盤を構築・管理するためのモジュールです。

| 項目 | 値 | 備考 |
| :-- | :-- | :-- |
| ワークスペースの使用 | `◯` | `stg`, `prd` 環境でのみ特定リソースを作成する制御あり |
| 識別子の使用可否 | `不可` | |
| stateファイルキー | `finops.tfstate` | |

## モジュール概要

本モジュールでは、以下の3つのコスト管理機能を構築し、Slackチャンネルへの通知を自動化します。

1. **予算超過検知・通知 (Budgets)**
   - 設定した月次予算に対し、実績が90%、または予測が100%を超過した場合にアラートを通知します。
2. **コスト異常検知・通知 (Cost Anomaly Detection)**
   - 機械学習を用いて予期せぬAWSサービスのコスト増加（$10以上）を検知し、即時通知します。
3. **前月の請求額通知 (Bill Report)**
   - 毎月最初の平日のAM9時にEventBridge Scheduler経由でLambdaを起動し、前月分の確定請求額（USDおよびJPY概算）とサービス別内訳をSlackに通知します。

## ⚠️依存関係・前提条件

- tfstateを格納するS3 bucketを用意し、./environments/***.hcl に bucket名を定義していること。
- AWS Chatbotと対象のSlack Workspaceの連携がAWSコンソール上から手動で完了していること。
- Secrets Managerにてstore `finops_commons`を作成。key名「SlackWebhookURL_cost」に事前に通知先CHのSlack Webhook URLを格納していること。

## 構築手順
### TF実行コマンド

以下は `stg` 環境（非本番アカウント）に適用する場合のコマンド例です。

```sh
cd ~/GitHub/terraform-aws-finops-slack-notice

# 初期化 (stg環境用バックエンド設定)
terraform init -reconfigure -backend-config=environments/stg.hcl

# 構文チェック
terraform validate

# Workspaceの切り替え
terraform workspace select stg

# プラン確認
terraform plan -var-file environments/stg.tfvars

# 適用
terraform apply -var-file environments/stg.tfvars
```

## ⚠️注意事項

- Workspaceによる作成制御（二重作成防止）
  - FinOpsリソースはAWSアカウント全体に適用されるため、同一アカウント内で複数のWorkspaceからリソースが重複作成されないよう設計されています。
  - stg および prd Workspaceでの実行時のみリソースが作成され、それ以外（dev など）では実行してもリソースの作成はスキップされます。

- AWS Providerのバージョンについて
  - Lambda関数のランタイムに python3.14 を指定しているため、TerraformのAWS Providerは v6.21.0 以上を使用する必要があります（providers.tf で定義済み）。

## 推奨事項
- 予算額の定期見直し: environments/*.tfvars に定義されている budget_amount は、数ヶ月に1回程度、実際の利用実績に合わせて見直して数値を調整してください。

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
