'use client';

import React, { useState, useEffect, useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import {
  Database, Zap, Search, Shield, Layers, GitBranch, ArrowRight,
  Github, ChevronRight, Code2, Lock, RefreshCw, Gauge,
  FileText, Terminal, Cpu, HardDrive, Box, Clock, Filter,
  Globe, Network, Activity, Eye, Archive, Key,
  Copy, Check, Sparkles, Binary, TreePine, Braces, Wand2,
  TestTube, Crosshair, Flower2, Trash2, Puzzle,
  CloudDownload, MemoryStick, Share2, MapPin, Sigma,
  Radio, Tag, Timer, History, FolderSync, Paintbrush,
  Mountain, ScrollText, Camera
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from '@/components/ui/table';

// ─── Data ──────────────────────────────────────────────────────────────────

const NAV_LINKS = [
  { label: 'Features', href: '#features' },
  { label: 'Comparison', href: '#comparison' },
  { label: 'Quick Start', href: '#quickstart' },
  { label: 'Benchmarks', href: '#benchmarks' },
  { label: 'Packages', href: '#packages' },
];

const COMPARISON_FEATURES = [
  'Queries', 'Live Queries', 'Secondary Indexes', 'Composite Indexes',
  'Relations', 'ACID Transactions', 'WAL', 'Schema Migration',
  'Multi-Isolate', 'Compression', 'TTL', 'Middleware',
  'Full-Text Search', 'Backup', 'Enhanced Encryption', 'Bulk Operations',
  'LRU Cache', 'Cursor', 'CLI', 'CRDT', 'Vector Search',
  'Time Travel', 'Sync', 'Aggregation', 'CDC', 'Geospatial',
  'Audit Log', 'Profiler', 'Plugin Architecture', 'Bloom Filters',
  'Graph', 'Time-Series', 'Reactive Signals', 'No-Codegen', 'Pure Dart',
];

const DB_COMPARISON: Record<string, Record<string, boolean | string>> = {
  'Rift': Object.fromEntries(COMPARISON_FEATURES.map(f => [f, true])),
  'Hive': Object.fromEntries(COMPARISON_FEATURES.map(f => [f, ['Pure Dart', 'No-Codegen'].includes(f)])),
  'Isar': Object.fromEntries(COMPARISON_FEATURES.map(f => [f, ['Queries', 'Multi-Isolate', 'Full-Text Search'].includes(f)])),
  'Drift': Object.fromEntries(COMPARISON_FEATURES.map(f => [f, ['Queries', 'ACID Transactions', 'Schema Migration'].includes(f)])),
  'ObjectBox': Object.fromEntries(COMPARISON_FEATURES.map(f => [f, ['Queries', 'Relations', 'ACID Transactions', 'Backup'].includes(f)])),
};

type FeatureCategory = 'Critical' | 'High' | 'Medium' | 'Competitive' | 'Future' | 'Advanced';

interface Feature {
  name: string;
  description: string;
  icon: React.ElementType;
  category: FeatureCategory;
}

const FEATURES: Feature[] = [
  // 🔴 Critical (7)
  { name: 'Query Builder', description: 'Type-safe fluent query API with filters, sorting, and chaining', icon: Filter, category: 'Critical' },
  { name: 'Live Queries', description: 'Reactive queries that auto-update when data changes', icon: Radio, category: 'Critical' },
  { name: 'Secondary Indexes', description: 'Fast lookups on any field with B-tree indexes', icon: Search, category: 'Critical' },
  { name: 'WAL', description: 'Write-Ahead Logging for crash recovery and durability', icon: HardDrive, category: 'Critical' },
  { name: 'ACID Transactions', description: 'Atomic, consistent, isolated, durable transactions', icon: Shield, category: 'Critical' },
  { name: 'Isolate Support', description: 'Multi-isolate access with built-in synchronization', icon: Cpu, category: 'Critical' },
  { name: 'Schema Migration', description: 'Versioned schema evolution with automatic migration', icon: GitBranch, category: 'Critical' },
  // 🟠 High (10)
  { name: 'Relations', description: 'One-to-many and many-to-many object relationships', icon: Network, category: 'High' },
  { name: 'Full-Text Search', description: 'Built-in FTS engine with tokenization and ranking', icon: Search, category: 'High' },
  { name: 'Typed Boxes', description: 'Type-safe boxes with compile-time guarantees', icon: Tag, category: 'High' },
  { name: 'Enhanced Encryption', description: 'AES-256 encryption with custom cipher support', icon: Lock, category: 'High' },
  { name: 'Bulk Operations', description: 'Batch put/delete for high-throughput scenarios', icon: Layers, category: 'High' },
  { name: 'DevTools Inspector', description: 'Visual database inspector for Flutter DevTools', icon: Eye, category: 'High' },
  { name: 'CLI Tools', description: 'Command-line tools for schema, backup, and migration', icon: Terminal, category: 'High' },
  { name: 'Compression', description: 'LZ4 compression for reduced storage footprint', icon: Archive, category: 'High' },
  { name: 'TTL', description: 'Time-to-live for automatic data expiration', icon: Timer, category: 'High' },
  { name: 'File Format Versioning', description: 'Forward-compatible file format with version headers', icon: FileText, category: 'High' },
  // 🟡 Medium (13)
  { name: 'Middleware', description: 'Pre/post hooks for put, delete, and query operations', icon: Braces, category: 'Medium' },
  { name: 'LRU Cache', description: 'Least-recently-used caching for hot data access', icon: MemoryStick, category: 'Medium' },
  { name: 'OPFS Web', description: 'Optimized web storage via Origin Private File System', icon: Globe, category: 'Medium' },
  { name: 'No-Codegen Mode', description: 'Use Rift without code generation — pure Dart only', icon: Code2, category: 'Medium' },
  { name: 'Pluggable Storage', description: 'Swap storage backends without changing API', icon: Puzzle, category: 'Medium' },
  { name: 'State Management', description: 'Riverpod & Bloc integrations out of the box', icon: Activity, category: 'Medium' },
  { name: 'Cursor/Iterator', description: 'Lazy iteration over large result sets', icon: Crosshair, category: 'Medium' },
  { name: 'Backup/Restore', description: 'Full and incremental backup with compression', icon: CloudDownload, category: 'Medium' },
  { name: 'Audit Log', description: 'Track all mutations with user and timestamp metadata', icon: ScrollText, category: 'Medium' },
  { name: 'Dart 3 Records', description: 'Native support for Dart 3 record types', icon: Braces, category: 'Medium' },
  { name: 'Read Cache', description: 'Automatic read caching for repeated accesses', icon: Database, category: 'Medium' },
  { name: 'Web Performance', description: 'Optimized IndexedDB & OPFS for web targets', icon: Gauge, category: 'Medium' },
  { name: 'In-Memory Mode', description: 'Pure in-memory database for testing and caching', icon: Zap, category: 'Medium' },
  // 🟢 Competitive (8)
  { name: 'CRDT', description: 'Conflict-free replicated data types for distributed sync', icon: RefreshCw, category: 'Competitive' },
  { name: 'Vector Search', description: 'Cosine similarity search for AI/ML embeddings', icon: Sparkles, category: 'Competitive' },
  { name: 'Time Travel', description: 'Query historical data states at any point in time', icon: History, category: 'Competitive' },
  { name: 'Binary Storage', description: 'Efficient binary serialization with zero-copy reads', icon: Binary, category: 'Competitive' },
  { name: 'Sync Layer', description: 'Pluggable sync layer for cloud and P2P replication', icon: FolderSync, category: 'Competitive' },
  { name: 'Geospatial Queries', description: 'Radius and bounding box queries on geo data', icon: MapPin, category: 'Competitive' },
  { name: 'Aggregation Pipeline', description: 'MongoDB-style aggregation with group, sum, avg', icon: Sigma, category: 'Competitive' },
  { name: 'CDC', description: 'Change Data Capture stream for event-driven architectures', icon: Activity, category: 'Competitive' },
  // 🔵 Future (17)
  { name: 'Time-Series', description: 'Optimized storage and queries for time-series data', icon: Clock, category: 'Future' },
  { name: 'Graph Schema', description: 'Native graph traversal with edges and vertices', icon: TreePine, category: 'Future' },
  { name: 'Smart Codegen', description: 'Intelligent code generation with incremental builds', icon: Wand2, category: 'Future' },
  { name: 'Profiler', description: 'Query and operation profiling with flame graphs', icon: Gauge, category: 'Future' },
  { name: 'Testing Utils', description: 'In-memory fixtures and mock utilities for tests', icon: TestTube, category: 'Future' },
  { name: 'Field-Level Encryption', description: 'Encrypt individual fields with separate keys', icon: Key, category: 'Future' },
  { name: 'Cross-Box Tx', description: 'Atomic transactions across multiple boxes', icon: Share2, category: 'Future' },
  { name: 'Bloom Filters', description: 'Probabilistic membership testing for fast lookups', icon: Flower2, category: 'Future' },
  { name: 'Background Compaction', description: 'Automatic compaction in background isolates', icon: Trash2, category: 'Future' },
  { name: 'Aurora OS', description: 'Support for Aurora OS platform', icon: Mountain, category: 'Future' },
  { name: 'Reactive Signals', description: 'Fine-grained reactivity with Dart signals', icon: Radio, category: 'Future' },
  { name: 'Incremental Export', description: 'Delta-based export for large datasets', icon: CloudDownload, category: 'Future' },
  { name: 'mmap', description: 'Memory-mapped file I/O for zero-copy performance', icon: MemoryStick, category: 'Future' },
  { name: 'Extension Types', description: 'Dart 3 extension type support in boxes', icon: Paintbrush, category: 'Future' },
  { name: 'SharedArrayBuffer', description: 'Web shared memory for multi-threaded access', icon: Share2, category: 'Future' },
  { name: 'Hive Migration', description: 'One-line migration from Hive to Rift', icon: ArrowRight, category: 'Future' },
  { name: 'Plugin Architecture', description: 'Extensible plugin system for custom functionality', icon: Puzzle, category: 'Future' },
  // 🟣 Advanced (20 NEW)
  { name: 'Observable Store', description: 'Reactive observables for deep nested objects with auto-notifications', icon: Eye, category: 'Advanced' },
  { name: 'Data Masking', description: 'Mask sensitive data for display — credit cards, emails, SSNs', icon: Shield, category: 'Advanced' },
  { name: 'Schema Validation', description: 'JSON Schema-style validation before storing data', icon: Check, category: 'Advanced' },
  { name: 'Snapshot Isolation', description: 'MVCC-style isolated read snapshots at a point in time', icon: Camera, category: 'Advanced' },
  { name: 'Rate Limiting', description: 'Token bucket rate limiting for read/write operations', icon: Gauge, category: 'Advanced' },
  { name: 'Data Versioning', description: 'Track versions of individual entries with full history', icon: GitBranch, category: 'Advanced' },
  { name: 'Partitioning', description: 'Hash/range partitioning across multiple boxes', icon: Layers, category: 'Advanced' },
  { name: 'Observability / Metrics', description: 'Prometheus-compatible metrics for monitoring operations', icon: Activity, category: 'Advanced' },
  { name: 'Transform Pipeline', description: 'ETL-style data transformation on read/write', icon: RefreshCw, category: 'Advanced' },
  { name: 'Replication', description: 'Master-slave and peer-to-peer replication support', icon: FolderSync, category: 'Advanced' },
  { name: 'Connection Pooling', description: 'Box connection pooling for server-side scenarios', icon: Database, category: 'Advanced' },
  { name: 'Data Sanitization', description: 'XSS prevention and input sanitization before storage', icon: Shield, category: 'Advanced' },
  { name: 'Event Sourcing', description: 'Append-only event store with projections and replay', icon: History, category: 'Advanced' },
  { name: 'Reactive Forms', description: 'Auto-persisting form fields backed by Rift boxes', icon: FileText, category: 'Advanced' },
  { name: 'Adaptive Caching', description: 'Smart cache that adapts strategy based on access patterns', icon: Zap, category: 'Advanced' },
  { name: 'Dictionary Compression', description: 'Pattern-based compression for structured data (30-50% better)', icon: Archive, category: 'Advanced' },
  { name: 'Access Control', description: 'Fine-grained RBAC permissions for box operations', icon: Lock, category: 'Advanced' },
  { name: 'Data Diff & Patch', description: 'RFC 6902 JSON Patch — compute diffs and apply patches', icon: GitBranch, category: 'Advanced' },
  { name: 'Lazy Loading Strategies', description: 'Configurable eager, lazy, on-demand, and prefetch strategies', icon: Crosshair, category: 'Advanced' },
  { name: 'Query Optimization', description: 'Query optimizer with cost estimation and index hints', icon: Sparkles, category: 'Advanced' },
];

const CATEGORY_CONFIG: Record<FeatureCategory, { color: string; bg: string; border: string; badge: string }> = {
  Critical: { color: 'text-red-400', bg: 'bg-red-500/10', border: 'border-red-500/20', badge: 'bg-red-500/20 text-red-400 border-red-500/30' },
  High: { color: 'text-orange-400', bg: 'bg-orange-500/10', border: 'border-orange-500/20', badge: 'bg-orange-500/20 text-orange-400 border-orange-500/30' },
  Medium: { color: 'text-yellow-400', bg: 'bg-yellow-500/10', border: 'border-yellow-500/20', badge: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30' },
  Competitive: { color: 'text-emerald-400', bg: 'bg-emerald-500/10', border: 'border-emerald-500/20', badge: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30' },
  Future: { color: 'text-blue-400', bg: 'bg-blue-500/10', border: 'border-blue-500/20', badge: 'bg-blue-500/20 text-blue-400 border-blue-500/30' },
  Advanced: { color: 'text-purple-400', bg: 'bg-purple-500/10', border: 'border-purple-500/20', badge: 'bg-purple-500/20 text-purple-400 border-purple-500/30' },
};

const BENCHMARKS = [
  { label: 'Write', rift: 85000, others: [{ name: 'Hive', value: 45000 }, { name: 'Isar', value: 70000 }] },
  { label: 'Read', rift: 120000, others: [{ name: 'Hive', value: 80000 }, { name: 'Isar', value: 95000 }] },
  { label: 'Query', rift: 50000, others: [{ name: 'Hive', value: 0 }, { name: 'Isar', value: 40000 }] },
];

const PACKAGES = [
  { name: 'rift', description: 'Core database library with all features', icon: Database, highlight: true },
  { name: 'rift_flutter', description: 'Flutter integration with widgets and bindings', icon: Box, highlight: false },
  { name: 'rift_generator', description: 'Code generation for typed adapters', icon: Cpu, highlight: false },
  { name: 'rift_inspector', description: 'DevTools inspector for visual debugging', icon: Eye, highlight: false },
];

// ─── Helper Components ─────────────────────────────────────────────────────

function CodeBlock({ code, language = 'dart', filename }: { code: string; language?: string; filename?: string }) {
  return (
    <div className="rounded-xl border border-border/50 bg-[oklch(0.06_0.015_293)] overflow-hidden">
      {filename && (
        <div className="flex items-center gap-2 px-4 py-2.5 border-b border-border/30 bg-[oklch(0.08_0.018_293)]">
          <div className="flex gap-1.5">
            <div className="w-3 h-3 rounded-full bg-red-500/60" />
            <div className="w-3 h-3 rounded-full bg-yellow-500/60" />
            <div className="w-3 h-3 rounded-full bg-green-500/60" />
          </div>
          <span className="text-xs text-muted-foreground ml-2 font-mono">{filename}</span>
        </div>
      )}
      <pre className="p-4 overflow-x-auto text-sm leading-relaxed">
        <code className="font-mono text-[oklch(0.85_0.01_293)]">{code}</code>
      </pre>
    </div>
  );
}

function DartCode({ code }: { code: string }) {
  // Simple Dart syntax highlighting
  const highlightDart = (line: string, idx: number) => {
    // Keywords
    const keywords = ['import', 'as', 'void', 'async', 'await', 'final', 'var', 'const', 'class', 'extends', 'implements', 'return', 'if', 'else', 'for', 'while', 'true', 'false', 'null', 'int', 'String', 'double', 'bool', 'List', 'Map', 'Set', 'dynamic', 'static', 'get', 'set', 'abstract', 'factory', 'this', 'super', 'new', 'is'];
    const types = ['Rift', 'RiftBox', 'RiftQuery', 'RiftCursor', 'RiftBox<Map>', 'Box'];
    const strings = /'[^']*'|"[^"]*"/g;
    const comments = /\/\/.*$/g;

    let processed = line;

    // Escape HTML
    processed = processed.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

    // Comments
    if (processed.trimStart().startsWith('//')) {
      return <span key={idx} className="text-[oklch(0.5_0.03_293)] italic">{processed}</span>;
    }

    // Highlight strings
    const parts: React.ReactNode[] = [];
    let remaining = processed;
    let partIdx = 0;

    const stringMatches = [...remaining.matchAll(/(&apos;[^&]*&apos;|&#39;[^&]*&#39;|'[^']*')/g)];

    // Simple approach: tokenize and colorize
    const tokens = processed.split(/(\s+|[{}()\[\];,.<>=!+\-*\/&|?:])/);
    return (
      <span key={idx}>
        {tokens.map((token, tIdx) => {
          if (!token) return null;
          if (keywords.includes(token)) {
            return <span key={tIdx} className="text-[oklch(0.75_0.15_293)]">{token}</span>;
          }
          if (types.some(t => token.startsWith(t))) {
            return <span key={tIdx} className="text-[oklch(0.65_0.2_165)]">{token}</span>;
          }
          if (/^'.*'$/.test(token) || /^".*"$/.test(token)) {
            return <span key={tIdx} className="text-[oklch(0.7_0.12_145)]">{token}</span>;
          }
          if (/^\d+$/.test(token)) {
            return <span key={tIdx} className="text-[oklch(0.75_0.15_60)]">{token}</span>;
          }
          if (token.startsWith("'") || token.startsWith('"')) {
            return <span key={tIdx} className="text-[oklch(0.7_0.12_145)]">{token}</span>;
          }
          return <span key={tIdx}>{token}</span>;
        })}
      </span>
    );
  };

  return (
    <div className="rounded-xl border border-border/50 bg-[oklch(0.06_0.015_293)] overflow-hidden">
      <div className="flex items-center gap-2 px-4 py-2.5 border-b border-border/30 bg-[oklch(0.08_0.018_293)]">
        <div className="flex gap-1.5">
          <div className="w-3 h-3 rounded-full bg-red-500/60" />
          <div className="w-3 h-3 rounded-full bg-yellow-500/60" />
          <div className="w-3 h-3 rounded-full bg-green-500/60" />
        </div>
        <span className="text-xs text-muted-foreground ml-2 font-mono">main.dart</span>
      </div>
      <pre className="p-4 overflow-x-auto text-sm leading-relaxed font-mono">
        {code.split('\n').map((line, idx) => (
          <div key={idx} className="min-h-[1.5em]">
            <span className="text-[oklch(0.35_0.02_293)] select-none mr-4 text-xs">{String(idx + 1).padStart(2, ' ')}</span>
            {highlightDart(line, idx)}
          </div>
        ))}
      </pre>
    </div>
  );
}

function AnimateOnScroll({ children, className = '', delay = 0 }: { children: React.ReactNode; className?: string; delay?: number }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: '-50px' });

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 30 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 30 }}
      transition={{ duration: 0.6, delay, ease: 'easeOut' }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

function SectionHeading({ title, subtitle, id }: { title: string; subtitle: string; id?: string }) {
  return (
    <AnimateOnScroll className="text-center mb-12 md:mb-16">
      {id && <div id={id} className="relative -top-24" />}
      <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mb-4">
        <span className="gradient-text">{title}</span>
      </h2>
      <p className="text-muted-foreground text-lg md:text-xl max-w-2xl mx-auto">{subtitle}</p>
    </AnimateOnScroll>
  );
}

// ─── Section: Navbar ────────────────────────────────────────────────────────

function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const handler = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', handler, { passive: true });
    return () => window.removeEventListener('scroll', handler);
  }, []);

  return (
    <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled ? 'bg-background/80 backdrop-blur-xl border-b border-border/50 shadow-lg shadow-purple-500/5' : 'bg-transparent'}`}>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <a href="#" className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-primary/20 flex items-center justify-center">
              <Database className="w-5 h-5 text-primary" />
            </div>
            <span className="text-xl font-bold gradient-text">Rift</span>
          </a>

          {/* Desktop nav */}
          <div className="hidden md:flex items-center gap-1">
            {NAV_LINKS.map(link => (
              <a
                key={link.href}
                href={link.href}
                className="px-3 py-2 text-sm text-muted-foreground hover:text-foreground transition-colors rounded-md hover:bg-white/5"
              >
                {link.label}
              </a>
            ))}
          </div>

          <div className="hidden md:flex items-center gap-3">
            <Button variant="ghost" size="sm" asChild>
              <a href="https://github.com/idris-ghamid/rift" target="_blank" rel="noopener noreferrer" className="gap-2">
                <Github className="w-4 h-4" />
                GitHub
              </a>
            </Button>
            <Button size="sm" className="bg-primary hover:bg-primary/90" asChild>
              <a href="#quickstart">
                Get Started
                <ArrowRight className="w-4 h-4" />
              </a>
            </Button>
          </div>

          {/* Mobile menu button */}
          <button
            className="md:hidden p-2 text-muted-foreground hover:text-foreground"
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label="Toggle menu"
          >
            {mobileOpen ? <span className="text-lg">✕</span> : (
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="3" y1="6" x2="21" y2="6" /><line x1="3" y1="12" x2="21" y2="12" /><line x1="3" y1="18" x2="21" y2="18" /></svg>
            )}
          </button>
        </div>

        {/* Mobile menu */}
        {mobileOpen && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="md:hidden py-4 border-t border-border/50"
          >
            {NAV_LINKS.map(link => (
              <a
                key={link.href}
                href={link.href}
                onClick={() => setMobileOpen(false)}
                className="block px-3 py-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
              >
                {link.label}
              </a>
            ))}
            <div className="flex gap-2 mt-4 px-3">
              <Button variant="outline" size="sm" asChild className="flex-1">
                <a href="https://github.com/idris-ghamid/rift" target="_blank" rel="noopener noreferrer" className="gap-2">
                  <Github className="w-4 h-4" />
                  GitHub
                </a>
              </Button>
              <Button size="sm" className="flex-1 bg-primary hover:bg-primary/90" asChild>
                <a href="#quickstart">Get Started</a>
              </Button>
            </div>
          </motion.div>
        )}
      </div>
    </nav>
  );
}

// ─── Section: Hero ──────────────────────────────────────────────────────────

function HeroSection() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-16">
      {/* Animated background */}
      <div className="absolute inset-0 grid-pattern animate-grid-fade" />
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-background/50 to-background" />
      
      {/* Floating orbs */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-primary/10 rounded-full blur-[120px] animate-float" />
      <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-primary/5 rounded-full blur-[100px] animate-float" style={{ animationDelay: '2s' }} />
      <div className="absolute top-1/3 right-1/3 w-64 h-64 bg-violet-500/5 rounded-full blur-[80px] animate-float" style={{ animationDelay: '4s' }} />

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 md:py-32">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left: Text content */}
          <div className="text-center lg:text-left">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
            >
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full border border-primary/30 bg-primary/10 text-primary text-sm mb-6">
                <Sparkles className="w-4 h-4" />
                v1.0 — Now Available
              </div>
            </motion.div>

            <motion.h1
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.1 }}
              className="text-5xl sm:text-6xl md:text-7xl lg:text-8xl font-black mb-6 tracking-tight"
            >
              <span className="animate-glow-pulse gradient-text">Rift</span>
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="text-xl md:text-2xl text-foreground/90 mb-2 font-semibold"
            >
              The next-generation NoSQL database for Flutter &amp; Dart
            </motion.p>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.25 }}
              className="text-base md:text-lg text-primary/80 mb-8 max-w-lg mx-auto lg:mx-0 font-medium"
            >
              Rift through your data ⚡
            </motion.p>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.3 }}
              className="text-base md:text-lg text-muted-foreground mb-8 max-w-lg mx-auto lg:mx-0"
            >
              Pure Dart. Blazing fast. Reactive queries. Zero native dependencies.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="flex flex-col sm:flex-row gap-3 justify-center lg:justify-start"
            >
              <Button size="lg" className="bg-primary hover:bg-primary/90 text-base px-8 h-12" asChild>
                <a href="#quickstart">
                  Get Started
                  <ArrowRight className="w-5 h-5" />
                </a>
              </Button>
              <Button variant="outline" size="lg" className="text-base px-8 h-12 border-border/50 hover:bg-white/5" asChild>
                <a href="https://github.com/idris-ghamid/rift" target="_blank" rel="noopener noreferrer" className="gap-2">
                  <Github className="w-5 h-5" />
                  View on GitHub
                </a>
              </Button>
            </motion.div>

            {/* Stats */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.6, delay: 0.6 }}
              className="flex gap-8 mt-10 justify-center lg:justify-start"
            >
              {[
                { value: '75+', label: 'Features' },
                { value: '85k', label: 'Writes/s' },
                { value: '0', label: 'Native Deps' },
              ].map(stat => (
                <div key={stat.label} className="text-center">
                  <div className="text-2xl font-bold text-primary">{stat.value}</div>
                  <div className="text-xs text-muted-foreground">{stat.label}</div>
                </div>
              ))}
            </motion.div>
          </div>

          {/* Right: Code preview */}
          <motion.div
            initial={{ opacity: 0, x: 30 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8, delay: 0.3 }}
            className="relative"
          >
            <div className="absolute -inset-4 bg-primary/5 rounded-3xl blur-2xl" />
            <div className="relative">
              <DartCode code={`import 'package:rift/rift.dart';

void main() async {
  await Rift.init();
  final users = await Rift.openBox<Map>('users');
  await users.put('u1', {'name': 'Idris', 'age': 25});

  // Query with filters
  final adults = users.query()
    .where('age', greaterThan: 18)
    .sortBy('name')
    .findAll();
}`} />
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

// ─── Section: Comparison Table ──────────────────────────────────────────────

function ComparisonSection() {
  const [showAll, setShowAll] = useState(false);
  const displayedFeatures = showAll ? COMPARISON_FEATURES : COMPARISON_FEATURES.slice(0, 10);

  return (
    <section className="py-20 md:py-28 relative" id="comparison">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <SectionHeading
          title="Feature Comparison"
          subtitle="See how Rift stacks up against the competition"
          id="comparison-heading"
        />

        <AnimateOnScroll>
          <div className="overflow-x-auto rounded-xl border border-border/50 rift-glow">
            <Table>
              <TableHeader>
                <TableRow className="border-border/50 hover:bg-transparent">
                  <TableHead className="w-[200px] text-foreground font-semibold">Feature</TableHead>
                  {Object.keys(DB_COMPARISON).map(db => (
                    <TableHead key={db} className="text-center font-semibold">
                      <span className={db === 'Rift' ? 'text-primary' : 'text-foreground'}>{db}</span>
                    </TableHead>
                  ))}
                </TableRow>
              </TableHeader>
              <TableBody>
                {displayedFeatures.map(feature => (
                  <TableRow key={feature} className="border-border/30 hover:bg-primary/5">
                    <TableCell className="font-medium text-foreground/90">{feature}</TableCell>
                    {Object.entries(DB_COMPARISON).map(([db, features]) => (
                      <TableCell key={db} className="text-center">
                        {features[feature] ? (
                          <span className={db === 'Rift' ? 'text-primary' : 'text-emerald-400'}>✅</span>
                        ) : (
                          <span className="text-muted-foreground/40">—</span>
                        )}
                      </TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>

          {!showAll && COMPARISON_FEATURES.length > 10 && (
            <div className="text-center mt-6">
              <Button variant="outline" onClick={() => setShowAll(true)} className="gap-2 border-border/50 hover:bg-primary/10">
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

// ─── Section: Features Grid ─────────────────────────────────────────────────

function FeaturesSection() {
  const [activeCategory, setActiveCategory] = useState<FeatureCategory | 'All'>('All');
  const categories: (FeatureCategory | 'All')[] = ['All', 'Critical', 'High', 'Medium', 'Competitive', 'Future'];
  const filtered = activeCategory === 'All' ? FEATURES : FEATURES.filter(f => f.category === activeCategory);

  return (
    <section className="py-20 md:py-28 relative" id="features">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <SectionHeading
          title="75+ Features"
          subtitle="Everything you need. Nothing you don't."
          id="features-heading"
        />

        {/* Category filter */}
        <AnimateOnScroll className="flex flex-wrap gap-2 justify-center mb-10">
          {categories.map(cat => {
            const config = cat === 'All' ? null : CATEGORY_CONFIG[cat];
            return (
              <Button
                key={cat}
                variant={activeCategory === cat ? 'default' : 'outline'}
                size="sm"
                onClick={() => setActiveCategory(cat)}
                className={activeCategory === cat
                  ? 'bg-primary hover:bg-primary/90'
                  : 'border-border/50 hover:bg-primary/10'
                }
              >
                {cat !== 'All' && config && (
                  <span className={`w-2 h-2 rounded-full ${
                    cat === 'Critical' ? 'bg-red-400' :
                    cat === 'High' ? 'bg-orange-400' :
                    cat === 'Medium' ? 'bg-yellow-400' :
                    cat === 'Competitive' ? 'bg-emerald-400' :
                    'bg-blue-400'
                  }`} />
                )}
                {cat}
                <span className="text-xs opacity-60 ml-1">
                  ({cat === 'All' ? FEATURES.length : FEATURES.filter(f => f.category === cat).length})
                </span>
              </Button>
            );
          })}
        </AnimateOnScroll>

        {/* Features grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {filtered.map((feature, idx) => {
            const config = CATEGORY_CONFIG[feature.category];
            const Icon = feature.icon;
            return (
              <AnimateOnScroll key={feature.name} delay={Math.min(idx * 0.03, 0.5)}>
                <Card className={`group h-full border-border/30 ${config.bg} hover:border-primary/30 transition-all duration-300 hover:shadow-lg hover:shadow-primary/5 hover:-translate-y-0.5`}>
                  <CardContent className="p-4">
                    <div className="flex items-start gap-3">
                      <div className={`shrink-0 w-9 h-9 rounded-lg ${config.bg} border ${config.border} flex items-center justify-center group-hover:scale-110 transition-transform`}>
                        <Icon className={`w-4 h-4 ${config.color}`} />
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <span className="font-semibold text-sm text-foreground/95 truncate">{feature.name}</span>
                        </div>
                        <p className="text-xs text-muted-foreground leading-relaxed">{feature.description}</p>
                        <Badge className={`mt-2 text-[10px] px-1.5 py-0 h-5 border ${config.badge}`}>
                          {feature.category}
                        </Badge>
                      </div>
                    </div>
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

// ─── Section: Quick Start ───────────────────────────────────────────────────

function QuickStartSection() {
  return (
    <section className="py-20 md:py-28 relative" id="quickstart">
      <div className="absolute inset-0 bg-gradient-to-b from-background via-primary/[0.02] to-background" />
      <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <SectionHeading
          title="Quick Start"
          subtitle="Up and running in under 60 seconds"
        />

        <div className="space-y-6">
          <AnimateOnScroll>
            <div className="flex items-center gap-3 mb-3">
              <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold text-sm">1</div>
              <h3 className="text-lg font-semibold">Add dependency</h3>
            </div>
            <CodeBlock
              code={`# pubspec.yaml
dependencies:
  rift: ^1.0.0`}
              filename="pubspec.yaml"
            />
          </AnimateOnScroll>

          <AnimateOnScroll delay={0.1}>
            <div className="flex items-center gap-3 mb-3">
              <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold text-sm">2</div>
              <h3 className="text-lg font-semibold">Hello Rift</h3>
            </div>
            <DartCode code={`import 'package:rift/rift.dart';

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

  // Query with filters
  final devs = users.query()
    .where('role', equalTo: 'Developer')
    .sortBy('name')
    .findAll();
}`} />
          </AnimateOnScroll>
        </div>
      </div>
    </section>
  );
}

// ─── Section: Architecture ──────────────────────────────────────────────────

function ArchitectureSection() {
  const layers = [
    { name: 'API Layer', desc: 'Public API & Box interface', color: 'from-violet-500 to-purple-600', bgColor: 'bg-violet-500/10', borderColor: 'border-violet-500/30', icon: Code2 },
    { name: 'Query Engine', desc: 'Filters, sorting, aggregation', color: 'from-purple-500 to-fuchsia-600', bgColor: 'bg-purple-500/10', borderColor: 'border-purple-500/30', icon: Filter },
    { name: 'Advanced Features', desc: 'FTS, CRDT, Vectors, Geo', color: 'from-fuchsia-500 to-pink-600', bgColor: 'bg-fuchsia-500/10', borderColor: 'border-fuchsia-500/30', icon: Sparkles },
    { name: 'Index Engine', desc: 'B-tree, composite, FTS indexes', color: 'from-pink-500 to-rose-600', bgColor: 'bg-pink-500/10', borderColor: 'border-pink-500/30', icon: Search },
    { name: 'Core Engine', desc: 'Transactions, WAL, isolation', color: 'from-rose-500 to-red-600', bgColor: 'bg-rose-500/10', borderColor: 'border-rose-500/30', icon: Shield },
    { name: 'Storage Engine', desc: 'Binary I/O, compression, mmap', color: 'from-orange-500 to-amber-600', bgColor: 'bg-orange-500/10', borderColor: 'border-orange-500/30', icon: HardDrive },
  ];

  return (
    <section className="py-20 md:py-28 relative">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        <SectionHeading
          title="Architecture"
          subtitle="Layered design for maximum extensibility"
        />

        <AnimateOnScroll>
          <div className="relative">
            {/* Center connecting line */}
            <div className="absolute left-1/2 top-0 bottom-0 w-px bg-gradient-to-b from-violet-500/30 via-fuchsia-500/30 to-amber-500/30 hidden lg:block" />

            <div className="space-y-2">
              {layers.map((layer, idx) => {
                const Icon = layer.icon;
                return (
                  <React.Fragment key={layer.name}>
                    <motion.div
                      initial={{ opacity: 0, x: -30 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true, margin: '-30px' }}
                      transition={{ duration: 0.5, delay: idx * 0.1 }}
                    >
                      <div className={`group relative rounded-xl border ${layer.borderColor} ${layer.bgColor} overflow-hidden hover:shadow-lg hover:shadow-primary/5 transition-all duration-300`}>
                        <div className={`absolute inset-0 bg-gradient-to-r ${layer.color} opacity-[0.06] group-hover:opacity-[0.12] transition-opacity`} />
                        <div className="relative flex items-center gap-4 p-4 md:p-5">
                          <div className={`shrink-0 w-10 h-10 rounded-lg bg-gradient-to-br ${layer.color} flex items-center justify-center shadow-lg`}>
                            <Icon className="w-5 h-5 text-white" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <h4 className="font-bold text-foreground/95">{layer.name}</h4>
                            <p className="text-sm text-muted-foreground">{layer.desc}</p>
                          </div>
                        </div>
                      </div>
                    </motion.div>
                    {/* Arrow connector */}
                    {idx < layers.length - 1 && (
                      <motion.div
                        initial={{ opacity: 0, scale: 0.5 }}
                        whileInView={{ opacity: 1, scale: 1 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.3, delay: idx * 0.1 + 0.2 }}
                        className="flex justify-center py-1"
                      >
                        <div className="w-6 h-6 rounded-full border border-border/50 bg-card flex items-center justify-center">
                          <svg width="10" height="6" viewBox="0 0 10 6" fill="none" className="text-primary">
                            <path d="M1 1L5 5L9 1" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                          </svg>
                        </div>
                      </motion.div>
                    )}
                  </React.Fragment>
                );
              })}
            </div>
          </div>
        </AnimateOnScroll>
      </div>
    </section>
  );
}

// ─── Section: Benchmarks ────────────────────────────────────────────────────

function BenchmarksSection() {
  const [animated, setAnimated] = useState(false);
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });

  useEffect(() => {
    if (isInView) {
      const timer = setTimeout(() => setAnimated(true), 200);
      return () => clearTimeout(timer);
    }
  }, [isInView]);

  const maxVal = 130000;

  return (
    <section className="py-20 md:py-28 relative" id="benchmarks" ref={ref}>
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <SectionHeading
          title="Performance"
          subtitle="Blazing fast. Benchmarks don't lie."
        />

        <AnimateOnScroll>
          <div className="space-y-8">
            {BENCHMARKS.map(bench => (
              <div key={bench.label}>
                <h3 className="text-lg font-semibold mb-4 text-foreground/90">{bench.label} Operations</h3>
                <div className="space-y-3">
                  {/* Rift bar */}
                  <div className="flex items-center gap-3">
                    <span className="text-sm font-medium w-14 text-primary">Rift</span>
                    <div className="flex-1 h-8 bg-primary/10 rounded-lg overflow-hidden relative">
                      <motion.div
                        className="h-full bg-gradient-to-r from-primary to-violet-400 rounded-lg relative"
                        initial={{ width: 0 }}
                        animate={animated ? { width: `${(bench.rift / maxVal) * 100}%` } : { width: 0 }}
                        transition={{ duration: 1.2, ease: 'easeOut' }}
                      >
                        <span className="absolute right-2 top-1/2 -translate-y-1/2 text-xs font-bold text-white">
                          {bench.rift.toLocaleString()} ops/s
                        </span>
                      </motion.div>
                    </div>
                  </div>
                  {/* Other DBs */}
                  {bench.others.map(other => (
                    <div key={other.name} className="flex items-center gap-3">
                      <span className="text-sm font-medium w-14 text-muted-foreground">{other.name}</span>
                      <div className="flex-1 h-7 bg-muted/30 rounded-lg overflow-hidden relative">
                        {other.value > 0 ? (
                          <motion.div
                            className="h-full bg-muted-foreground/30 rounded-lg relative"
                            initial={{ width: 0 }}
                            animate={animated ? { width: `${(other.value / maxVal) * 100}%` } : { width: 0 }}
                            transition={{ duration: 1.2, ease: 'easeOut' }}
                          >
                            <span className="absolute right-2 top-1/2 -translate-y-1/2 text-xs font-medium text-muted-foreground">
                              {other.value.toLocaleString()} ops/s
                            </span>
                          </motion.div>
                        ) : (
                          <div className="h-full flex items-center pl-3">
                            <span className="text-xs text-muted-foreground/50">N/A</span>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
            <p className="text-xs text-muted-foreground/60 text-center mt-6">
              Benchmarks performed on Apple M2, 16GB RAM, macOS 14. Results may vary by platform.
            </p>
          </div>
        </AnimateOnScroll>
      </div>
    </section>
  );
}

// ─── Section: Code Examples ─────────────────────────────────────────────────

function CodeExamplesSection() {
  return (
    <section className="py-20 md:py-28 relative">
      <div className="absolute inset-0 bg-gradient-to-b from-background via-primary/[0.02] to-background" />
      <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <SectionHeading
          title="Code Examples"
          subtitle="See Rift in action"
        />

        <AnimateOnScroll>
          <Tabs defaultValue="queries" className="w-full">
            <TabsList className="w-full flex flex-wrap h-auto gap-1 bg-muted/50 p-1 rounded-xl">
              {[
                { value: 'queries', label: 'Queries', icon: Filter },
                { value: 'reactive', label: 'Reactive', icon: Radio },
                { value: 'encryption', label: 'Encryption', icon: Lock },
                { value: 'sync', label: 'Sync', icon: RefreshCw },
              ].map(tab => {
                const Icon = tab.icon;
                return (
                  <TabsTrigger key={tab.value} value={tab.value} className="flex-1 gap-1.5 data-[state=active]:bg-primary/20 data-[state=active]:text-primary">
                    <Icon className="w-4 h-4" />
                    <span className="hidden sm:inline">{tab.label}</span>
                  </TabsTrigger>
                );
              })}
            </TabsList>

            <TabsContent value="queries" className="mt-6">
              <DartCode code={`import 'package:rift/rift.dart';

void main() async {
  await Rift.init();
  final users = await Rift.openBox<Map>('users');

  // Seed some data
  await users.putAll({
    'u1': {'name': 'Alice', 'age': 28, 'city': 'NYC'},
    'u2': {'name': 'Bob', 'age': 17, 'city': 'LA'},
    'u3': {'name': 'Charlie', 'age': 35, 'city': 'NYC'},
  });

  // Complex query: adults in NYC, sorted by name
  final results = users.query()
    .where('age', greaterThan: 18)
    .where('city', equalTo: 'NYC')
    .sortBy('name', descending: true)
    .limit(10)
    .findAll();

  // Aggregation
  final avgAge = users.query()
    .where('city', equalTo: 'NYC')
    .average('age');
}`} />
            </TabsContent>

            <TabsContent value="reactive" className="mt-6">
              <DartCode code={`import 'package:rift/rift.dart';

void main() async {
  await Rift.init();
  final users = await Rift.openBox<Map>('users');

  // Live query — automatically updates
  final subscription = users.query()
    .where('role', equalTo: 'admin')
    .live()
    .listen((results) {
      print('Admins updated: \$\{results.length} found');
      for (final user in results) {
        print('  - \$\{user[\'name\']}');
      }
    });

  // These changes trigger the listener
  await users.put('u1', {'name': 'Alice', 'role': 'admin'});
  await users.put('u2', {'name': 'Bob', 'role': 'user'});
  await users.put('u3', {'name': 'Charlie', 'role': 'admin'});

  // Don't forget to dispose
  await subscription.cancel();
}`} />
            </TabsContent>

            <TabsContent value="encryption" className="mt-6">
              <DartCode code={`import 'package:rift/rift.dart';

void main() async {
  await Rift.init(encryptionKey: 'your-256-bit-key');

  // Encrypted box
  final vault = await Rift.openBox<Map>(
    'vault',
    encryption: RiftEncryption.aes256,
  );

  await vault.put('secret', {
    'token': 'abc123',
    'ssn': '000-00-0000',
  });

  // Field-level encryption (Future)
  final users = await Rift.openBox<Map>(
    'users',
    encryptedFields: ['ssn', 'creditCard'],
  );

  // Only specified fields are encrypted
  await users.put('u1', {
    'name': 'Alice',        // plain text
    'ssn': '000-00-0000',   // encrypted
  });
}`} />
            </TabsContent>

            <TabsContent value="sync" className="mt-6">
              <DartCode code={`import 'package:rift/rift.dart';

void main() async {
  await Rift.init();

  // CRDT-enabled box for conflict-free sync
  final notes = await Rift.openBox<Map>(
    'notes',
    crdt: true,
  );

  // Local mutations are automatically tracked
  await notes.put('n1', {
    'title': 'Meeting Notes',
    'content': 'Discuss roadmap',
    'updatedAt': DateTime.now(),
  });

  // Sync layer — push local changes
  final sync = RiftSync(notes, adapter: HttpSyncAdapter(
    endpoint: 'https://api.example.com/sync',
  ));

  await sync.push(); // Send local changes
  await sync.pull(); // Receive remote changes

  // Conflicts resolved automatically via CRDT
  // CDC stream for real-time updates
  notes.changes.listen((change) {
    print('Changed: \$\{change.key} → \$\{change.value}');
  });
}`} />
            </TabsContent>
          </Tabs>
        </AnimateOnScroll>
      </div>
    </section>
  );
}

// ─── Section: Packages ──────────────────────────────────────────────────────

function PackagesSection() {
  return (
    <section className="py-20 md:py-28 relative" id="packages">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        <SectionHeading
          title="Packages"
          subtitle="Everything you need, modular by design"
        />

        <div className="grid sm:grid-cols-2 gap-4 md:gap-6">
          {PACKAGES.map((pkg, idx) => {
            const Icon = pkg.icon;
            return (
              <AnimateOnScroll key={pkg.name} delay={idx * 0.1}>
                <Card className={`h-full border-border/30 transition-all duration-300 hover:shadow-lg hover:shadow-primary/5 hover:-translate-y-0.5 ${pkg.highlight ? 'rift-glow-strong border-primary/30 bg-primary/5' : 'hover:border-primary/20'}`}>
                  <CardHeader className="pb-2">
                    <div className="flex items-center gap-3">
                      <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${pkg.highlight ? 'bg-primary/20' : 'bg-muted'}`}>
                        <Icon className={`w-5 h-5 ${pkg.highlight ? 'text-primary' : 'text-muted-foreground'}`} />
                      </div>
                      <div>
                        <CardTitle className="text-base">
                          <code className="font-mono">{pkg.name}</code>
                        </CardTitle>
                        {pkg.highlight && (
                          <Badge className="mt-1 bg-primary/20 text-primary border-primary/30 text-[10px]">
                            Core
                          </Badge>
                        )}
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm text-muted-foreground">{pkg.description}</p>
                    <div className="mt-3 p-2 rounded-md bg-[oklch(0.06_0.015_293)] font-mono text-xs text-primary/80">
                      {pkg.name === 'rift' ? 'rift: ^1.0.0' : `${pkg.name}: ^1.0.0`}
                    </div>
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

