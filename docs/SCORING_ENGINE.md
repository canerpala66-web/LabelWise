# LabelWise Score: Scoring Engine

## Purpose

The LabelWise Score is an educational indicator designed to help consumers compare packaged food products quickly. It summarizes available product information as a score from 0 to 100. In the Turkish user experience, it is labeled **Sağlık Puanı**.

The LabelWise Score is not a medical score and must not be presented as a diagnosis, treatment recommendation, or absolute safety judgment.

## MVP Calculation

Every product starts with a base score of **100**. Applicable deductions and positive adjustments are then added. The final LabelWise Score is limited to the 0–100 range.

Rules must be applied only when the required product data is available. Missing information must not be guessed.

## Added Sugar

| Severity | Adjustment |
| --- | ---: |
| Very High | -25 |
| High | -15 |
| Moderate | -8 |
| Low | 0 |

## Saturated Fat

| Severity | Adjustment |
| --- | ---: |
| Very High | -20 |
| High | -12 |
| Moderate | -6 |
| Low | 0 |

## Sodium

| Severity | Adjustment |
| --- | ---: |
| Very High | -15 |
| High | -10 |
| Moderate | -5 |
| Low | 0 |

## Fiber

| Severity | Adjustment |
| --- | ---: |
| High | +10 |
| Moderate | +5 |
| Low | 0 |

## Protein

| Severity | Adjustment |
| --- | ---: |
| High | +5 |
| Moderate | +2 |
| Low | 0 |

## Status

These are draft MVP rules and will evolve over time.

The exact severity thresholds will be defined later using nutritional guidelines.

The LabelWise Score is an educational indicator. It is **not a medical score**.
