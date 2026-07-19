import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Gizlilik Politikası",
  description: "LabelWise gizlilik politikası için yer tutucu sayfa.",
  alternates: {
    canonical: "/privacy",
  },
};

export default function PrivacyPage() {
  return (
    <LegalPage
      eyebrow="Gizlilik"
      title="Gizlilik Politikası"
      intro="Bu sayfada LabelWise için nihai gizlilik politikası yayınlanacaktır. Bu sayfa yayın öncesi güncellenecektir."
      sections={[
        {
          title: "Politika Özeti",
          body: (
            <p>
              LabelWise kullanıcı verilerinin nasıl işlendiğini, hangi amaçlarla
              kullanılabileceğini ve hangi güvenlik ilkelerinin uygulanacağını bu
              sayfada açık şekilde paylaşacaktır.
            </p>
          ),
        },
        {
          title: "Yayın Öncesi Güncelleme",
          body: (
            <p>
              Nihai uygulama akışları, yasal gereklilikler ve mağaza yayın
              ihtiyaçları doğrultusunda bu metin yayın öncesinde tamamlanacaktır.
            </p>
          ),
        },
      ]}
    />
  );
}
