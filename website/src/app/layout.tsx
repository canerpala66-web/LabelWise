import type { Metadata } from "next";
import { Cormorant_Garamond, Manrope } from "next/font/google";
import "./globals.css";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";

const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["latin"],
});

const cormorant = Cormorant_Garamond({
  variable: "--font-cormorant",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://www.labelwise.net"),
  title: {
    default: "LabelWise | Barkodu okut, daha bilinçli seç.",
    template: "%s | LabelWise",
  },
  description:
    "LabelWise, gıda ürünlerinin içeriklerini, besin değerlerini ve etiket bilgilerini daha anlaşılır hale getiren mobil barkod tarama uygulamasıdır.",
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "LabelWise | Barkodu okut, daha bilinçli seç.",
    description:
      "Türkiye için geliştirilen LabelWise ile gıda ürünlerinin etiket bilgilerini daha anlaşılır şekilde keşfedin.",
    url: "https://www.labelwise.net",
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
      className={`${manrope.variable} ${cormorant.variable} h-full scroll-smooth antialiased`}
    >
      <body className="min-h-full">
        <div className="relative flex min-h-screen flex-col">
          <div className="site-shell absolute inset-0 -z-10" />
          <div className="site-mesh absolute inset-0 -z-10 opacity-90" />
          <SiteHeader />
          <div className="flex-1">{children}</div>
          <SiteFooter />
        </div>
      </body>
    </html>
  );
}
