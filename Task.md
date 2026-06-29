# Task.md — Paradigm Docs

> AGENTS.md EE 準拠: 全 AI エージェントの進捗・決定事項の集約ファイル

## CURRENT STATUS

**v2.0 — Stagehand LOCAL ピボット反映 + Twenty SSOT 操作モデル**

全ドキュメントを Stagehand v3 LOCAL ピボットに合わせて改訂。
「Twenty CRM が唯一の操作画面、Hermes チャットが指示インターフェース」の SSOT モデルで統一。
新規 GUI ダッシュボードは作成しない（Twenty CRM ですべて完結）。

## 構成

| パス | 内容 | 改訂 |
|------|------|------|
| `/` | ランディング（プロジェクト一覧） | ✅ v1.2 |
| `/docs` | 統合ドキュメント トップ | ✅ v1.2 |
| `/docs/outbound-form-agent` | OFA 概要（Stagehand v3 + Twenty SSOT 操作モデル） | ✅ v2.0 |
| `/docs/outbound-form-agent/setup` | セットアップ完全ガイド | ✅ v1.1 |
| `/docs/outbound-form-agent/architecture` | アーキテクチャ（Stagehand LOCAL + CDP + DeepSeek） | ✅ v2.0 |
| `/docs/outbound-form-agent/api` | CLI リファレンス | ✅ v1.2 |
| `/docs/twenty-crm` | Twenty CRM 完全運用ガイド | ✅ v1.2 |
| `/docs/cli-tools` | CLI ツール群 | ✅ v1.2 |

## ドキュメント品質基準

| # | 基準 | 達成 |
|---|------|------|
| 1 | 前提条件 — 必要な環境・バージョンを明示 | ✅ |
| 2 | 手順 — コピペで実行できるコマンド例 | ✅ |
| 3 | 確認方法 — 各ステップの成功判定基準 | ✅ |
| 4 | トラブルシューティング — エラー・原因・対処の表 | ✅ |
| 5 | 初心者向け — 専門用語に説明、図解と表を多用 | ✅ |

## 更新ルール

- **機能追加・仕様変更時**: Task.md 更新と並行して、必ず docs/content/ 下の対応 MDX を更新すること
- **指示不要**: ユーザーの指示を待たず自律実行
- **Twenty SSOT 厳守**: 操作手順はすべて Twenty CRM 上で完結する設計を維持。新規ダッシュボード禁止

## Completed

- ✅ Fumadocs OSS 構築 + docs.paradigmjp.com デプロイ
- ✅ 全 8 ページ実務運用ガイド改訂
- ✅ Outbound Form Agent Stagehand v3 LOCAL ピボット反映
- ✅ Twenty CRM SSOT 操作モデル統一
