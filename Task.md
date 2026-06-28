# Task.md — Paradigm Docs

> AGENTS.md EE 準拠: 全 AI エージェントの進捗・決定事項の集約ファイル

## CURRENT STATUS

**v1.0 公開済み** — `https://docs.paradigmjp.com`

- Fumadocs OSS（Next.js 16 + MDX）
- Hetzner CX22 コンテナ同居（coolify ネットワーク）
- Cloudflare DNS + Traefik ルーティング
- Docker restart: always

## 構成

| ページ | 内容 |
|--------|------|
| `/` | ランディング（プロジェクト一覧 + CTA） |
| `/docs` | 統合ドキュメント トップ |
| `/docs/outbound-form-agent` | OFA 概要・アーキテクチャ・セットアップ・API |
| `/docs/twenty-crm` | Twenty CRM REST API 連携 |
| `/docs/cli-tools` | CLI ツール群一覧 |

## 技術スタック

- **Framework**: Fumadocs OSS（fumadocs-ui-template ベース）
- **Runtime**: Next.js 16.2.6 + React 19 on Node 24 Alpine
- **Hosting**: Hetzner CX22（Docker + Coolify Traefik）
- **DNS**: Cloudflare（docs.paradigmjp.com → 178.105.138.55）

## Active Handoff

- Dockerfile: multi-stage（builder → runner）
- Traefik config: `/data/coolify/proxy/dynamic/paradigmjp.yml`
- Container IP: `10.0.1.32`（coolify network）
- Backup: `paradigmjp.yml.bak-20260629-docs`

## 残タスク

- [ ] 全プロジェクト docs/*.md 自動収集 CI
- [ ] OG 画像生成（現在はデフォルト）
- [ ] コンテンツ拡充（各プロジェクトの詳細追加）
