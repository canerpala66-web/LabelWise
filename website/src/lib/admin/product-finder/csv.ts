import { parseBarcode, safeString } from "@/lib/admin/imports/helpers";
import { importTemplateHeaders } from "@/lib/admin/imports/constants";

export type ParsedBarcodeSource = {
  rawCount: number;
  parsedCount: number;
  invalidCount: number;
  duplicatesRemoved: number;
  barcodes: string[];
};

export type ParsedProductFinderUpload =
  | ({ mode: "barcode_only" } & ParsedBarcodeSource)
  | {
      mode: "full_template";
      rawCount: number;
      parsedCount: number;
      invalidCount: number;
      duplicatesRemoved: number;
      barcodes: string[];
      rows: Array<Partial<Record<(typeof importTemplateHeaders)[number], string>>>;
    };

const candidateDelimiters = [",", ";", "\t"] as const;

function parseDelimitedLine(line: string, delimiter: string) {
  const cells: string[] = [];
  let current = "";
  let insideQuotes = false;

  for (let index = 0; index < line.length; index += 1) {
    const char = line[index];

    if (char === '"') {
      if (insideQuotes && line[index + 1] === '"') {
        current += '"';
        index += 1;
      } else {
        insideQuotes = !insideQuotes;
      }
      continue;
    }

    if (char === delimiter && !insideQuotes) {
      cells.push(current);
      current = "";
      continue;
    }

    current += char;
  }

  cells.push(current);
  return cells;
}

function scoreDelimiter(lines: string[], delimiter: string) {
  const widths = lines
    .slice(0, 5)
    .map((line) => parseDelimitedLine(line, delimiter).length);

  const maxWidth = Math.max(...widths);
  const minWidth = Math.min(...widths);
  const consistentRows = widths.filter((width) => width > 1).length;

  return {
    delimiter,
    maxWidth,
    minWidth,
    consistentRows,
  };
}

function detectDelimiter(lines: string[]) {
  const scores = candidateDelimiters.map((delimiter) =>
    scoreDelimiter(lines, delimiter),
  );

  scores.sort((left, right) => {
    if (right.consistentRows !== left.consistentRows) {
      return right.consistentRows - left.consistentRows;
    }

    if (right.maxWidth !== left.maxWidth) {
      return right.maxWidth - left.maxWidth;
    }

    return left.minWidth - right.minWidth;
  });

  return scores[0]?.delimiter ?? ",";
}

export function parseBarcodeTextarea(input: string) {
  return input
    .split(/\r?\n/)
    .map((line) => parseBarcode(line))
    .map((line) => safeString(line))
    .filter(Boolean);
}

function detectBarcodeColumn(headers: string[]) {
  const barcodeColumnIndex = headers.findIndex(
    (item) => item === "barcode" || item === "barkod",
  );

  return barcodeColumnIndex >= 0 ? barcodeColumnIndex : 0;
}

function hasBarcodeHeader(headers: string[]) {
  return headers.some((item) => item === "barcode" || item === "barkod");
}

function looksLikeHeaderRow(firstRow: string[], secondRow?: string[]) {
  const firstCell = safeString(firstRow[0] ?? "");
  const secondCell = safeString(secondRow?.[0] ?? "");

  if (!firstCell) {
    return false;
  }

  if (/^\d{8,14}$/.test(firstCell)) {
    return false;
  }

  if (firstCell === "barcode" || firstCell === "barkod") {
    return true;
  }

  if (secondCell && /^\d{8,14}$/.test(secondCell)) {
    return true;
  }

  return false;
}

function hasImportTemplateHeaders(headers: string[]) {
  const normalizedTemplateHeaders = new Set<string>(importTemplateHeaders);
  const matchedCount = headers.filter((item) => normalizedTemplateHeaders.has(item)).length;
  return matchedCount >= 4 && headers.includes("barcode");
}

export function finalizeParsedBarcodes(values: string[]): ParsedBarcodeSource {
  const seen = new Set<string>();
  const barcodes: string[] = [];
  let invalidCount = 0;
  let duplicatesRemoved = 0;

  for (const value of values.map(parseBarcode).map(safeString).filter(Boolean)) {
    if (seen.has(value)) {
      duplicatesRemoved += 1;
      continue;
    }

    seen.add(value);
    barcodes.push(value);

    if (!/^\d{8,14}$/.test(value) || /[;,\t]/.test(value)) {
      invalidCount += 1;
    }
  }

  return {
    rawCount: values.length,
    parsedCount: barcodes.length,
    invalidCount,
    duplicatesRemoved,
    barcodes,
  };
}

export function parseBarcodeCsvDetailed(content: string): ParsedBarcodeSource {
  const parsed = parseProductFinderCsv(content);
  if (parsed.mode === "full_template") {
    return {
      rawCount: parsed.rawCount,
      parsedCount: parsed.parsedCount,
      invalidCount: parsed.invalidCount,
      duplicatesRemoved: parsed.duplicatesRemoved,
      barcodes: parsed.barcodes,
    };
  }
  return parsed;
}

