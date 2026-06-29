# Outbound Form Agent — Steel + Stagehand 移行 & 実務運用レベル化 実装計画

> **For Hermes:** この計画に従い、タスクごとに逐次実装する。

**Goal:** Playwright + puppeteer-extra-plugin-stealth を Steel + Stagehand に置換し、paradigm-docs のダッシュボードから 1 クリックでフォーム自動送信を実行できるようにする。DeepSeek API は維持。cron/n8n 不使用、アイドル時サーバー負荷ゼロ。

**Architecture:**
```
Steel Browser (Docker常駐、127.0.0.1:9223)
  └─ Chrome + CDP (bot検出回避内蔵)
       ↑ chromium.connectOverCDP()
outbound-form-agent (Docker一時起動、ダッシュボードからトリガー)
  ├─ Stagehand v3 (AI駆動フォーム操作: act/extract/observe)
  ├─ DeepSeek V4 (文章生成)
  └─ Twenty CRM REST API (企業取得・結果書き戻し)
paradigm-docs /dashboard
  └─ POST /api/run-agent → Docker run → 完了待ち → 結果表示
```

**Tech Stack:** Steel (ghcr.io/steel-dev/steel-browser), Stagehand v3, playwright-core, DeepSeek API, Docker, Next.js API Route, SQLite, Slack Webhook

**制約:**
- cron/n8n/定期実行 NG → ダッシュボードボタンによる手動トリガーのみ
- DeepSeek 以外の有料 API NG → Steel セルフホスト版（無料）、Stagehand OSS 版
- サーバーディスク逼迫注意 → Docker image prune を定期的に実施、ログ・スクリーンショットの自動ローテーション

**ディスク見積:**
- Steel Docker image: ~3GB（圧縮時 ~1.5GB）
- outbound-form-agent Docker image: ~1.5GB（Node.js + Stagehand + playwright-core、ブラウザバイナリ不要）
- 追加合計: ~4.5GB
- 現在空き: 58GB → 導入後空き: ~53GB ✓

---

## Phase 1: Steel Browser を Hetzner にデプロイ

### Task 1.1: ディスク使用量を確認 & Steel 用ディレクトリ作成

**Objective:** 現状の Docker ディスク使用量を把握し、Steel 用ディレクトリを確保

**Files:**
- サーバー上の `/opt/steel-browser/` を作成

**Step 1: 現状確認**
```bash
ssh root@178.105.138.55 'docker system df && docker image ls --format "table {{.Repository}}\t{{.Size}}" | head -20'
```

**Step 2: 不要イメージ削除（dangling images）**
```bash
ssh root@178.105.138.55 'docker image prune -f'
```

**Step 3: ディレクトリ作成**
```bash
ssh root@178.105.138.55 'mkdir -p /opt/steel-browser/.cache'
```

### Task 1.2: Steel Docker Compose ファイル作成 & 起動

**Objective:** Steel を内部ネットワークのみに公開する形で起動（9223 ポートは外部非公開）

**Files:**
- 作成: `/opt/steel-browser/docker-compose.yml`

**Step 1: docker-compose.yml を配置**

```yaml
services:
  steel:
    image: ghcr.io/steel-dev/steel-browser:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"   # API（localhostのみ）
      - "127.0.0.1:9223:9223"   # CDP（localhostのみ）
    volumes:
      - ./.cache:/app/.cache
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: "2"
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
```

> **ディスク保護:** ログを 50MB × 3 ファイルに制限（最大 150MB）

**Step 2: Steel 起動**
```bash
ssh root@178.105.138.55 'cd /opt/steel-browser && docker compose up -d'
```

**Step 3: 起動確認**
```bash
ssh root@178.105.138.55 'curl -s http://127.0.0.1:3000/api/health && echo " OK"'
```

**検証:** HTTP 200 + `{"status":"ok"}` が返ること

### Task 1.3: CDP 接続テスト

**Objective:** Playwright から Steel の CDP に接続できることを確認

**Step 1: playwright-core で接続テスト**
```bash
ssh root@178.105.138.55 'cd /opt/steel-browser && npx playwright-core --version 2>/dev/null || npm install -g playwright-core'
```

