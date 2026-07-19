import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

const effectiveDate = "19 Temmuz 2026";
const contactEmail = "canerpala66@gmail.com";

export const metadata: Metadata = {
  title: "LabelWise Sağlık ve Veri Bilgilendirmesi",
  description:
    "LabelWise saglik, yapay zeka ve veri dogrulugu bilgilendirmesi.",
  alternates: {
    canonical: "/disclaimer",
  },
};

export default function DisclaimerPage() {
  return (
    <LegalPage
      eyebrow="Bilgilendirme"
      title="Saglik, Yapay Zeka ve Veri Dogrulugu Bilgilendirmesi"
      intro="Bu sayfa, LabelWise icerigini daha guvenli ve daha dogru beklentilerle kullanabilmeniz icin seffaflik amaciyla hazirlanmistir. Metin hukuki veya tibbi tavsiye niteliginde degildir."
      effectiveDate={effectiveDate}
      contactEmail={contactEmail}
      transparencyNote="LabelWise tibbi teshis, tedavi veya profesyonel saglik tavsiyesi sunmaz. Uygulamadaki bilgiler eksik, hatali veya guncel olmayan veri icerebilir."
      sections={[
        {
          title: "Bilgilendirme Amacli Kullanim",
          body: (
            <p>
              LabelWise, gida urunleri hakkinda genel bilgilendirme saglamak icin
              tasarlanmistir. Uygulama, karar vermeyi destekleyen bir arac niteliginde
              olup tek basina nihai kaynak olarak kullanilmamalidir.
            </p>
          ),
        },
        {
          title: "Tibbi Tavsiye Degildir",
          body: (
            <p>
              LabelWise tibbi teshis, tedavi veya profesyonel saglik tavsiyesi
              sunmaz. Uygulamadaki hicbir bilgi doktor, diyetisyen, eczaci veya
              diger uzman gorusunun yerine gecmez.
            </p>
          ),
        },
        {
          title: "Alerji, Intolerans ve Ozel Saglik Durumlari",
          body: (
            <p>
              Alerji, intolerans, hamilelik, kronik hastalik, ozel diyet veya cocuk
              beslenmesi gibi konularda urun etiketini ve uzman gorusunu esas alin.
              Bu gibi durumlarda uygulama ciktisi yerine resmi etiket bilgisi ve
              profesyonel yonlendirme oncelikli olmalidir.
            </p>
          ),
        },
        {
          title: "Urun Etiketleri Esastir",
          body: (
            <p>
              Urun uzerindeki resmi etiket bilgileri her zaman onceliklidir.
              Icerikler, alerjenler, son kullanma tarihi, saklama kosullari ve
              urunun uygunlugu hakkinda son kontrol kullanici tarafindan yapilmalidir.
            </p>
          ),
        },
        {
          title: "Veri Kaynaklari Hatali veya Eksik Olabilir",
          body: (
            <p>
              Uygulamadaki bilgiler eksik, hatali veya guncel olmayan veri icerebilir.
              Ucuncu taraf veriler, kullanici gonderimleri ve otomatik isleme
              surecleri her zaman tam veya guncel sonuc vermeyebilir.
            </p>
          ),
        },
        {
          title: "Yapay Zeka Ciktilari Hata Icerbilir",
          body: (
            <p>
              Yapay zeka tarafindan olusturulan urun yorumlari, icerik aciklamalari
              veya ozetler hata icerebilir. Bu ciktlar bilgilendirme amaclidir ve
              baglayici uzman gorusu olarak degerlendirilmemelidir.
            </p>
          ),
        },
        {
          title: "Besin Puani ve Alternatif Onerileri",
          body: (
            <p>
              Besin puani ve alternatif onerileri genel karsilastirma kolayligi
              saglamak icin sunulur. Bu gosterimler her kullanici icin uygun veya
              yeterli olmayabilir; kisisel ihtiyaclar, saglik durumu ve hedefler
              farklilik gosterebilir.
            </p>
          ),
        },
        {
          title: "Kullanici Gonderimleri",
          body: (
            <p>
              Kullanicilar tarafindan gonderilen urun duzeltmeleri, fotograf ve
              aciklamalar da hata icerebilir. Bu gonderimler inceleme sonrasinda
              kullanilsa da dogruluklari garanti edilmez.
            </p>
          ),
        },
        {
          title: "Son Karar Kullanicya Aittir",
          body: (
            <p>
              Uygulamadaki bilgiler yardimci niteliktedir. Bir urunu satin alma,
              tuketme veya kacınma konusunda son karar kullaniciya aittir ve bu karar
              verilirken resmi etiket bilgileri ile uzman gorusu oncelikli
              tutulmalidir.
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
