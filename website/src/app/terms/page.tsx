import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

const effectiveDate = "19 Temmuz 2026";
const contactEmail = "canerpala66@gmail.com";

export const metadata: Metadata = {
  title: "LabelWise Kullanım Koşulları",
  description:
    "LabelWise kullanim kosullari: bilgilendirme amaci, veri dogrulugu sinirlari, AI ciktlari ve abonelik kullanimi hakkinda genel esaslar.",
  alternates: {
    canonical: "/terms",
  },
};

export default function TermsPage() {
  return (
    <LegalPage
      eyebrow="Koşullar"
      title="Kullanım Koşulları"
      intro="Bu kullanim kosullari, LabelWise mobil uygulamasi ve https://labelwise.net uzerindeki ilgili sayfalarin kullanimina iliskin temel esaslari aciklar. Metin seffaflik amaciyla sunulur; hukuki tavsiye niteliginde degildir."
      effectiveDate={effectiveDate}
      contactEmail={contactEmail}
      transparencyNote="LabelWise bilgilendirme amaclidir. Urun etiketleri, alerjenler, son kullanma tarihi, icerik uygunlugu ve kisisel saglik ihtiyaclari acisindan son kontrol her zaman kullaniciya aittir."
      sections={[
        {
          title: "Giris",
          body: (
            <p>
              LabelWise hizmetini kullanarak bu kosullari kabul etmis sayilirsiniz.
              Eger bu kosullari kabul etmiyorsaniz uygulamayi ve ilgili web
              sayfalarini kullanmamalisiniz.
            </p>
          ),
        },
        {
          title: "Uygulamanin Amaci",
          body: (
            <p>
              LabelWise, gida urunleriyle ilgili barkod tarama, urun sorgulama,
              besin puani, icerik aciklamalari, AI tabanli urun analizi ve daha
              dengeli alternatifler gibi bilgilendirme amacli araclar sunar.
              Hizmet bir tibbi hizmet veya profesyonel beslenme danismanligi
              yerine gecmez.
            </p>
          ),
        },
        {
          title: "Kullanici Hesabi",
          body: (
            <p>
              Hesap olustururken sagladiginiz bilgilerin dogru, guncel ve size ait
              olmasi gerekir. Hesap bilgilerinizin gizliligini korumaktan ve
              hesabiniz uzerinden gerceklesen islemlerden siz sorumlusunuz.
            </p>
          ),
        },
        {
          title: "Uygun Kullanim Kurallari",
          body: (
            <ul className="list-disc space-y-2 pl-5">
              <li>Hizmeti hukuka aykiri, aldatıcı veya baskalarinin haklarini ihlal edecek sekilde kullanmamalısınız.</li>
              <li>Yaniltici urun gonderimleri, otomatik kotuye kullanim, yetkisiz erisim girisimleri veya sistem isleyisini bozacak islemler yasaktir.</li>
              <li>Fotograf, metin veya duzeltme gonderimlerinde kisisel veri, hassas veri veya hak ihlaline yol acabilecek icerikler paylasilmamalidir.</li>
            </ul>
          ),
        },
        {
          title: "Urun Verileri ve Bilgi Dogrulugu",
          body: (
            <p>
              Uygulamadaki urun verileri OpenFoodFacts, kullanici gonderimleri,
              etiket okumasi ve diger kaynaklar temelinde olusabilir. Bu bilgiler
              eksik, guncel olmayan veya hatali olabilir. Kullanicilar resmi urun
              etiketi, alerjen bilgisi, saklama kosullari ve son kullanma tarihini
              bizzat kontrol etmekle sorumludur.
            </p>
          ),
        },
        {
          title: "Saglik ve Beslenme Bilgilendirmesi",
          body: (
            <p>
              LabelWise bilgilendirme amaclidir ve doktor, diyetisyen, eczaci veya
              baska bir profesyonel tavsiyenin yerine gecmez. Alerji, intolerans,
              kronik hastalik, hamilelik, ozel diyet veya cocuk beslenmesi gibi
              durumlarda profesyonel gorus ve urun etiketi esas alinmalidir.
            </p>
          ),
        },
        {
          title: "Yapay Zeka Ciktilari",
          body: (
            <p>
              AI tabanli analizler ve icerik aciklamalari kullanicinin karar
              vermesini kolaylastirmak icin sunulur. Bu ciktlar eksik veya hatali
              olabilir ve tek basina nihai karar dayanak olusturmamalidir.
            </p>
          ),
        },
        {
          title: "Kullanici Gonderimleri",
          body: (
            <p>
              Kullanicilar urun ekleme, duzeltme, fotograf ve benzeri icerik
              gonderebilir. Bu gonderimler incelenebilir, duzenlenebilir,
              reddedilebilir veya urun veritabanini gelistirmek amaciyla
              kullanilabilir. Kullanici, gonderdigi icerigin paylasimi icin gerekli
              haklara sahip oldugunu beyan eder.
            </p>
          ),
        },
        {
          title: "Premium Ozellikler ve Abonelikler",
          body: (
            <p>
              Premium ozellikler kullanima kademeli olarak sunulabilir. Tum
              ozellikler her kullanici, ulke, surum veya donemde ayni sekilde
              mevcut olmayabilir.
            </p>
          ),
        },
        {
          title: "Odeme, Yenileme ve Iptal",
          body: (
            <p>
              Abonelik fiyatlari, vergiler, yenileme kosullari ve mevcut teklifler
              satin alma aninda Google Play tarafindan gosterildigi sekliyle
              uygulanir. Kullanici aboneliklerini Google Play hesap ayarlari
              uzerinden yonetir ve iptal eder.
            </p>
          ),
        },
        {
          title: "Fikri Mulkiyet",
          body: (
            <p>
              LabelWise markasi, tasarimi, yazi, grafik, yazilim bileşenleri ve
              ilgili icerikler, aksi belirtilmedikce Caner Pala veya ilgili hak
              sahiplerine aittir. Yetkisiz kopyalama, dagitma veya ticari kullanim
              yasaktir.
            </p>
          ),
        },
        {
          title: "Ucuncu Taraf Hizmetler",
          body: (
            <p>
              LabelWise, Supabase, Firebase, OpenFoodFacts, OpenAI tabanli servisler
              ve Google Play gibi ucuncu taraf hizmetlere dayanabilir. Bu servislerin
              kesintisi, degisikligi veya politika farklari belirli islevleri
              etkileyebilir.
            </p>
          ),
        },
        {
          title: "Sorumlulugun Sinirlandirilmasi",
          body: (
            <p>
              Uygulanabilir mevzuat kapsaminda izin verilen olcude, LabelWise
              hizmetten dogan dolayli zararlar, veri kaybi, ticari kayip veya yanlis
              karar risklerinden tam olarak sorumlu tutulamaz. Hizmet "oldugu gibi"
              ve "mevcut oldugu sekilde" sunulabilir.
            </p>
          ),
        },
        {
          title: "Hizmette Degisiklikler",
          body: (
            <p>
              Ozellikler, tasarim, fiyatlama, desteklenen planlar veya entegrasyonlar
              onceden bildirim yapilarak veya yapilmaksizin degistirilebilir,
              sinirlandirilabilir veya kaldirilabilir.
            </p>
          ),
        },
        {
          title: "Hesabin Askiya Alinmasi veya Sonlandirilmasi",
          body: (
            <p>
              Kotuye kullanim, hukuka aykiri faaliyet, guvenlik riski veya bu
              kosullarin ihlali halinde hesap gecici olarak askiya alinabilir veya
              sonlandirilabilir.
            </p>
          ),
        },
        {
          title: "Uygulanacak Hukuk / Genel Hukumler",
          body: (
            <p>
              Bu kosullar, uygulanabilir oldugu olcude Turkiye Cumhuriyeti hukuku
              cercevesinde yorumlanir. Herhangi bir hukmun gecersiz sayilmasi, diger
              hukumlerin gecerliligini etkilemez.
            </p>
          ),
        },
        {
          title: "Iletisim",
          body: (
            <ul className="list-disc space-y-2 pl-5">
              <li>Sahip / sorumlu: Caner Pala</li>
              <li>E-posta: canerpala66@gmail.com</li>
              <li>Web sitesi: https://labelwise.net</li>
            </ul>
          ),
        },
      ]}
    />
  );
}
