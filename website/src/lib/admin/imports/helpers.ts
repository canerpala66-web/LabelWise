import crypto from "node:crypto";

export function sanitizeFileName(name: string) {
  return name.replace(/[^\p{L}\p{N}._-]+/gu, "_").slice(0, 120) || "import";
}

export function normalizeWhitespace(value: string) {
  return value.replace(/\r\n/g, "\n").replace(/[ \t]+/g, " ").replace(/\n{3,}/g, "\n\n").trim();
}

export function compactSpaces(value: string) {
  return value.replace(/\s+/g, " ").trim();
}

export function safeString(value: unknown) {
  if (typeof value === "string") {
    return value.trim();
  }

  if (typeof value === "number" && Number.isFinite(value)) {
    return String(value);
  }

  if (typeof value === "boolean") {
    return value ? "true" : "false";
  }

  return "";
}

export function parseBoolean(value: unknown, fallback = false) {
  if (typeof value === "boolean") {
    return value;
  }

  const normalized = safeString(value).toLowerCase();
  if (!normalized) {
    return fallback;
  }

  return ["true", "1", "evet", "yes"].includes(normalized);
}

export function parseNumeric(value: unknown) {
  const raw = safeString(value);
  if (!raw) {
    return null;
  }

  const normalized = raw.replace(/\s+/g, "").replace(",", ".");
  if (!/^[-+]?\d+(\.\d+)?$/.test(normalized)) {
    return Number.isFinite(Number(normalized)) ? Number(normalized) : null;
  }

  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

export function parseBarcode(value: unknown) {
  const raw = safeString(value);
  if (!raw) {
    return "";
  }

  if (/^[0-9]+(?:\.[0]+)?$/.test(raw)) {
    return raw.replace(/\.0+$/, "");
  }

  const compact = raw.replace(/\s+/g, "");
  const scientific = compact.match(/^(\d+(?:\.\d+)?)e\+?(\d+)$/i);

  if (scientific) {
    const coefficient = scientific[1];
    const exponent = Number(scientific[2]);
    const digits = coefficient.replace(".", "");
    const decimalPlaces = coefficient.includes(".")
      ? coefficient.length - coefficient.indexOf(".") - 1
      : 0;
    const zeroCount = Math.max(exponent - decimalPlaces, 0);
    return `${digits}${"0".repeat(zeroCount)}`;
  }

  return compact;
}

export function parseDateInput(value: unknown) {
  const raw = safeString(value);
  if (!raw) {
    return null;
  }

  const normalized = raw.includes("T")
    ? raw
    : raw.replace(/\./g, "-").replace(/\//g, "-");
  const date = new Date(normalized);
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  return date;
}

export function formatDateTime(value: string | null) {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return new Intl.DateTimeFormat("tr-TR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}

export function formatDate(value: string | null) {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return new Intl.DateTimeFormat("tr-TR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(date);
}

export function chunkArray<T>(items: T[], size: number) {
  const chunks: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

export function createPreviewToken() {
  return crypto.randomUUID();
}

export function createConfirmationKey(previewToken: string, userId: string) {
  return crypto.createHash("sha256").update(`${previewToken}:${userId}`).digest("hex");
}

export function csvEscape(value: unknown) {
  const raw = safeString(value);
  const protectedValue = /^[=+\-@]/.test(raw) ? `'${raw}` : raw;
  return `"${protectedValue.replace(/"/g, '""')}"`;
}

export function jsonSafeParse<T>(value: string): T | null {
  try {
    return JSON.parse(value) as T;
  } catch {
    return null;
  }
}
