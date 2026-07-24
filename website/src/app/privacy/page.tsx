import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

const effectiveDate = "24 Temmuz 2026";
const contactEmail = "canerpala66@gmail.com";

export const metadata: Metadata = {
  title: "LabelWise Gizlilik Politikası",
  description:
    "LabelWise gizlilik politikası: hangi verilerin işlenebileceği, yapay zekâ süreçleri, abonelik verileri ve kullanıcı hakları hakkında bilgilendirme.",
  alternates: {
    canonical: "/privacy",
  },
};

export default function PrivacyPage() {
  return (
    <LegalPage
      eyebrow="Gizlilik"
      title="Gizlilik Politikası"
      intro="Bu politika, LabelWise hizmeti kapsamında hangi verilerin işlenebileceğini, bu verilerin hangi amaçlarla kullanılabileceğini ve kullanıcıların hangi haklara sahip olabileceğini açıklamak için hazırlanmıştır. Metin genel bilgilendirme amaçlıdır; hukuki tavsiye niteliğinde değildir."
      effectiveDate={effectiveDate}
      contactEmail={contactEmail}
      transparencyNote="LabelWise genel bilgilendirme amaçlıdır. Uygulamadaki ürün verileri, kullanıcı gönderimleri ve yapay zekâ çıktıları eksik veya hatalı olabilir; hizmet tıbbi tavsiye, teşhis veya tedavi sunmaz."
      sections={[
        {
          title: "1. Veri sorumlusu ve kapsam",
          body: (
            <>
              <p>
                LabelWise, Caner Pala tarafından sunulan bir mobil barkod tarama ve
                ürün açıklama hizmetidir. Bu politika, labelwise.net üzerindeki web
                sayfaları ile LabelWise mobil uygulaması kapsamında işlenebilecek
                verileri açıklar.
              </p>
              <p>
                Hizmetin çalışması için gerekli veriler, makul teknik ve idari
                önlemlerle korunmaya çalışılır. Bununla birlikte, internet üzerinden
                veri aktarımının tamamen risksiz olduğu garanti edilemez.
              </p>
            </>
          ),
        },
        {
          title: "2. İşlenebilecek veri türleri",
          body: (
            <ul>
              <li>Hesap verileri: e-posta adresi, kullanıcı kimliği ve profil alanları.</li>
              <li>Uygulama kullanımı: tarama geçmişi, son görüntülenen ürünler ve yerel cihaz tercihleri.</li>
              <li>Teknik veriler: cihaz türü, işletim sistemi, uygulama sürümü, çökme kayıtları ve performans sinyalleri.</li>
              <li>Abonelik bağlamı: Google Play satın alma doğrulama durumu ve premium yetki bilgileri.</li>
              <li>Ürün katkıları: eksik ürün gönderimleri, düzeltme bildirimleri ve ürün fotoğrafları.</li>
              <li>Yapay zekâ çıktı bağlamı: ürün özeti, açıklama metinleri ve analiz sürüm bilgileri.</li>
            </ul>
          ),
        },
        {
          title: "3. Verilerin kullanım amaçları",
          body: (
            <ul>
              <li>Hesap oluşturma, oturum açma ve profil bilgilerini sürdürme.</li>
              <li>Barkod tarama, ürün sorgulama ve ürün bilgilerini gösterme.</li>
              <li>Skor, içerik özeti, AI açıklaması ve alternatif önerileri üretme.</li>
              <li>Eksik ürün gönderimlerini ve düzeltmeleri inceleme.</li>
              <li>Premium erişimi doğrulama ve abonelik süreçlerini yönetme.</li>
              <li>Hizmet güvenliğini, kararlılığını ve performansını iyileştirme.</li>
            </ul>
          ),
        },
        {
          title: "4. Üçüncü taraf hizmetler",
          body: (
            <ul>
              <li>Supabase: kimlik doğrulama, veri tabanı, dosya saklama ve edge function altyapısı için.</li>
              <li>Firebase Analytics ve Crashlytics: temel analiz ve hata izleme için.</li>
              <li>OpenFoodFacts: ürün verilerinin bir kısmını sağlamak veya zenginleştirmek için.</li>
              <li>Yapay zekâ servisleri: ürün özetleri ve anlaşılır açıklama üretmek için.</li>
              <li>Google Play: abonelik satın alma ve yenileme süreçleri için.</li>
            </ul>
          ),
        },
        {
          title: "5. Kullanıcı gönderimleri ve ürün fotoğrafları",
          body: (
            <>
              <p>
                Kullanıcılar eksik ürün, düzeltme veya fotoğraf gönderebilir. Bu
                içerikler inceleme ve doğrulama sürecinden sonra ürün veri tabanını
                geliştirmek amacıyla kullanılabilir.
              </p>
              <p>
                Kullanıcıların; yüz, kimlik bilgisi, sağlık verisi veya üçüncü
                kişilere ait özel içerik barındıran görseller yüklememesi gerekir.
                Ürün fotoğraflarında yalnızca ambalaj, içerik listesi ve besin
                tablosu gibi gerekli alanların paylaşılması önerilir.
              </p>
            </>
          ),
        },
        {
          title: "6. Yapay zekâ süreçleri",
          body: (
            <>
              <p>
                LabelWise, belirli ürün verilerini ve etiket içeriklerini daha
                anlaşılır hale getirmek için yapay zekâ tabanlı sistemler
                kullanabilir.
              </p>
              <p>
                Yapay zekâ çıktıları genel bilgilendirme amaçlıdır. Eksik veya
                hatalı olabilir. Nihai karar, resmi ürün etiketi ve gerekli
                durumlarda uzman görüşü ile birlikte değerlendirilmelidir.
              </p>
            </>
          ),
        },
        {
          title: "7. Ödemeler ve abonelikler",
          body: (
            <>
              <p>
                Premium abonelik ödemeleri Google Play üzerinden işlenir. LabelWise,
                tam kart numarası veya güvenlik kodu gibi hassas ödeme verilerini
                doğrudan toplamaz.
              </p>
              <p>
                Premium erişimin doğrulanması için satın alma bağlamına ait sınırlı
                abonelik verileri saklanabilir.
              </p>
            </>
          ),
        },
        {
          title: "8. Veri saklama ve güvenlik",
          body: (
            <>
              <p>
                Veriler, hesabın aktif olduğu süre boyunca veya hizmetin çalışması,
                yasal yükümlülükler, güvenlik kontrolleri ve uyuşmazlık yönetimi için
                gerektiği ölçüde saklanabilir.
              </p>
              <p>
                LabelWise erişim kontrolleri, hizmet sağlayıcı güvenlik özellikleri
                ve makul koruma önlemleri kullanır. Buna rağmen hiçbir sistemin tam
                güvenli olduğu garanti edilemez.
              </p>
            </>
          ),
        },
        {
          title: "9. Kullanıcı hakları",
          body: (
            <>
              <p>
                Uygulanabilir mevzuat kapsamında kullanıcılar; kendileriyle ilgili
                veriler hakkında bilgi isteme, düzeltme talep etme, silme talebinde
                bulunma ve bazı işlemlere itiraz etme hakkına sahip olabilir.
              </p>
              <p>
                Bu hakları kullanmak için canerpala66@gmail.com adresi üzerinden
                iletişime geçilebilir.
              </p>
            </>
          ),
        },
        {
          title: "10. Hesap silme",
          body: (
            <>
              <p>
                Hesap silme talebi uygulama içinden veya e-posta yoluyla iletilebilir.
                Talep değerlendirilirken kimlik doğrulama ve kötüye kullanımı önleme
                amacıyla ek bilgi istenebilir.
              </p>
              <p>
                Ayrıntılı bilgi için{" "}
                <a href="/account-deletion">hesap silme sayfası</a> incelenebilir.
              </p>
            </>
          ),
        },
        {
          title: "11. Politika güncellemeleri",
          body: (
            <p>
              Bu politika zaman zaman güncellenebilir. Önemli değişiklikler
              olduğunda web sitesi veya uygulama üzerinden görünür şekilde
              bilgilendirme yapılabilir.
            </p>
          ),
        },
      ]}
    />
  );
}
