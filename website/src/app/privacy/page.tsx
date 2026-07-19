import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

const effectiveDate = "19 Temmuz 2026";
const contactEmail = "canerpala66@gmail.com";

export const metadata: Metadata = {
  title: "LabelWise Gizlilik Politikası",
  description:
    "LabelWise gizlilik politikasi: verilerin toplanmasi, kullanimi, yapay zeka islemleri ve abonelik verileri hakkinda bilgilendirme.",
  alternates: {
    canonical: "/privacy",
  },
};

export default function PrivacyPage() {
  return (
    <LegalPage
      eyebrow="Gizlilik"
      title="Gizlilik Politikası"
      intro="Bu politika, LabelWise hizmeti kapsaminda hangi verilerin toplanabilecegini, bu verilerin hangi amaclarla kullanilabilecegini ve kullanicilarin hangi haklara sahip olabilecegini aciklamak icin hazirlanmistir. Metin seffaflik amaciyla sunulur; hukuki tavsiye niteliginde degildir."
      effectiveDate={effectiveDate}
      contactEmail={contactEmail}
      transparencyNote="LabelWise bilgilendirme amaclidir. Uygulamadaki urun verileri, kullanici gonderimleri ve yapay zeka ciktilari hatali veya eksik olabilir; hizmet tibbi teshis, tedavi veya profesyonel saglik tavsiyesi sunmaz."
      sections={[
        {
          title: "Giris",
          body: (
            <>
              <p>
                LabelWise, Caner Pala tarafindan sunulan bir mobil gida barkod
                tarama hizmetidir. Bu politika, https://labelwise.net uzerindeki
                kamuya acik sayfalar ile LabelWise mobil uygulamasi kapsaminda
                uygulanabilir mevzuat kapsaminda verilerin nasil ele alinabilecegini
                aciklar.
              </p>
              <p className="mt-3">
                Veriler hizmetin calismasi icin gerekli oldugu olcude islenir ve
                makul onlemler ile korunmaya calisilir. Bununla birlikte, internet
                uzerinden yapilan veri aktarimlarinin veya depolama sistemlerinin
                tamamen risksiz oldugu garanti edilemez.
              </p>
            </>
          ),
        },
        {
          title: "Toplayabilecegimiz Veriler",
          body: (
            <>
              <p>Asagidaki veri kategorileri toplanabilir veya olusturulabilir:</p>
              <ul className="mt-3 list-disc space-y-2 pl-5">
                <li>Hesap bilgileri: e-posta adresi, kullanici kimlik numaralari ve profil bilgileri.</li>
                <li>Uygulama kullanimi bilgileri: tarama gecmisi, son goruntulenen urunler, onboarding durumu ve cihaz uzerindeki yerel depolama verileri.</li>
                <li>Teknik veriler: cihaz turu, isletim sistemi, uygulama surumu, hata kayitlari ve temel performans bilgileri.</li>
                <li>Abonelik ve odeme baglami verileri: Google Play satin alma durumu, abonelik yetkilendirme bilgisi, islem dogrulama ve abonelik metaverileri.</li>
                <li>Urun gonderimleri: eksik urun bildirimleri, duzeltme raporlari, aciklama metinleri ve urun fotograflari.</li>
                <li>Yapay zeka isleme baglaminda olusan icerikler: urun ozeti, icerik aciklamalari ve AI tabanli analiz ciktisi.</li>
              </ul>
            </>
          ),
        },
        {
          title: "Verileri Hangi Amaclarla Kullanabiliriz",
          body: (
            <ul className="list-disc space-y-2 pl-5">
              <li>Hesap olusturma, oturum acma ve kullanici profilini surdurme.</li>
              <li>Barkod tarama, urun sorgulama ve urun hakkinda bilgi gosterme.</li>
              <li>Besin puani, icerik aciklamalari, AI urun analizi ve alternatif onerileri uretme.</li>
              <li>Eksik urun, duzeltme ve fotograf gonderimlerini inceleme ve urun veritabanini gelistirme.</li>
              <li>Abonelik yetkisini dogrulama ve premium erisim saglama.</li>
              <li>Hizmet guvenligini, istikrarini ve performansini iyilestirme.</li>
              <li>Uygulanabilir mevzuat kapsaminda hukuki yukumlulukleri yerine getirme.</li>
            </ul>
          ),
        },
        {
          title: "Kullandigimiz Ucuncu Taraf Hizmetler",
          body: (
            <ul className="list-disc space-y-2 pl-5">
              <li>Supabase Auth, Database, Storage ve Edge Functions: hesap, veri saklama ve uygulama arka ucu islevleri icin.</li>
              <li>Firebase Analytics: temel kullanim analizi ve urun gelistirme icin.</li>
              <li>Firebase Crashlytics: hata takibi ve performans izleme icin.</li>
              <li>OpenFoodFacts: urun verilerinin bir kismini saglamak veya zenginlestirmek icin.</li>
              <li>OpenAI API veya benzeri backend AI saglayicilari: urun icerigiyle ilgili ozet ve aciklama uretmek icin.</li>
              <li>Google Play Billing: abonelik satin alma, yenileme ve odeme islemleri icin.</li>
            </ul>
          ),
        },
        {
          title: "Urun Verileri ve Kullanici Gonderimleri",
          body: (
            <>
              <p>
                Kullanici, urun bulunamadiginda veya veri duzeltme gerektiginde
                uygulama icinden bilgi, aciklama veya fotograf gonderebilir.
                Gonderilen bilgiler inceleme sonrasi urun veritabanini gelistirmek
                icin kullanilabilir; duzenlenebilir, reddedilebilir veya silinebilir.
              </p>
              <p className="mt-3">
                Kullanicilarin kisisel veri, hassas saglik verisi, baska kisilere
                ait bilgi veya yuz gibi ayirt edici unsurlar iceren gorselleri
                yuklememesi gerekir. Urun fotografi gonderimlerinde yalnizca gerekli
                urun etiket ve ambalaj bilgileri paylasilmalidir.
              </p>
            </>
          ),
        },
        {
          title: "Yapay Zeka Isleme Sureci",
          body: (
            <>
              <p>
                LabelWise, belirli urun verilerini ve etiket bilgilerinin bir
                kismini AI tabanli sistemler araciligiyla isleyebilir. Bu isleme,
                urunlerin iceriklerini daha anlasilir hale getirmek ve ozetleyici
                aciklamalar sunmak amaciyla yapilir.
              </p>
              <p className="mt-3">
                Yapay zeka ciktilari bilgilendirme amaclidir; hatali veya eksik
                olabilir. Kullanicilar, AI analizlerine kisisel veya hassas veri
                eklememeli ve nihai karari resmi urun etiketi ile uzman gorusune
                dayanarak vermelidir.
              </p>
            </>
          ),
        },
        {
          title: "Odemeler ve Abonelikler",
          body: (
            <>
              <p>
                Premium abonelik odemeleri Google Play uzerinden islenir. LabelWise
                dogrudan tam kart numarasi, kart son kullanma tarihi veya guvenlik
                kodu gibi tam odeme bilgilerini toplamaz.
              </p>
              <p className="mt-3">
                Bununla birlikte, hizmetin calismasi icin gerekli oldugu olcude
                abonelik yetkilendirme durumu, satin alma dogrulama bilgisi ve ilgili
                metaveriler saklanabilir. Bu veriler premium erisimin dogrulanmasi,
                hileli kullanim riskinin azaltulmasi ve destek sureclerinin
                yurutulmesi icin kullanilabilir.
              </p>
            </>
          ),
        },
        {
          title: "Verilerin Paylasilmasi",
          body: (
            <>
              <p>
                Veriler, hizmet saglayicilarla yalnizca hizmetin sunulmasi, teknik
                isleyisin saglanmasi veya uygulanabilir mevzuat kapsamindaki
                yukumluluklerin yerine getirilmesi icin gerekli oldugu olcude
                paylasilabilir.
              </p>
              <p className="mt-3">
                LabelWise, kullanici verilerini keyfi sekilde satmaz. Ancak hukuki
                talepler, guvenlik olaylari veya haklarin korunmasi gibi durumlarda
                makul olcude paylasim gerekebilir.
              </p>
            </>
          ),
        },
        {
          title: "Veri Saklama Suresi",
          body: (
            <p>
              Veriler, hesabin aktif oldugu sure boyunca veya hizmetin calismasi,
              yasal yukumlulukler, guvenlik kontrolleri ve uyusmazlik yonetimi icin
              gerekli oldugu surece saklanabilir. Yerel cihaz verileri kullanici
              tarafindan uygulama kaldirilarak veya cihaz ayarlari uzerinden
              temizlenebilir.
            </p>
          ),
        },
        {
          title: "Guvenlik",
          body: (
            <p>
              LabelWise, verileri korumak icin erisim sinirlamalari, hizmet
              saglayici guvenlik ozellikleri ve diger makul onlemler uygulamaya
              calisir. Buna ragmen hicbir sistemin tam guvenli oldugu garanti
              edilemez ve kullanicilar da hesap bilgilerini korumakla sorumludur.
            </p>
          ),
        },
        {
          title: "Kullanici Haklari",
          body: (
            <>
              <p>
                Uygulanabilir mevzuat kapsaminda kullanicilar, kendileriyle ilgili
                veriler hakkinda bilgi talep etme, duzeltme isteme, silme talebinde
                bulunma, belirli islemlere itiraz etme veya veri isleme konusunda
                ek aciklama isteme hakkina sahip olabilir.
              </p>
              <p className="mt-3">
                Bu haklarin kullanilmasi icin canerpala66@gmail.com adresi
                uzerinden iletisime gecilebilir.
              </p>
            </>
          ),
        },
        {
          title: "Hesap Silme Talepleri",
          body: (
            <>
              <p>
                Kullanicilar hesap silme talebini uygulama icindeki uygun alanlar
                araciligiyla veya canerpala66@gmail.com adresine e-posta gondererek
                iletebilir. Talep degerlendirilirken hesabin dogrulanmasi ve kotuye
                kullanim riskinin azaltulmasi icin ek bilgi istenebilir.
              </p>
              <p className="mt-3">
                Hesap silme sureci hakkinda ek bilgi icin
                {" "}
                <a
                  href="https://labelwise.net/account-deletion"
                  className="font-semibold text-white underline decoration-[color:var(--gold)] underline-offset-4"
                >
                  https://labelwise.net/account-deletion
                </a>
                {" "}
                sayfasi incelenebilir.
              </p>
              <p className="mt-3">
                Hesap silme sonrasinda, uygulanabilir mevzuat kapsaminda veya
                guvenlik, uyusmazlik, muhasebe ve abonelik dogrulama amaclariyla
                saklanmasi gereken belirli veriler sinirli sureyle tutulabilir.
              </p>
            </>
          ),
        },
        {
          title: "Cocuklarin Gizliligi",
          body: (
            <p>
              LabelWise cocuklara yonelik ozel bir hizmet olarak tasarlanmamistir.
              Ebeveyn veya yasal temsilci, cocuga ait verilerin izinsiz sekilde
              saglandigini dusunuyorsa iletisime gecerek inceleme ve gerekli
              islemleri talep edebilir.
            </p>
          ),
        },
        {
          title: "Uluslararasi Veri Aktarimlari",
          body: (
            <p>
              Kullanilan altyapi ve ucuncu taraf hizmetler nedeniyle belirli veriler
              farkli ulkelerdeki sunucularda islenebilir veya saklanabilir. Bu
              durumda LabelWise, uygulanabilir mevzuat kapsaminda gerekli oldugu
              olcude makul teknik ve sozlesmesel onlemlerin uygulanmasini hedefler.
            </p>
          ),
        },
        {
          title: "Politika Guncellemeleri",
          body: (
            <p>
              Bu politika zaman zaman guncellenebilir. Onemli degisiklikler
              oldugunda, uygun gorulurse uygulama icinde veya web sitesinde yeni
              tarih ile birlikte duyuru yapilabilir.
            </p>
          ),
        },
        {
          title: "Iletisim",
          body: (
            <>
              <p>Veri gizliligiyle ilgili talepler icin iletisim bilgileri:</p>
              <ul className="mt-3 list-disc space-y-2 pl-5">
                <li>Veri sorumlusu / sahip: Caner Pala</li>
                <li>E-posta: canerpala66@gmail.com</li>
                <li>Web sitesi: https://labelwise.net</li>
              </ul>
            </>
          ),
        },
      ]}
    />
  );
}
