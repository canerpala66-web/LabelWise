export function ProductAnalysisScene() {
  return (
    <div className="product-analysis-scene">
      <div className="product-analysis-scene__package">
        <span className="product-analysis-scene__label">Örnek ürün</span>
        <h3>Fırın Tahıl Barı</h3>
        <p>Kurgusal ürün görselleştirmesi</p>
      </div>

      <div className="product-analysis-scene__beam" aria-hidden="true">
        <span />
      </div>

      <div className="product-analysis-scene__dashboard">
        <div className="product-analysis-scene__score">
          <span>LabelWise skoru</span>
          <strong>81</strong>
          <em>Dengeli seçim</em>
        </div>

        <div className="product-analysis-scene__stats">
          <article>
            <span>Şeker</span>
            <strong>Orta</strong>
          </article>
          <article>
            <span>Lif</span>
            <strong>İyi</strong>
          </article>
          <article>
            <span>Tuz</span>
            <strong>Düşük</strong>
          </article>
        </div>

        <div className="product-analysis-scene__notes">
          <div>
            <span>İçerik özeti</span>
            <p>Yulaf ve tahıl temeli güçlü. Tatlandırıcı ve şeker katkısı ölçülü.</p>
          </div>
          <div>
            <span>AI açıklama</span>
            <p>
              Günlük atıştırmalık için dengeli görünüyor; yine de porsiyon ve şeker
              dengesine bakmak mantıklı olabilir.
            </p>
          </div>
        </div>

        <small>Tıbbi tavsiye değildir. Genel bilgilendirme amaçlıdır.</small>
      </div>
    </div>
  );
}
