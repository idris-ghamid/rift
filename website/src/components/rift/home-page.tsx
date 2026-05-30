'use client';

import React, { useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import {
  Database, Zap, Shield, Search, Lock, Sparkles, ArrowRight,
  Github, Filter, Radio, HardDrive, Cpu, GitBranch, Network,
  Layers, Lock as LockIcon, Terminal, Timer, Eye, Activity,
  Braces, MemoryStick, Globe, Puzzle, TestTube, Check,
  RefreshCw, History, Binary, FolderSync, MapPin, Sigma,
  Clock, TreePine, Wand2, Key, Share2, Flower2, Trash2,
  Mountain, Archive, CloudDownload, ScrollText, Box, Camera,
  Gauge, Code2, Paintbrush, FileText, ChevronRight,
  Zap as BoltIcon, Shield as ShieldIcon, Search as SearchIcon,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from '@/components/ui/table';

// ─── Animation helpers ──────────────────────────────────────────────────────

function AnimateOnScroll({ children, className = '', delay = 0 }: { children: React.ReactNode; className?: string; delay?: number }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: '-60px' });

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 40 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 40 }}
      transition={{ duration: 0.7, delay, ease: [0.25, 0.46, 0.45, 0.94] }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

// ─── Dart Syntax Highlighter ────────────────────────────────────────────────

function DartCode({ code, filename = 'main.dart' }: { code: string; filename?: string }) {
  const highlightDart = (line: string) => {
    const keywords = ['import', 'as', 'void', 'async', 'await', 'final', 'var', 'const', 'class', 'return', 'if', 'else', 'for', 'while', 'true', 'false', 'null', 'int', 'String', 'double', 'bool', 'List', 'Map', 'Set', 'dynamic', 'static', 'get', 'set', 'abstract', 'factory', 'this', 'super', 'new', 'is'];
    const types = ['Rift', 'RiftBox', 'RiftQuery', 'RiftCursor', 'Box'];

    if (line.trimStart().startsWith('//')) {
      return <span className="text-muted-foreground/50 italic">{line}</span>;
    }

    const tokens = line.split(/(\s+|[{}()\[\];,.<>=!+\-*\/&|?:])/);
    return (
      <>
        {tokens.map((token, tIdx) => {
          if (!token) return null;
          if (keywords.includes(token)) {
            return <span key={tIdx} className="text-apple-purple dark:text-[#5E5CE6]">{token}</span>;
          }
          if (types.some(t => token.startsWith(t))) {
            return <span key={tIdx} className="text-apple-green dark:text-[#30D158]">{token}</span>;
          }
          if (/^'.*'$/.test(token) || /^".*"$/.test(token)) {
            return <span key={tIdx} className="text-apple-orange dark:text-[#FF9F0A]">{token}</span>;
          }
          if (/^\d+$/.test(token)) {
            return <span key={tIdx} className="text-apple-teal dark:text-[#64D2FF]">{token}</span>;
          }
          return <span key={tIdx}>{token}</span>;
        })}
      </>
    );
  };

  return (
    <div className="rounded-2xl border border-border/40 bg-[#1e1e2e] dark:bg-black/80 overflow-hidden shadow-2xl">
      <div className="flex items-center gap-2 px-4 py-3 border-b border-white/10 bg-white/5">
        <div className="flex gap-2">
          <div className="w-3 h-3 rounded-full bg-[#FF5F56]" />
          <div className="w-3 h-3 rounded-full bg-[#FFBD2E]" />
          <div className="w-3 h-3 rounded-full bg-[#27C93F]" />
        </div>
        <span className="text-xs text-white/40 ml-3 font-mono">{filename}</span>
      </div>
      <pre className="p-5 overflow-x-auto text-sm leading-[1.8] font-mono text-white/90">
        {code.split('\n').map((line, idx) => (
          <div key={idx} className="min-h-[1.6em]">
            <span className="text-white/20 select-none mr-5 text-xs inline-block w-6 text-right">{idx + 1}</span>
            {highlightDart(line)}
          </div>
        ))}
      </pre>
    </div>
  );
}

function CodeBlock({ code, filename }: { code: string; filename: string }) {
  return (
    <div className="rounded-2xl border border-border/40 bg-[#1e1e2e] dark:bg-black/80 overflow-hidden shadow-2xl">
      <div className="flex items-center gap-2 px-4 py-3 border-b border-white/10 bg-white/5">
        <div className="flex gap-2">
          <div className="w-3 h-3 rounded-full bg-[#FF5F56]" />
          <div className="w-3 h-3 rounded-full bg-[#FFBD2E]" />
          <div className="w-3 h-3 rounded-full bg-[#27C93F]" />
        </div>
        <span className="text-xs text-white/40 ml-3 font-mono">{filename}</span>
      </div>
      <pre className="p-5 overflow-x-auto text-sm leading-[1.8] font-mono text-white/90">
        {code}
      </pre>
    </div>
  );
}

// ─── Comparison Data ────────────────────────────────────────────────────────

const COMPARISON_FEATURES = [
  'Queries', 'Live Queries', 'Secondary Indexes', 'Composite Indexes',
  'Relations', 'ACID Transactions', 'WAL', 'Schema Migration',
  'Multi-Isolate', 'Compression', 'TTL', 'Middleware',
  'Full-Text Search', 'Backup', 'Encryption', 'Bulk Operations',
  'LRU Cache', 'Cursor', 'CLI', 'CRDT', 'Vector Search',
  'Time Travel', 'Sync', 'Aggregation', 'CDC', 'Geospatial',
  'Audit Log', 'Profiler', 'Plugin System', 'Bloom Filters',
  'Graph', 'Time-Series', 'Reactive Signals', 'Pure Dart', 'Zero Native Deps',
];

const DB_COMPARISON: Record<string, Record<string, boolean>> = {
  'Rift': Object.fromEntries(COMPARISON_FEATURES.map(f => [f, true])),
  'Hive v2': Object.fromEntries(COMPARISON_FEATURES.map(f => [f, ['Pure Dart', 'Zero Native Deps'].includes(f)])),
  'hive_ce': Object.fromEntries(COMPARISON_FEATURES.map(f => [f, ['Pure Dart', 'Zero Native Deps', 'Queries', 'Encryption'].includes(f)])),
  'Isar': Object.fromEntries(COMPARISON_FEATURES.map(f => [f, ['Queries', 'Multi-Isolate', 'Full-Text Search'].includes(f)])),
  'Drift': Object.fromEntries(COMPARISON_FEATURES.map(f => [f, ['Queries', 'ACID Transactions', 'Schema Migration'].includes(f)])),
};

// ─── Feature Data ───────────────────────────────────────────────────────────

interface FeatureCategoryData {
  name: string;
  color: string;
  bgColor: string;
  borderColor: string;
  features: { name: string; icon: React.ElementType }[];
}

const FEATURE_CATEGORIES: FeatureCategoryData[] = [
  {
    name: 'Query & Search',
    color: 'text-apple-blue dark:text-[#0A84FF]',
    bgColor: 'bg-apple-blue/10 dark:bg-[#0A84FF]/10',
    borderColor: 'border-apple-blue/20 dark:border-[#0A84FF]/20',
    features: [
      { name: 'Query Builder', icon: Filter },
      { name: 'Live Query', icon: Radio },
      { name: 'Full-Text Search', icon: Search },
      { name: 'Secondary Index', icon: Database },
      { name: 'Cursor', icon: Eye },
      { name: 'Query Optimization', icon: Sparkles },
      { name: 'Vector Search', icon: Sparkles },
      { name: 'Geospatial', icon: MapPin },
      { name: 'Graph', icon: TreePine },
    ],
  },
  {
    name: 'Data & Schema',
    color: 'text-apple-purple dark:text-[#5E5CE6]',
    bgColor: 'bg-apple-purple/10 dark:bg-[#5E5CE6]/10',
    borderColor: 'border-apple-purple/20 dark:border-[#5E5CE6]/20',
    features: [
      { name: 'Transactions', icon: Shield },
      { name: 'Cross-Box TX', icon: Share2 },
      { name: 'Schema Migration', icon: GitBranch },
      { name: 'Relations', icon: Network },
      { name: 'Bulk Ops', icon: Layers },
      { name: 'Typed Boxes', icon: Box },
      { name: 'Validation', icon: Check },
      { name: 'Middleware', icon: Braces },
      { name: 'Partitioning', icon: Layers },
      { name: 'Aggregation', icon: Sigma },
      { name: 'Diff & Patch', icon: GitBranch },
      { name: 'Versioning', icon: History },
      { name: 'Transform', icon: RefreshCw },
      { name: 'Rate Limiting', icon: Gauge },
    ],
  },
  {
    name: 'Security & Privacy',
    color: 'text-apple-red dark:text-[#FF453A]',
    bgColor: 'bg-apple-red/10 dark:bg-[#FF453A]/10',
    borderColor: 'border-apple-red/20 dark:border-[#FF453A]/20',
    features: [
      { name: 'Encryption', icon: Lock },
      { name: 'Field Encryption', icon: Key },
      { name: 'Access Control', icon: LockIcon },
      { name: 'Data Masking', icon: Eye },
      { name: 'Sanitization', icon: Shield },
      { name: 'Audit Log', icon: ScrollText },
    ],
  },
  {
    name: 'Performance & Storage',
    color: 'text-apple-orange dark:text-[#FF9F0A]',
    bgColor: 'bg-apple-orange/10 dark:bg-[#FF9F0A]/10',
    borderColor: 'border-apple-orange/20 dark:border-[#FF9F0A]/20',
    features: [
      { name: 'Compression', icon: Archive },
      { name: 'LRU Cache', icon: MemoryStick },
      { name: 'Read Cache', icon: Database },
      { name: 'Adaptive Caching', icon: Zap },
      { name: 'In-Memory', icon: Cpu },
      { name: 'WAL', icon: HardDrive },
      { name: 'Background Compaction', icon: Trash2 },
      { name: 'Binary Storage', icon: Binary },
      { name: 'Dictionary Compression', icon: Archive },
      { name: 'Pluggable Storage', icon: Puzzle },
      { name: 'TTL', icon: Timer },
      { name: 'Time Travel', icon: History },
      { name: 'Time-Series', icon: Clock },
    ],
  },
  {
    name: 'Sync & Distribution',
    color: 'text-apple-green dark:text-[#30D158]',
    bgColor: 'bg-apple-green/10 dark:bg-[#30D158]/10',
    borderColor: 'border-apple-green/20 dark:border-[#30D158]/20',
    features: [
      { name: 'Sync Layer', icon: FolderSync },
      { name: 'CDC', icon: Activity },
      { name: 'Replication', icon: FolderSync },
      { name: 'CRDT', icon: RefreshCw },
      { name: 'Event Sourcing', icon: History },
      { name: 'Connection Pooling', icon: Database },
      { name: 'Observable Store', icon: Eye },
    ],
  },
  {
    name: 'Developer Tools',
    color: 'text-apple-violet dark:text-[#BF5AF2]',
    bgColor: 'bg-apple-violet/10 dark:bg-[#BF5AF2]/10',
    borderColor: 'border-apple-violet/20 dark:border-[#BF5AF2]/20',
    features: [
      { name: 'Testing', icon: TestTube },
      { name: 'Code Generator', icon: Wand2 },
      { name: 'Codec Mode', icon: Code2 },
      { name: 'Inspector', icon: Eye },
      { name: 'Profiler', icon: Gauge },
      { name: 'Metrics', icon: Activity },
      { name: 'Dart 3 Records', icon: Braces },
      { name: 'Extension Types', icon: Paintbrush },
      { name: 'Plugin System', icon: Puzzle },
      { name: 'CLI', icon: Terminal },
    ],
  },
  {
    name: 'Platform & Integration',
    color: 'text-apple-teal dark:text-[#64D2FF]',
    bgColor: 'bg-apple-teal/10 dark:bg-[#64D2FF]/10',
    borderColor: 'border-apple-teal/20 dark:border-[#64D2FF]/20',
    features: [
      { name: 'Web Perf', icon: Globe },
      { name: 'OPFS', icon: HardDrive },
      { name: 'mmap', icon: MemoryStick },
      { name: 'Isolate', icon: Cpu },
      { name: 'Aurora OS', icon: Mountain },
      { name: 'SharedArrayBuffer', icon: Share2 },
      { name: 'Backup', icon: CloudDownload },
      { name: 'Incremental Export', icon: CloudDownload },
      { name: 'File Versioning', icon: FileText },
      { name: 'Hive Migration', icon: ArrowRight },
      { name: 'State Management', icon: Activity },
      { name: 'Signals', icon: Radio },
      { name: 'Reactive Forms', icon: FileText },
    ],
  },
];

// ─── Architecture Layers ────────────────────────────────────────────────────

const ARCH_LAYERS = [
  { name: 'API Layer', items: 'Box<E> │ RiftQuery │ Migration │ Middleware │ CLI', color: 'from-apple-blue to-apple-purple', textColor: 'text-apple-blue' },
  { name: 'Query Engine', items: 'Filters │ Sort │ Live Queries │ FTS │ Aggregation', color: 'from-apple-purple to-apple-violet', textColor: 'text-apple-purple' },
  { name: 'Advanced Features', items: 'CRDT │ Vector Search │ CDC │ Time Travel │ Graph', color: 'from-apple-violet to-apple-red', textColor: 'text-apple-violet' },
  { name: 'Index Engine', items: 'Primary (SkipList) │ Secondary (B-Tree/Hash)', color: 'from-apple-red to-apple-orange', textColor: 'text-apple-orange' },
  { name: 'Core Engine', items: 'WAL │ Transactions │ Encryption │ Compression │ TTL', color: 'from-apple-orange to-apple-green', textColor: 'text-apple-green' },
  { name: 'Storage Engine (Pluggable)', items: 'BitcaskVM │ IndexedDB │ Memory │ OPFS', color: 'from-apple-green to-apple-teal', textColor: 'text-apple-green' },
];

// ─── Hero Section ───────────────────────────────────────────────────────────

function HeroSection() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Background effects */}
      <div className="absolute inset-0">
        <div className="absolute top-1/4 left-1/4 w-[600px] h-[600px] bg-primary/8 rounded-full blur-[150px]" />
        <div className="absolute bottom-1/4 right-1/4 w-[500px] h-[500px] bg-apple-purple/6 rounded-full blur-[130px]" />
        <div className="absolute top-1/2 right-1/2 w-[400px] h-[400px] bg-apple-violet/4 rounded-full blur-[100px]" />
      </div>
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-background/40 to-background" />

      <div className="relative z-10 max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-32 text-center">
        {/* Version badge */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="mb-8"
        >
          <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-primary/30 bg-primary/8 text-primary text-sm font-medium">
            <BoltIcon className="w-3.5 h-3.5" />
            v1.0 — Now Available
          </span>
        </motion.div>

        {/* Title */}
        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.1 }}
          className="text-7xl sm:text-8xl md:text-9xl font-black tracking-tight mb-6"
        >
          <span className="apple-gradient-text">Rift</span>
        </motion.h1>

        {/* Lightning icon */}
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="mb-6"
        >
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-primary/10 border border-primary/20">
            <Zap className="w-7 h-7 text-primary" />
          </div>
        </motion.div>

        {/* Tagline */}
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.25 }}
          className="text-2xl md:text-3xl lg:text-4xl font-semibold text-foreground/90 mb-4 leading-tight"
        >
          The next-generation NoSQL database
          <br />
          <span className="text-primary">for Flutter &amp; Dart</span>
        </motion.p>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.35 }}
          className="text-base md:text-lg text-muted-foreground mb-10 max-w-xl mx-auto leading-relaxed"
        >
          Pure Dart. Blazing fast. Reactive queries. Zero native dependencies.
        </motion.p>

        {/* CTAs */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.45 }}
          className="flex flex-col sm:flex-row gap-4 justify-center mb-12"
        >
          <Button
            size="lg"
            className="bg-primary hover:bg-primary/90 text-base px-8 h-12 rounded-full shadow-lg shadow-primary/25"
            onClick={() => document.getElementById('quickstart')?.scrollIntoView({ behavior: 'smooth' })}
          >
            Get Started
            <ArrowRight className="w-5 h-5 ml-1" />
          </Button>
          <Button
            variant="outline"
            size="lg"
            className="text-base px-8 h-12 rounded-full border-border/50 hover:bg-secondary/80"
            asChild
          >
            <a
              href="https://github.com/idris-ghamid/rift"
              target="_blank"
              rel="noopener noreferrer"
              className="gap-2"
            >
              <Github className="w-5 h-5" />
              View on GitHub
            </a>
          </Button>
        </motion.div>

        {/* Stats badges */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="flex flex-wrap gap-3 justify-center"
        >
          {[
            { value: '75+', label: 'Features' },
            { value: '100%', label: 'Pure Dart' },
            { value: '6', label: 'Platforms' },
            { value: 'Zero', label: 'Native Deps' },
          ].map((stat) => (
            <div
              key={stat.label}
              className="flex items-center gap-2 px-4 py-2 rounded-full bg-card/60 border border-border/40 backdrop-blur-sm"
            >
              <span className="font-bold text-primary text-sm">{stat.value}</span>
              <span className="text-muted-foreground text-xs">{stat.label}</span>
            </div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}

// ─── Feature Highlights Grid ────────────────────────────────────────────────

const HIGHLIGHT_FEATURES = [
  {
    icon: Filter,
    title: 'Query Builder',
    description: 'Fluent query builder for filtering, sorting, and paginating data',
    gradient: 'from-apple-blue to-apple-purple',
    iconBg: 'bg-apple-blue/10',
  },
  {
    icon: Radio,
    title: 'Live Queries',
    description: 'Reactive queries that auto-update when data changes',
    gradient: 'from-apple-purple to-apple-violet',
    iconBg: 'bg-apple-purple/10',
  },
  {
    icon: Shield,
    title: 'ACID Transactions',
    description: 'Atomic operations with savepoints and rollback',
    gradient: 'from-apple-violet to-apple-red',
    iconBg: 'bg-apple-violet/10',
  },
  {
    icon: HardDrive,
    title: 'WAL Recovery',
    description: 'Write-Ahead Log for crash safety and data durability',
    gradient: 'from-apple-red to-apple-orange',
    iconBg: 'bg-apple-red/10',
  },
  {
    icon: Lock,
    title: 'Encryption',
    description: 'AES-256 with PBKDF2 key derivation and HMAC verification',
    gradient: 'from-apple-orange to-apple-green',
    iconBg: 'bg-apple-orange/10',
  },
  {
    icon: Sparkles,
    title: 'Vector Search',
    description: 'Cosine similarity search for AI and embedding applications',
    gradient: 'from-apple-green to-apple-teal',
    iconBg: 'bg-apple-green/10',
  },
];

function FeatureHighlightsSection() {
  return (
    <section className="py-24 md:py-32 relative" id="features">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <AnimateOnScroll className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 tracking-tight">
            Built for
            <span className="apple-gradient-text"> modern apps</span>
          </h2>
          <p className="text-lg md:text-xl text-muted-foreground max-w-2xl mx-auto">
            Every feature you need. Nothing you don&apos;t.
          </p>
        </AnimateOnScroll>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {HIGHLIGHT_FEATURES.map((feature, idx) => {
            const Icon = feature.icon;
            return (
              <AnimateOnScroll key={feature.title} delay={idx * 0.08}>
                <Card className="group h-full border-border/30 bg-card/50 backdrop-blur-sm apple-card-hover overflow-hidden">
                  <CardContent className="p-6">
                    <div className={`w-12 h-12 rounded-2xl ${feature.iconBg} flex items-center justify-center mb-5 group-hover:scale-110 transition-transform duration-300`}>
                      <Icon className="w-6 h-6 text-primary" />
                    </div>
                    <h3 className="text-lg font-semibold mb-2">{feature.title}</h3>
                    <p className="text-sm text-muted-foreground leading-relaxed">{feature.description}</p>
                  </CardContent>
                </Card>
              </AnimateOnScroll>
            );
          })}
        </div>
      </div>
    </section>
  );
}

// ─── Comparison Table ───────────────────────────────────────────────────────

function ComparisonSection() {
  const [showAll, setShowAll] = React.useState(false);
  const displayedFeatures = showAll ? COMPARISON_FEATURES : COMPARISON_FEATURES.slice(0, 12);

  return (
    <section className="py-24 md:py-32 relative" id="comparison">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <AnimateOnScroll className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 tracking-tight">
            How Rift
            <span className="apple-gradient-text"> compares</span>
          </h2>
          <p className="text-lg md:text-xl text-muted-foreground max-w-2xl mx-auto">
            See how Rift stacks up against the most popular Dart databases
          </p>
        </AnimateOnScroll>

        <AnimateOnScroll>
          <div className="overflow-x-auto rounded-2xl border border-border/40 bg-card/50 backdrop-blur-sm shadow-lg">
            <Table>
              <TableHeader>
                <TableRow className="border-border/30 hover:bg-transparent">
                  <TableHead className="w-[180px] font-semibold">Feature</TableHead>
                  {Object.keys(DB_COMPARISON).map((db) => (
                    <TableHead key={db} className="text-center font-semibold min-w-[80px]">
                      <span className={db === 'Rift' ? 'text-primary' : ''}>{db}</span>
                    </TableHead>
                  ))}
                </TableRow>
              </TableHeader>
              <TableBody>
                {displayedFeatures.map((feature) => (
                  <TableRow key={feature} className="border-border/20 hover:bg-primary/5">
                    <TableCell className="font-medium text-sm">{feature}</TableCell>
                    {Object.entries(DB_COMPARISON).map(([db, features]) => (
                      <TableCell key={db} className="text-center">
                        {features[feature] ? (
                          <span className={db === 'Rift' ? 'text-primary' : 'text-apple-green dark:text-[#30D158]'}>
                            ✅
                          </span>
                        ) : (
                          <span className="text-muted-foreground/30">❌</span>
                        )}
                      </TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>

          {!showAll && (
            <div className="text-center mt-6">
              <Button
                variant="outline"
                onClick={() => setShowAll(true)}
                className="gap-2 rounded-full border-border/40 hover:bg-primary/10"
              >
                Show all {COMPARISON_FEATURES.length} features
                <ChevronRight className="w-4 h-4" />
              </Button>
            </div>
          )}
        </AnimateOnScroll>
      </div>
    </section>
  );
}

// ─── Quick Start Section ────────────────────────────────────────────────────

function QuickStartSection() {
  return (
    <section className="py-24 md:py-32 relative" id="quickstart">
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-primary/[0.02] to-transparent" />
      <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <AnimateOnScroll className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 tracking-tight">
            Quick
            <span className="apple-gradient-text"> Start</span>
          </h2>
          <p className="text-lg md:text-xl text-muted-foreground max-w-2xl mx-auto">
            Up and running in under 60 seconds
          </p>
        </AnimateOnScroll>

        <div className="space-y-8">
          <AnimateOnScroll>
            <div className="flex items-center gap-4 mb-4">
              <div className="w-10 h-10 rounded-full bg-primary/15 flex items-center justify-center text-primary font-bold text-sm shrink-0">
                1
              </div>
              <h3 className="text-xl font-semibold">Add dependency</h3>
            </div>
            <CodeBlock
              code={`# pubspec.yaml
dependencies:
  rift: ^1.0.0`}
              filename="pubspec.yaml"
            />
          </AnimateOnScroll>

          <AnimateOnScroll delay={0.1}>
            <div className="flex items-center gap-4 mb-4">
              <div className="w-10 h-10 rounded-full bg-primary/15 flex items-center justify-center text-primary font-bold text-sm shrink-0">
                2
              </div>
              <h3 className="text-xl font-semibold">Hello Rift</h3>
            </div>
            <DartCode
              code={`import 'package:rift/rift.dart';

void main() async {
  await Rift.init();
  final users = await Rift.openBox<Map>('users');
  await users.put('u1', {'name': 'Idris', 'age': 25});
  
  final adults = users.query()
    .where('age', greaterThan: 18)
    .sortBy('name')
    .limit(10)
    .findAll();
}`}
            />
          </AnimateOnScroll>
        </div>
      </div>
    </section>
  );
}

// ─── Architecture Section ───────────────────────────────────────────────────

function ArchitectureSection() {
  return (
    <section className="py-24 md:py-32 relative">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <AnimateOnScroll className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 tracking-tight">
            Layered
            <span className="apple-gradient-text"> Architecture</span>
          </h2>
          <p className="text-lg md:text-xl text-muted-foreground max-w-2xl mx-auto">
            Designed for maximum extensibility and performance
          </p>
        </AnimateOnScroll>

        <AnimateOnScroll>
          <div className="rounded-2xl border border-border/40 bg-card/50 backdrop-blur-sm overflow-hidden shadow-lg">
            {ARCH_LAYERS.map((layer, idx) => (
              <div
                key={layer.name}
                className={`arch-layer border-b border-border/20 last:border-b-0 ${
                  idx === 0 ? 'rounded-t-2xl' : ''
                } ${idx === ARCH_LAYERS.length - 1 ? 'rounded-b-2xl' : ''}`}
              >
                <div className="flex flex-col sm:flex-row items-start sm:items-center p-4 sm:p-5 gap-2 sm:gap-0">
                  <div className="sm:w-48 shrink-0">
                    <div className="flex items-center gap-3">
                      <div className={`w-2 h-8 rounded-full bg-gradient-to-b ${layer.color}`} />
                      <span className={`font-semibold text-sm ${layer.textColor}`}>
                        {layer.name}
                      </span>
                    </div>
                  </div>
                  <div className="sm:flex-1 sm:pl-4 sm:border-l border-border/20">
                    <span className="text-xs sm:text-sm text-muted-foreground font-mono leading-relaxed">
                      {layer.items}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </AnimateOnScroll>
      </div>
    </section>
  );
}

// ─── All Features Section ───────────────────────────────────────────────────

function AllFeaturesSection() {
  const [activeCategory, setActiveCategory] = React.useState<string | null>(null);

  const displayedCategories = activeCategory
    ? FEATURE_CATEGORIES.filter(c => c.name === activeCategory)
    : FEATURE_CATEGORIES;

  return (
    <section className="py-24 md:py-32 relative" id="all-features">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <AnimateOnScroll className="text-center mb-12">
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 tracking-tight">
            75+
            <span className="apple-gradient-text"> Features</span>
          </h2>
          <p className="text-lg md:text-xl text-muted-foreground max-w-2xl mx-auto">
            Organized by category. Everything you need to build great apps.
          </p>
        </AnimateOnScroll>

        {/* Category filter */}
        <AnimateOnScroll className="flex flex-wrap gap-2 justify-center mb-12">
          <button
            onClick={() => setActiveCategory(null)}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-all duration-200 ${
              !activeCategory
                ? 'bg-primary text-primary-foreground shadow-md shadow-primary/25'
                : 'bg-secondary/60 text-muted-foreground hover:text-foreground hover:bg-secondary'
            }`}
          >
            All
          </button>
          {FEATURE_CATEGORIES.map((cat) => (
            <button
              key={cat.name}
              onClick={() => setActiveCategory(activeCategory === cat.name ? null : cat.name)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-all duration-200 ${
                activeCategory === cat.name
                  ? 'bg-primary text-primary-foreground shadow-md shadow-primary/25'
                  : 'bg-secondary/60 text-muted-foreground hover:text-foreground hover:bg-secondary'
              }`}
            >
              {cat.name}
              <span className="ml-1.5 text-xs opacity-70">({cat.features.length})</span>
            </button>
          ))}
        </AnimateOnScroll>

        {/* Feature grids by category */}
        <div className="space-y-12">
          {displayedCategories.map((category, catIdx) => (
            <AnimateOnScroll key={category.name} delay={catIdx * 0.05}>
              <div className="mb-4">
                <h3 className={`text-lg font-semibold mb-1 ${category.color}`}>
                  {category.name}
                </h3>
                <p className="text-sm text-muted-foreground">
                  {category.features.length} features
                </p>
              </div>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3">
                {category.features.map((feature) => {
                  const Icon = feature.icon;
                  return (
                    <div
                      key={feature.name}
                      className={`group flex items-center gap-2.5 p-3 rounded-xl border ${category.borderColor} ${category.bgColor} hover:shadow-md transition-all duration-200 cursor-default`}
                    >
                      <Icon className={`w-4 h-4 shrink-0 ${category.color} group-hover:scale-110 transition-transform`} />
                      <span className="text-xs font-medium truncate">{feature.name}</span>
                    </div>
                  );
                })}
              </div>
            </AnimateOnScroll>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─── CTA Section ────────────────────────────────────────────────────────────

function CTASection() {
  return (
    <section className="py-24 md:py-32 relative">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <AnimateOnScroll>
          <div className="rounded-3xl border border-border/30 bg-card/50 backdrop-blur-sm p-10 md:p-16 relative overflow-hidden">
            <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-apple-purple/5" />
            <div className="relative z-10">
              <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mb-4 tracking-tight">
                Ready to
                <span className="apple-gradient-text"> Rift?</span>
              </h2>
              <p className="text-lg text-muted-foreground mb-8 max-w-lg mx-auto">
                Start building with the most feature-rich NoSQL database for Flutter &amp; Dart.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Button
                  size="lg"
                  className="bg-primary hover:bg-primary/90 text-base px-8 h-12 rounded-full shadow-lg shadow-primary/25"
                  onClick={() => document.getElementById('quickstart')?.scrollIntoView({ behavior: 'smooth' })}
                >
                  Get Started
                  <ArrowRight className="w-5 h-5 ml-1" />
                </Button>
                <Button
                  variant="outline"
                  size="lg"
                  className="text-base px-8 h-12 rounded-full border-border/50 hover:bg-secondary/80"
                  asChild
                >
                  <a
                    href="https://github.com/idris-ghamid/rift"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="gap-2"
                  >
                    <Github className="w-5 h-5" />
                    View on GitHub
                  </a>
                </Button>
              </div>
            </div>
          </div>
        </AnimateOnScroll>
      </div>
    </section>
  );
}

// ─── Main Export ────────────────────────────────────────────────────────────

export default function HomePage() {
  return (
    <main className="min-h-screen">
      <HeroSection />
      <FeatureHighlightsSection />
      <ComparisonSection />
      <QuickStartSection />
      <ArchitectureSection />
      <AllFeaturesSection />
      <CTASection />
    </main>
  );
}
