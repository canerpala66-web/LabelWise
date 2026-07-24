import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

const effectiveDate = "24 Temmuz 2026";
const contactEmail = "canerpala66@gmail.com";

export const metadata: Metadata = {
  title: "LabelWise Kullanım Koşulları",
  description:
    "LabelWise kullanım koşulları: hizmetin amacı, veri doğruluğu sınırları, yapay zekâ çıktıları ve premium abonelik kullanımı hakkında genel esaslar.",
  alternates: {
    canonical: "/terms",
  },
};

export default function TermsPage() {
  return (
    <LegalPage
      eyebrow="Koşullar"
      title="Kullanım Koşulları"
      intro="Bu kullanım koşulları, LabelWise mobil uygulaması ve labelwise.net üzerindeki ilgili sayfaların kullanımına ilişkin temel esasları açıklar. Metin genel bilgilendirme amaçlıdır; hukuki tavsiye niteliğinde değildir."
      effectiveDate={effectiveDate}
      contactEmail={contactEmail}
      transparencyNote="LabelWise ürünleri anlamayı kolaylaştırmayı amaçlar. Alerjenler, son kullanma tarihi, içerik uygunluğu ve kişisel sağlık ihtiyaçları açısından son değerlendirme her zaman kullanıcıya aittir."
      sections={[
        {
          title: "1. Hizmetin kabulü",
          body: (
            <p>
              LabelWise hizmetini kullanarak bu koşulları kabul etmiş sayılırsınız.
              Eğer bu koşulları kabul etmiyorsanız uygulamayı ve ilgili web
              sayfalarını kullanmamalısınız.
            </p>
          ),
        },
        {
          title: "2. Hizmetin amacı",
          body: (
            <p>
              LabelWise; barkod tarama, ürün sorgulama, içerik açıklamaları, skor
              üretimi, AI tabanlı özetler ve daha dengeli alternatif önerileri gibi
              bilgilendirme amaçlı araçlar sunar. Hizmet, tıbbi değerlendirme veya
              profesyonel beslenme danışmanlığı yerine geçmez.
            </p>
          ),
        },
        {
          title: "3. Kullanıcı hesabı",
          body: (
            <p>
              Hesap oluştururken paylaştığınız bilgilerin doğru, güncel ve size ait
              olması gerekir. Hesap bilgilerinizin güvenliğini korumaktan ve hesabınız
              üzerinden gerçekleşen işlemlerden siz sorumlusunuz.
            </p>
          ),
        },
        {
          title: "4. Uygun kullanım kuralları",
          body: (
            <ul>
              <li>Hizmet hukuka aykırı, aldatıcı veya başkalarının haklarını ihlal edecek şekilde kullanılmamalıdır.</li>
              <li>Yanıltıcı ürün gönderimleri, otomatik kötüye kullanım ve yetkisiz erişim girişimleri yasaktır.</li>
              <li>Gönderilen fotoğraf ve metinlerde kişisel veri veya üçüncü kişilere ait özel içerik paylaşılmamalıdır.</li>
            </ul>
          ),
        },
        {
          title: "5. Ürün verileri ve doğruluk sınırları",
          body: (
            <p>
              Uygulamadaki ürün verileri; açık veri kaynakları, kullanıcı gönderimleri,
              ürün etiketleri ve sistem içi yorum katmanlarından oluşabilir. Bu
              bilgiler eksik, güncel olmayan veya hatalı olabilir. Resmî ürün etiketi,
              alerjen bilgisi ve son kullanma tarihi her zaman kullanıcı tarafından
              ayrıca kontrol edilmelidir.
            </p>
          ),
        },
        {
          title: "6. Yapay zekâ çıktıları",
          body: (
            <p>
              Yapay zekâ tabanlı açıklamalar ve özetler, kullanıcının karar vermesini
              kolaylaştırmak için sunulur. Bu çıktılar hatalı veya eksik olabilir ve
              tek başına nihai karar dayanağı olmamalıdır.
            </p>
          ),
        },
        {
          title: "7. Kullanıcı gönderimleri",
          body: (
            <p>
              Kullanıcılar ürün ekleme, düzeltme, fotoğraf veya benzeri içerikler
              gönderebilir. Bu gönderimler incelenebilir, düzenlenebilir,
              reddedilebilir veya ürün veri tabanını geliştirmek amacıyla
              kullanılabilir. Kullanıcı, paylaştığı içerik üzerinde gerekli haklara
              sahip olduğunu beyan eder.
            </p>
          ),
        },
        {
          title: "8. Premium özellikler ve abonelikler",
          body: (
            <>
              <p>
                Premium özellikler kademeli olarak sunulabilir. Tüm özellikler her
                kullanıcı, sürüm veya dönemde aynı şekilde mevcut olmayabilir.
              </p>
              <p>
                Abonelik ücretleri, vergiler ve yenileme koşulları satın alma anında
                Google Play ekranında gösterildiği şekliyle uygulanır.
              </p>
            </>
          ),
        },
        {
          title: "9. Üçüncü taraf hizmetler",
          body: (
            <p>
              LabelWise; Supabase, Firebase, OpenFoodFacts, yapay zekâ servisleri ve
              Google Play gibi üçüncü taraf altyapılara dayanabilir. Bu servislerdeki
              kesinti, değişiklik veya politika farkları bazı özellikleri
              etkileyebilir.
            </p>
          ),
        },
        {
          title: "10. Sorumluluğun sınırlandırılması",
          body: (
            <p>
              Uygulanabilir mevzuat kapsamında izin verilen ölçüde, LabelWise hizmetten
              doğan dolaylı zararlar, veri kaybı, ticari kayıp veya yanlış karar
              risklerinden tamamen sorumlu tutulamaz. Hizmet “olduğu gibi” ve “mevcut
              olduğu şekilde” sunulabilir.
            </p>
          ),
        },
        {
          title: "11. Hizmette değişiklikler",
          body: (
            <p>
              Özellikler, tasarım, fiyatlama, desteklenen planlar veya entegrasyonlar
              önceden bildirim yapılarak ya da yapılmaksızın değiştirilebilir,
              sınırlandırılabilir veya kaldırılabilir.
            </p>
          ),
        },
        {
          title: "12. Hesabın askıya alınması",
          body: (
            <p>
              Kötüye kullanım, hukuka aykırı faaliyet, güvenlik riski veya bu
              koşulların ihlali halinde hesap geçici olarak askıya alınabilir veya
              sonlandırılabilir.
            </p>
          ),
        },
        {
          title: "13. İletişim",
          body: (
            <ul>
              <li>Sorumlu kişi: Caner Pala</li>
              <li>E-posta: canerpala66@gmail.com</li>
              <li>Web sitesi: https://labelwise.net</li>
            </ul>
          ),
        },
      ]}
    />
  );
}