**Step 2: 簡易接続スクリプト実行**
一時スクリプトで CDP 接続 → ページ表示 → スクリーンショット取得をテスト。

```bash
ssh root@178.105.138.55 'node -e "
const { chromium } = require(\"playwright-core\");
(async () => {
  const browser = await chromium.connectOverCDP(\"http://127.0.0.1:9223\");
  const contexts = browser.contexts();
  console.log(\"Contexts:\", contexts.length);
  const page = contexts[0].pages()[0] || await contexts[0].newPage();
  await page.goto(\"https://example.com\", { waitUntil: \"networkidle\" });
  const title = await page.title();
  console.log(\"Title:\", title);
  console.log(\"CDP connection: OK\");
  await browser.close();
})();
"'
```

**検証:** `CDP connection: OK` が出力されること

---

## Phase 2: outbound-form-agent の Steel + Stagehand 移行

### Task 2.1: リポジトリクローン & 依存関係更新

**Objective:** 作業用クローンを作成し、package.json を更新

**Files:**
- 変更: `package.json`（dependencies 差し替え）
- 削除: `puppeteer-extra-plugin-stealth`, `playwright`（通常版）
- 追加: `@browserbasehq/stagehand`, `playwright-core`

**Step 1: リポジトリクローン**
```bash
cd /tmp
rm -rf outbound-form-agent-v2
git clone https://github.com/Gracecom1/outbound-form-agent.git outbound-form-agent-v2
cd outbound-form-agent-v2
```

**Step 2: 依存関係更新**

```json
{
  "dependencies": {
    "@browserbasehq/stagehand": "^3.0.0",
    "openai": "^6.45.0",
    "playwright-core": "^1.52.0",
    "zod": "^3.24.0"
  }
}
```

削除する依存: `playwright`, `playwright-extra`, `puppeteer-extra-plugin-stealth`

### Task 2.2: Steel 接続モジュール作成

**Objective:** Steel CDP への接続・セッション管理を抽象化する新モジュール

**Files:**
- 作成: `src/steel-client.ts`
- 作成: `src/types.ts`（Stagehand 用の型を追加）

**Step 1: steel-client.ts**

```typescript
import { chromium, type Browser, type BrowserContext, type Page } from "playwright-core";

const STEEL_CDP_URL = process.env.STEEL_CDP_URL || "http://127.0.0.1:9223";

let browser: Browser | null = null;

export async function getBrowser(): Promise<Browser> {
  if (!browser || !browser.isConnected()) {
    browser = await chromium.connectOverCDP(STEEL_CDP_URL);
  }
  return browser;
}

export async function createContext(): Promise<{ context: BrowserContext; page: Page }> {
  const b = await getBrowser();
  const contexts = b.contexts();
  const context = contexts[0] || await b.newContext({
    userAgent:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    viewport: { width: 1440, height: 900 },
    locale: "ja-JP",
    timezoneId: "Asia/Tokyo",
  });
  const pages = context.pages();
  const page = pages[0] || await context.newPage();
  return { context, page };
}

export async function closeBrowser(): Promise<void> {
  if (browser) {
    try {
      await browser.close();
    } catch {
      console.warn("ブラウザのクローズ中にエラーが発生しましたが無視します");
    }
    browser = null;
  }
}
```

### Task 2.3: Stagehand によるフォーム操作モジュール作成

**Objective:** 既存の form-selector.ts + form-submitter.ts の 17 種 CSS セレクタ + 手動入力ロジックを、Stagehand の AI-driven `act()` / `observe()` に置換

**Files:**
- 作成: `src/stagehand-agent.ts`
- 削除予定（旧コード）: `src/form-selector.ts`, `src/form-submitter.ts`, `src/captcha.ts`

**Step 1: Stagehand 初期化**

```typescript
import { Stagehand } from "@browserbasehq/stagehand";
import type { Page } from "playwright-core";
import type { Logger } from "./logger.js";

let stagehand: Stagehand | null = null;

export async function initStagehand(env: { DEEPSEEK_API_KEY: string }): Promise<Stagehand> {
  if (!stagehand) {
    stagehand = new Stagehand({
      env: "LOCAL",
      verbose: 1,
      model: "deepseek/deepseek-chat",
      modelProvider: {
        apiKey: env.DEEPSEEK_API_KEY,
        baseURL: "https://api.deepseek.com/v1",
      },
    });
    await stagehand.init();
  }
  return stagehand;
}
```

