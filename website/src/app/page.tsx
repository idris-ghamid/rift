'use client';

import React, { useState, useCallback, useSyncExternalStore } from 'react';
import { Navbar, type Page } from '@/components/rift/navbar';
import { Footer } from '@/components/rift/footer';
import HomePage from '@/components/rift/home-page';
import AboutPage from '@/components/rift/about-page';
import DocsPage from '@/components/rift/docs-page';

function getHash(): string {
  if (typeof window === 'undefined') return 'home';
  return window.location.hash.replace('#', '') || 'home';
}

function subscribeToHash(callback: () => void) {
  window.addEventListener('hashchange', callback);
  return () => window.removeEventListener('hashchange', callback);
}

export default function Home() {
  const hash = useSyncExternalStore(subscribeToHash, getHash, () => 'home');
  const validPage: Page = ['home', 'about', 'docs'].includes(hash) ? (hash as Page) : 'home';
  const [manualPage, setManualPage] = useState<Page | null>(null);

  const currentPage = manualPage ?? validPage;

  const handleNavigate = useCallback((page: Page) => {
    setManualPage(page);
    window.location.hash = page;
  }, []);

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <Navbar currentPage={currentPage} onNavigate={handleNavigate} />
      <div className="flex-1">
        {currentPage === 'home' && <HomePage />}
        {currentPage === 'about' && <AboutPage />}
        {currentPage === 'docs' && <DocsPage />}
      </div>
      <Footer />
    </div>
  );
}
