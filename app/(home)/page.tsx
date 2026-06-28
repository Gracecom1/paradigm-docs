import Link from 'next/link';
import { ArrowRight, BookOpen, Code2, Cpu, Database } from 'lucide-react';

const services = [
  {
    title: 'Outbound Form Agent',
    description: 'Twenty CRM SSOT → フォーム自動送信エージェント',
    href: '/docs/outbound-form-agent',
    icon: Cpu,
  },
  {
    title: 'Twenty CRM',
    description: 'セルフホスト CRM · REST API 連携',
    href: '/docs/twenty-crm',
    icon: Database,
  },
  {
    title: 'CLI ツール群',
    description: 'CLI 完結の完全自動化パイプライン',
    href: '/docs/cli-tools',
    icon: Code2,
  },
];

export default function HomePage() {
  return (
    <div className="flex flex-col items-center flex-1">
      {/* Hero */}
      <section className="w-full max-w-4xl px-6 py-24 md:py-32 text-center">
        <h1 className="text-4xl md:text-6xl font-bold tracking-tight mb-6">
          Paradigm{' '}
          <span className="text-blue-500">Docs</span>
        </h1>
        <p className="text-lg md:text-xl text-muted-foreground max-w-2xl mx-auto mb-10">
          全プロジェクトのドキュメントを一箇所に集約。
          AI エージェントによる自動更新 · 日本語最適化 · CLI 完結。
        </p>
        <Link
          href="/docs"
          className="inline-flex items-center gap-2 px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors font-medium"
        >
          <BookOpen className="w-5 h-5" />
          ドキュメントを見る
          <ArrowRight className="w-4 h-4" />
        </Link>
      </section>

      {/* Services */}
      <section className="w-full max-w-5xl px-6 pb-24">
        <h2 className="text-2xl font-bold mb-8 text-center">プロジェクト一覧</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {services.map((svc) => (
            <Link
              key={svc.title}
              href={svc.href}
              className="group p-6 border rounded-xl hover:border-blue-500/50 hover:bg-blue-50/50 dark:hover:bg-blue-950/20 transition-all"
            >
              <svc.icon className="w-8 h-8 text-blue-500 mb-4 group-hover:scale-110 transition-transform" />
              <h3 className="font-semibold mb-2">{svc.title}</h3>
              <p className="text-sm text-muted-foreground">{svc.description}</p>
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}
