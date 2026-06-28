# Task.md — Paradigm Docs

> AGENTS.md EE 準拠: 全 AI エージェントの進捗・決定事項の集約ファイル

## CURRENT STATUS

**v1.1 公開済み** — `https://docs.paradigmjp.com`

- Fumadocs OSS（Next.js 16.2.6 + React 19 on Node 24 Alpine）
- Hetzner CX22 コンテナ同居（coolify ネットワーク）
- Cloudflare DNS + Traefik ルーティング
- Docker restart: always
- 自動収集 cron: 毎日 3:00 JST（`/root/sync-docs.sh`）
- 手書きドキュメント保護: `external/` サブディレクトリに分離

## 構成

| パス | 内容 |
|------|------|
| `/` | ランディング（プロジェクト一覧 + CTA） |
| `/docs` | 統合ドキュメント トップ |
| `/docs/outbound-form-agent` | OFA 概要（詳細版） |
| `/docs/outbound-form-agent/setup` | セットアップ完全ガイド（前提・手順・トラブルシューティング） |
| `/docs/outbound-form-agent/architecture` | アーキテクチャ（データフロー・並列処理・CAPTCHA 詳細） |
| `/docs/outbound-form-agent/api` | CLI リファレンス |
| `/docs/twenty-crm` | Twenty CRM REST API 連携 |
| `/docs/cli-tools` | CLI ツール群一覧 |

## ドキュメント品質基準

全ページで以下を満たすこと:
1. **前提条件** — 必要な環境・バージョンを明示
2. **手順** — コピペで実行できるコマンド例
3. **確認方法** — 各ステップの成功判定基準
4. **トラブルシューティング** — よくあるエラーと解決策
5. **初心者向け** — 専門用語の説明、読みやすい表形式

## 更新ルール

- **機能追加・仕様変更時**: Task.md 更新と並行して、必ず docs/content/ 下の対応 MDX を更新すること
- **指示不要**: ユーザーの指示を待たず自律実行
- **再デプロイ**: SSH → `/root/sync-docs.sh` でビルド + Docker 再起動
- **自動 cron**: 毎日 3:00 JST に外部リポジトリの `docs/` を収集

## 技術スタック

- **Framework**: Fumadocs OSS（fumadocs-ui-template ベース）
- **Runtime**: Next.js 16.2.6 + React 19 on Node 24 Alpine
- **Hosting**: Hetzner CX22（Docker + Coolify Traefik）
- **DNS**: Cloudflare（docs.paradigmjp.com → 178.105.138.55）

## Active Handoff

- Dockerfile: single-stage（COPY . . → npm install && npm run build）
- Traefik config: `/data/coolify/proxy/dynamic/paradigmjp.yml`
- Container IP: `10.0.1.32`（coolify network）
- Backup: `paradigmjp.yml.bak-20260629-docs`
- 外部 docs 収集先: `content/docs/external/`（手書き上書き防止）

## 残タスク

- [ ] OG 画像生成（現在はデフォルト）
- [ ] コンテンツ拡充（Twenty CRM 詳細、CLI ツール群個別ページ）
