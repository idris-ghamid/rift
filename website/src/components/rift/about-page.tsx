'use client';

import React, { useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import {
  Code2, Smartphone, Globe, Gamepad2, Palette, Brain,
  Linkedin, Twitter, Instagram, Github, ExternalLink,
  Youtube, MessageCircle, Pin, Send, Film,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

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

const FOCUS_AREAS = [
  { icon: Smartphone, label: 'Mobile & Web Development', color: 'text-apple-blue dark:text-[#0A84FF]', bg: 'bg-apple-blue/10 dark:bg-[#0A84FF]/10' },
  { icon: Brain, label: 'AI Systems & Automation', color: 'text-apple-purple dark:text-[#5E5CE6]', bg: 'bg-apple-purple/10 dark:bg-[#5E5CE6]/10' },
  { icon: Code2, label: 'Developer Tools & Infrastructure', color: 'text-apple-violet dark:text-[#BF5AF2]', bg: 'bg-apple-violet/10 dark:bg-[#BF5AF2]/10' },
  { icon: Gamepad2, label: 'Game Development (Unity)', color: 'text-apple-orange dark:text-[#FF9F0A]', bg: 'bg-apple-orange/10 dark:bg-[#FF9F0A]/10' },
  { icon: Palette, label: 'Creative Editing (AE, Photoshop)', color: 'text-apple-green dark:text-[#30D158]', bg: 'bg-apple-green/10 dark:bg-[#30D158]/10' },
];

const TECH_STACK = [
  { category: 'Mobile', items: ['Flutter', 'Dart', 'Kotlin'], color: 'text-apple-blue dark:text-[#0A84FF]' },
  { category: 'Web', items: ['React', 'Next.js', 'JavaScript', 'HTML/CSS', 'Tailwind CSS'], color: 'text-apple-purple dark:text-[#5E5CE6]' },
  { category: 'AI', items: ['LLMs', 'Gemini API', 'Automation Workflows'], color: 'text-apple-violet dark:text-[#BF5AF2]' },
  { category: 'Game Dev', items: ['Unity'], color: 'text-apple-orange dark:text-[#FF9F0A]' },
];

const SOCIAL_LINKS = [
  { icon: Linkedin, label: 'LinkedIn', href: 'https://www.linkedin.com/in/idris-ghamid', color: 'hover:text-[#0A66C2]' },
  { icon: Twitter, label: 'X (Twitter)', href: 'https://x.com/IdrisGhamid', color: 'hover:text-foreground' },
  { icon: Instagram, label: 'Instagram', href: 'https://www.instagram.com/idris.ghamid', color: 'hover:text-[#E4405F]' },
  { icon: MessageCircle, label: 'Threads', href: 'https://www.threads.com/@idris.ghamid', color: 'hover:text-foreground' },
  { icon: Youtube, label: 'TikTok', href: 'https://www.tiktok.com/@idris.ghamid', color: 'hover:text-[#FE2C55]' },
  { icon: Globe, label: 'Reddit', href: 'https://www.reddit.com/u/IdrisGhamid', color: 'hover:text-[#FF4500]' },
  { icon: Send, label: 'Telegram', href: 'https://t.me/IDRV72', color: 'hover:text-[#0088CC]' },
  { icon: Pin, label: 'Pinterest', href: 'https://www.pinterest.com/idrisghamid', color: 'hover:text-[#E60023]' },
  { icon: Github, label: 'GitHub', href: 'https://github.com/idris-ghamid', color: 'hover:text-foreground' },
];

const IDRISIUM_PRODUCTS = [
  'Mobile & Web Apps',
  'Developer Tools',
  'AI Systems & Automation',
];

export default function AboutPage() {
  return (
    <main className="min-h-screen pt-24 pb-16">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Profile Header */}
        <AnimateOnScroll className="text-center mb-16">
          {/* Avatar */}
          <div className="mb-8 flex justify-center">
            <div className="w-28 h-28 rounded-full bg-gradient-to-br from-apple-blue to-apple-purple flex items-center justify-center shadow-xl shadow-primary/20">
              <span className="text-4xl font-bold text-white">IG</span>
            </div>
          </div>

          {/* Name */}
          <h1 className="text-4xl md:text-5xl font-bold mb-2 tracking-tight">
            Idris Ghamid
          </h1>
          <p className="text-xl text-muted-foreground mb-3" dir="rtl" lang="ar">
            إدريس غامد
          </p>

          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-primary/10 border border-primary/20 text-primary text-sm font-medium mb-6">
            <Code2 className="w-3.5 h-3.5" />
            Founder @ IDRISIUM Corp
          </div>

          {/* Bio */}
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto leading-relaxed">
            Programmer building mobile apps, web systems &amp; games (Unity) | Editor (AE, Photoshop)
          </p>
        </AnimateOnScroll>

        {/* Overview */}
        <AnimateOnScroll delay={0.1} className="mb-16">
          <Card className="border-border/30 bg-card/50 backdrop-blur-sm">
            <CardContent className="p-8">
              <h2 className="text-2xl font-semibold mb-4">Overview</h2>
              <p className="text-muted-foreground leading-relaxed text-base">
                I build scalable software systems, developer tools, and AI-powered products across mobile and web. 
                I also work on game development and creative digital production.
              </p>
            </CardContent>
          </Card>
        </AnimateOnScroll>

        {/* Focus Areas */}
        <AnimateOnScroll delay={0.15} className="mb-16">
          <h2 className="text-2xl font-semibold mb-6 text-center">Focus Areas</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {FOCUS_AREAS.map((area, idx) => {
              const Icon = area.icon;
              return (
                <AnimateOnScroll key={area.label} delay={idx * 0.06}>
                  <Card className="h-full border-border/30 bg-card/50 backdrop-blur-sm apple-card-hover">
                    <CardContent className="p-5 flex items-center gap-4">
                      <div className={`w-11 h-11 rounded-xl ${area.bg} flex items-center justify-center shrink-0`}>
                        <Icon className={`w-5 h-5 ${area.color}`} />
                      </div>
                      <span className="font-medium text-sm">{area.label}</span>
                    </CardContent>
                  </Card>
                </AnimateOnScroll>
              );
            })}
          </div>
        </AnimateOnScroll>

        {/* Tech Stack */}
        <AnimateOnScroll delay={0.2} className="mb-16">
          <h2 className="text-2xl font-semibold mb-6 text-center">Tech Stack</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {TECH_STACK.map((stack, idx) => (
              <AnimateOnScroll key={stack.category} delay={idx * 0.08}>
                <Card className="border-border/30 bg-card/50 backdrop-blur-sm">
                  <CardContent className="p-6">
                    <h3 className={`font-semibold mb-3 ${stack.color}`}>{stack.category}</h3>
                    <div className="flex flex-wrap gap-2">
                      {stack.items.map((item) => (
                        <span
                          key={item}
                          className="px-3 py-1.5 rounded-lg bg-secondary/60 text-sm text-foreground/80"
                        >
                          {item}
                        </span>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </AnimateOnScroll>
            ))}
          </div>
        </AnimateOnScroll>

        {/* IDRISIUM Corp */}
        <AnimateOnScroll delay={0.25} className="mb-16">
          <Card className="border-border/30 bg-card/50 backdrop-blur-sm overflow-hidden relative">
            <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-apple-purple/5" />
            <CardContent className="p-8 relative z-10">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-apple-blue to-apple-purple flex items-center justify-center">
                  <span className="text-white font-bold text-sm">ID</span>
                </div>
                <div>
                  <h2 className="text-2xl font-semibold">IDRISIUM Corp</h2>
                  <a
                    href="http://idrisium.linkpc.net/"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm text-primary hover:underline inline-flex items-center gap-1"
                  >
                    idrisium.linkpc.net
                    <ExternalLink className="w-3 h-3" />
                  </a>
                </div>
              </div>
              <p className="text-muted-foreground mb-5 leading-relaxed">
                Building modern digital products, developer tools, and AI-driven systems.
              </p>
              <div className="flex flex-wrap gap-2">
                {IDRISIUM_PRODUCTS.map((product) => (
                  <Badge key={product} className="px-3 py-1 bg-primary/10 text-primary border-primary/20 hover:bg-primary/15">
                    {product}
                  </Badge>
                ))}
              </div>
            </CardContent>
          </Card>
        </AnimateOnScroll>

        {/* Connect Links */}
        <AnimateOnScroll delay={0.3}>
          <h2 className="text-2xl font-semibold mb-6 text-center">Connect</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {SOCIAL_LINKS.map((link, idx) => {
              const Icon = link.icon;
              return (
                <AnimateOnScroll key={link.label} delay={idx * 0.04}>
                  <a
                    href={link.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className={`group flex items-center gap-3 p-4 rounded-xl border border-border/30 bg-card/50 backdrop-blur-sm apple-card-hover transition-colors ${link.color}`}
                  >
                    <Icon className="w-5 h-5 text-muted-foreground group-hover:text-inherit transition-colors shrink-0" />
                    <span className="text-sm font-medium">{link.label}</span>
                    <ExternalLink className="w-3 h-3 text-muted-foreground/40 ml-auto shrink-0" />
                  </a>
                </AnimateOnScroll>
              );
            })}
          </div>
        </AnimateOnScroll>
      </div>
    </main>
  );
}
