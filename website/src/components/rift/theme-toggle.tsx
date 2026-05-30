'use client';

import { useTheme } from 'next-themes';
import { useSyncExternalStore } from 'react';
import { Sun, Moon } from 'lucide-react';

export function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  // Use useSyncExternalStore to detect client-side mounting
  const mounted = useSyncExternalStore(
    (callback) => {
      // No-op subscribe since we only need the initial render detection
      window.addEventListener('load', callback);
      return () => window.removeEventListener('load', callback);
    },
    () => true,
    () => false
  );

  if (!mounted) {
    return <div className="w-9 h-9" />;
  }

  return (
    <button
      onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
      className="w-9 h-9 rounded-full flex items-center justify-center hover:bg-secondary/80 transition-colors"
      aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
    >
      {theme === 'dark' ? (
        <Sun className="w-4 h-4 text-foreground" />
      ) : (
        <Moon className="w-4 h-4 text-foreground" />
      )}
    </button>
  );
}
