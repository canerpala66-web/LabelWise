import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Abonelik Koşulları",
  description: "LabelWise abonelik koşulları için yer tutucu sayfa.",
  alternates: {
    canonical: "/subscription-terms",
  },
};

export default function SubscriptionTermsPage() {
  return (
    <LegalPage
      eyebrow="Abonelik"
      title="Abonelik Koşulları"
      intro="Premium ve ücretli özelliklere ilişkin nihai şartlar burada yayınlanacaktır. Bu sayfa yayın öncesi güncellenecektir."
      sections={[
        {
          title: "Premium Durumu",
          body: (
            <p>
              Premium özellikler kademeli olarak kullanıma sunulacaktır. Bu
              sayfada sunulan planların kapsamı ve geçerli koşulları açıklanacaktır.
            </p>
          ),
        },
        {
          title: "Yayın Öncesi Güncelleme",
          body: (
            <p>
              Ücretlendirme, yenileme, iptal ve mağaza platformu koşullarına dair
              kesin metin yayın öncesi eklenecektir.
            </p>
          ),
        },
      ]}
    />
  );
}
