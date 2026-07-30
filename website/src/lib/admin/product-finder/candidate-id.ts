function simpleHash(value: string) {
  let hash = 0;
  for (let index = 0; index < value.length; index += 1) {
    hash = (hash * 31 + value.charCodeAt(index)) >>> 0;
  }
  return hash.toString(36);
}

function slugify(value: string) {
  return value
    .toLowerCase()
    .replace(/^https?:\/\//, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 36);
}

export function normalizeCandidateSourceUrl(value: string | null | undefined) {
  if (!value?.trim()) return "";

  try {
    const parsed = new URL(value.trim());
    parsed.hash = "";
    if ((parsed.protocol === "https:" && parsed.port === "443") || (parsed.protocol === "http:" && parsed.port === "80")) {
      parsed.port = "";
    }
    return parsed.toString();
  } catch {
    return value.trim();
  }
}

export function buildUrlCandidateId(options: {
  sourceName?: string | null;
  sourceProductId?: string | null;
  sourceUrl?: string | null;
  productName?: string | null;
}) {
  const sourceName = (options.sourceName || "source").trim().toLowerCase();
  const sourceProductId = (options.sourceProductId || "").trim().toLowerCase();
  const normalizedUrl = normalizeCandidateSourceUrl(options.sourceUrl);
  const slugSource =
    sourceProductId ||
    slugify(normalizedUrl || options.productName || "") ||
    "candidate";
  const hashSource = normalizedUrl || `${sourceName}:${sourceProductId}:${options.productName || ""}`;
  const shortHash = simpleHash(hashSource).slice(0, 8);

  return `finder-url-${sourceName}-${slugSource}-${shortHash}`;
}

export function ensureUniqueCandidateId(
  preferredId: string,
  existingIds: Iterable<string>,
) {
  const used = new Set(existingIds);
  if (!used.has(preferredId)) return preferredId;

  let suffix = 2;
  while (used.has(`${preferredId}-${suffix}`)) {
    suffix += 1;
  }

  return `${preferredId}-${suffix}`;
}
