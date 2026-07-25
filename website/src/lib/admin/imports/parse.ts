import "server-only";

import {
  MAX_IMPORT_FILE_SIZE_BYTES,
  MAX_IMPORT_ROWS,
  allowedExtensions,
} from "@/lib/admin/imports/constants";
import { sanitizeFileName, safeString } from "@/lib/admin/imports/helpers";
import type { ParsedImportRow } from "@/lib/admin/imports/types";

type SupportedImportFileType = "csv" | "xlsx" | "json";

type ImportFileDescriptor = {
  fileName: string;
  sanitizedFileName: string;
  fileType: SupportedImportFileType;
  fileSize: number;
  rows: ParsedImportRow[];
};

function detectFileType(file: File): SupportedImportFileType | null {
  const lowerName = file.name.toLowerCase();
  if (lowerName.endsWith(".csv")) return "csv";
  if (lowerName.endsWith(".xlsx")) return "xlsx";
  if (lowerName.endsWith(".json")) return "json";
  return null;
}

function parseCsvLine(line: string) {
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

    if (char === "," && !insideQuotes) {
      cells.push(current);
      current = "";
      continue;
    }

    current += char;
  }

  cells.push(current);
  return cells;
}

function parseCsvContent(content: string) {
  const normalized = content.replace(/^\uFEFF/, "");
  const lines = normalized.split(/\r?\n/).filter((line) => line.trim().length > 0);

  if (lines.length === 0) {
    throw new Error("Dosya boş görünüyor.");
  }

  const headers = parseCsvLine(lines[0]).map((header) => header.trim());

  if (headers.length === 0 || headers.every((header) => !header)) {
    throw new Error("CSV başlıkları okunamadı.");
  }

  return lines.slice(1).map((line, index) => {
    const values = parseCsvLine(line);
    const row: Record<string, unknown> = {};

    headers.forEach((header, columnIndex) => {
      if (!header) return;
      row[header] = values[columnIndex] ?? "";
    });

    return {
      rowNumber: index + 2,
      source: row,
    } satisfies ParsedImportRow;
  });
}

export function parseCsv(content: string) {
  return parseCsvContent(content);
}

export async function parseXlsx(buffer: ArrayBuffer) {
  try {
    const xlsx = await import("xlsx");
    const workbook = xlsx.read(Buffer.from(buffer), {
      type: "buffer",
      raw: false,
      dense: true,
      cellFormula: false,
      cellHTML: false,
      cellText: true,
    });

    const firstSheetName = workbook.SheetNames[0];
    const firstSheet = workbook.Sheets[firstSheetName];

    if (!firstSheet) {
      throw new Error("Excel sayfası bulunamadı.");
    }

    const matrix = xlsx.utils.sheet_to_json<(string | number | null)[]>(firstSheet, {
      header: 1,
      raw: false,
      defval: "",
      blankrows: false,
    });

    if (matrix.length === 0) {
      throw new Error("Excel dosyası boş görünüyor.");
    }

    const headers = (matrix[0] ?? []).map((cell) => safeString(cell));

    if (headers.length === 0 || headers.every((header) => !header)) {
      throw new Error("Excel başlıkları okunamadı.");
    }

    return matrix.slice(1).map((row, index) => {
      const normalizedRow: Record<string, unknown> = {};

      headers.forEach((header, columnIndex) => {
        if (!header) return;
        normalizedRow[header] = row[columnIndex] ?? "";
      });

      return {
        rowNumber: index + 2,
        source: normalizedRow,
      } satisfies ParsedImportRow;
    });
  } catch (error) {
    throw new Error(
      error instanceof Error && error.message
        ? error.message
        : "Excel dosyası güvenli biçimde okunamadı.",
    );
  }
}

export function parseJson(content: string) {
  let parsed: unknown;

  try {
    parsed = JSON.parse(content);
  } catch {
    throw new Error("JSON dosyası geçerli değil.");
  }

  if (!Array.isArray(parsed)) {
    throw new Error("JSON kök değeri ürün dizisi olmalıdır.");
  }

  if (parsed.length === 0) {
    throw new Error("JSON dosyası boş görünüyor.");
  }

  return parsed.map((item, index) => {
    if (!item || typeof item !== "object" || Array.isArray(item)) {
      throw new Error(`JSON içindeki ${index + 1}. satır nesne biçiminde değil.`);
    }

    return {
      rowNumber: index + 1,
      source: item as Record<string, unknown>,
    } satisfies ParsedImportRow;
  });
}

export async function parseImportFile(file: File): Promise<ImportFileDescriptor> {
  const fileType = detectFileType(file);

  if (!fileType || !allowedExtensions.includes(`.${fileType}`)) {
    throw new Error("Yalnızca CSV, XLSX ve JSON dosyaları desteklenir.");
  }

  if (file.size === 0) {
    throw new Error("Boş dosya yüklenemez.");
  }

  if (file.size > MAX_IMPORT_FILE_SIZE_BYTES) {
    throw new Error("Dosya boyutu 5 MB sınırını aşıyor.");
  }

  const sanitizedFileName = sanitizeFileName(file.name);

  let rows: ParsedImportRow[];

  if (fileType === "csv") {
    const content = await file.text();
    rows = parseCsv(content);
  } else if (fileType === "xlsx") {
    const buffer = await file.arrayBuffer();
    rows = await parseXlsx(buffer);
  } else {
    const content = await file.text();
    rows = parseJson(content);
  }

  if (rows.length > MAX_IMPORT_ROWS) {
    throw new Error("Dosya en fazla 500 satır içerebilir.");
  }

  return {
    fileName: file.name,
    sanitizedFileName,
    fileType,
    fileSize: file.size,
    rows,
  };
}
