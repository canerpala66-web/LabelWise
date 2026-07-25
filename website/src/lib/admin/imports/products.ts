import "server-only";

import { createSupabaseAdminClient } from "@/lib/supabase/server";
import type {
  ExistingProductSnapshot,
  ImportJobRecord,
  ImportMode,
  ImportRowRecord,
  PreviewPayload,
  ProductWritePayload,
  ValidationMessage,
} from "@/lib/admin/imports/types";
import { IMPORT_BATCH_SIZE } from "@/lib/admin/imports/constants";
import { chunkArray } from "@/lib/admin/imports/helpers";

const productSelectFields = [
  "id",
  "barcode",
  "name",
  "brand",
  "category",
  "ingredients_text",
  "energy_kcal",
  "energy_kj",
  "fat",
  "saturated_fat",
  "carbohydrates",
  "sugars",
  "fiber",
  "protein",
  "salt",
  "sodium",
  "image_url",
  "source",
  "data_source",
  "source_url",
  "data_updated_at",
  "packaging_version",
  "is_current",
  "verification_notes",
  "quantity_value",
  "quantity_unit",
  "serving_size",
  "country",
  "language_code",
  "external_id",
  "notes",
  "is_verified",
  "updated_at",
].join(",");

type ImportJobInsert = {
  file_name: string;
  file_type: string;
  file_size: number;
  status: string;
  import_mode: ImportMode;
  allow_stale_override: boolean;
  confirmation_key: string;
  total_rows: number;
  valid_rows: number;
  warning_rows: number;
  invalid_rows: number;
  created_by: string;
  confirmed_at: string;
};

type ImportRowInsert = {
  import_job_id: string;
  row_number: number;
  barcode: string | null;
  normalized_data: Record<string, unknown>;
  validation_errors: ValidationMessage[];
  validation_warnings: ValidationMessage[];
  status: string;
  existing_product_id: string | null;
  imported_product_id?: string | null;
  processed_at?: string | null;
};

export async function getExistingProductsByBarcodes(barcodes: string[]) {
  if (barcodes.length === 0) {
    return new Map<string, ExistingProductSnapshot>();
  }

  const client = createSupabaseAdminClient();
  const { data, error } = await client
    .from("products")
    .select(productSelectFields)
    .in("barcode", barcodes);

  if (error) {
    throw error;
  }

  return new Map(
    ((data ?? []) as unknown as ExistingProductSnapshot[]).map((item) => [item.barcode, item]),
  );
}