// ─── Section: Migration ─────────────────────────────────────────────────────

function MigrationSection() {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText("import 'package:rift/rift.dart';");
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section className="py-20 md:py-28 relative">
      <div className="absolute inset-0 bg-gradient-to-b from-background via-primary/[0.02] to-background" />
      <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <SectionHeading
          title="Migrate from Hive"
          subtitle="It's easier than you think"
        />

        <AnimateOnScroll>
          <Card className="border-primary/20 bg-primary/5 rift-glow">
            <CardContent className="p-6 md:p-8">
              <div className="text-center mb-6">
                <h3 className="text-xl md:text-2xl font-bold mb-2">Just change the import!</h3>
                <p className="text-muted-foreground">Rift is a superset of the Hive API. Migration is one line.</p>
              </div>

              <div className="space-y-4">
                <div className="rounded-lg bg-[oklch(0.06_0.015_293)] p-4 border border-red-500/20">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-xs font-medium text-red-400">Old</span>
                  </div>
                  <code className="text-sm font-mono text-red-300/80 line-through">
                    import &apos;package:hive_ce/hive_ce.dart&apos;;
                  </code>
                </div>

                <div className="flex justify-center">
                  <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
                    <ArrowRight className="w-5 h-5 text-primary" />
                  </div>
                </div>

                <div className="rounded-lg bg-[oklch(0.06_0.015_293)] p-4 border border-primary/30 relative">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-xs font-medium text-primary">New</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <code className="text-sm font-mono text-primary/90">
                      import &apos;package:rift/rift.dart&apos;;
                    </code>
                    <button
                      onClick={handleCopy}
                      className="shrink-0 p-1.5 rounded-md hover:bg-primary/20 transition-colors text-primary/60 hover:text-primary"
                      aria-label="Copy to clipboard"
                    >
                      {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
              </div>

              <div className="mt-6 text-center">
                <p className="text-sm text-muted-foreground">
                  That&apos;s it. Same API. 75+ more features. Zero native dependencies.
                </p>
              </div>
            </CardContent>
          </Card>
        </AnimateOnScroll>
      </div>
    </section>
  );
}

