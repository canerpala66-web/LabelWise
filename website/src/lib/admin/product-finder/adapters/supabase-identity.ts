import "server-only";

import { createSupabaseAdminClient } from "@/lib/supabase/server";
import type {
  BarcodeIdentityProvider,
  ProductIdentityInput,
  ProductIdentityResult,
} from "@/lib/admin/product-finder/providers";
import { normalizeIdentity } from "@/lib/admin/product-finder/identity-normalizer";

type ProductRow = {
  barcode: string;
  name: string | null;
  brand: string | null;
  quantity_value: number | null;
  quantity_unit: string | null;
  serving_size: string | null;
  source_url: string | null;
};

export const supabaseIdentityProvider: BarcodeIdentityProvider = {
  id: "supabase-identity",
  label: "Supabase Products",
  priority: 10,
  async lookupBarcode(input: ProductIdentityInput): Promise<ProductIdentityResult | null> {
    const client = createSupabaseAdminClient();
    const { data, error } = await client
      .from("products")
      .select("barcode,name,brand,quantity_value,quantity_unit,serving_size,source_url")
      .eq("barcode", input.barcode)
      .maybeSingle<ProductRow>();

    if (error) {
      throw error;
    }

    if (!data) {
      return null;
    }

    const normalized = normalizeIdentity({
      barcode: input.barcode,
      rawName: data.name,
      productName: data.name,
      brand: data.brand,
      quantityText:
        data.serving_size ??
        (data.quantity_value != null && data.quantity_unit
          ? `${data.quantity_value} ${data.quantity_unit}`
          : null),
      sourceName: "supabase",
      sourceUrl: data.source_url,
    });

    return {
      providerId: "supabase-identity",
      ...normalized,
      quantity_value: data.quantity_value ?? normalized.quantity_value,
      quantity_unit: data.quantity_unit ?? normalized.quantity_unit,
      quantity_display:
        data.serving_size ??
        normalized.quantity_display ??
        (data.quantity_value != null && data.quantity_unit
          ? `${data.quantity_value} ${data.quantity_unit}`
          : null),
      confidence: Math.max(normalized.confidence, 94),
      issues: normalized.issues.filter((issue) => issue.code !== "low_identity_confidence"),
    };
  },
};
