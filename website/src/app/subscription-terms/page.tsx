import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

const effectiveDate = "19 Temmuz 2026";
const contactEmail = "canerpala66@gmail.com";

export const metadata: Metadata = {
  title: "LabelWise Abonelik Koşulları",
  description:
    "LabelWise premium abonelikler, Google Play odemeleri ve iptal surecleri hakkinda ozet kosullar.",
  alternates: {
    canonical: "/subscription-terms",
  },
};

export default function SubscriptionTermsPage() {
  return (
    <LegalPage
      eyebrow="Abonelik"
      title="Abonelik Koşulları"
      intro="Bu sayfa, LabelWise premium abonelikleri kullanima sunuldugunda uygulanacak genel esaslari aciklar. Metin seffaflik amaciyla hazirlanmistir; hukuki veya mali tavsiye niteliginde degildir."
      effectiveDate={effectiveDate}
      contactEmail={contactEmail}
      transparencyNote="Premium abonelikler kullanima sunuldugunda veya planlar uygulama icinde kademeli olarak sunuldugunda, satin alma sirasindaki son fiyat, vergi, yenileme ve teklif bilgileri Google Play ekraninda gosterildigi sekliyle gecerli olur."
      sections={[
        {
          title: "Premium Abonelik Hakkinda",
          body: (
            <p>
              Premium abonelikler kullanima sunuldugunda, kullanicilara ek ozellikler
              veya genisletilmis deneyimler saglayabilir. Planlar uygulama icinde
              kademeli olarak sunulabilir ve tum kullanicilar ayni anda ayni
              secenekleri gormeyebilir.
            </p>
          ),
        },
        {
          title: "Planlar ve Fiyatlar",
          body: (
            <ul className="list-disc space-y-2 pl-5">
              <li>Aylik Premium: 69,99 TL / ay</li>
              <li>Yillik Premium: 299,99 TL / yil</li>
            </ul>
          ),
        },
        {
          title: "Otomatik Yenileme",
          body: (
            <p>
              Google Play uzerinden satin alinan abonelikler, kullanici tarafindan
              iptal edilmedigi surece otomatik olarak yenilenebilir. Yenileme
              kosullari ve zamanlamasi satin alma aninda Google Play tarafindan
              gosterilir.
            </p>
          ),
        },
        {
          title: "Satin Alma ve Odeme Islemleri",
          body: (
            <p>
              Odemeler Google Play uzerinden islenir. LabelWise dogrudan tam kart
              bilgilerini toplamaz veya saklamaz. Satin alma sirasindaki son fiyat,
              vergiler, kampanyalar ve diger ayrintilar Google Play ekraninda
              gosterildigi sekliyle uygulanir.
            </p>
          ),
        },
        {
          title: "Abonelik Yonetimi ve Iptal",
          body: (
            <p>
              Kullanicilar aboneliklerini Google Play hesap / abonelik ayarlari
              uzerinden yonetebilir veya iptal edebilir. Uygulamanin silinmesi her
              zaman aboneligin otomatik olarak iptal edildigi anlamina gelmez.
            </p>
          ),
        },
        {
          title: "Premium Erisim ve Dogrulama",
          body: (
            <p>
              Premium erisim, yalnizca dogrulanmis abonelik yetkisi sonrasinda
              saglanir. Bu amacla satin alma dogrulama bilgileri ve abonelik
              metaverileri hizmetin calismasi icin gerekli oldugu olcude
              saklanabilir.
            </p>
          ),
        },
        {
          title: "Iade Politikasi",
          body: (
            <p>
              Iade talepleri ve uygunluk durumu, Google Play politikalarina ve
              uygulanabilir kurallara gore degerlendirilebilir. LabelWise her durum
              icin dogrudan iade taahhudu vermez.
            </p>
          ),
        },
        {
          title: "Ozelliklerin Degismesi",
          body: (
            <p>
              Premium kapsamindaki ozellikler zamanla degisebilir, yeniden
              duzenlenebilir veya belirli bolgelerde farklilasabilir. Belirli bir
              ozelligin surekli ve degismeden sunulacagi garanti edilmez.
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
