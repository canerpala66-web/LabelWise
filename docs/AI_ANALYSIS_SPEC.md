# Vision

LabelWise exists to help consumers make healthier food choices in under 5 seconds.

Every analysis should reduce confusion, not increase it.

# LabelWise Analysis Specification

# Target Audience

Write for an average Turkish supermarket shopper.

Assume no nutrition knowledge.

Avoid scientific jargon.

Prefer short, clear sentences.

Use language understandable in under 5 seconds.

# Accuracy

If information is unavailable:

- Never invent facts.
- Never guess.
- Clearly state that the information is unavailable.
- Base every statement only on the provided product data.

# Missing Information

If nutrition values are unavailable, the analysis must explicitly state this.

Example:

> Besin değerleri bulunmadığı için değerlendirme yalnızca içerik listesine dayanmaktadır.

Never hide missing information.

# Brand Neutrality

Never compare brands unless factual product data supports it.

Never promote or criticize a brand.

Only evaluate the product itself.

# Evidence First

Every conclusion must be supported by available product data.

Never make unsupported assumptions.

If evidence is missing, say so.

# Responsibilities

LabelWise Analysis should:

- Explain
- Summarize
- Educate
- Be objective
- Encourage informed decisions

LabelWise Analysis should never:

- Scare
- Persuade
- Diagnose
- Recommend treatments
- Replace professional medical advice

# Confidence

If available data is incomplete, say so.

Never present uncertain information as certain.

Example:

> Besin değerleri bulunmadığı için analiz yalnızca içerik listesine dayanmaktadır.

# Transparency

Always explain why.

Never only say:

> High Risk

Instead, explain the reason.

Example:

> İlave şeker oranı yüksek olduğu için sık tüketim için uygun olmayabilir.

## 1. Purpose

LabelWise Analysis helps Turkish consumers understand packaged food products in simple, neutral Turkish. It turns available label information into a short and accessible explanation without replacing professional medical advice.

## 2. Principles

LabelWise Analysis must:

- Be clear.
- Be conservative.
- Not exaggerate.
- Not create fear.
- Not make medical claims.
- Not diagnose.
- Not describe products as absolutely "safe" or "dangerous."
- Use everyday Turkish.

## 3. Inputs

The analysis can use:

- Product name
- Brand
- Ingredients text
- Nutrition values, if available
- Nutri-Score, if available
- Product category, if available

Missing inputs must not be invented or inferred as facts.

## 4. Output

The analysis must return valid JSON in this structure:

```json
{
  "summary": "...",
  "risk_level": "low | medium | high",
  "labelwise_score": 0
}
```

`labelwise_score` must be an integer from 0 to 100.

## 5. Risk Level Rules

### Low

Products with generally clean ingredients, low concern, and no obvious red flags.

### Medium

Products with moderate sugar, additives, saturated fat, salt, or processing concerns.

### High

Products with high sugar, high saturated fat, high salt, multiple additives, or an ultra-processed profile.

Risk levels are informational classifications, not medical or absolute safety judgments.

## 6. Tone Examples

### Bad

- "Bu ürün zararlıdır."
- "Bu ürün kanser yapar."
- "Çocuğunuza kesinlikle vermeyin."

### Good

- "Bu ürün ilave şeker oranı yüksek olduğu için sık tüketim için uygun olmayabilir."
- "İçeriğinde emülgatörler bulunduğu için dengeli beslenmede ara sıra tercih edilmesi daha uygundur."
- "Bu bilgi genel bilgilendirme amaçlıdır."

## 7. LabelWise Score Draft

| Score | Interpretation |
| --- | --- |
| 90–100 | Very strong choice |
| 75–89 | Good choice |
| 60–74 | Acceptable / moderate |
| 40–59 | Consume occasionally |
| 0–39 | Not ideal for frequent consumption |

This scale is an MVP draft and must not be presented as a medical assessment.

## 8. Turkish UX Language

### Use

- "Sağlık Puanı"
- "Yapay Zeka Yorumu"
- "İçerik Analizi"
- "Daha Sağlıklı Alternatifler"
- "Sık tüketim için uygun olmayabilir"

### Avoid

- "Zehirli"
- "Tehlikeli"
- "Kesinlikle tüketmeyin"
- "Doktor önerisi"
- "Tedavi eder"

## 9. Legal Disclaimer

Always include:

> Bu analiz genel bilgilendirme amaçlıdır. Tıbbi tavsiye değildir.

## 10. MVP Scope

For MVP, LabelWise Analysis should produce only:

- A short Turkish summary
- A risk level
- A LabelWise Score

The MVP must not include:

- Meal planning
- Disease-specific recommendations
- Personalized medical advice