**Step 2: フォーム検出（Stagehand observe）**

```typescript
export async function detectFormWithStagehand(
  stagehand: Stagehand,
  page: Page,
  logger: Logger
): Promise<{ hasForm: boolean; formDescription: string; captchaDetected: boolean }> {
  const result = await stagehand.observe(
    "このページに問い合わせフォーム（お問い合わせ、Contact Us）がありますか？フォームの項目（名前、メール、電話、会社名、内容など）と送信ボタンの場所を特定してください。CAPTCHA（画像認証、reCAPTCHA、hCaptcha、Turnstile、「私はロボットではありません」など）がある場合も報告してください。",
    { page }
  );
  // ... 結果をパース
}
```

**Step 3: フォーム入力（Stagehand act）**

```typescript
export async function fillFormWithStagehand(
  stagehand: Stagehand,
  page: Page,
  fields: Map<string, string>,
  logger: Logger
): Promise<void> {
  const fieldDescriptions = Array.from(fields.entries())
    .map(([label, value]) => `- ${label}: "${value}"`)
    .join("\n");

  await stagehand.act(
    `フォームに以下の内容を入力してください：
${fieldDescriptions}
各フィールドのラベルを見て、適切なフィールドに値を入力してください。`,
    { page }
  );
}
```

**Step 4: 送信 & 結果確認**

```typescript
export async function submitAndVerify(
  stagehand: Stagehand,
  page: Page,
  logger: Logger
): Promise<{ success: boolean; message: string }> {
  await stagehand.act("送信ボタンをクリックしてください", { page });
  await page.waitForLoadState("networkidle", { timeout: 10000 }).catch(() => {});

  const result = await stagehand.observe(
    "このページは送信成功を示していますか？「ありがとう」「送信完了」「Thank you」「送信されました」などの成功メッセージがあれば 'success'、エラーメッセージがあれば 'error'、判断できない場合は 'unknown' と回答してください。",
    { page }
  );
  // ... 結果をパース
}
```

### Task 2.4: form-agent.ts を Stagehand 版に書き換え

**Objective:** メインのフォーム送信ロジックを Steel + Stagehand を使う形に書き換え

**Files:**
- 変更: `src/form-agent.ts`（全面書き換え）

**変更内容:**
- `import { chromium } from "playwright-extra"` → `import { createContext } from "./steel-client.js"`
- `import stealth from "puppeteer-extra-plugin-stealth"` → 削除（Steel 内蔵）
- `chromium.use(stealth())` → 削除
- ブラウザ起動（`chromium.launch`）→ `createContext()` に置換
- フォーム検出（`detectFieldsInAllFrames`）→ `detectFormWithStagehand()`
- フォーム入力（`fillFormFields`）→ `fillFormWithStagehand()`
- 送信（`clickSubmit`）→ `submitAndVerify()`
- `applyStealthScript()` → 削除（Steel 内蔵）
- フォーム検出の 3 層フォールバック → Stagehand の AI 検出に一本化

### Task 2.5: CLI オプション 6 種を実装

**Objective:** ドキュメントに記載されているが未実装の CLI オプションを追加

**Files:**
- 変更: `src/index.ts`

**追加するオプション（シンプルな argv パース）:**

```typescript
function parseArgs() {
  const args = process.argv.slice(2);
  const getVal = (flag: string): string | undefined => {
    const idx = args.indexOf(flag);
    return idx !== -1 && idx + 1 < args.length ? args[idx + 1] : undefined;
  };

  return {
    dryRun: args.includes("--dry-run") || args.includes("--dry"),
    single: args.includes("--single"),
    max: getVal("--max") ? parseInt(getVal("--max")!) : undefined,
    company: getVal("--company"),
    concurrency: getVal("--concurrency") ? parseInt(getVal("--concurrency")!) : undefined,
    timeout: getVal("--timeout") ? parseInt(getVal("--timeout")!) : undefined,
    logLevel: getVal("--log-level"),
    output: getVal("--output"),
  };
}
```

