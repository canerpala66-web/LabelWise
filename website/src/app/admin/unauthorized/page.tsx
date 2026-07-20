import type { Metadata } from "next";
import { AdminUnauthorized } from "@/components/admin-unauthorized";

export const metadata: Metadata = {
  title: "Yetkisiz Erisim",
  description: "LabelWise admin paneli yetki uyarisi.",
  robots: {
    index: false,
    follow: false,
  },
};

export default function AdminUnauthorizedPage() {
  return <AdminUnauthorized />;
}
