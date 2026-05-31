'use client';

import React, { useState } from 'react';
import {
  Download, Terminal, BookOpen, ArrowRight, Package,
  Code2, Database, Zap, Shield, CheckCircle2, ExternalLink,
  ChevronRight,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import InstallationGuide from './docs/installation-guide';
import QuickStart from './docs/quick-start';

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
  const [activeSection, setActiveSection] = useState('installation');

  const scrollToSection = (id: string) => {
    setActiveSection(id);
  };

  return (
    <main className="min-h-screen pt-24 pb-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl md:text-5xl font-bold mb-4 tracking-tight">
            Documentation
          </h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Everything you need to know about Rift. From installation to advanced features.
          </p>
        </div>

        {/* Navigation */}
        <div className="flex flex-wrap justify-center gap-3 mb-12">
          {DOC_SECTIONS.map((section) => {
            const Icon = section.icon;
            return (
              <Button
                key={section.id}
                variant={activeSection === section.id ? 'default' : 'outline'}
                onClick={() => scrollToSection(section.id)}
                className="flex items-center gap-2"
              >
                <Icon className="w-4 h-4" />
                {section.title}
              </Button>
            );
          })}
        </div>

        {/* Content */}
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Sidebar */}
          <div className="lg:col-span-1">
            <Card className="sticky top-24">
              <CardContent className="p-4">
                <nav className="space-y-2">
                  {DOC_SECTIONS.map((section) => {
                    const Icon = section.icon;
                    return (
                      <button
                        key={section.id}
                        onClick={() => scrollToSection(section.id)}
                        className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-left transition-colors ${
                          activeSection === section.id
                            ? 'bg-primary text-primary-foreground'
                            : 'hover:bg-muted'
                        }`}
                      >
                        <Icon className="w-4 h-4" />
                        <span className="text-sm font-medium">{section.title}</span>
                      </button>
                    );
                  })}
                </nav>
              </CardContent>
            </Card>
          </div>

          {/* Main Content */}
          <div className="lg:col-span-3">
            {activeSection === 'installation' && <InstallationGuide />}
            {activeSection === 'quickstart' && <QuickStart />}
            {activeSection === 'api-reference' && (
              <div className="space-y-6">
                <h2 className="text-3xl font-bold mb-6">API Reference</h2>
                <div className="space-y-3">
                  {API_ENDPOINTS.map((endpoint) => (
                    <Card key={endpoint.path}>
                      <CardContent className="p-4">
                        <div className="flex items-start gap-4">
                          <Badge
                            variant={
                              endpoint.method === 'GET'
                                ? 'default'
                                : endpoint.method === 'PUT'
                                ? 'secondary'
                                : endpoint.method === 'DEL'
                                ? 'destructive'
                                : 'outline'
                            }
                            className="shrink-0"
                          >
                            {endpoint.method}
                          </Badge>
                          <div className="flex-1">
                            <code className="text-sm font-mono">{endpoint.path}</code>
                            <p className="text-sm text-muted-foreground mt-1">{endpoint.desc}</p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </div>
            )}
            {activeSection === 'migration' && (
              <div className="space-y-6">
                <h2 className="text-3xl font-bold mb-6">Migration from Hive</h2>
                <Card>
                  <CardContent className="p-6 space-y-4">
                    <p className="text-muted-foreground">
                      Migrating from Hive or hive_ce to Rift is simple. Rift maintains full API compatibility with Hive.
                    </p>
                    <div className="space-y-4">
                      <div className="flex items-start gap-3">
                        <CheckCircle2 className="w-5 h-5 text-green-500 mt-0.5" />
                        <div>
                          <h3 className="font-semibold mb-1">Replace imports</h3>
                          <code className="text-sm bg-muted/50 px-2 py-1 rounded">
                            import 'package:hive/hive.dart' → import 'package:rift/rift.dart'
                          </code>
                        </div>
                      </div>
                      <div className="flex items-start gap-3">
                        <CheckCircle2 className="w-5 h-5 text-green-500 mt-0.5" />
                        <div>
                          <h3 className="font-semibold mb-1">Replace Hive.init()</h3>
                          <code className="text-sm bg-muted/50 px-2 py-1 rounded">
                            Hive.init() → Rift.init()
                          </code>
                        </div>
                      </div>
                      <div className="flex items-start gap-3">
                        <CheckCircle2 className="w-5 h-5 text-green-500 mt-0.5" />
                        <div>
                          <h3 className="font-semibold mb-1">All other APIs remain the same</h3>
                          <p className="text-sm text-muted-foreground">
                            Box, HiveBox, HiveType, HiveField - all work exactly the same
                          </p>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
