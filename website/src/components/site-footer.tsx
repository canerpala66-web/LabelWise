import Link from "next/link";

const footerLinks = [
  { href: "/privacy", label: "Gizlilik Politikası" },
  { href: "/terms", label: "Kullanım Koşulları" },
  { href: "/disclaimer", label: "Yasal Bilgilendirme" },
  { href: "/subscription-terms", label: "Abonelik Koşulları" },
  { href: "/contact", label: "İletişim" },
];

export function SiteFooter() {
  return (
    <footer className="border-t border-[color:var(--border-soft)] bg-[linear-gradient(180deg,rgba(8,18,15,0),rgba(6,14,11,0.92))]">
      <div className="mx-auto flex w-full max-w-7xl flex-col gap-8 px-6 py-10 sm:px-8 lg:px-10">
        <div className="flex flex-col gap-3">
          <span className="font-display text-3xl text-white">
            LabelWise
          </span>
          <p className="max-w-2xl text-sm leading-7 text-[color:var(--text-muted)]">
            Türkiye&apos;de gıda ürünlerini daha anlaşılır hale getirmek için
            geliştirilen mobil barkod tarama deneyimi.
          </p>
        </div>
        <nav className="flex flex-wrap gap-x-5 gap-y-3 text-sm text-[color:var(--text-muted)]">
          {footerLinks.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="transition-colors duration-300 hover:text-white"
            >
              {link.label}
            </Link>
          ))}
        </nav>
        <p className="text-xs uppercase tracking-[0.28em] text-[color:var(--text-soft)]">
          labelwise.net
        </p>
      </div>
    </footer>
  );
}
