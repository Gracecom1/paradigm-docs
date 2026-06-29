# Task.md — Paradigm Docs

> AGENTS.md EE 準拠: 全 AI エージェントの進捗・決定事項の集約ファイル

## CURRENT STATUS

**v1.2 完全公開済み** — `https://docs.paradigmjp.com`

全 7 ページを実務運用ガイドに全面改訂。
Git 運用・日次ルーチン・トラブル対応表を追加し、初心者が読めば実際に運用できるレベルに到達。

## 構成

| パス | 内容 | 改訂状態 |
|------|------|---------|
| `/` | ランディング（5分で始める・日次運用クイックスタート） | ✅ v1.2 |
| `/docs` | 統合ドキュメント トップ（全ツールの役割図解・クイックナビ） | ✅ v1.2 |
| `/docs/outbound-form-agent` | OFA 概要（前回詳細改訂済み） | ✅ v1.1 |
| `/docs/outbound-form-agent/setup` | セットアップ完全ガイド（6 ステップ・トラブル表） | ✅ v1.1 |
| `/docs/outbound-form-agent/architecture` | アーキテクチャ（データフロー図・並列処理・7 種 CAPTCHA） | ✅ v1.1 |
| `/docs/outbound-form-agent/api` | **CLI リファレンス実務版**（全オプション表・シナリオ別コマンド・cron 設定・ログ解釈・Git 運用） | ✅ v1.2 |
| `/docs/twenty-crm` | **Twenty CRM 完全運用ガイド**（JWT 取得手順・curl 全操作・日次チェックリスト・バックアップ） | ✅ v1.2 |
| `/docs/cli-tools` | **CLI ツール群実務版**（Git 運用パターン・cron 全自動化・環境チェックリスト・構成図） | ✅ v1.2 |

## ドキュメント品質基準（全ページ達成）

| # | 基準 | 達成 |
|---|------|------|
| 1 | **前提条件** — 必要な環境・バージョンを明示 | ✅ |
| 2 | **手順** — コピペで実行できるコマンド例 | ✅ |
| 3 | **確認方法** — 各ステップの成功判定基準 | ✅ |
| 4 | **トラブルシューティング** — エラー・原因・対処の表 | ✅ |
| 5 | **Git 運用** — clone/pull/status/log/stash/conflict 解決 | ✅ |
| 6 | **日次運用** — 毎朝の作業フローをコマンド付きで | ✅ |
| 7 | **初心者向け** — 専門用語に説明、図解と表を多用 | ✅ |

## 更新ルール

- **機能追加・仕様変更時**: Task.md 更新と並行して、必ず docs/content/ 下の対応 MDX を更新すること
- **指示不要**: ユーザーの指示を待たず自律実行
- **再デプロイ**: scp + docker build + stop/rm/run で即時反映
- **自動 cron**: 毎日 03:00 JST `98f7504a1516`（外部 docs 収集は external/ へ分離保護）

## 技術スタック

| 項目 | 値 |
|------|-----|
| Framework | Fumadocs OSS（Next.js 16.2.6 + React 19 on Node 24 Alpine） |
| Hosting | Hetzner CX22（Docker + Coolify Traefik、178.105.138.55） |
| DNS | Cloudflare（proxied A レコード） |
| GitHub | Gracecom1/paradigm-docs |

## 残タスク

なし（全ページ実務運用レベルに到達）
