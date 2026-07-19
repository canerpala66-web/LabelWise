import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Yasal Bilgilendirme",
  description:
    "LabelWise sağlık, yapay zekâ ve veri doğruluğu açıklamaları için yer tutucu sayfa.",
  alternates: {
    canonical: "/disclaimer",
  },
};

export default function DisclaimerPage() {
  return (
    <LegalPage
      eyebrow="Bilgilendirme"
      title="Sağlık, Yapay Zekâ ve Veri Doğruluğu Açıklaması"
      intro="Bu sayfa yayın öncesi güncellenecektir."
      sections={[
        {
          title: "Tıbbi Sınırlar",
          body: (
            <p>
              LabelWise bilgilendirme amaçlıdır; tıbbi tavsiye, teşhis veya tedavi
              önerisi sunmaz.
            </p>
          ),
        },
        {
          title: "Veri ve AI Sınırları",
          body: (
            <p>
              Ürün etiketleri, veri kaynakları ve yapay zekâ çıktıları eksik ya da
              hatalı olabilir. Nihai değerlendirme için resmi ürün etiketi ve
              güvenilir uzman görüşü esas alınmalıdır.
            </p>
          ),
        },
      ]}
    />
  );
}
