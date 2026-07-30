import type {
  BarcodeIdentityProvider,
  ProductDetailProvider,
  ProductIdentityInput,
  ProductIdentityResult,
  SourceCandidate,
} from "@/lib/admin/product-finder/providers";

function todayIso() {
  return "2026-07-30";
}

export const mockBarcodeIdentityProvider: BarcodeIdentityProvider = {
  id: "mock-identity",
  label: "Mock Identity",
  priority: 10,
  async lookupBarcode(input: ProductIdentityInput): Promise<ProductIdentityResult | null> {
    if (!/^\d{8,14}$/.test(input.barcode)) {
      return null;
    }

    if (input.barcode === "8690574114658") {
      return {
        providerId: "mock-identity",
        barcode: input.barcode,
        brand: "Pepsi",
        product_name: "Pepsi Kola Kutu",
        quantity_value: 330,
        quantity_unit: "ml",
        variant: "klasik",
        source_name: "mock",
        source_url: "https://mock.local/pepsi-kola-kutu",
        confidence: 96,
        issues: [],
      };
    }

    if (input.barcode === "5000112664478") {
      return {
        providerId: "mock-identity",
        barcode: input.barcode,
        brand: "Coca-Cola",
        product_name: "Coca-Cola Original Taste",
        quantity_value: 330,
        quantity_unit: "ml",
        variant: "klasik",
        source_name: "mock",
        source_url: "https://mock.local/coca-cola-original-taste",
        confidence: 94,
        issues: [],
      };
    }

    return {
      providerId: "mock-identity",
      barcode: input.barcode,
      brand: null,
      product_name: `Mock ürün ${input.barcode}`,
      quantity_value: null,
      quantity_unit: null,
      variant: null,
      source_name: "mock",
      source_url: null,
      confidence: 52,
      issues: [],
    };
  },
};

export const mockProductDetailProvider: ProductDetailProvider = {
  id: "mock-detail",
  label: "Mock Detail",
  priority: 10,
  async searchProduct(identity) {
    const common = {
      source_name: "mock" as const,
      source_product_id: `mock-${identity.barcode}`,
      barcode: identity.barcode,
      brand: identity.brand,
      product_name: identity.product_name,
      quantity_value: identity.quantity_value,
      quantity_unit: identity.quantity_unit,
      quantity_display:
        identity.quantity_value != null && identity.quantity_unit
          ? `${identity.quantity_value} ${identity.quantity_unit}`
          : null,
      variant: identity.variant,
      category: "Gazlı İçecek",
      ingredients: "Su, şeker, karbondioksit, aroma vericiler",
      nutrition_basis: "100ml" as const,
      energy_kcal_100g: 42,
      energy_kj_100g: 176,
      fat_100g: 0,
      saturated_fat_100g: 0,
      carbohydrates_100g: 10.6,
      sugars_100g: 10.6,
      fiber_100g: 0,
      protein_100g: 0,
      salt_100g: 0.03,
      sodium_100g: 0.012,
      image_front_url: "https://mock.local/images/product-front.jpg",
      image_source_url: "https://mock.local/images/product-front.jpg",
      data_updated_at: todayIso(),
      match_confidence: null,
      issue_list: [],
    };

    if (identity.barcode === "8690574114658") {
      return [
        {
          ...common,
          source_url: "https://mock.local/migros/pepsi-kola-kutu",
          source_name: "mock",
        },
      ] satisfies SourceCandidate[];
    }

    if (identity.barcode === "5000112664478") {
      return [
        {
          ...common,
          brand: "Coca-Cola",
          product_name: "Coca-Cola Original Taste",
          source_url: "https://mock.local/carrefoursa/coca-cola-original-taste",
        },
      ] satisfies SourceCandidate[];
    }

    return [
      {
        ...common,
        category: null,
        ingredients: null,
        nutrition_basis: null,
        energy_kcal_100g: null,
        energy_kj_100g: null,
        fat_100g: null,
        saturated_fat_100g: null,
        carbohydrates_100g: null,
        sugars_100g: null,
        fiber_100g: null,
        protein_100g: null,
        salt_100g: null,
        sodium_100g: null,
        image_front_url: null,
        image_source_url: null,
        source_url: null,
      },
    ] satisfies SourceCandidate[];
  },
};
