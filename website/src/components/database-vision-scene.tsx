export function DatabaseVisionScene() {
  return (
    <div className="database-vision-scene">
      <div className="database-vision-scene__aurora" aria-hidden="true" />
      <div className="database-vision-scene__grid" aria-hidden="true">
        {Array.from({ length: 18 }).map((_, index) => (
          <span
            key={index}
            className={`database-vision-scene__node database-vision-scene__node--${(index % 6) + 1}`}
          />
        ))}
      </div>

      <div className="database-vision-scene__stats">
        <div>
          <strong>22.000+</strong>
          <span>ürün verisi</span>
        </div>
        <div>
          <strong>6.500+</strong>
          <span>editör katkısı</span>
        </div>
      </div>

      <div className="database-vision-scene__cluster">
        <article>
          <strong>Atıştırmalıklar</strong>
          <span>Barkod akışı</span>
        </article>
        <article>
          <strong>Süt ürünleri</strong>
          <span>Doğrulanan veri</span>
        </article>
        <article>
          <strong>İçecekler</strong>
          <span>AI özet katmanı</span>
        </article>
      </div>
    </div>
  );
}
