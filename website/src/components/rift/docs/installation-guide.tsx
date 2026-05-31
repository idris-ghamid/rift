'use client';

import React from 'react';
import { Check, Copy, Terminal, Download, Zap } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export default function InstallationGuide() {
  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      {/* Hero Section */}
      <div className="text-center space-y-4">
        <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
          Installation Guide
        </h1>
        <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
          Get started with Rift in minutes. Simple installation for all platforms.
        </p>
      </div>

      {/* Quick Install */}
      <Card className="border-primary/20">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="w-5 h-5 text-primary" />
            Quick Install
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm relative">
            <code>flutter pub add rift</code>
            <Button
              size="sm"
              variant="ghost"
              className="absolute top-2 right-2"
              onClick={() => copyToClipboard('flutter pub add rift')}
            >
              <Copy className="w-4 h-4" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Core Package */}
      <Card>
        <CardHeader>
          <CardTitle>Core Package</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            The core Rift package for Dart projects. Includes all database features.
          </p>
          <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm relative">
            <code>dependencies:
  rift: ^1.0.0</code>
            <Button
              size="sm"
              variant="ghost"
              className="absolute top-2 right-2"
              onClick={() => copyToClipboard('dependencies:\n  rift: ^1.0.0')}
            >
              <Copy className="w-4 h-4" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Flutter Integration */}
      <Card>
        <CardHeader>
          <CardTitle>Flutter Integration</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            For Flutter projects, add the Flutter integration package.
          </p>
          <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm relative">
            <code>flutter pub add rift_flutter</code>
            <Button
              size="sm"
              variant="ghost"
              className="absolute top-2 right-2"
              onClick={() => copyToClipboard('flutter pub add rift_flutter')}
            >
              <Copy className="w-4 h-4" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Code Generation */}
      <Card>
        <CardHeader>
          <CardTitle>Code Generation</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            For automatic TypeAdapter generation, add the code generator.
          </p>
          <div className="space-y-3">
            <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm relative">
              <code>flutter pub add rift_generator --dev</code>
              <Button
                size="sm"
                variant="ghost"
                className="absolute top-2 right-2"
                onClick={() => copyToClipboard('flutter pub add rift_generator --dev')}
              >
                <Copy className="w-4 h-4" />
              </Button>
            </div>
            <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm relative">
              <code>flutter pub add build_runner --dev</code>
              <Button
                size="sm"
                variant="ghost"
                className="absolute top-2 right-2"
                onClick={() => copyToClipboard('flutter pub add build_runner --dev')}
              >
                <Copy className="w-4 h-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Initialize */}
      <Card>
        <CardHeader>
          <CardTitle>Initialize Rift</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            Initialize Rift in your Flutter app.
          </p>
          <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm relative">
            <pre>{`import 'package:rift_flutter/rift_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Rift.initFlutter();
  runApp(MyApp());
}`}</pre>
            <Button
              size="sm"
              variant="ghost"
              className="absolute top-2 right-2"
              onClick={() => copyToClipboard("import 'package:rift_flutter/rift_flutter.dart';\n\nvoid main() async {\n  WidgetsFlutterBinding.ensureInitialized();\n  await Rift.initFlutter();\n  runApp(MyApp());\n}")}
            >
              <Copy className="w-4 h-4" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Platform Support */}
      <Card>
        <CardHeader>
          <CardTitle>Platform Support</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {['Android', 'iOS', 'Web', 'Windows', 'macOS', 'Linux'].map((platform) => (
              <div key={platform} className="flex items-center gap-2">
                <Check className="w-4 h-4 text-green-500" />
                <span className="text-sm">{platform}</span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
