import "server-only";

import type {
  BarcodeIdentityProvider,
  ProductIdentityInput,
  ProductIdentityResult,
} from "@/lib/admin/product-finder/providers";
import { normalizeIdentity } from "@/lib/admin/product-finder/identity-normalizer";

type OpenFoodFactsResponse = {
  status?: number;
  product?: {
    product_name?: string | null;
    product_name_tr?: string | null;
    brands?: string | null;
    quantity?: string | null;
    image_front_url?: string | null;
    url?: string | null;
  } | null;
};

export const openFoodFactsIdentityProvider: BarcodeIdentityProvider = {
  id: "openfoodfacts-identity",
  label: "OpenFoodFacts",
  priority: 20,
  async lookupBarcode(input: ProductIdentityInput): Promise<ProductIdentityResult | null> {
    const response = await fetch(
      `https://world.openfoodfacts.org/api/v2/product/${encodeURIComponent(input.barcode)}.json`,
      {
        headers: {
          "User-Agent": "LabelWise Product Finder / 1.0 (admin@labelwise.net)",
        },
        cache: "no-store",
      },
    );

    if (!response.ok) {
      throw new Error(`OPENFOODFACTS_${response.status}`);
    }

    const payload = (await response.json()) as OpenFoodFactsResponse;
    if (payload.status !== 1 || !payload.product) {
      return null;
    }

    const product = payload.product;
    const normalized = normalizeIdentity({
      barcode: input.barcode,
      rawName: product.product_name_tr ?? product.product_name,
      productName: product.product_name_tr ?? product.product_name,
      brand: product.brands?.split(",")[0] ?? null,
      quantityText: product.quantity,
      sourceName: "openfoodfacts",
      sourceUrl: product.url ?? `https://world.openfoodfacts.org/product/${input.barcode}`,
    });

    return {
      providerId: "openfoodfacts-identity",
      ...normalized,
    };
  },
};
