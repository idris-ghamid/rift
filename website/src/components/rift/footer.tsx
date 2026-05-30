'use client';

import { Database, Github, Linkedin, Twitter, Instagram, ExternalLink } from 'lucide-react';

export function Footer() {
  return (
    <footer className="border-t border-border/50 bg-card/50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="md:col-span-2">
            <div className="flex items-center gap-2.5 mb-4">
              <div className="w-8 h-8 rounded-lg bg-primary/15 flex items-center justify-center">
                <Database className="w-4.5 h-4.5 text-primary" />
              </div>
              <span className="text-xl font-semibold apple-gradient-text">
                Rift
              </span>
            </div>
            <p className="text-muted-foreground text-sm max-w-md leading-relaxed">
              The next-generation NoSQL database for Flutter &amp; Dart. 
              Pure Dart. Blazing fast. Reactive queries. Zero native dependencies.
            </p>
            <div className="flex gap-3 mt-4">
              <a
                href="https://github.com/idris-ghamid/rift"
                target="_blank"
                rel="noopener noreferrer"
                className="w-9 h-9 rounded-full bg-secondary/60 flex items-center justify-center hover:bg-primary/15 hover:text-primary transition-colors"
                aria-label="GitHub"
              >
                <Github className="w-4 h-4" />
              </a>
              <a
                href="https://www.linkedin.com/in/idris-ghamid"
                target="_blank"
                rel="noopener noreferrer"
                className="w-9 h-9 rounded-full bg-secondary/60 flex items-center justify-center hover:bg-primary/15 hover:text-primary transition-colors"
                aria-label="LinkedIn"
              >
                <Linkedin className="w-4 h-4" />
              </a>
              <a
                href="https://x.com/IdrisGhamid"
                target="_blank"
                rel="noopener noreferrer"
                className="w-9 h-9 rounded-full bg-secondary/60 flex items-center justify-center hover:bg-primary/15 hover:text-primary transition-colors"
                aria-label="X (Twitter)"
              >
                <Twitter className="w-4 h-4" />
              </a>
              <a
                href="https://www.instagram.com/idris.ghamid"
                target="_blank"
                rel="noopener noreferrer"
                className="w-9 h-9 rounded-full bg-secondary/60 flex items-center justify-center hover:bg-primary/15 hover:text-primary transition-colors"
                aria-label="Instagram"
              >
                <Instagram className="w-4 h-4" />
              </a>
            </div>
          </div>

          {/* Links */}
          <div>
            <h3 className="font-semibold text-sm mb-3">Product</h3>
            <ul className="space-y-2">
              {['Features', 'Quick Start', 'Documentation', 'Comparison'].map((item) => (
                <li key={item}>
                  <span className="text-sm text-muted-foreground hover:text-primary transition-colors cursor-pointer">
                    {item}
                  </span>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="font-semibold text-sm mb-3">Resources</h3>
            <ul className="space-y-2">
              {[
                { label: 'GitHub', href: 'https://github.com/idris-ghamid/rift' },
                { label: 'pub.dev', href: 'https://pub.dev/packages/rift' },
                { label: 'IDRISIUM Corp', href: 'http://idrisium.linkpc.net/' },
                { label: 'Issue Tracker', href: 'https://github.com/idris-ghamid/rift/issues' },
              ].map((item) => (
                <li key={item.label}>
                  <a
                    href={item.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm text-muted-foreground hover:text-primary transition-colors inline-flex items-center gap-1"
                  >
                    {item.label}
                    <ExternalLink className="w-3 h-3" />
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="mt-10 pt-6 border-t border-border/50 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-xs text-muted-foreground">
            &copy; {new Date().getFullYear()} IDRISIUM Corp. All rights reserved.
          </p>
          <p className="text-xs text-muted-foreground">
            Built with ❤️ by{' '}
            <a
              href="https://github.com/idris-ghamid"
              target="_blank"
              rel="noopener noreferrer"
              className="text-primary hover:underline"
            >
              Idris Ghamid
            </a>
          </p>
        </div>
      </div>
    </footer>
  );
}
