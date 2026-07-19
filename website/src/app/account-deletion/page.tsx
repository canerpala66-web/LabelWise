import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

const effectiveDate = "19 Temmuz 2026";
const contactEmail = "canerpala66@gmail.com";

export const metadata: Metadata = {
  title: "LabelWise Hesap Silme Talebi",
  description:
    "LabelWise hesabinizi ve iliskili verilerinizi silme talebi hakkinda bilgi.",
  alternates: {
    canonical: "/account-deletion",
  },
};

export default function AccountDeletionPage() {
  return (
    <LegalPage
      eyebrow="Hesap Silme"
      title="Hesap Silme Talebi"
      intro="Bu sayfa, LabelWise kullanicilarinin hesap silme talebini nasil iletebilecegini aciklamak icin hazirlanmistir. Metin seffaflik amaclidir; otomatik silme islemi bu sayfa uzerinden baslatilmaz."
      effectiveDate={effectiveDate}
      contactEmail={contactEmail}
      transparencyNote="Hesap silme talebi, degerlendirme ve kimlik dogrulama sonrasinda uygulanabilir ve teknik olarak mumkun oldugu olcude yerine getirilir. Bazi kayitlar yasal veya guvenlik gerekceleriyle sinirli sure saklanabilir."
      sections={[
        {
          title: "Talep Hakkinda",
          body: (
            <p>
              LabelWise kullanicilari hesaplarinin ve hesapla iliskili
              verilerinin silinmesini talep edebilir.
            </p>
          ),
        },
        {
          title: "Talep Nasil Gonderilir",
          body: (
            <>
              <p>
                Talep icin canerpala66@gmail.com adresine e-posta
                gonderebilirsiniz.
              </p>
              <p className="mt-3">
                Onerilen e-posta konusu:
                <strong> LabelWise Hesap Silme Talebi</strong>
              </p>
              <p className="mt-3">
                Mumkunse hesabinizla iliskili e-posta adresinden yazmaniz, talebin
                daha hizli dogrulanmasina yardimci olur.
              </p>
            </>
          ),
        },
        {
          title: "Degerlendirme ve Uygulama",
          body: (
            <p>
              Talep degerlendirildikten sonra uygulanabilir ve teknik olarak mumkun
              oldugu olcude hesapla iliskili veriler silinir veya anonimlestirilir.
            </p>
          ),
        },
        {
          title: "Sinirli Sure Saklanabilecek Kayitlar",
          body: (
            <p>
              Bazi kayitlar guvenlik, kotuye kullanimın onlenmesi, yasal
              yukumlulukler, abonelik dogrulama surecleri veya uyusmazlik cozumu
              amaclariyla sinirli sure saklanabilir.
            </p>
          ),
        },
        {
          title: "Cihazdaki Yerel Veriler",
          body: (
            <p>
              Cihazda tutulan yerel veriler uygulamanin kaldirilmasi veya cihaz
              ayarlari uzerinden temizlenebilir.
            </p>
          ),
        },
        {
          title: "Abonelikler Hakkinda Onemli Not",
          body: (
            <p>
              Aktif bir aboneliginiz varsa, hesap silme islemi Google Play
              aboneliginizi otomatik olarak iptal etmeyebilir. Aboneliginizi Google
              Play uzerinden ayri olarak yonetmeniz veya iptal etmeniz gerekir.
            </p>
          ),
        },
        {
          title: "Iletisim",
          body: (
            <ul className="list-disc space-y-2 pl-5">
              <li>E-posta: canerpala66@gmail.com</li>
              <li>Web sitesi: https://labelwise.net</li>
            </ul>
          ),
        },
      ]}
    />
  );
}
