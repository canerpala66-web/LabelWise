const steps = [
  "Ön yüz fotoğrafı",
  "Arka etiket",
  "Besin tablosu",
  "İnceleme",
  "Veri tabanı",
];

export function ContributionFlowScene() {
  return (
    <div className="contribution-flow-scene">
      {steps.map((step, index) => (
        <div key={step} className="contribution-flow-scene__step">
          <div className="contribution-flow-scene__card">
            <span>{String(index + 1).padStart(2, "0")}</span>
            <strong>{step}</strong>
          </div>
          {index < steps.length - 1 ? (
            <div className="contribution-flow-scene__arrow" aria-hidden="true">
              →
            </div>
          ) : null}
        </div>
      ))}
    </div>
  );
}
