'use client';

import React from 'react';
import { Database, Save, Download, Search, ArrowRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export default function QuickStart() {
  return (
    <div className="max-w-4xl mx-auto space-y-8">
      {/* Hero Section */}
      <div className="text-center space-y-4">
        <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
          Quick Start
        </h1>
        <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
          Get started with Rift in 5 minutes. Simple, fast, and powerful.
        </p>
      </div>

      {/* Step 1: Open a Box */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="w-5 h-5 text-primary" />
            Step 1: Open a Box
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            Open a box to store your data. Boxes are like tables in SQL databases.
          </p>
          <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm">
            <pre>{`final box = await Rift.openBox('myBox');`}</pre>
          </div>
        </CardContent>
      </Card>

      {/* Step 2: Save Data */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Save className="w-5 h-5 text-primary" />
            Step 2: Save Data
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            Save data to the box using a key-value pair.
          </p>
          <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm">
            <pre>{`await box.put('user1', {'name': 'Idris', 'age': 25});`}</pre>
          </div>
        </CardContent>
      </Card>

      {/* Step 3: Get Data */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Download className="w-5 h-5 text-primary" />
            Step 3: Get Data
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            Retrieve data from the box using the key.
          </p>
          <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm">
            <pre>{`final user = box.get('user1');
print(user); // {'{name: Idris, age: 25}'}`}</pre>
          </div>
        </CardContent>
      </Card>

      {/* Step 4: Query Data */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Search className="w-5 h-5 text-primary" />
            Step 4: Query Data
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            Use the query builder to search and filter your data.
          </p>
          <div className="bg-muted/50 rounded-lg p-4 font-mono text-sm">
            <pre>{`final results = box.query()
  .where('age', greaterThan: 20)
  .findAll();`}</pre>
          </div>
        </CardContent>
      </Card>

      {/* Next Steps */}
      <Card className="border-primary/20">
        <CardHeader>
          <CardTitle>Next Steps</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
              <span className="font-medium">Typed Boxes</span>
              <ArrowRight className="w-4 h-4 text-muted-foreground" />
            </div>
            <div className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
              <span className="font-medium">Live Queries</span>
              <ArrowRight className="w-4 h-4 text-muted-foreground" />
            </div>
            <div className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
              <span className="font-medium">Transactions</span>
              <ArrowRight className="w-4 h-4 text-muted-foreground" />
            </div>
            <div className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
              <span className="font-medium">Encryption</span>
              <ArrowRight className="w-4 h-4 text-muted-foreground" />
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