### Task 2.6: 再試行ロジック追加

**Objective:** 1 回のネットワークエラーで終了せず、最大 3 回まで再試行

**Files:**
- 変更: `src/form-agent.ts`

**実装:**
```typescript
const MAX_RETRIES = 3;
for (let retry = 0; retry < MAX_RETRIES; retry++) {
  try {
    // フォーム送信処理
    break;
  } catch (error) {
    if (retry < MAX_RETRIES - 1 && isRetryableError(error)) {
      logger.warn(`再試行 ${retry + 1}/${MAX_RETRIES}`);
      await sleep(2000 * (retry + 1)); // exponential backoff
    } else {
      throw error;
    }
  }
}
```

リトライ可能なエラー: timeout, network error, ERR_*, ECONNREFUSED, ENOTFOUND
リトライ不可: CAPTCHA 検出済み, no_form

### Task 2.7: Slack 通知追加

**Objective:** 処理完了時に Slack に通知。AGENTS.md ルール N 準拠。

**Files:**
- 作成: `src/notify.ts`

**実装:**
```typescript
export async function notifySlack(
  webhookUrl: string,
  result: RunResult
): Promise<void> {
  const message = {
    text: `📊 フォーム自動送信 完了`,
    blocks: [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: [
            `*Outbound Form Agent — 実行結果*`,
            `✅ 送信成功: ${result.sent}`,
            `🔒 CAPTCHA: ${result.skipped.captcha}`,
            `📭 フォームなし: ${result.skipped.noForm}`,
            `🚫 ブロック: ${result.skipped.blocked}`,
            `⏱️ タイムアウト: ${result.skipped.timeout}`,
            `❌ エラー: ${result.skipped.error}`,
            `⏱ 処理時間: ${duration}s`,
          ].join("\n"),
        },
      },
    ],
  };
  await fetch(webhookUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(message),
  });
}
```

環境変数: `SLACK_WEBHOOK_URL`

### Task 2.8: 環境変数に Steel CDP URL 追加

**Objective:** `.env` に Steel 接続情報を追加

**Files:**
- 変更: `src/types.ts`（envSchema に STEEL_CDP_URL 追加）
- 変更: `.env.example`

### Task 2.9: Dockerfile 作成

**Objective:** ブラウザバイナリ不要の軽量 Docker イメージ（Node.js + Stagehand + playwright-core のみ）

**Files:**
- 作成: `Dockerfile`

```dockerfile
FROM node:24-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY dist/ ./dist/
ENV STEEL_CDP_URL=http://172.17.0.1:9223
ENTRYPOINT ["node", "dist/index.js"]
```

> 注: `172.17.0.1` は Docker ホストのブリッジ IP。Steel が `127.0.0.1:9223` で待つ場合、同一ホスト上の別コンテナからは `host.docker.internal` またはホスト IP でアクセス。

### Task 2.10: ビルド & 動作テスト

**Objective:** TypeScript ビルドし、Docker イメージを作成して Hetzner で動作確認

```bash
cd /tmp/outbound-form-agent-v2
npm install
npm run build
# Docker イメージビルド
docker build -t outbound-form-agent:v2 .
# テスト実行
docker run --rm --env-file .env outbound-form-agent:v2 --dry-run
```

---

## Phase 3: paradigm-docs ダッシュボード

### Task 3.1: API Route 作成

**Objective:** ダッシュボードの「実行」ボタンから呼ばれる API エンドポイント

**Files:**
- 作成: `app/api/run-agent/route.ts`

```typescript
import { NextResponse } from "next/server";
import { execSync } from "child_process";

export async function POST(request: Request) {
  try {
    const body = await request.json() as { mode?: string; company?: string };
    const mode = body.mode || "";

    // Docker run 実行
    const cmd = `docker run --rm \\
      --env-file /opt/outbound-form-agent/.env \\
      --add-host host.docker.internal:host-gateway \\
      -e STEEL_CDP_URL=http://host.docker.internal:9223 \\
      outbound-form-agent:v2 \\
      ${mode === "dry-run" ? "--dry-run" : ""} \\
      ${mode === "single" ? "--single" : ""} \\
      ${body.company ? `--company "${body.company}"` : ""}`;

    const output = execSync(cmd, {
      timeout: 600_000, // 10分
      encoding: "utf-8",
    });

    return NextResponse.json({ ok: true, output });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return NextResponse.json({ ok: false, error: message }, { status: 500 });
  }
}
```

