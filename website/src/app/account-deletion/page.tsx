import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

const effectiveDate = "24 Temmuz 2026";
const contactEmail = "canerpala66@gmail.com";

export const metadata: Metadata = {
  title: "LabelWise Hesap Silme",
  description:
    "LabelWise hesabını silme süreci, uygulama içi silme seçeneği ve sınırlı süre saklanabilecek kayıtlar hakkında bilgilendirme.",
  alternates: {
    canonical: "/account-deletion",
  },
};

export default function AccountDeletionPage() {
  return (
    <LegalPage
      eyebrow="Hesap Silme"
      title="Hesap Silme Bilgisi"
      intro="Bu sayfa, LabelWise kullanıcılarının hesap silme sürecini anlaması için hazırlanmıştır. Hesap silme işlemi uygulama içinden başlatılabilir; bazı durumlarda destek kanalları üzerinden ek doğrulama gerekebilir."
      effectiveDate={effectiveDate}
      contactEmail={contactEmail}
      transparencyNote="Hesap silme işlemi kalıcıdır. Teknik olarak mümkün olduğu ölçüde kişisel profil ve hesap verileri silinir. Yasal, güvenlik veya abonelik doğrulama nedenleriyle belirli kayıtlar sınırlı süre saklanabilir."
      sections={[
        {
          title: "1. Uygulama içinden hesap silme",
          body: (
            <>
              <p>
                LabelWise hesabı, mobil uygulamadaki profil / hesap alanı içinden
                silinebilir. İşlem öncesinde kullanıcıdan açık onay alınır.
              </p>
              <p>
                Hesap silme sonrasında oturum kapatılır ve hesapla ilişkili kişisel
                profil verileri sistemden kaldırılmaya çalışılır.
              </p>
            </>
          ),
        },
        {
          title: "2. Destek üzerinden talep",
          body: (
            <>
              <p>
                Uygulama içindeki silme akışı kullanılamıyorsa, canerpala66@gmail.com
                adresine e-posta göndererek de talep iletilebilir.
              </p>
              <p>
                Önerilen konu satırı: <strong>LabelWise Hesap Silme Talebi</strong>
              </p>
            </>
          ),
        },
        {
          title: "3. Silinebilecek veriler",
          body: (
            <ul>
              <li>Kimlik doğrulama hesabı</li>
              <li>Profil alanları ve uygulama hesabına bağlı kişisel bilgiler</li>
              <li>Kullanıcıya bağlı premium yetki kayıtları</li>
            </ul>
          ),
        },
        {
          title: "4. Sınırlı süre saklanabilecek kayıtlar",
          body: (
            <p>
              Güvenlik, kötüye kullanımı önleme, muhasebe yükümlülükleri, abonelik
              doğrulama geçmişi veya hukuki uyuşmazlık yönetimi gibi nedenlerle bazı
              kayıtlar sınırlı süre boyunca saklanabilir.
            </p>
          ),
        },
        {
          title: "5. Cihazdaki yerel veriler",
          body: (
            <p>
              Uygulama kaldırıldığında veya cihaz ayarlarından ilgili veriler
              temizlendiğinde, cihazda saklanan yerel kayıtlar da silinebilir.
            </p>
          ),
        },
        {
          title: "6. Google Play abonelikleri hakkında önemli not",
          body: (
            <p>
              Aktif bir Google Play aboneliğiniz varsa, hesap silme işlemi bu
              aboneliği otomatik olarak iptal etmeyebilir. Aboneliğin ayrıca Google
              Play hesap ayarları üzerinden yönetilmesi veya iptal edilmesi gerekir.
            </p>
          ),
        },
        {
          title: "7. İletişim",
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
