import type { Metadata } from "next";
import { Suspense } from "react";
import { AdminResetPasswordForm } from "@/components/admin-reset-password-form";

export const metadata: Metadata = {
  title: "Admin Şifre Sıfırlama",
  description: "LabelWise admin paneli için yeni şifre belirleme ekranı.",
  robots: {
    index: false,
    follow: false,
  },
};

export default function AdminResetPasswordPage() {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[28rem] opacity-80" />
      <section className="mx-auto flex min-h-[70vh] w-full max-w-6xl items-center justify-center px-6 py-16 sm:px-8 lg:px-10">
        <Suspense
          fallback={
            <div className="card w-full max-w-lg p-8 text-sm text-white/82 sm:p-10">
              Recovery oturumu hazırlanıyor...
            </div>
          }
        >
          <AdminResetPasswordForm />
        </Suspense>
      </section>
    </main>
  );
}