### Task 3.2: ダッシュボードページ作成

**Objective:** 処理待ち企業の一覧 + 実行ボタン + 履歴を表示

**Files:**
- 作成: `app/dashboard/page.tsx`

ページ構成:
1. **処理待ち企業一覧** — Twenty CRM から `paradigmSalesStatus` が `送信待ち` / `カルテ生成中` / `手動確認` の企業を取得してテーブル表示
2. **実行ボタン** — 「全件実行」「ドライラン」「1 社テスト」の 3 ボタン
3. **実行履歴** — 過去の実行ログ（in-memory or SQLite）

### Task 3.3: Twenty CRM からのリアルタイム企業データ取得

**Objective:** ダッシュボード表示用に Twenty CRM から企業データを取得するサーバーサイド関数

**Files:**
- 作成: `lib/twenty.ts`

### Task 3.4: Traefik ルーティング設定

**Objective:** ダッシュボードページを docs.paradigmjp.com/dashboard でアクセス可能に

**Files:**
- 変更: サーバーの Traefik 設定（すでに `docs.paradigmjp.com` がルーティング済みなので、`/dashboard` は Next.js のルーティングで自動対応）

---

## Phase 4: 統合テスト & デプロイ

### Task 4.1: エンドツーエンドテスト

**Objective:** 実際の Twenty CRM データを使った完全テスト

1. `--dry-run` で処理対象企業一覧が正しいことを確認
2. `--single` で 1 社のフォーム送信が成功することを確認
3. Twenty CRM に結果が正しく書き戻されることを確認

### Task 4.2: outbound-form-agent Docker イメージを Hetzner に配置

```bash
# ローカルでビルド
docker build -t outbound-form-agent:v2 .
docker save outbound-form-agent:v2 | gzip > /tmp/outbound-form-agent-v2.tar.gz
# サーバーに転送
scp /tmp/outbound-form-agent-v2.tar.gz root@178.105.138.55:/tmp/
ssh root@178.105.138.55 'docker load < /tmp/outbound-form-agent-v2.tar.gz && rm /tmp/outbound-form-agent-v2.tar.gz'
```

### Task 4.3: paradigm-docs に変更をデプロイ

既存のデプロイフロー（GitHub clone → Docker build → コンテナ差し替え）を使用。

---

## Phase 5: ドキュメント更新

### Task 5.1: paradigm-docs の API ページを実態に合わせて修正

**Files:**
- 変更: `content/docs/outbound-form-agent/index.mdx`（Steel + Stagehand アーキテクチャに更新）
- 変更: `content/docs/outbound-form-agent/architecture.mdx`（新アーキテクチャ図）
- 変更: `content/docs/outbound-form-agent/api.mdx`（実装済み CLI オプションのみ記載）

### Task 5.2: ダッシュボード利用ガイド追加

**Files:**
- 作成: `content/docs/outbound-form-agent/dashboard.mdx`

---

## リスク & 注意点

| リスク | 対策 |
|--------|------|
| Steel の Docker イメージサイズが予想以上 | 事前に docker pull でサイズ確認。大きすぎる場合は `--no-cache` でビルド検討 |
| Stagehand + DeepSeek の互換性 | DeepSeek が OpenAI 互換 API を提供しているため動作するはず。ダメなら Stagehand を使わず Playwright 直操作にフォールバック |
| 複数企業処理時の Steel セッション管理 | 1 企業ごとに新しい context + page を作成。処理後は close()。Steel のセッション上限に注意（デフォルト制限あり） |
| Docker の `host.docker.internal` 非対応 | Linux では `--add-host host.docker.internal:host-gateway` が必要 |
| 本番環境で Steel のポートが他からアクセスされる | `127.0.0.1:9223` でバインドし、外部非公開を厳守 |
| ディスク逼迫 | ログローテーション（50MB×3）、Docker image prune を cron ではなく手動 or デプロイ時に実施 |
