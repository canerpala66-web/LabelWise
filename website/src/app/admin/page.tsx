import { redirect } from "next/navigation";
import { getAdminGateState } from "@/lib/admin/auth";

export default async function AdminIndexPage() {
  const { session, isAdmin } = await getAdminGateState();

  if (!session) {
    redirect("/admin/login");
  }

  if (!isAdmin) {
    redirect("/admin/unauthorized");
  }

  redirect("/admin/submissions");
}
