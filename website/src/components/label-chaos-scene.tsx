import type { CSSProperties } from "react";

export function LabelChaosScene() {
  return (
    <div className="label-chaos">
      <div className="label-chaos__panel label-chaos__panel--chaotic">
        <span className="label-chaos__eyebrow">Etiket karmaşası</span>
        <div className="label-chaos__barcode" aria-hidden="true">
          {Array.from({ length: 22 }).map((_, index) => (
            <span
              key={index}
              className="label-chaos__barcode-line"
              style={
                {
                  "--chaos-height": `${26 + ((index * 13) % 52)}px`,
                } as CSSProperties
              }
            />
          ))}
        </div>
        <div className="label-chaos__cloud">
          {[
            "Glukoz-fruktoz şurubu",
            "Palm yağı",
            "E330",
            "Emülgatör",
            "Koruyucu",
            "100 g için",
            "Enerji",
            "Doymuş yağ",
            "Sodyum benzoat",
          ].map((item, index) => (
            <span
              key={item}
              className={`label-chaos__token label-chaos__token--chaotic token-${index + 1}`}
            >
              {item}
            </span>
          ))}
        </div>
      </div>

      <div className="label-chaos__connector" aria-hidden="true">
        <span />
        <span />
        <span />
      </div>

      <div className="label-chaos__panel label-chaos__panel--clarified">
        <span className="label-chaos__eyebrow">LabelWise açıklaması</span>
        <div className="label-chaos__clarity-grid">
          <article>
            <strong>Şeker yükü</strong>
            <p>Yüksek olabilir</p>
          </article>
          <article>
            <strong>İşlenmiş içerik</strong>
            <p>Daha dikkatli bakılabilir</p>
          </article>
          <article>
            <strong>Günlük kullanım</strong>
            <p>Her gün için güçlü tercih değil</p>
          </article>
          <article>
            <strong>Alternatif</strong>
            <p>Daha sade içerik bulunabilir</p>
          </article>
        </div>
      </div>
    </div>
  );
}
