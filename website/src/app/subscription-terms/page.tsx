import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

const effectiveDate = "24 Temmuz 2026";
const contactEmail = "canerpala66@gmail.com";

export const metadata: Metadata = {
  title: "LabelWise Abonelik Koşulları",
  description:
    "LabelWise Premium abonelik planları, Google Play yenileme koşulları ve premium erişim doğrulaması hakkında özet bilgiler.",
  alternates: {
    canonical: "/subscription-terms",
  },
};

export default function SubscriptionTermsPage() {
  return (
    <LegalPage
      eyebrow="Abonelik"
      title="Abonelik Koşulları"
      intro="Bu sayfa, LabelWise Premium abonelikleri için geçerli olabilecek genel esasları açıklar. Metin genel bilgilendirme amaçlıdır; hukuki veya mali tavsiye niteliğinde değildir."
      effectiveDate={effectiveDate}
      contactEmail={contactEmail}
      transparencyNote="Premium planlar kademeli olarak kullanıma sunulabilir. Satın alma anındaki son fiyat, vergi, yenileme ve teklif bilgileri Google Play ekranında gösterildiği şekliyle geçerli olur."
      sections={[
        {
          title: "1. Premium planlar",
          body: (
            <ul>
              <li>Aylık Premium: 69,99 TL / ay</li>
              <li>Yıllık Premium: 299,99 TL / yıl</li>
            </ul>
          ),
        },
        {
          title: "2. Sunulabilecek premium avantajları",
          body: (
            <ul>
              <li>Reklamsız kullanım</li>
              <li>Daha detaylı AI ürün analizleri</li>
              <li>Daha sağlıklı alternatif önerileri</li>
              <li>Daha rafine premium deneyim katmanları</li>
            </ul>
          ),
        },
        {
          title: "3. Satın alma ve ödeme",
          body: (
            <p>
              Ödemeler Google Play üzerinden işlenir. LabelWise, tam kart bilgilerini
              doğrudan toplamaz veya saklamaz. Satın alma sırasında görünen son fiyat,
              vergiler ve varsa kampanyalar Google Play ekranında gösterildiği şekliyle
              uygulanır.
            </p>
          ),
        },
        {
          title: "4. Otomatik yenileme",
          body: (
            <p>
              Google Play üzerinden satın alınan abonelikler, kullanıcı tarafından
              iptal edilmedikçe otomatik olarak yenilenebilir. Yenileme zamanlaması ve
              koşulları Google Play tarafından belirlenir ve satın alma anında
              kullanıcıya gösterilir.
            </p>
          ),
        },
        {
          title: "5. İptal ve abonelik yönetimi",
          body: (
            <p>
              Kullanıcılar aboneliklerini Google Play hesap ayarları üzerinden
              yönetebilir veya iptal edebilir. Uygulamanın silinmesi her zaman
              aboneliğin otomatik olarak iptal edildiği anlamına gelmez.
            </p>
          ),
        },
        {
          title: "6. Premium erişimin doğrulanması",
          body: (
            <p>
              Premium erişim yalnızca doğrulanmış abonelik yetkisine göre aktif hale
              gelir. Satın alma bağlamındaki sınırlı veriler, premium yetkinin
              doğrulanması ve kötüye kullanım riskinin azaltılması amacıyla
              işlenebilir.
            </p>
          ),
        },
        {
          title: "7. İadeler ve anlaşmazlıklar",
          body: (
            <p>
              İade talepleri ve uygunluk durumu genel olarak Google Play politikaları
              ve uygulanabilir kurallara göre değerlendirilir. LabelWise her durum
              için doğrudan iade taahhüdü vermez.
            </p>
          ),
        },
        {
          title: "8. Özelliklerin değişmesi",
          body: (
            <p>
              Premium kapsamındaki özellikler zaman içinde değiştirilebilir, yeniden
              düzenlenebilir veya belirli bölgelerde farklılaştırılabilir. Belirli bir
              özelliğin aynı biçimde sürekli sunulacağı garanti edilmez.
            </p>
          ),
        },
        {
          title: "9. İletişim",
          body: (
            <ul>
              <li>E-posta: canerpala66@gmail.com</li>
              <li>Web sitesi: https://labelwise.net</li>
            </ul>
          ),
        },
      ]}
    />
  );
}
