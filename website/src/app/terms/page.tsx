import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Kullanım Koşulları",
  description: "LabelWise kullanım koşulları için yer tutucu sayfa.",
  alternates: {
    canonical: "/terms",
  },
};

export default function TermsPage() {
  return (
    <LegalPage
      eyebrow="Koşullar"
      title="Kullanım Koşulları"
      intro="LabelWise kullanım şartları bu alanda yayınlanacaktır. Bu sayfa yayın öncesi güncellenecektir."
      sections={[
        {
          title: "Genel Çerçeve",
          body: (
            <p>
              Uygulamanın kullanım kapsamı, kullanıcı sorumlulukları ve hizmetin
              kullanım şartları burada tanımlanacaktır.
            </p>
          ),
        },
        {
          title: "Sürüm Notu",
          body: (
            <p>
              Hizmet modeli, mağaza gereklilikleri ve yayınlanan özelliklere göre
              nihai metin güncellenecektir.
            </p>
          ),
        },
      ]}
    />
  );
}