// ─── Section: Footer ────────────────────────────────────────────────────────

function Footer() {
  return (
    <footer className="border-t border-border/30 py-12 md:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col items-center text-center gap-6">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-primary/20 flex items-center justify-center">
              <Database className="w-5 h-5 text-primary" />
            </div>
            <span className="text-xl font-bold gradient-text">Rift</span>
          </div>

          <p className="text-muted-foreground text-sm">
            Made with ❤️ by <a href="https://github.com/idris-ghamid" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">Idris Ghamid</a>
          </p>

          <div className="flex items-center gap-6">
            <a href="https://github.com/idris-ghamid/rift" target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors">
              <Github className="w-4 h-4" />
              GitHub
            </a>
            <span className="text-muted-foreground/30">|</span>
            <span className="text-sm text-muted-foreground">Apache 2.0 License</span>
          </div>

          <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20">
            <span className="text-primary text-sm">⭐</span>
            <span className="text-sm text-muted-foreground">If Rift helps you, give it a star!</span>
          </div>

          <p className="text-xs text-muted-foreground/40 mt-4">
            © {new Date().getFullYear()} Rift Database. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}

// ─── Main Landing Page ─────────────────────────────────────────────────────

export default function RiftLanding() {
  return (
    <div className="min-h-screen flex flex-col bg-background">
      <Navbar />
      <main className="flex-1">
        <HeroSection />
        <ComparisonSection />
        <FeaturesSection />
        <QuickStartSection />
        <ArchitectureSection />
        <BenchmarksSection />
        <CodeExamplesSection />
        <PackagesSection />
        <MigrationSection />
      </main>
      <Footer />
    </div>
  );
}