export function mergeNonEmptyFields(
  existing: ExistingProductSnapshot | null,
  incoming: ProductWritePayload,
): ProductWritePayload {
  if (!existing) {
    return incoming;
  }

  const merged: ProductWritePayload = {
    barcode: existing.barcode,
    name: existing.name ?? incoming.name,
    source: incoming.source ?? existing.source,
  };

  if (incoming.name?.trim()) merged.name = incoming.name;
  if (incoming.brand?.trim()) merged.brand = incoming.brand;
  if (incoming.category?.trim()) merged.category = incoming.category;
  if (incoming.ingredients_text?.trim()) merged.ingredients_text = incoming.ingredients_text;
  if (incoming.quantity_value != null) merged.quantity_value = incoming.quantity_value;
  if (incoming.quantity_unit?.trim()) merged.quantity_unit = incoming.quantity_unit;
  if (incoming.serving_size?.trim()) merged.serving_size = incoming.serving_size;
  if (incoming.energy_kcal != null) merged.energy_kcal = incoming.energy_kcal;
  if (incoming.energy_kj != null) merged.energy_kj = incoming.energy_kj;
  if (incoming.fat != null) merged.fat = incoming.fat;
  if (incoming.saturated_fat != null) merged.saturated_fat = incoming.saturated_fat;
  if (incoming.carbohydrates != null) merged.carbohydrates = incoming.carbohydrates;
  if (incoming.sugars != null) merged.sugars = incoming.sugars;
  if (incoming.fiber != null) merged.fiber = incoming.fiber;
  if (incoming.protein != null) merged.protein = incoming.protein;
  if (incoming.salt != null) merged.salt = incoming.salt;
  if (incoming.sodium != null) merged.sodium = incoming.sodium;
  if (incoming.image_url?.trim()) merged.image_url = incoming.image_url;
  if (incoming.source?.trim()) merged.source = incoming.source;
  if (incoming.data_source?.trim()) merged.data_source = incoming.data_source;
  if (incoming.source_url?.trim()) merged.source_url = incoming.source_url;
  if (incoming.data_updated_at?.trim()) merged.data_updated_at = incoming.data_updated_at;
  if (incoming.packaging_version?.trim()) merged.packaging_version = incoming.packaging_version;
  if (incoming.is_current != null) merged.is_current = incoming.is_current;
  if (incoming.verification_notes?.trim()) merged.verification_notes = incoming.verification_notes;
  if (incoming.country?.trim()) merged.country = incoming.country;
  if (incoming.language_code?.trim()) merged.language_code = incoming.language_code;
  if (incoming.external_id?.trim()) merged.external_id = incoming.external_id;
  if (incoming.notes?.trim()) merged.notes = incoming.notes;
  if (incoming.is_verified != null) merged.is_verified = incoming.is_verified;

  const fallbackTextFields: Array<[keyof ProductWritePayload, keyof ExistingProductSnapshot]> = [
    ["brand", "brand"],
    ["category", "category"],
    ["ingredients_text", "ingredients_text"],
    ["source", "source"],
    ["data_source", "data_source"],
    ["source_url", "source_url"],
    ["packaging_version", "packaging_version"],
    ["verification_notes", "verification_notes"],
    ["quantity_unit", "quantity_unit"],
    ["serving_size", "serving_size"],
    ["country", "country"],
    ["language_code", "language_code"],
    ["external_id", "external_id"],
    ["notes", "notes"],
    ["image_url", "image_url"],
  ];

  for (const [targetKey, sourceKey] of fallbackTextFields) {
    if (!merged[targetKey] && existing[sourceKey] != null) {
      merged[targetKey] = existing[sourceKey] as never;
    }
  }

  const fallbackNumericFields: Array<[keyof ProductWritePayload, keyof ExistingProductSnapshot]> = [
    ["energy_kcal", "energy_kcal"],
    ["energy_kj", "energy_kj"],
    ["fat", "fat"],
    ["saturated_fat", "saturated_fat"],
    ["carbohydrates", "carbohydrates"],
    ["sugars", "sugars"],
    ["fiber", "fiber"],
    ["protein", "protein"],
    ["salt", "salt"],
    ["sodium", "sodium"],
    ["quantity_value", "quantity_value"],
  ];

  for (const [targetKey, sourceKey] of fallbackNumericFields) {
    if (merged[targetKey] == null && existing[sourceKey] != null) {
      merged[targetKey] = existing[sourceKey] as never;
    }
  }

  if (merged.data_updated_at == null && existing.data_updated_at) {
    merged.data_updated_at = existing.data_updated_at;
  }

  if (merged.is_current == null && existing.is_current != null) {
    merged.is_current = existing.is_current;
  }

  if (merged.is_verified == null && existing.is_verified != null) {
    merged.is_verified = existing.is_verified;
  }

  return merged;
}

export function mapImportRowToProduct(normalized: PreviewPayload["rows"][number]["normalized"]): ProductWritePayload {
  return {
    barcode: normalized.barcode ?? "",
    name: normalized.productName ?? "",
    brand: normalized.brand,
    category: normalized.category,
    ingredients_text: normalized.ingredients,
    quantity_value: normalized.quantityValue,
    quantity_unit: normalized.quantityUnit,
    serving_size: normalized.servingSize,
    energy_kcal: normalized.energyKcal100g,
    energy_kj: normalized.energyKj100g,
    fat: normalized.fat100g,
    saturated_fat: normalized.saturatedFat100g,
    carbohydrates: normalized.carbohydrates100g,
    sugars: normalized.sugars100g,
    fiber: normalized.fiber100g,
    protein: normalized.protein100g,
    salt: normalized.salt100g,
    sodium: normalized.sodium100g,
    image_url: normalized.imageFrontUrl,
    source: "bulk_import",
    data_source: normalized.dataSource,
    source_url: normalized.sourceUrl,
    data_updated_at: normalized.dataUpdatedAt,
    packaging_version: normalized.packagingVersion,
    is_current: normalized.isCurrent,
    verification_notes: normalized.verificationNotes,
    country: normalized.country,
    language_code: normalized.languageCode,
    external_id: normalized.externalId,
    notes: normalized.notes,
    is_verified: normalized.isVerified,
  };
}

export async function findJobByConfirmationKey(createdBy: string, confirmationKey: string) {
  const client = createSupabaseAdminClient();
  const { data, error } = await client
    .from("product_import_jobs")
    .select("*")
    .eq("created_by", createdBy)
    .eq("confirmation_key", confirmationKey)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return (data ?? null) as ImportJobRecord | null;
}

