"use client";

import { usePathname } from "next/navigation";
import type { ReactNode } from "react";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";

type Props = {
  children: ReactNode;
};

function isAdminRoute(pathname: string | null) {
  return pathname === "/admin" || pathname?.startsWith("/admin/") || false;
}

export function SiteChrome({ children }: Props) {
  const pathname = usePathname();
  const hidePublicChrome = isAdminRoute(pathname);

  return (
    <div className="relative flex min-h-screen flex-col">
      <div className="site-shell absolute inset-0 -z-10" />
      <div className="site-mesh absolute inset-0 -z-10 opacity-90" />
      {hidePublicChrome ? null : <SiteHeader />}
      <div className="flex-1">{children}</div>
      {hidePublicChrome ? null : <SiteFooter />}
    </div>
  );
}
