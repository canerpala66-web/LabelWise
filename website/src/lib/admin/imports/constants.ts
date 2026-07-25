import type { ImportMode } from "@/lib/admin/imports/types";

export const MAX_IMPORT_FILE_SIZE_BYTES = 5 * 1024 * 1024;
export const MAX_IMPORT_ROWS = 500;
export const IMPORT_BATCH_SIZE = 100;

export const allowedExtensions = [".csv", ".xlsx", ".json"] as const;

export const importTemplateHeaders = [
  "barcode",
  "product_name",
  "brand",
  "category",
  "ingredients",
  "quantity_value",
  "quantity_unit",
  "serving_size",
  "energy_kcal_100g",
  "energy_kj_100g",
  "fat_100g",
  "saturated_fat_100g",
  "carbohydrates_100g",
  "sugars_100g",
  "fiber_100g",
  "protein_100g",
  "salt_100g",
  "sodium_100g",
  "image_front_url",
  "data_source",
  "source_url",
  "data_updated_at",
  "packaging_version",
  "is_current",
  "verification_notes",
  "country",
  "language_code",
  "external_id",
  "notes",
  "is_verified",
  "import_action",
] as const;

export const importTemplateExampleRow = {
  barcode: "ORNEK_BARKODU_SILIN",
  product_name: "Ornek Marka Ornek Urun 150 g",
  brand: "Ornek Marka",
  category: "Atistirmalik",
  ingredients: "Ornek icerik listesi - import oncesi silin.",
  quantity_value: "150",
  quantity_unit: "g",
  serving_size: "30 g",
  energy_kcal_100g: "450",
  energy_kj_100g: "1880",
  fat_100g: "18",
  saturated_fat_100g: "6,5",
  carbohydrates_100g: "62",
  sugars_100g: "21",
  fiber_100g: "4",
  protein_100g: "7",
  salt_100g: "0,8",
  sodium_100g: "",
  image_front_url: "https://ornek.example.com/product-front.jpg",
  data_source: "product_packaging",
  source_url: "",
  data_updated_at: "2026-07-01",
  packaging_version: "v1",
  is_current: "true",
  verification_notes: "Ornek satiri import oncesi silin.",
  country: "TR",
  language_code: "tr",
  external_id: "",
  notes: "",
  is_verified: "false",
  import_action: "upsert",
} as const;

export const placeholderIngredientValues = new Set([
  "bilgi yok",
  "mevcut değil",
  "mevcut degil",
  "yok",
  "-",
  "n/a",
  "na",
  "none",
]);

export const normalizedDataSources = new Set([
  "manufacturer_website",
  "official_catalog",
  "product_packaging",
  "retailer",
  "openfoodfacts",
  "admin_research",
  "other",
]);

export const importModeOptions: Array<{
  value: ImportMode;
  label: string;
  description: string;
}> = [
  {
    value: "insert_and_update",
    label: "Yeni ürünleri ekle ve mevcut ürünleri güncelle",
    description: "Varsayılan ve en dengeli seçenek.",
  },
  {
    value: "insert_only",
    label: "Sadece yeni ürünleri ekle",
    description: "Mevcut barkodlara dokunmaz.",
  },
  {
    value: "update_only",
    label: "Yalnızca mevcut ürünleri güncelle",
    description: "Yeni barkodları atlar.",
  },
];
