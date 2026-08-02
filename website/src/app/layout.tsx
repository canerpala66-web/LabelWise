import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { SiteChrome } from "@/components/site-chrome";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin", "latin-ext"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://labelwise.net"),
  title: {
    default: "LabelWise | Etiketlerin arkasındaki gerçeği görün.",
    template: "%s | LabelWise",
  },
  description:
    "LabelWise, paketli gıdaların içeriklerini, besin değerlerini ve etiket dilini daha anlaşılır hale getiren premium barkod deneyimidir.",
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "LabelWise | Etiketlerin arkasındaki gerçeği görün.",
    description:
      "Barkodu tara, içeriği anla, daha bilinçli seç. Türkiye odaklı gıda şeffaflığı deneyimi.",
    url: "https://labelwise.net",
    siteName: "LabelWise",
    images: [
      {
        url: "/labelwise-logo.png",
        width: 1200,
        height: 1200,
        alt: "LabelWise logo",
      },
    ],
    locale: "tr_TR",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "LabelWise",
    description:
      "Gıda ürünlerinin etiket bilgilerini daha anlaşılır hale getiren mobil barkod tarama uygulaması.",
    images: ["/labelwise-logo.png"],
  },
  icons: {
    icon: [
      { url: "/labelwise-logo.png", type: "image/png" },
      { url: "/favicon.ico" },
    ],
    apple: [{ url: "/labelwise-logo.png", type: "image/png" }],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="tr"
      className={`${inter.variable} h-full scroll-smooth antialiased`}
    >
      <body className="min-h-full">
        <SiteChrome>{children}</SiteChrome>
      </body>
    </html>
  );
}