export async function createImportJob(input: ImportJobInsert) {
  const client = createSupabaseAdminClient();
  const { data, error } = await client
    .from("product_import_jobs")
    .insert(input)
    .select("*")
    .single();

  if (error) {
    throw error;
  }

  return data as ImportJobRecord;
}

export async function insertImportRows(rows: ImportRowInsert[]) {
  const client = createSupabaseAdminClient();
  const { error } = await client.from("product_import_rows").insert(rows);
  if (error) {
    throw error;
  }
}

export async function updateImportJob(jobId: string, payload: Partial<ImportJobRecord>) {
  const client = createSupabaseAdminClient();
  const { error } = await client.from("product_import_jobs").update(payload).eq("id", jobId);
  if (error) {
    throw error;
  }
}

export async function getImportJobs() {
  const client = createSupabaseAdminClient();
  const { data, error } = await client
    .from("product_import_jobs")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(30);

  if (error) {
    throw error;
  }

  return (data ?? []) as ImportJobRecord[];
}

export async function getImportJobById(jobId: string) {
  const client = createSupabaseAdminClient();
  const { data, error } = await client
    .from("product_import_jobs")
    .select("*")
    .eq("id", jobId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return (data ?? null) as ImportJobRecord | null;
}

export async function getImportRowsByJobId(jobId: string) {
  const client = createSupabaseAdminClient();
  const { data, error } = await client
    .from("product_import_rows")
    .select("*")
    .eq("import_job_id", jobId)
    .order("row_number", { ascending: true });

  if (error) {
    throw error;
  }

  return (data ?? []) as ImportRowRecord[];
}

export async function insertProduct(payload: ProductWritePayload) {
  const client = createSupabaseAdminClient();
  const { data, error } = await client.from("products").insert(payload).select("id").single();
  if (error) {
    throw error;
  }
  return data as { id: string };
}

export async function updateProduct(productId: string, payload: ProductWritePayload) {
  const client = createSupabaseAdminClient();
  const { data, error } = await client
    .from("products")
    .update(payload)
    .eq("id", productId)
    .select("id")
    .single();
  if (error) {
    throw error;
  }
  return data as { id: string };
}

export async function updateImportRowResult(rowId: string, payload: Partial<ImportRowRecord>) {
  const client = createSupabaseAdminClient();
  const { error } = await client.from("product_import_rows").update(payload).eq("id", rowId);
  if (error) {
    throw error;
  }
}

export function shouldProcessRow(
  row: PreviewPayload["rows"][number],
  importMode: ImportMode,
  allowStaleOverride: boolean,
) {
  if (row.errors.length > 0 || row.duplicateInFile) {
    return false;
  }

  if (!allowStaleOverride && row.requiresStaleOverride) {
    return false;
  }

  if (!row.normalized.isCurrent) {
    return false;
  }

  if (importMode === "insert_only" && row.existingProduct) {
    return false;
  }

  if (importMode === "update_only" && !row.existingProduct) {
    return false;
  }

  return true;
}

export async function processImportRows(args: {
  jobId: string;
  rows: Array<PreviewPayload["rows"][number] & { rowRecordId: string }>;
  importMode: ImportMode;
  allowStaleOverride: boolean;
}) {
  let insertedRows = 0;
  let updatedRows = 0;
  let skippedRows = 0;
  let failedRows = 0;

  const chunks = chunkArray(args.rows, IMPORT_BATCH_SIZE);

  for (const chunk of chunks) {
    for (const row of chunk) {
      const shouldProcess = shouldProcessRow(row, args.importMode, args.allowStaleOverride);

      if (!shouldProcess) {
        skippedRows += 1;
        await updateImportRowResult(row.rowRecordId, {
          status: "skipped",
          processed_at: new Date().toISOString(),
        });
        continue;
      }

      try {
        const mapped = mapImportRowToProduct(row.normalized);
        if (row.existingProduct) {
          const merged = mergeNonEmptyFields(row.existingProduct, mapped);
          const result = await updateProduct(row.existingProduct.id, merged);
          updatedRows += 1;
          await updateImportRowResult(row.rowRecordId, {
            status: "imported",
            imported_product_id: result.id,
            processed_at: new Date().toISOString(),
          });
        } else {
          const result = await insertProduct(mapped);
          insertedRows += 1;
          await updateImportRowResult(row.rowRecordId, {
            status: "imported",
            imported_product_id: result.id,
            processed_at: new Date().toISOString(),
          });
        }
      } catch {
        failedRows += 1;
        await updateImportRowResult(row.rowRecordId, {
          status: "failed",
          processed_at: new Date().toISOString(),
        });
      }
    }
  }

  return {
    insertedRows,
    updatedRows,
    skippedRows,
    failedRows,
  };
}
