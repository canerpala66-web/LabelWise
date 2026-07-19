import type { Metadata } from "next";
import { SubmitProductContent } from "@/components/submit-product-content";

export const metadata: Metadata = {
  title: "Submitted Products",
  description: "LabelWise eksik urun gonderimi bilgilendirme sayfasi.",
  alternates: {
    canonical: "/submitted-products",
  },
};

export default function SubmittedProductsPage() {
  return <SubmitProductContent />;
}
