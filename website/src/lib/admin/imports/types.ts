export const importModes = [
  "insert_and_update",
  "insert_only",
  "update_only",
] as const;

export type ImportMode = (typeof importModes)[number];

export const importJobStatuses = [
  "uploaded",
  "validating",
  "ready",
  "importing",
  "completed",
  "partially_completed",
  "failed",
  "cancelled",
] as const;

export type ImportJobStatus = (typeof importJobStatuses)[number];

export type ValidationSeverity = "error" | "warning";

export type ValidationCode =
  | "missing_barcode"
  | "invalid_barcode"
  | "duplicate_in_file"
  | "barcode_conflict_unknown"
  | "missing_product_name"
  | "incomplete_product_name"
  | "missing_brand"
  | "missing_category"
  | "missing_ingredients"
  | "invalid_ingredients"
  | "missing_data_source"
  | "invalid_data_source"
  | "missing_update_date"
  | "invalid_update_date"
  | "future_update_date"
  | "stale_data"
  | "stale_update_attempt"
  | "missing_nutrition_data"
  | "invalid_numeric_value"
  | "negative_numeric_value"
  | "manual_review"
  | "quantity_mismatch"
  | "unverified_source"
  | "invalid_image_url"
  | "invalid_image_protocol"
  | "unsafe_image_url"
  | "invalid_import_action"
  | "not_current_product";

export type ValidationMessage = {
  code: ValidationCode;
  message: string;
  field?: string;
  severity: ValidationSeverity;
};

export type ParsedImportRow = {
  rowNumber: number;
  source: Record<string, unknown>;
};

export type ImportRowInput = {
  barcode: string | null;
  productName: string | null;
  brand: string | null;
  category: string | null;
  ingredients: string | null;
  quantityValue: number | null;
  quantityUnit: string | null;
  servingSize: string | null;
  energyKcal100g: number | null;
  energyKj100g: number | null;
  fat100g: number | null;
  saturatedFat100g: number | null;
  carbohydrates100g: number | null;
  sugars100g: number | null;
  fiber100g: number | null;
  protein100g: number | null;
  salt100g: number | null;
  sodium100g: number | null;
  imageFrontUrl: string | null;
  dataSource: string | null;
  sourceUrl: string | null;
  dataUpdatedAt: string | null;
  packagingVersion: string | null;
  isCurrent: boolean;
  verificationNotes: string | null;
  country: string;
  languageCode: string;
  externalId: string | null;
  notes: string | null;
  isVerified: boolean;
  importAction: "upsert" | "insert" | "update";
};

export type ExistingProductSnapshot = {
  id: string;
  barcode: string;
  name: string | null;
  brand: string | null;
  category: string | null;
  ingredients_text: string | null;
  energy_kcal: number | null;
  energy_kj: number | null;
  fat: number | null;
  saturated_fat: number | null;
  carbohydrates: number | null;
  sugars: number | null;
  fiber: number | null;
  protein: number | null;
  salt: number | null;
  sodium: number | null;
  image_url: string | null;
  source: string | null;
  data_source: string | null;
  source_url: string | null;
  data_updated_at: string | null;
  packaging_version: string | null;
  is_current: boolean | null;
  verification_notes: string | null;
  quantity_value: number | null;
  quantity_unit: string | null;
  serving_size: string | null;
  country: string | null;
  language_code: string | null;
  external_id: string | null;
  notes: string | null;
  is_verified: boolean | null;
  updated_at: string | null;
};

export type ImportRowStatus =
  | "valid_new"
  | "valid_update"
  | "valid_current"
  | "invalid"
  | "warning"
  | "duplicate_in_file"
  | "missing_nutrition_data"
  | "incomplete_product_name"
  | "manual_review"
  | "stale_data"
  | "stale_update_attempt"
  | "unverified_source"
  | "missing_update_date"
  | "quantity_mismatch"
  | "skipped"
  | "imported"
  | "failed";

export type PreviewRow = {
  rowNumber: number;
  raw: Record<string, unknown>;
  normalized: ImportRowInput;
  errors: ValidationMessage[];
  warnings: ValidationMessage[];
  status: ImportRowStatus;
  duplicateInFile: boolean;
  existingProduct: ExistingProductSnapshot | null;
  isNewProduct: boolean;
  isUpdate: boolean;
  isCurrentProduct: boolean;
  shouldImportByDefault: boolean;
  requiresStaleOverride: boolean;
};

export type PreviewSummary = {
  totalRows: number;
  validRows: number;
  warningRows: number;
  invalidRows: number;
  newRows: number;
  updateRows: number;
  currentRows: number;
  duplicateRows: number;
  staleRows: number;
  staleUpdateRows: number;
  missingNutritionRows: number;
  rowsWithImages: number;
};

export type PreviewPayload = {
  fileName: string;
  fileType: "csv" | "xlsx" | "json";
  fileSize: number;
  generatedAt: string;
  previewToken: string;
  rows: PreviewRow[];
  summary: PreviewSummary;
};

export type ProductWritePayload = {
  barcode: string;
  name: string;
  brand?: string | null;
  category?: string | null;
  ingredients_text?: string | null;
  quantity_value?: number | null;
  quantity_unit?: string | null;
  serving_size?: string | null;
  energy_kcal?: number | null;
  energy_kj?: number | null;
  fat?: number | null;
  saturated_fat?: number | null;
  carbohydrates?: number | null;
  sugars?: number | null;
  fiber?: number | null;
  protein?: number | null;
  salt?: number | null;
  sodium?: number | null;
  image_url?: string | null;
  source?: string | null;
  data_source?: string | null;
  source_url?: string | null;
  data_updated_at?: string | null;
  packaging_version?: string | null;
  is_current?: boolean | null;
  verification_notes?: string | null;
  country?: string | null;
  language_code?: string | null;
  external_id?: string | null;
  notes?: string | null;
  is_verified?: boolean | null;
};

export type ImportJobRecord = {
  id: string;
  file_name: string;
  file_type: string;
  file_size: number;
  status: ImportJobStatus;
  import_mode: ImportMode;
  allow_stale_override: boolean;
  total_rows: number;
  valid_rows: number;
  warning_rows: number;
  invalid_rows: number;
  inserted_rows: number;
  updated_rows: number;
  skipped_rows: number;
  failed_rows: number;
  created_by: string;
  created_at: string;
  confirmed_at: string | null;
  completed_at: string | null;
  error_message: string | null;
};

export type ImportRowRecord = {
  id: string;
  import_job_id: string;
  row_number: number;
  barcode: string | null;
  normalized_data: Record<string, unknown>;
  validation_errors: ValidationMessage[];
  validation_warnings: ValidationMessage[];
  status: string;
  existing_product_id: string | null;
  imported_product_id: string | null;
  created_at: string;
  processed_at: string | null;
};

export type ConfirmImportResult = {
  jobId: string;
  status: ImportJobStatus;
  insertedRows: number;
  updatedRows: number;
  skippedRows: number;
  failedRows: number;
};
