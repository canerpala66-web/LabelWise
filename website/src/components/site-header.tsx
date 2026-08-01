import Image from "next/image";
import Link from "next/link";

const navItems = [
  { href: "/", label: "Ana Sayfa" },
  { href: "/blog", label: "Blog" },
  { href: "/#how-it-works", label: "Nasıl çalışır?" },
  { href: "/#premium", label: "Premium" },
  { href: "/#trust", label: "Güven" },
];

export function SiteHeader() {
  return (
    <header className="site-header sticky top-0 z-50 px-3 pt-3 sm:px-6 sm:pt-4 lg:px-8">
      <div className="site-header__inner mx-auto flex w-full max-w-7xl items-center justify-between rounded-full border border-white/12 bg-[rgba(10,26,21,0.72)] px-3.5 py-2.5 shadow-[0_20px_60px_rgba(5,12,10,0.28)] backdrop-blur-2xl sm:px-6 sm:py-3">
        <Link
          href="/"
          className="site-header__brand flex items-center gap-2.5 text-white transition-transform duration-300 hover:scale-[1.02] sm:gap-3"
        >
          <span className="overflow-hidden rounded-full shadow-[0_10px_30px_rgba(200,169,107,0.18)] ring-1 ring-white/10">
            <Image
              src="/labelwise-logo.png"
              alt="LabelWise logo"
              width={44}
              height={44}
              className="site-header__logo h-9 w-9 object-cover sm:h-11 sm:w-11"
              priority
            />
          </span>
          <span className="site-header__title font-display text-[1.55rem] leading-none sm:text-3xl">
            LabelWise
          </span>
        </Link>

        <nav className="hidden items-center gap-2 md:flex">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-full px-4 py-2 text-sm font-medium text-white/72 hover:bg-white/8 hover:text-white"
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <Link href="/contact" className="button-nav site-header__cta">
          İletişim
        </Link>
      </div>
    </header>
  );
}
