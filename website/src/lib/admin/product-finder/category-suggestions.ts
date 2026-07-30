import { safeString } from "@/lib/admin/imports/helpers";

export type CategorySuggestion = {
  value: string;
  reason: string;
  confidence: "high" | "medium";
};

type Rule = {
  category: string;
  reason: string;
  confidence: "high" | "medium";
  phrases?: string[];
  tokens?: string[];
  requiresLiquid?: boolean;
  requiresSolid?: boolean;
  exclude?: string[];
};

function normalizeText(value: string | null | undefined) {
  return safeString(value)
    .toLocaleLowerCase("tr-TR")
    .replace(/ç/g, "c")
    .replace(/ğ/g, "g")
    .replace(/ı/g, "i")
    .replace(/ö/g, "o")
    .replace(/ş/g, "s")
    .replace(/ü/g, "u")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function hasWholeToken(haystack: string, token: string) {
  const escaped = token.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(`(?:^|\\s)${escaped}(?:$|\\s)`, "i").test(haystack);
}

function phraseMatch(haystack: string, phrase: string) {
  return haystack.includes(phrase);
}

const orderedRules: Rule[] = [
  {
    category: "Glutensiz Ürün",
    reason: "Ürün adı glutensiz sinyali veriyor.",
    confidence: "medium",
    tokens: ["glutensiz"],
  },
  {
    category: "Ton Balığı",
    reason: "Ürün adı ton balığı sinyali veriyor.",
    confidence: "high",
    phrases: ["ton baligi", "konserve ton"],
  },
  {
    category: "Balık Konservesi",
    reason: "Ürün adı balık konservesi sinyali veriyor.",
    confidence: "high",
    phrases: ["balik konservesi"],
  },
  {
    category: "Bebek Gıdası",
    reason: "Ürün adı bebek gıdası sinyali veriyor.",
    confidence: "high",
    phrases: ["bebek mamasi", "devam sutu", "bebek ek gida"],
  },
  {
    category: "Soğuk Çay",
    reason: "Ürün adı soğuk çay / ice tea sinyali veriyor.",
    confidence: "high",
    phrases: ["soguk cay", "ice tea", "iced tea", "ice tea", "fuse tea", "fuzetea", "lipton ice tea"],
    requiresLiquid: true,
  },
  {
    category: "Maden Suyu",
    reason: "Ürün adı maden suyu / soda sinyali veriyor.",
    confidence: "high",
    phrases: ["maden suyu", "mineralli su", "dogal mineralli su"],
    tokens: ["soda"],
    requiresLiquid: true,
  },
  {
    category: "Enerji İçeceği",
    reason: "Ürün adı enerji içeceği sinyali veriyor.",
    confidence: "high",
    phrases: ["enerji icecegi", "energy drink", "red bull", "monster", "burn"],
    requiresLiquid: true,
  },
  {
    category: "Gazlı İçecek",
    reason: "Ürün adı gazlı içecek / kola sinyali veriyor.",
    confidence: "high",
    phrases: ["coca cola", "coca cola", "coca-cola", "gazli icecek", "gazoz", "fanta", "sprite", "pepsi"],
    tokens: ["kola", "cola"],
    requiresLiquid: true,
    exclude: ["maden suyu", "soguk cay"],
  },
  {
    category: "Meyve Suyu",
    reason: "Ürün adı meyve suyu / nektar sinyali veriyor.",
    confidence: "high",
    phrases: ["meyve suyu", "seftali nektari", "portakal suyu", "visne suyu", "nektar"],
    requiresLiquid: true,
  },
  {
    category: "Ayran",
    reason: "Ürün adı ayran sinyali veriyor.",
    confidence: "high",
    tokens: ["ayran"],
    requiresLiquid: true,
  },
  {
    category: "Kefir",
    reason: "Ürün adı kefir sinyali veriyor.",
    confidence: "high",
    tokens: ["kefir"],
    requiresLiquid: true,
  },
  {
    category: "Bitkisel İçecek",
    reason: "Ürün adı bitkisel içecek sinyali veriyor.",
    confidence: "high",
    phrases: ["bitkisel icecek", "badem sutu", "yulaf icecegi", "soya icecegi"],
    requiresLiquid: true,
  },
  {
    category: "Süt",
    reason: "Ürün adı süt sinyali veriyor.",
    confidence: "high",
    phrases: ["uht sut", "gunluk sut"],
    tokens: ["sut"],
    requiresLiquid: true,
    exclude: ["sutlu cikolata", "devam sutu"],
  },
  {
    category: "Yoğurt",
    reason: "Ürün adı yoğurt sinyali veriyor.",
    confidence: "high",
    phrases: ["suzme yogurt"],
    tokens: ["yogurt"],
    requiresSolid: true,
  },
  {
    category: "Peynir",
    reason: "Ürün adı peynir sinyali veriyor.",
    confidence: "high",
    phrases: ["beyaz peynir", "kasar", "kaşar", "cheddar", "labne", "krem peynir"],
    tokens: ["peynir"],
  },
  {
    category: "Tereyağı",
    reason: "Ürün adı tereyağı sinyali veriyor.",
    confidence: "high",
    phrases: ["tereyagi", "tereyag"],
  },
  {
    category: "Krema",
    reason: "Ürün adı krema sinyali veriyor.",
    confidence: "high",
    tokens: ["krema"],
  },
  {
    category: "Kaymak",
    reason: "Ürün adı kaymak sinyali veriyor.",
    confidence: "high",
    tokens: ["kaymak"],
  },
  {
    category: "Cips",
    reason: "Ürün adı cips sinyali veriyor.",
    confidence: "high",
    phrases: ["patates cipsi", "tortilla cips", "misir cipsi"],
    tokens: ["cips"],
  },
  {
    category: "Kraker",
    reason: "Ürün adı kraker sinyali veriyor.",
    confidence: "high",
    tokens: ["kraker"],
  },
  {
    category: "Patlamış Mısır",
    reason: "Ürün adı patlamış mısır / popcorn sinyali veriyor.",
    confidence: "high",
    phrases: ["patlamis misir", "popcorn"],
  },
  {
    category: "Kuruyemiş",
    reason: "Ürün adı kuruyemiş sinyali veriyor.",
    confidence: "high",
    tokens: ["kuruyemis", "findik", "fistik", "badem", "ceviz", "kaju", "leblebi"],
    exclude: ["findik kremasi", "kakaolu findik kremasi"],
  },
  {
    category: "Çekirdek",
    reason: "Ürün adı çekirdek sinyali veriyor.",
    confidence: "high",
    tokens: ["cekirdek"],
  },
  {
    category: "Kakaolu Fındık Kreması",
    reason: "Ürün adı kakaolu fındık kreması sinyali veriyor.",
    confidence: "high",
    phrases: ["kakaolu findik kremasi", "surulebilir cikolata", "surulebilir cikolata", "nutella"],
    tokens: ["findik kremasi"],
  },
  {
    category: "Çikolata",
    reason: "Ürün adı çikolata sinyali veriyor.",
    confidence: "high",
    phrases: ["sutlu cikolata", "bitter cikolata", "tablet cikolata"],
    tokens: ["cikolata"],
    exclude: ["kakaolu findik kremasi", "surulebilir cikolata"],
  },
  {
    category: "Gofret",
    reason: "Ürün adı gofret sinyali veriyor.",
    confidence: "high",
    tokens: ["gofret"],
  },
  {
    category: "Bisküvi",
    reason: "Ürün adı bisküvi sinyali veriyor.",
    confidence: "high",
    phrases: ["bebe biskuvisi"],
    tokens: ["biskuvi", "burcak"],
  },
  {
    category: "Kek",
    reason: "Ürün adı kek sinyali veriyor.",
    confidence: "high",
    phrases: ["baton kek", "brownie", "browni"],
    tokens: ["kek"],
  },
  {
    category: "Şekerleme",
    reason: "Ürün adı şekerleme sinyali veriyor.",
    confidence: "high",
    phrases: ["jelibon"],
    tokens: ["sekerleme", "lokum"],
  },
  {
    category: "Sakız",
    reason: "Ürün adı sakız sinyali veriyor.",
    confidence: "high",
    tokens: ["sakiz"],
  },
  {
    category: "Dondurma",
    reason: "Ürün adı dondurma sinyali veriyor.",
    confidence: "high",
    tokens: ["dondurma"],
  },
  {
    category: "Puding",
    reason: "Ürün adı puding sinyali veriyor.",
    confidence: "high",
    tokens: ["puding"],
  },
  {
    category: "Reçel",
    reason: "Ürün adı reçel / marmelat sinyali veriyor.",
    confidence: "high",
    tokens: ["recel", "marmelat", "receli"],
  },
  {
    category: "Bal",
    reason: "Ürün adı bal sinyali veriyor.",
    confidence: "high",
    tokens: ["bal", "bali"],
  },
  {
    category: "Pekmez",
    reason: "Ürün adı pekmez sinyali veriyor.",
    confidence: "high",
    tokens: ["pekmez", "pekmezi"],
  },
  {
    category: "Helva",
    reason: "Ürün adı helva sinyali veriyor.",
    confidence: "high",
    tokens: ["helva"],
  },
  {
    category: "Tahin",
    reason: "Ürün adı tahin sinyali veriyor.",
    confidence: "high",
    tokens: ["tahin"],
    exclude: ["tahin helva"],
  },
  {
    category: "Zeytin",
    reason: "Ürün adı zeytin sinyali veriyor.",
    confidence: "high",
    tokens: ["zeytin"],
  },
  {
    category: "Kahvaltılık Sos",
    reason: "Ürün adı kahvaltılık sos / ezme sinyali veriyor.",
    confidence: "high",
    phrases: ["kahvaltilik sos"],
    tokens: ["ezme"],
  },
  {
    category: "Kahvaltılık Gevrek",
    reason: "Ürün adı gevrek / müsli / granola sinyali veriyor.",
    confidence: "high",
    phrases: ["corn flakes"],
    tokens: ["gevrek", "musli", "granola"],
  },
  {
    category: "Yulaf",
    reason: "Ürün adı yulaf sinyali veriyor.",
    confidence: "high",
    phrases: ["yulaf ezmesi"],
    tokens: ["yulaf"],
  },
  {
    category: "Ekmek",
    reason: "Ürün adı ekmek sinyali veriyor.",
    confidence: "high",
    phrases: ["tost ekmegi", "sandvic ekmegi"],
    tokens: ["ekmek", "lavas", "tortilla"],
  },
  {
    category: "Galeta",
    reason: "Ürün adı galeta / grissini sinyali veriyor.",
    confidence: "high",
    tokens: ["galeta", "grissini"],
  },
  {
    category: "Unlu Mamuller",
    reason: "Ürün adı unlu mamul sinyali veriyor.",
    confidence: "medium",
    phrases: ["unlu mamul"],
  },
  {
    category: "Makarna",
    reason: "Ürün adı makarna sinyali veriyor.",
    confidence: "high",
    tokens: ["makarna", "spagetti", "penne", "eriste"],
  },
  {
    category: "Pirinç",
    reason: "Ürün adı pirinç sinyali veriyor.",
    confidence: "high",
    tokens: ["pirinc"],
  },
  {
    category: "Bulgur",
    reason: "Ürün adı bulgur sinyali veriyor.",
    confidence: "high",
    tokens: ["bulgur"],
  },
  {
    category: "Bakliyat",
    reason: "Ürün adı bakliyat sinyali veriyor.",
    confidence: "high",
    tokens: ["mercimek", "nohut", "fasulye", "bakliyat"],
  },
  {
    category: "Un",
    reason: "Ürün adı un sinyali veriyor.",
    confidence: "high",
    tokens: ["un", "unu"],
    exclude: ["unlu mamul"],
  },
  {
    category: "Şeker",
    reason: "Ürün adı şeker sinyali veriyor.",
    confidence: "high",
    tokens: ["seker"],
    exclude: ["sekerleme"],
  },
  {
    category: "Tuz",
    reason: "Ürün adı tuz sinyali veriyor.",
    confidence: "high",
    tokens: ["tuz", "tuzu"],
  },
  {
    category: "Sıvı Yağ",
    reason: "Ürün adı sıvı yağ sinyali veriyor.",
    confidence: "high",
    phrases: ["aycicek yagi", "zeytinyagi", "misir yagi"],
    tokens: ["yag"],
    exclude: ["tereyagi", "doymus yag"],
  },
  {
    category: "Salça",
    reason: "Ürün adı salça sinyali veriyor.",
    confidence: "high",
    tokens: ["salca", "salcasi"],
  },
  {
    category: "Sos",
    reason: "Ürün adı sos sinyali veriyor.",
    confidence: "high",
    tokens: ["ketcap", "mayonez", "hardal", "sos"],
  },
  {
    category: "Sirke",
    reason: "Ürün adı sirke sinyali veriyor.",
    confidence: "high",
    tokens: ["sirke", "sirkesi"],
  },
  {
    category: "Dondurulmuş Pizza",
    reason: "Ürün adı pizza sinyali veriyor.",
    confidence: "high",
    tokens: ["pizza"],
  },
  {
    category: "Dondurulmuş Hazır Ürün",
    reason: "Ürün adı dondurulmuş hazır ürün sinyali veriyor.",
    confidence: "high",
    phrases: ["hazir urun"],
    tokens: ["nugget", "sinitzel", "schnitzel"],
  },
  {
    category: "Mantı",
    reason: "Ürün adı mantı sinyali veriyor.",
    confidence: "high",
    tokens: ["manti"],
  },
  {
    category: "Hazır Çorba",
    reason: "Ürün adı hazır çorba sinyali veriyor.",
    confidence: "high",
    phrases: ["hazir corba"],
    tokens: ["corba"],
  },
  {
    category: "Konserve",
    reason: "Ürün adı konserve sinyali veriyor.",
    confidence: "high",
    tokens: ["konserve"],
  },
  {
    category: "Turşu",
    reason: "Ürün adı turşu sinyali veriyor.",
    confidence: "high",
    tokens: ["tursu", "tursusu"],
  },
  {
    category: "Şarküteri",
    reason: "Ürün adı şarküteri sinyali veriyor.",
    confidence: "high",
    tokens: ["sucuk", "salam", "sosis", "jambon"],
  },
  {
    category: "Sporcu Gıdası",
    reason: "Ürün adı sporcu gıdası sinyali veriyor.",
    confidence: "high",
    phrases: ["protein bar", "protein tozu"],
  },
  {
    category: "Su",
    reason: "Ürün adı su sinyali veriyor.",
    confidence: "medium",
    tokens: ["su"],
    requiresLiquid: true,
    exclude: ["maden suyu", "meyve suyu"],
  },
];

export function inferProductFinderCategorySuggestion(args: {
  productName: string | null;
  brand?: string | null;
  ingredients?: string | null;
  quantityUnit?: string | null;
  currentCategory?: string | null;
}) {
  if (safeString(args.currentCategory)) return null;

  const name = normalizeText(args.productName);
  const brand = normalizeText(args.brand);
  const ingredients = normalizeText(args.ingredients);
  const unit = normalizeText(args.quantityUnit);
  const liquid = unit === "ml" || unit === "l";
  const solid = unit === "g" || unit === "kg";
  const primary = [name, brand].filter(Boolean).join(" ").trim();
  const combined = [primary, ingredients].filter(Boolean).join(" ").trim();

  if (!primary && !ingredients) return null;

  const matches: CategorySuggestion[] = [];

  for (const rule of orderedRules) {
    if (rule.requiresLiquid && !liquid) continue;
    if (rule.requiresSolid && !solid) continue;
    if (rule.exclude?.some((item) => phraseMatch(combined, item))) continue;

    const phraseMatched =
      rule.phrases?.some((phrase) => phraseMatch(primary, normalizeText(phrase))) ||
      false;
    const tokenMatched =
      rule.tokens?.some((token) => hasWholeToken(primary, normalizeText(token))) ||
      false;

    if (!phraseMatched && !tokenMatched) continue;

    matches.push({
      value: rule.category,
      reason: rule.reason,
      confidence: rule.confidence,
    });
  }

  if (matches.length === 0) {
    return null;
  }

  return matches[0] ?? null;
}
