import { safeString } from "@/lib/admin/imports/helpers";

export const NUTRITION_TABLE_NOT_AVAILABLE_MARKER = "nutrition_table_not_available:true";

export function hasNutritionTableNotAvailableMarker(...values: Array<string | null | undefined>) {
  return values.some((value) =>
    safeString(value).toLowerCase().includes(NUTRITION_TABLE_NOT_AVAILABLE_MARKER),
  );
}

export function appendNutritionTableNotAvailableMarker(value: string | null | undefined) {
  const current = safeString(value);
  if (!current) return NUTRITION_TABLE_NOT_AVAILABLE_MARKER;
  if (hasNutritionTableNotAvailableMarker(current)) return current;
  return `${current}\n${NUTRITION_TABLE_NOT_AVAILABLE_MARKER}`;
}

export function removeNutritionTableNotAvailableMarker(value: string | null | undefined) {
  return safeString(value)
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line && line.toLowerCase() !== NUTRITION_TABLE_NOT_AVAILABLE_MARKER)
    .join("\n");
}
