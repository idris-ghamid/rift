'use client';

import React, { useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import {
  Download, Terminal, BookOpen, ArrowRight, Package,
  Code2, Database, Zap, Shield, CheckCircle2, ExternalLink,
  ChevronRight,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';

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

function CodeBlock({ code, filename }: { code: string; filename: string }) {
  return (
    <div className="rounded-2xl border border-border/40 bg-[#1e1e2e] dark:bg-black/80 overflow-hidden shadow-lg">
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

const DOC_SECTIONS = [
  {
    id: 'installation',
    icon: Download,
    title: 'Installation',
    color: 'text-apple-blue dark:text-[#0A84FF]',
    bg: 'bg-apple-blue/10 dark:bg-[#0A84FF]/10',
  },
  {
    id: 'quickstart',
    icon: Zap,
    title: 'Quick Start',
    color: 'text-apple-purple dark:text-[#5E5CE6]',
    bg: 'bg-apple-purple/10 dark:bg-[#5E5CE6]/10',
  },
  {
    id: 'api-reference',
    icon: Code2,
    title: 'API Reference',
    color: 'text-apple-violet dark:text-[#BF5AF2]',
    bg: 'bg-apple-violet/10 dark:bg-[#BF5AF2]/10',
  },
  {
    id: 'migration',
    icon: ArrowRight,
    title: 'Migration from Hive',
    color: 'text-apple-orange dark:text-[#FF9F0A]',
    bg: 'bg-apple-orange/10 dark:bg-[#FF9F0A]/10',
  },
];

const API_ENDPOINTS = [
  { method: 'GET', path: 'Rift.init()', desc: 'Initialize the database engine' },
  { method: 'GET', path: 'Rift.openBox<T>(name)', desc: 'Open or create a typed box' },
  { method: 'PUT', path: 'box.put(key, value)', desc: 'Store a key-value pair' },
  { method: 'GET', path: 'box.get(key)', desc: 'Retrieve a value by key' },
  { method: 'DEL', path: 'box.delete(key)', desc: 'Delete a value by key' },
  { method: 'QRY', path: 'box.query()', desc: 'Create a new query builder' },
  { method: 'QRY', path: 'query.where(field, filter)', desc: 'Add a filter condition' },
  { method: 'QRY', path: 'query.sortBy(field)', desc: 'Sort results by field' },
  { method: 'QRY', path: 'query.limit(n)', desc: 'Limit the number of results' },
  { method: 'QRY', path: 'query.findAll()', desc: 'Execute query and return all results' },
  { method: 'SUB', path: 'box.liveQuery()', desc: 'Create a reactive live query' },
  { method: 'TXN', path: 'Rift.transaction(() => ...)', desc: 'Run operations in a transaction' },
];

export default function DocsPage() {
  const scrollToSection = (id: string) => {
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <main className="min-h-screen pt-24 pb-16">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <AnimateOnScroll className="text-center mb-16">
          <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 tracking-tight">
            <span className="apple-gradient-text">Documentation</span>
          </h1>
          <p className="text-lg md:text-xl text-muted-foreground max-w-2xl mx-auto">
            Everything you need to get started with Rift
          </p>
        </AnimateOnScroll>

        {/* Quick Nav Cards */}
        <AnimateOnScroll delay={0.1} className="mb-16">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {DOC_SECTIONS.map((section, idx) => {
              const Icon = section.icon;
              return (
                <button
                  key={section.id}
                  onClick={() => scrollToSection(section.id)}
                  className="group text-left"
                >
                  <Card className="h-full border-border/30 bg-card/50 backdrop-blur-sm apple-card-hover">
                    <CardContent className="p-5">
                      <div className={`w-10 h-10 rounded-xl ${section.bg} flex items-center justify-center mb-3 group-hover:scale-110 transition-transform`}>
                        <Icon className={`w-5 h-5 ${section.color}`} />
                      </div>
                      <h3 className="font-semibold text-sm mb-1">{section.title}</h3>
                      <p className="text-xs text-muted-foreground">Jump to section →</p>
                    </CardContent>
                  </Card>
                </button>
              );
            })}
          </div>
        </AnimateOnScroll>

        {/* Installation */}
        <AnimateOnScroll id="installation" className="mb-20">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-xl bg-apple-blue/10 dark:bg-[#0A84FF]/10 flex items-center justify-center">
              <Download className="w-5 h-5 text-apple-blue dark:text-[#0A84FF]" />
            </div>
            <h2 className="text-3xl font-bold">Installation</h2>
          </div>
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-semibold mb-3">1. Add to pubspec.yaml</h3>
              <CodeBlock
                code={`dependencies:
  rift: ^1.0.0
  
  # Optional: Flutter integration
  rift_flutter: ^1.0.0
  
  # Optional: Code generation
  rift_generator: ^1.0.0`}
                filename="pubspec.yaml"
              />
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-3">2. Install packages</h3>
              <CodeBlock
                code={`$ flutter pub get`}
                filename="terminal"
              />
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-3">3. Run code generation (optional)</h3>
              <CodeBlock
                code={`$ dart run build_runner build`}
                filename="terminal"
              />
            </div>
          </div>
        </AnimateOnScroll>

        {/* Quick Start */}
        <AnimateOnScroll id="quickstart" className="mb-20">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-xl bg-apple-purple/10 dark:bg-[#5E5CE6]/10 flex items-center justify-center">
              <Zap className="w-5 h-5 text-apple-purple dark:text-[#5E5CE6]" />
            </div>
            <h2 className="text-3xl font-bold">Quick Start</h2>
          </div>
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-semibold mb-3">Basic Usage</h3>
              <CodeBlock
                code={`import 'package:rift/rift.dart';

void main() async {
  // Initialize Rift
  await Rift.init();
  
  // Open a box
  final users = await Rift.openBox<Map>('users');
  
  // Store data
  await users.put('u1', {
    'name': 'Idris',
    'age': 25,
    'role': 'Developer',
  });
  
  // Read it back
  final user = users.get('u1');
  print(user); // {name: Idris, age: 25, role: Developer}
}`}
                filename="main.dart"
              />
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-3">Query Builder</h3>
              <CodeBlock
                code={`// Filter, sort, and paginate
final adults = users.query()
  .where('age', greaterThan: 18)
  .where('role', equalTo: 'Developer')
  .sortBy('name')
  .limit(10)
  .findAll();

// Live queries (reactive)
final liveResults = users.liveQuery()
  .where('age', greaterThan: 18)
  .watch();  // Auto-updates when data changes`}
                filename="query_example.dart"
              />
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-3">Transactions</h3>
              <CodeBlock
                code={`// ACID Transactions with savepoints
await Rift.transaction(() async {
  await users.put('u1', {'balance': 100});
  await users.put('u2', {'balance': 200});
  
  // Savepoint for partial rollback
  await Rift.savepoint('sp1');
  await users.put('u3', {'balance': 50});
  
  // Rollback to savepoint
  await Rift.rollbackTo('sp1'); // u3 is rolled back
});`}
                filename="transaction_example.dart"
              />
            </div>
          </div>
        </AnimateOnScroll>

        {/* API Reference */}
        <AnimateOnScroll id="api-reference" className="mb-20">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-xl bg-apple-violet/10 dark:bg-[#BF5AF2]/10 flex items-center justify-center">
              <Code2 className="w-5 h-5 text-apple-violet dark:text-[#BF5AF2]" />
            </div>
            <h2 className="text-3xl font-bold">API Reference</h2>
          </div>

          <div className="rounded-2xl border border-border/40 bg-card/50 backdrop-blur-sm overflow-hidden">
            {API_ENDPOINTS.map((endpoint, idx) => {
              const methodColor = {
                GET: 'text-apple-green dark:text-[#30D158] bg-apple-green/10 dark:bg-[#30D158]/10',
                PUT: 'text-apple-blue dark:text-[#0A84FF] bg-apple-blue/10 dark:bg-[#0A84FF]/10',
                DEL: 'text-apple-red dark:text-[#FF453A] bg-apple-red/10 dark:bg-[#FF453A]/10',
                QRY: 'text-apple-purple dark:text-[#5E5CE6] bg-apple-purple/10 dark:bg-[#5E5CE6]/10',
                SUB: 'text-apple-orange dark:text-[#FF9F0A] bg-apple-orange/10 dark:bg-[#FF9F0A]/10',
                TXN: 'text-apple-teal dark:text-[#64D2FF] bg-apple-teal/10 dark:bg-[#64D2FF]/10',
              }[endpoint.method] || '';

              return (
                <div
                  key={endpoint.path}
                  className={`flex items-center gap-4 p-4 ${
                    idx !== API_ENDPOINTS.length - 1 ? 'border-b border-border/20' : ''
                  } hover:bg-primary/5 transition-colors`}
                >
                  <span className={`px-2.5 py-1 rounded-md text-xs font-bold ${methodColor} shrink-0`}>
                    {endpoint.method}
                  </span>
                  <code className="text-sm font-mono text-foreground/90 shrink-0 min-w-[200px]">
                    {endpoint.path}
                  </code>
                  <span className="text-sm text-muted-foreground hidden sm:block">
                    {endpoint.desc}
                  </span>
                </div>
              );
            })}
          </div>
        </AnimateOnScroll>

        {/* Migration from Hive */}
        <AnimateOnScroll id="migration" className="mb-20">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-xl bg-apple-orange/10 dark:bg-[#FF9F0A]/10 flex items-center justify-center">
              <ArrowRight className="w-5 h-5 text-apple-orange dark:text-[#FF9F0A]" />
            </div>
            <h2 className="text-3xl font-bold">Migration from Hive</h2>
          </div>

          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-semibold mb-3">One-line migration</h3>
              <CodeBlock
                code={`// Simply change the import — that's it!
// Before:
import 'package:hive/hive.dart';

// After:
import 'package:rift/rift.dart';

// Your existing Hive code works with Rift!
// Rift is a superset of Hive's API, so all your
// existing code continues to work unchanged.

// NEW: Access Rift-specific features
final users = await Rift.openBox<Map>('users');

// Queries (not available in Hive)
final results = users.query()
  .where('age', greaterThan: 18)
  .findAll();

// Live queries (not available in Hive)
final live = users.liveQuery()
  .where('active', equalTo: true)
  .watch();`}
                filename="migration.dart"
              />
            </div>

            <Card className="border-border/30 bg-card/50 backdrop-blur-sm">
              <CardContent className="p-6">
                <h3 className="text-lg font-semibold mb-4">Migration Checklist</h3>
                <div className="space-y-3">
                  {[
                    'Replace hive dependency with rift in pubspec.yaml',
                    'Update imports from package:hive to package:rift',
                    'Existing Hive boxes are automatically compatible',
                    'Enable new features incrementally (queries, transactions, etc.)',
                    'Run rift_generator for typed adapter code generation',
                  ].map((item, idx) => (
                    <div key={idx} className="flex items-start gap-3">
                      <CheckCircle2 className="w-5 h-5 text-apple-green dark:text-[#30D158] shrink-0 mt-0.5" />
                      <span className="text-sm text-foreground/80">{item}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </AnimateOnScroll>

        {/* Feature Docs Links */}
        <AnimateOnScroll>
          <Card className="border-border/30 bg-card/50 backdrop-blur-sm overflow-hidden relative">
            <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-apple-purple/5" />
            <CardContent className="p-8 relative z-10">
              <h2 className="text-2xl font-semibold mb-2">Explore Features</h2>
              <p className="text-muted-foreground mb-6">
                Dive deeper into Rift&apos;s capabilities
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                {[
                  'Query Builder', 'Live Queries', 'Transactions', 'Encryption',
                  'Vector Search', 'CRDT', 'Full-Text Search', 'Sync',
                  'WAL Recovery', 'Time Travel', 'Schema Migration', 'Relations',
                ].map((feature) => (
                  <a
                    key={feature}
                    href="https://github.com/idris-ghamid/rift"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 p-3 rounded-xl border border-border/30 bg-secondary/30 hover:bg-primary/10 hover:border-primary/20 transition-all group"
                  >
                    <ChevronRight className="w-4 h-4 text-muted-foreground group-hover:text-primary transition-colors" />
                    <span className="text-sm font-medium">{feature}</span>
                  </a>
                ))}
              </div>
            </CardContent>
          </Card>
        </AnimateOnScroll>
      </div>
    </main>
  );
}
