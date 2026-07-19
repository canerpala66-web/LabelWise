import Image from "next/image";
import Link from "next/link";

const navItems = [
  { href: "/", label: "Ana Sayfa" },
  { href: "/#about", label: "Hakkında" },
  { href: "/#developer", label: "Geliştirici" },
  { href: "/privacy", label: "Politikalar" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 px-4 pt-4 sm:px-6 lg:px-8">
      <div className="mx-auto flex w-full max-w-7xl items-center justify-between rounded-full border border-white/12 bg-[rgba(10,26,21,0.72)] px-4 py-3 shadow-[0_20px_60px_rgba(5,12,10,0.28)] backdrop-blur-2xl sm:px-6">
        <Link
          href="/"
          className="flex items-center gap-3 text-white transition-transform duration-300 hover:scale-[1.02]"
        >
          <span className="overflow-hidden rounded-full shadow-[0_10px_30px_rgba(200,169,107,0.18)] ring-1 ring-white/10">
            <Image
              src="/labelwise-logo.png"
              alt="LabelWise logo"
              width={44}
              height={44}
              className="h-11 w-11 object-cover"
              priority
            />
          </span>
          <span className="font-display text-3xl leading-none">LabelWise</span>
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

        <Link href="/contact" className="button-nav">
          İletişim
        </Link>
      </div>
    </header>
  );
}