export function parseProductFinderCsv(content: string): ParsedProductFinderUpload {
  const normalized = content.replace(/^\uFEFF/, "");
  const lines = normalized.split(/\r?\n/).filter((line) => line.trim().length > 0);

  if (lines.length === 0) {
    return { mode: "barcode_only", ...finalizeParsedBarcodes([]) };
  }

  const delimiter = detectDelimiter(lines);
  const firstRow = parseDelimitedLine(lines[0], delimiter).map((item) =>
    item.trim().toLowerCase(),
  );
  const secondRow = lines[1]
    ? parseDelimitedLine(lines[1], delimiter).map((item) => item.trim().toLowerCase())
    : undefined;
  const barcodeColumnIndex = detectBarcodeColumn(firstRow);
  const startsWithHeader =
    hasBarcodeHeader(firstRow) || looksLikeHeaderRow(firstRow, secondRow);

  if (startsWithHeader && hasImportTemplateHeaders(firstRow)) {
    const headers = firstRow;
    const rawRows = lines.slice(1).map((line) => parseDelimitedLine(line, delimiter));
    const normalizedRows = rawRows
      .map((row) =>
        Object.fromEntries(
          headers
            .map((header, index) => [header, safeString(row[index] ?? "")] as const)
            .filter(([header]) => importTemplateHeaders.includes(header as (typeof importTemplateHeaders)[number])),
        ) as Partial<Record<(typeof importTemplateHeaders)[number], string>>,
      )
      .filter((row) => safeString(row.barcode));

    const barcodeStats = finalizeParsedBarcodes(
      normalizedRows.map((row) => safeString(row.barcode)),
    );

    const seen = new Set<string>();
    const dedupedRows = normalizedRows.filter((row) => {
      const barcode = safeString(row.barcode);
      if (!barcode || seen.has(barcode)) {
        return false;
      }
      seen.add(barcode);
      return true;
    });

    return {
      mode: "full_template",
      rawCount: normalizedRows.length,
      parsedCount: barcodeStats.parsedCount,
      invalidCount: barcodeStats.invalidCount,
      duplicatesRemoved: normalizedRows.length - dedupedRows.length,
      barcodes: dedupedRows.map((row) => safeString(row.barcode)),
      rows: dedupedRows,
    };
  }

  const values = lines
    .slice(startsWithHeader ? 1 : 0)
    .map((line) => parseDelimitedLine(line, delimiter)[barcodeColumnIndex] ?? "")
    .map(safeString)
    .filter(Boolean);

  return { mode: "barcode_only", ...finalizeParsedBarcodes(values) };
}

export function parseBarcodeRowsDetailed(rows: unknown[][]): ParsedBarcodeSource {
  const parsed = parseProductFinderRows(rows);
  if (parsed.mode === "full_template") {
    return {
      rawCount: parsed.rawCount,
      parsedCount: parsed.parsedCount,
      invalidCount: parsed.invalidCount,
      duplicatesRemoved: parsed.duplicatesRemoved,
      barcodes: parsed.barcodes,
    };
  }
  return parsed;
}

export function parseProductFinderRows(rows: unknown[][]): ParsedProductFinderUpload {
  if (rows.length === 0) {
    return { mode: "barcode_only", ...finalizeParsedBarcodes([]) };
  }

  const headers = (rows[0] ?? []).map((item) => safeString(item).toLowerCase());
  const barcodeColumnIndex = detectBarcodeColumn(headers);

  if (hasImportTemplateHeaders(headers)) {
    const normalizedRows = rows
      .slice(1)
      .map((row) =>
        Object.fromEntries(
          headers
            .map((header, index) => [header, safeString(row[index] ?? "")] as const)
            .filter(([header]) => importTemplateHeaders.includes(header as (typeof importTemplateHeaders)[number])),
        ) as Partial<Record<(typeof importTemplateHeaders)[number], string>>,
      )
      .filter((row) => safeString(row.barcode));

    const barcodeStats = finalizeParsedBarcodes(
      normalizedRows.map((row) => safeString(row.barcode)),
    );

    const seen = new Set<string>();
    const dedupedRows = normalizedRows.filter((row) => {
      const barcode = safeString(row.barcode);
      if (!barcode || seen.has(barcode)) {
        return false;
      }
      seen.add(barcode);
      return true;
    });

    return {
      mode: "full_template",
      rawCount: normalizedRows.length,
      parsedCount: barcodeStats.parsedCount,
      invalidCount: barcodeStats.invalidCount,
      duplicatesRemoved: normalizedRows.length - dedupedRows.length,
      barcodes: dedupedRows.map((row) => safeString(row.barcode)),
      rows: dedupedRows,
    };
  }

  const values = rows
    .slice(1)
    .map((row) => safeString(row[barcodeColumnIndex] ?? ""))
    .filter(Boolean);

  return { mode: "barcode_only", ...finalizeParsedBarcodes(values) };
}

export function parseBarcodeCsv(content: string) {
  return parseBarcodeCsvDetailed(content).barcodes;
}
