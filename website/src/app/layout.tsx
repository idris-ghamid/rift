import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { ThemeProvider } from "next-themes";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Rift — The next-generation NoSQL database for Flutter & Dart",
  description:
    "Pure Dart. Blazing fast. Reactive queries. Zero native dependencies. Rift through your data with the most feature-rich NoSQL database for Flutter & Dart.",
  keywords: [
    "Rift",
    "NoSQL",
    "Flutter",
    "Dart",
    "database",
    "Hive",
    "Isar",
    "reactive queries",
    "local database",
  ],
  authors: [{ name: "Idris Ghamid" }],
  icons: {
    icon: "https://z-cdn.chatglm.cn/z-ai/static/logo.svg",
  },
  openGraph: {
    title: "Rift — The next-generation NoSQL database for Flutter & Dart",
    description:
      "Pure Dart. Blazing fast. Reactive queries. Zero native dependencies.",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Rift — The next-generation NoSQL database for Flutter & Dart",
    description:
      "Pure Dart. Blazing fast. Reactive queries. Zero native dependencies.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark" suppressHydrationWarning>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-background text-foreground`}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem
          disableTransitionOnChange
        >
          {children}
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
