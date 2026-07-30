import { validateMigrosProductUrl } from "@/lib/admin/product-finder/adapters/migros";

export type ParsedProductUrl = {
  url: string;
  source: "migros";
};

export type ParsedProductUrlBatch = {
  urls: ParsedProductUrl[];
  rawCount: number;
  parsedCount: number;
  duplicatesRemoved: number;
  unsupportedCount: number;
  invalidCount: number;
};

function isMigrosDetailUrl(url: string) {
  const parsed = validateMigrosProductUrl(url);
  if (!parsed) return false;
  const path = parsed.pathname.toLowerCase();
  return path.includes("-p-") && path !== "/" && !path.startsWith("/arama");
}

export function parseProductUrlTextarea(input: string): ParsedProductUrlBatch {
  const lines = input
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  const seen = new Set<string>();
  const urls: ParsedProductUrl[] = [];
  let duplicatesRemoved = 0;
  let unsupportedCount = 0;
  let invalidCount = 0;

  for (const line of lines) {
    let parsedUrl: URL;
    try {
      parsedUrl = new URL(line);
    } catch {
      invalidCount += 1;
      continue;
    }

    const normalized = parsedUrl.toString();
    if (seen.has(normalized)) {
      duplicatesRemoved += 1;
      continue;
    }
    seen.add(normalized);

    if (isMigrosDetailUrl(normalized)) {
      urls.push({ url: normalized, source: "migros" });
      continue;
    }

    if (validateMigrosProductUrl(normalized)) {
      unsupportedCount += 1;
      continue;
    }

    unsupportedCount += 1;
  }

  return {
    urls,
    rawCount: lines.length,
    parsedCount: urls.length,
    duplicatesRemoved,
    unsupportedCount,
    invalidCount,
  };
}
