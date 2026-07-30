"use client";

import { useMemo, useState } from "react";
import { RemoteImagePreview } from "@/components/remote-image-preview";
import { applyMigrosSuggestions } from "@/lib/admin/product-finder/adapters/migros";
import { importTemplateHeaders } from "@/lib/admin/imports/constants";
import {
  finalizeParsedBarcodes,
  parseProductFinderCsv,
  parseProductFinderRows,
  parseBarcodeTextarea,
  type ParsedProductFinderUpload,
} from "@/lib/admin/product-finder/csv";
import { buildExportMatrix } from "@/lib/admin/product-finder/export";
import {
  createHydratedCandidateFromImportRow,
  createMockCandidate,
} from "@/lib/admin/product-finder/mock";
import type { ProductFinderCandidate } from "@/lib/admin/product-finder/types";
import type { SourceCandidate } from "@/lib/admin/product-finder/providers";
import {
  approveCandidate,
  rejectCandidate,
  summarizeCandidates,
  updateCandidateField,
  validateBarcodeBatch,
} from "@/lib/admin/product-finder/validation";
import { mockBarcodeIdentityProvider, mockProductDetailProvider } from "@/lib/admin/product-finder/adapters/mock-provider";
import {
  isEligibleForMockResolution,
  resolveProductFinderCandidate,
  resolutionToProductFinderCandidate,
} from "@/lib/admin/product-finder/resolver";
import { mapSourceCandidateToProductFinderCandidate } from "@/lib/admin/product-finder/source-candidate-mapper";
import type { ProductIdentityResult } from "@/lib/admin/product-finder/providers";
import { parseProductUrlTextarea } from "@/lib/admin/product-finder/url-input";

type IdentityApiResult = {
  barcode: string;
  identity: ProductIdentityResult | null;
  status: "resolved" | "needs_review" | "not_found" | "invalid";
  issues: ProductFinderCandidate["issue_list"];
  source_attempts?: Array<{
    providerId: string;
    success: boolean;
    message?: string;
  }>;
};

type MarketApiResult = {
  candidate_id: string;
  barcode: string;
  status: "enriched" | "needs_market_review" | "not_found" | "source_error";
  selected_source_url: string | null;
  match_confidence: number | null;
  match_reasons: string[];
  parsed_candidate: SourceCandidate | null;
  market_candidates: Array<{
    source_url: string;
    product_name: string | null;
    match_confidence: number;
  }>;
  note?: string;
};

type UrlParseApiResult = {
  url: string;
  status: "parsed" | "unsupported_domain" | "invalid_url" | "source_error";
  candidate: SourceCandidate | null;
  issues: ProductFinderCandidate["issue_list"];
};

function buildUrlCandidateId(url: string, index: number) {
  const safeSlug = url
    .replace(/^https?:\/\//, "")
    .replace(/[^a-z0-9]+/gi, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48);

  return `finder-url-${index + 1}-${safeSlug || "candidate"}`;
}

function hasMeaningfulText(value: string | null | undefined) {
  return Boolean(value?.trim());
}

function applyIdentityResultToCandidate(
  candidate: ProductFinderCandidate,
  result: IdentityApiResult,
) {
  if (!result.identity) {
    const uniqueIssues = [
      ...candidate.issue_list,
      ...result.issues.filter(
        (issue) => !candidate.issue_list.some((existing) => existing.code === issue.code),
      ),
    ];

    return {
      ...candidate,
      issue_list: uniqueIssues,
      status: result.status === "invalid" ? candidate.status : "needs_review",
    };
  }

  let next = { ...candidate };
  const identity = result.identity;

  if (!hasMeaningfulText(next.brand) && identity.brand) {
    next = updateCandidateField(next, "brand", identity.brand);
  }

  if (!hasMeaningfulText(next.product_name) && identity.product_name) {
    next = updateCandidateField(next, "product_name", identity.product_name);
  }

  if (next.quantity_value == null && identity.quantity_value != null) {
    next = updateCandidateField(next, "quantity_value", String(identity.quantity_value));
  }

  if (!hasMeaningfulText(next.quantity_unit) && identity.quantity_unit) {
    next = updateCandidateField(next, "quantity_unit", identity.quantity_unit);
  }

  if (!hasMeaningfulText(next.serving_size) && identity.quantity_display) {
    next = updateCandidateField(next, "serving_size", identity.quantity_display);
  }

  if (!hasMeaningfulText(next.data_source) || next.data_source === "product_finder") {
    next = updateCandidateField(next, "data_source", identity.source_name);
  }

  if (!hasMeaningfulText(next.source_url) && identity.source_url) {
    next = updateCandidateField(next, "source_url", identity.source_url);
  }

  const currentNotes = next.verification_notes.trim();
  const identityNote = `identity_source:${identity.source_name}`;
  const evidenceNote =
    identity.source_name === "web_search" && identity.evidence_results?.length
      ? `identity_evidence:${identity.evidence_results
          .slice(0, 2)
          .map((item) => `${item.domain}:${item.title}`)
          .join(" | ")}`
      : "";

  if (!currentNotes.includes(identityNote) || (evidenceNote && !currentNotes.includes("identity_evidence:"))) {
    next = updateCandidateField(
      next,
      "verification_notes",
      [currentNotes, identityNote, evidenceNote].filter(Boolean).join("\n"),
    );
  }

  if (identity.confidence != null) {
    next.match_confidence = identity.confidence;
  }

  const mergedIssues = [
    ...next.issue_list,
    ...result.issues.filter(
      (issue) => !next.issue_list.some((existing) => existing.code === issue.code),
    ),
  ];

  return {
    ...next,
    issue_list: mergedIssues,
    status: result.status === "resolved" ? next.status : "needs_review",
  };
}

function isEligibleForIdentityResolution(candidate: ProductFinderCandidate) {
  if (!/^\d{8,14}$/.test(candidate.barcode)) return false;
  if (candidate.status === "approved" || candidate.status === "export_ready") return false;

  const needsIdentity =
    !hasMeaningfulText(candidate.brand) ||
    !hasMeaningfulText(candidate.product_name) ||
    candidate.quantity_value == null ||
    !hasMeaningfulText(candidate.quantity_unit) ||
    candidate.data_source === "product_finder";

  return needsIdentity;
}

function isEligibleForMarketResolution(candidate: ProductFinderCandidate) {
  if (!/^\d{8,14}$/.test(candidate.barcode)) return false;
  if (!hasMeaningfulText(candidate.product_name)) return false;
  if (candidate.status === "approved" || candidate.status === "export_ready") return false;

  const needsEnrichment =
    !hasMeaningfulText(candidate.ingredients) ||
    candidate.energy_kcal_100g == null ||
    candidate.sugars_100g == null ||
    !hasMeaningfulText(candidate.image_front_url);

  return needsEnrichment;
}

function mergeMarketCandidate(
  candidate: ProductFinderCandidate,
  sourceCandidate: SourceCandidate,
  result: MarketApiResult,
) {
  let next = { ...candidate };

  if (!hasMeaningfulText(next.ingredients) && sourceCandidate.ingredients) {
    next = updateCandidateField(next, "ingredients", sourceCandidate.ingredients);
  }
  if (next.energy_kcal_100g == null && sourceCandidate.energy_kcal_100g != null) {
    next = updateCandidateField(next, "energy_kcal_100g", String(sourceCandidate.energy_kcal_100g));
  }
  if (next.energy_kj_100g == null && sourceCandidate.energy_kj_100g != null) {
    next = updateCandidateField(next, "energy_kj_100g", String(sourceCandidate.energy_kj_100g));
  }
  if (next.fat_100g == null && sourceCandidate.fat_100g != null) {
    next = updateCandidateField(next, "fat_100g", String(sourceCandidate.fat_100g));
  }
  if (next.saturated_fat_100g == null && sourceCandidate.saturated_fat_100g != null) {
    next = updateCandidateField(next, "saturated_fat_100g", String(sourceCandidate.saturated_fat_100g));
  }
  if (next.carbohydrates_100g == null && sourceCandidate.carbohydrates_100g != null) {
    next = updateCandidateField(next, "carbohydrates_100g", String(sourceCandidate.carbohydrates_100g));
  }
  if (next.sugars_100g == null && sourceCandidate.sugars_100g != null) {
    next = updateCandidateField(next, "sugars_100g", String(sourceCandidate.sugars_100g));
  }
  if (next.fiber_100g == null && sourceCandidate.fiber_100g != null) {
    next = updateCandidateField(next, "fiber_100g", String(sourceCandidate.fiber_100g));
  }
  if (next.protein_100g == null && sourceCandidate.protein_100g != null) {
    next = updateCandidateField(next, "protein_100g", String(sourceCandidate.protein_100g));
  }
  if (next.salt_100g == null && sourceCandidate.salt_100g != null) {
    next = updateCandidateField(next, "salt_100g", String(sourceCandidate.salt_100g));
  }
  if (next.sodium_100g == null && sourceCandidate.sodium_100g != null) {
    next = updateCandidateField(next, "sodium_100g", String(sourceCandidate.sodium_100g));
  }
  if (!hasMeaningfulText(next.image_front_url) && sourceCandidate.image_front_url) {
    next = updateCandidateField(next, "image_front_url", sourceCandidate.image_front_url);
  }
  if (!hasMeaningfulText(next.source_url) && sourceCandidate.source_url) {
    next = updateCandidateField(next, "source_url", sourceCandidate.source_url);
  }
  if ((!hasMeaningfulText(next.data_source) || next.data_source === "product_finder") && sourceCandidate.source_name) {
    next = updateCandidateField(next, "data_source", sourceCandidate.source_name);
  }

  const currentNotes = next.verification_notes.trim();
  const lines = [
    currentNotes,
    `market_source:migros`,
    result.note ?? "",
  ].filter(Boolean);
  next = updateCandidateField(next, "verification_notes", Array.from(new Set(lines)).join("\n"));

  if (sourceCandidate.match_confidence != null) {
    next.match_confidence = sourceCandidate.match_confidence;
  } else if (result.match_confidence != null) {
    next.match_confidence = result.match_confidence;
  }

  return next;
}

function getSourceSuggestionPayload(sourceCandidate: SourceCandidate) {
  if (!sourceCandidate.raw_payload || typeof sourceCandidate.raw_payload !== "object") {
    return {};
  }

  return sourceCandidate.raw_payload as {
    nutrition_basis_suggestion?: "100g" | "100ml" | null;
    nutrition_basis_suggestion_reason?: string | null;
    category_suggestion?: string | null;
    category_suggestion_reason?: string | null;
    category_suggestion_confidence?: "high" | "medium" | null;
  };
}

const filters = [
  ["all", "Tümü"],
  ["needs_review", "İnceleme gerekenler"],
  ["approved", "Onaylananlar"],
  ["rejected", "Reddedilenler"],
  ["ingredients_missing", "Eksik içerik"],
  ["nutrition_missing", "Eksik besin değeri"],
  ["export_ready", "Export hazır"],
] as const;

type FilterValue = (typeof filters)[number][0];

const editableFields: Array<keyof ProductFinderCandidate> = [
  "barcode",
  "product_name",
  "brand",
  "category",
  "ingredients",
  "quantity_value",
  "quantity_unit",
  "serving_size",
  "energy_kcal_100g",
  "energy_kj_100g",
  "fat_100g",
  "saturated_fat_100g",
  "carbohydrates_100g",
  "sugars_100g",
  "fiber_100g",
  "protein_100g",
  "salt_100g",
  "sodium_100g",
  "image_front_url",
  "data_source",
  "source_url",
  "data_updated_at",
  "packaging_version",
  "is_current",
  "verification_notes",
  "country",
  "language_code",
  "external_id",
  "notes",
  "is_verified",
  "import_action",
] as const;

const decimalFields = new Set<keyof ProductFinderCandidate>([
  "quantity_value",
  "energy_kcal_100g",
  "energy_kj_100g",
  "fat_100g",
  "saturated_fat_100g",
  "carbohydrates_100g",
  "sugars_100g",
  "fiber_100g",
  "protein_100g",
  "salt_100g",
  "sodium_100g",
]);

function matchesFilter(candidate: ProductFinderCandidate, filter: FilterValue) {
  switch (filter) {
    case "needs_review":
      return candidate.status === "needs_review";
    case "approved":
      return candidate.status === "approved" || candidate.status === "export_ready";
    case "rejected":
      return candidate.status === "rejected";
    case "ingredients_missing":
      return candidate.issue_list.some((item) => item.code === "ingredients_missing");
    case "nutrition_missing":
      return candidate.issue_list.some(
        (item) =>
          item.code === "nutrition_missing" ||
          item.code === "nutrition_basis_missing",
      );
    case "export_ready":
      return candidate.approved_for_export;
    default:
      return true;
  }
}

function getApprovalError(candidate: ProductFinderCandidate) {
  if (!/^\d{8,14}$/.test(candidate.barcode)) {
    return "Geçerli barkod olmadan onay verilemez.";
  }

  if (!candidate.product_name.trim()) {
    return "Ürün adı eksik.";
  }

  if (!candidate.ingredients.trim()) {
    return "İçindekiler eksik.";
  }

  if (!candidate.data_source.trim()) {
    return "Veri kaynağı eksik.";
  }

  if (!candidate.data_updated_at.trim()) {
    return "Veri tarihi eksik.";
  }

  return null;
}

function candidateToDraftValues(candidate: ProductFinderCandidate) {
  return Object.fromEntries(
    editableFields.map((field) => [String(field), String(candidate[field] ?? "")]),
  ) as Record<string, string>;
}

function mergeCandidatesByBarcode(
  barcodes: string[],
  uploadedFileData: ParsedProductFinderUpload | null,
) {
  const hydratedRows =
    uploadedFileData?.mode === "full_template" ? uploadedFileData.rows : [];

  const hydratedMap = new Map(
    hydratedRows.map((row) => [String(row.barcode), row] as const),
  );

  return barcodes.map((barcode) => {
    const hydratedRow = hydratedMap.get(barcode);
    return hydratedRow
      ? createHydratedCandidateFromImportRow(hydratedRow)
      : createMockCandidate(barcode);
  });
}

export function AdminProductFinderClient() {
  const [barcodeInput, setBarcodeInput] = useState("");
  const [urlInput, setUrlInput] = useState("");
  const [uploadedFileName, setUploadedFileName] = useState("");
  const [uploadedFileData, setUploadedFileData] = useState<ParsedProductFinderUpload | null>(null);
  const [candidates, setCandidates] = useState<ProductFinderCandidate[]>([]);
  const [error, setError] = useState("");
  const [filter, setFilter] = useState<FilterValue>("all");
  const [editingId, setEditingId] = useState<string | null>(null);
  const [rejectionReason, setRejectionReason] = useState<Record<string, string>>({});
  const [draftCandidate, setDraftCandidate] = useState<ProductFinderCandidate | null>(null);
  const [draftValues, setDraftValues] = useState<Record<string, string>>({});
  const [draftError, setDraftError] = useState("");
  const [migrosUrl, setMigrosUrl] = useState("");
  const [migrosLoading, setMigrosLoading] = useState(false);
  const [migrosError, setMigrosError] = useState("");
  const [migrosPreview, setMigrosPreview] = useState<SourceCandidate | null>(null);
  const [identityLoading, setIdentityLoading] = useState(false);
  const [marketLoading, setMarketLoading] = useState(false);
  const [urlLoading, setUrlLoading] = useState(false);
  const [urlError, setUrlError] = useState("");

  const editingCandidate =
    candidates.find((candidate) => candidate.id === editingId) ?? null;

  const summary = useMemo(() => summarizeCandidates(candidates), [candidates]);
  const textareaStats = useMemo(
    () => finalizeParsedBarcodes(parseBarcodeTextarea(barcodeInput)),
    [barcodeInput],
  );
  const urlStats = useMemo(() => parseProductUrlTextarea(urlInput), [urlInput]);
  const filteredCandidates = useMemo(
    () => candidates.filter((candidate) => matchesFilter(candidate, filter)),
    [candidates, filter],
  );

  async function handleFileUpload(file: File | null) {
    if (!file) return;

    try {
      let parsed: ParsedProductFinderUpload;
      const lowerName = file.name.toLowerCase();

      if (lowerName.endsWith(".xlsx")) {
        const xlsx = await import("xlsx");
        const buffer = await file.arrayBuffer();
        const workbook = xlsx.read(buffer, { type: "array" });
        const firstSheetName = workbook.SheetNames[0];
        const firstSheet = firstSheetName ? workbook.Sheets[firstSheetName] : null;

        if (!firstSheet) {
          throw new Error("XLSX_EMPTY");
        }

        const rows = xlsx.utils.sheet_to_json(firstSheet, {
          header: 1,
          raw: false,
          defval: "",
        }) as unknown[][];

        parsed = parseProductFinderRows(rows);
      } else {
        const content = await file.text();
        parsed = parseProductFinderCsv(content);
      }

      setUploadedFileName(file.name);
      setUploadedFileData(parsed);
      setError("");
    } catch {
      setError("Dosya okunamadı. CSV veya XLSX dosyası deneyin.");
    }
  }

  function clearUploadedFile() {
    setUploadedFileName("");
    setUploadedFileData(null);
  }

  function handleCreateCandidates() {
    const mergedBarcodes = [
      ...parseBarcodeTextarea(barcodeInput),
      ...(uploadedFileData?.barcodes ?? []),
    ];

    const batch = validateBarcodeBatch(mergedBarcodes);
    if (!batch.ok) {
      setError(batch.error);
      return;
    }

    const nextCandidates = mergeCandidatesByBarcode(batch.normalized, uploadedFileData);
    setCandidates(nextCandidates);
    setError("");
  }

  async function handleMockResolve() {
    const barcodeOnlyCandidates = candidates.filter(isEligibleForMockResolution);

    if (barcodeOnlyCandidates.length === 0) {
      setError("Mock kaynaklarla doldurulacak eksik barkod adayı bulunamadı.");
      return;
    }

    const resolved = await Promise.all(
      barcodeOnlyCandidates.map(async (candidate) => {
        const resolution = await resolveProductFinderCandidate(
          { barcode: candidate.barcode },
          [mockBarcodeIdentityProvider],
          [mockProductDetailProvider],
        );
        return resolutionToProductFinderCandidate(resolution);
      }),
    );

    const resolvedMap = new Map(resolved.map((candidate) => [candidate.barcode, candidate]));
    setCandidates((current) =>
      current.map((candidate) => resolvedMap.get(candidate.barcode) ?? candidate),
    );
    setError("");
  }

  async function handleIdentityResolve() {
    const targetCandidates = candidates.filter(isEligibleForIdentityResolution);

    if (targetCandidates.length === 0) {
      setError("Kimlik doldurulacak barkod adayı bulunamadı.");
      return;
    }

    setIdentityLoading(true);
    setError("");

    try {
      const response = await fetch("/api/admin/product-finder/identity/resolve", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          barcodes: targetCandidates.map((candidate) => candidate.barcode),
        }),
      });

      const payload = (await response.json()) as {
        error?: string;
        results?: IdentityApiResult[];
      };

      if (response.status === 401 || response.status === 403) {
        setError("Yetki kontrolü başarısız, sayfayı yenileyin veya tekrar giriş yapın.");
        return;
      }

      if (!response.ok || !payload.results) {
        setError(payload.error || "Barkod kimliği çözümlenemedi.");
        return;
      }

      const resultMap = new Map(payload.results.map((item) => [item.barcode, item]));
      setCandidates((current) =>
        current.map((candidate) => {
          const result = resultMap.get(candidate.barcode);
          if (!result) return candidate;
          const updated = applyIdentityResultToCandidate(candidate, result);
          const sourceAttemptNote = result.source_attempts?.find(
            (attempt) => attempt.providerId === "web-search-identity" && attempt.message,
          )?.message;

          if (!sourceAttemptNote) {
            return updated;
          }

          const existing = updated.verification_notes.trim();
          return updateCandidateField(
            updated,
            "verification_notes",
            existing ? `${existing}\n${sourceAttemptNote}` : sourceAttemptNote,
          );
        }),
      );
    } catch {
      setError("Barkod kimliği çözümlenemedi.");
    } finally {
      setIdentityLoading(false);
    }
  }

  async function handleMigrosResolve() {
    const url = migrosUrl.trim();
    if (!url) {
      setMigrosError("Geçerli bir Migros ürün URL’si gir.");
      setMigrosPreview(null);
      return;
    }

    setMigrosLoading(true);
    setMigrosError("");
    setMigrosPreview(null);

    try {
      const response = await fetch("/api/admin/product-finder/migros/parse-url", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url }),
      });

      const payload = (await response.json()) as {
        error?: string;
        candidate?: SourceCandidate;
      };

      if (response.status === 401 || response.status === 403) {
        setMigrosError("Yetki kontrolü başarısız, sayfayı yenileyin veya tekrar giriş yapın.");
        return;
      }

      if (!response.ok || !payload.candidate) {
        setMigrosError(payload.error || "Migros URL çözümlenemedi.");
        return;
      }

      setMigrosPreview(payload.candidate);
    } catch {
      setMigrosError("Migros URL çözümlenemedi.");
    } finally {
      setMigrosLoading(false);
    }
  }

  function handleAddMigrosCandidate() {
    if (!migrosPreview) return;
    const mapped = mapSourceCandidateToProductFinderCandidate(migrosPreview);

    setCandidates((current) => {
      const existingIndex = current.findIndex(
        (candidate) =>
          candidate.barcode &&
          mapped.barcode &&
          candidate.barcode === mapped.barcode,
      );

      if (existingIndex >= 0) {
        const next = [...current];
        next[existingIndex] = mapped;
        return next;
      }

      return [...current, mapped];
    });
  }

  function handleApplyMigrosSuggestions() {
    if (!migrosPreview) return;
    setMigrosPreview(applyMigrosSuggestions(migrosPreview));
  }

  async function handleMarketResolve() {
    const targetCandidates = candidates.filter(isEligibleForMarketResolution);

    if (targetCandidates.length === 0) {
      setError("Migros ile tamamlanacak uygun aday bulunamadı.");
      return;
    }

    setMarketLoading(true);
    setError("");

    try {
      const response = await fetch("/api/admin/product-finder/market/resolve", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          candidates: targetCandidates.map((candidate) => ({
            id: candidate.id,
            barcode: candidate.barcode,
            brand: candidate.brand,
            product_name: candidate.product_name,
            quantity_value: candidate.quantity_value,
            quantity_unit: candidate.quantity_unit,
          })),
        }),
      });

      const payload = (await response.json()) as {
        error?: string;
        results?: MarketApiResult[];
      };

      if (response.status === 401 || response.status === 403) {
        setError("Yetki kontrolü başarısız, sayfayı yenileyin veya tekrar giriş yapın.");
        return;
      }

      if (!response.ok || !payload.results) {
        setError(
          payload.error ||
            "Migros arama sayfası koruma nedeniyle otomatik tamamlanamadı. URL ile ürün ekleme akışını kullanın.",
        );
        return;
      }

      const resultMap = new Map(payload.results.map((item) => [item.candidate_id, item]));
      setCandidates((current) =>
        current.map((candidate) => {
          const result = resultMap.get(candidate.id);
          if (!result) return candidate;

          if (result.status === "enriched" && result.parsed_candidate) {
            return mergeMarketCandidate(candidate, applyMigrosSuggestions(result.parsed_candidate), result);
          }

          if (result.note) {
            const existing = candidate.verification_notes.trim();
            return updateCandidateField(
              candidate,
              "verification_notes",
              existing ? `${existing}\n${result.note}` : result.note,
            );
          }

          return candidate;
        }),
      );
    } catch {
      setError("Migros arama sayfası koruma nedeniyle otomatik tamamlanamadı. URL ile ürün ekleme akışını kullanın.");
    } finally {
      setMarketLoading(false);
    }
  }

  async function handleUrlResolve() {
    if (urlStats.urls.length === 0) {
      setUrlError("En az bir desteklenen ürün linki gir.");
      return;
    }

    setUrlLoading(true);
    setUrlError("");
    setError("");

    try {
      const response = await fetch("/api/admin/product-finder/urls/parse", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          urls: urlStats.urls.map((item) => item.url),
        }),
      });

      const payload = (await response.json()) as {
        error?: string;
        results?: UrlParseApiResult[];
      };

      if (response.status === 401 || response.status === 403) {
        setUrlError("Yetki kontrolü başarısız, sayfayı yenileyin veya tekrar giriş yapın.");
        return;
      }

      if (!response.ok || !payload.results) {
        setUrlError(payload.error || "Ürün linkleri çözümlenemedi.");
        return;
      }

      const mappedCandidates = payload.results
        .filter((item) => item.status === "parsed" && item.candidate)
        .map((item, index) =>
          mapSourceCandidateToProductFinderCandidate(item.candidate!, {
            candidateId: buildUrlCandidateId(item.url, index),
          }),
        );

      setCandidates((current) => [...mappedCandidates, ...current]);
    } catch {
      setUrlError("Ürün linkleri çözümlenemedi.");
    } finally {
      setUrlLoading(false);
    }
  }

  function setCandidate(next: ProductFinderCandidate) {
    setCandidates((current) =>
      current.map((candidate) => (candidate.id === next.id ? next : candidate)),
    );
  }

  function handleApprove(candidate: ProductFinderCandidate) {
    const approvalError = getApprovalError(candidate);
    if (approvalError) {
      setError(approvalError);
      return;
    }

    setCandidate(approveCandidate(candidate));
    setError("");
  }

  function handleReject(candidate: ProductFinderCandidate) {
    setCandidate(rejectCandidate(candidate, rejectionReason[candidate.id] ?? ""));
  }

  function openEditor(candidate: ProductFinderCandidate) {
    setDraftCandidate({ ...candidate });
    setDraftValues(candidateToDraftValues(candidate));
    setDraftError("");
    setEditingId(candidate.id);
  }

  function updateDraftValue(field: keyof ProductFinderCandidate, value: string) {
    setDraftValues((current) => ({ ...current, [String(field)]: value }));
    setDraftError("");
  }

  function handleSaveDraft() {
    if (!draftCandidate) return;

    let nextCandidate = { ...draftCandidate };

    for (const field of editableFields) {
      const value = draftValues[String(field)] ?? "";

      if (decimalFields.has(field)) {
        const normalized = value.replace(",", ".").trim();
        if (normalized && Number.isNaN(Number(normalized))) {
          setDraftError(`${field} alanı için geçerli bir sayı girin.`);
          return;
        }
      }

      nextCandidate = updateCandidateField(nextCandidate, field, value);
    }

    setCandidate(nextCandidate);
    setDraftCandidate(null);
    setDraftValues({});
    setDraftError("");
    setEditingId(null);
  }

  async function handleExportXlsx() {
    const exportRows = candidates.filter((item) => item.approved_for_export);
    if (exportRows.length === 0) {
      setError("XLSX dışa aktarmak için en az bir onaylı satır gerekli.");
      return;
    }

    const xlsx = await import("xlsx");
    const worksheet = xlsx.utils.aoa_to_sheet(buildExportMatrix(exportRows));
    const workbook = xlsx.utils.book_new();
    xlsx.utils.book_append_sheet(workbook, worksheet, "ProductFinder");
    xlsx.writeFile(workbook, "labelwise-product-finder-approved.xlsx");
  }

  return (
    <div className="space-y-8">
      <div className="card p-6 sm:p-8">
        <div className="mb-8 rounded-[1.5rem] border border-emerald-300/12 bg-emerald-200/[0.05] p-5 sm:p-6">
          <div className="flex flex-col gap-6 lg:grid lg:grid-cols-[1.2fr_0.8fr]">
            <div className="space-y-3">
              <div>
                <h3 className="text-xl font-semibold text-white">Ürün linkleriyle ekle</h3>
                <p className="mt-2 text-sm leading-7 text-[color:var(--text-muted)]">
                  Bu sprintte ana akış Migros ürün detay linkleri. Her satıra bir ürün linki yapıştır, sistem doğrudan ürün detayını çözümlemeye çalışsın. Barkod alanı şimdilik boş kalır ve satır review modunda başlar.
                </p>
              </div>

              <label className="flex flex-col gap-2 text-sm text-[color:var(--text-muted)]">
                <span className="text-white">Ürün detay URL’leri</span>
                <textarea
                  value={urlInput}
                  onChange={(event) => setUrlInput(event.target.value)}
                  placeholder={"https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927\nhttps://www.migros.com.tr/..."}
                  className="min-h-44 rounded-[1.5rem] border border-white/10 bg-white/5 px-4 py-4 text-white outline-none placeholder:text-white/35"
                />
                <span>Şimdilik yalnızca açık Migros ürün detay linkleri desteklenir. Arama veya kategori linkleri işlenmez.</span>
              </label>

              <div className="flex flex-wrap gap-3">
                <button
                  type="button"
                  className="button-primary min-h-11 px-5 disabled:cursor-not-allowed disabled:opacity-60"
                  onClick={() => void handleUrlResolve()}
                  disabled={urlLoading}
                >
                  {urlLoading ? "Linkler çözümleniyor..." : "Linkleri çözümle"}
                </button>
              </div>

              {urlError ? (
                <div className="rounded-2xl border border-amber-300/20 bg-amber-200/10 px-4 py-3 text-sm text-[color:var(--gold-soft)]">
                  {urlError}
                </div>
              ) : null}
            </div>

            <div className="rounded-[1.5rem] border border-white/8 bg-white/[0.03] p-5">
              <div className="text-xs uppercase tracking-[0.18em] text-[color:var(--text-soft)]">
                Link özeti
              </div>
              <div className="mt-4 grid gap-3 sm:grid-cols-2">
                {[
                  ["Toplam satır", urlStats.rawCount],
                  ["Desteklenen link", urlStats.parsedCount],
                  ["Silinen tekrar", urlStats.duplicatesRemoved],
                  ["Desteklenmeyen", urlStats.unsupportedCount],
                  ["Geçersiz", urlStats.invalidCount],
                ].map(([label, value]) => (
                  <div key={String(label)} className="rounded-2xl border border-white/8 bg-black/10 p-4">
                    <div className="text-xs uppercase tracking-[0.16em] text-[color:var(--text-soft)]">
                      {label}
                    </div>
                    <div className="mt-2 text-2xl font-semibold text-white">{String(value)}</div>
                  </div>
                ))}
              </div>
              <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
                Barkod keşfi ayrı bir sonraki adım olacak. Buradaki amaç önce ürün detayını güvenli biçimde içeri almak.
              </p>
            </div>
          </div>
        </div>

        <h2 className="text-2xl font-semibold text-white">Ürün Bulucu</h2>
        <p className="mt-3 max-w-3xl text-sm leading-7 text-[color:var(--text-muted)]">
          Barkodlardan ürün adayları oluştur, eksik alanları düzenle ve mevcut ürün içe aktarma formatıyla uyumlu XLSX çıktısı al.
        </p>

        <div className="mt-6 grid gap-6 lg:grid-cols-[1.15fr_0.85fr]">
          <div className="space-y-3">
            <label className="flex flex-col gap-2 text-sm text-[color:var(--text-muted)]">
              <span className="text-white">Barkodları alt alta yapıştır</span>
              <textarea
                value={barcodeInput}
                onChange={(event) => setBarcodeInput(event.target.value)}
                placeholder={"8690504030012\n5000112664478"}
                className="min-h-56 rounded-[1.5rem] border border-white/10 bg-white/5 px-4 py-4 text-white outline-none placeholder:text-white/35"
              />
              <span>En fazla 100 barkod. EAN-8, EAN-13 veya UPC formatı desteklenir.</span>
            </label>
          </div>

          <div className="rounded-[1.5rem] border border-white/8 bg-white/[0.03] p-5">
            <h3 className="text-base font-semibold text-white">CSV veya XLSX yükle</h3>
            <p className="mt-2 text-sm leading-7 text-[color:var(--text-muted)]">
              barcode/barkod kolonu varsa okunur. 31 kolonluk ürün import dosyası yüklersen alanlar otomatik doldurulur.
            </p>
            <label className="mt-5 flex min-h-32 cursor-pointer flex-col items-center justify-center rounded-[1.4rem] border border-dashed border-white/12 bg-white/[0.03] px-4 py-5 text-center">
              <span className="text-sm text-white">{uploadedFileName || "CSV / XLSX seç"}</span>
              <input
                type="file"
                accept=".csv,.xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,text/csv"
                className="sr-only"
                onChange={(event) => void handleFileUpload(event.target.files?.[0] ?? null)}
              />
            </label>

            {uploadedFileData ? (
              <div className="mt-4 rounded-2xl border border-white/8 bg-white/[0.03] p-4 text-sm text-[color:var(--text-muted)]">
                <div className="text-white">{uploadedFileName}</div>
                <div className="mt-2 text-xs uppercase tracking-[0.18em] text-[color:var(--text-soft)]">
                  {uploadedFileData.mode === "full_template"
                    ? "31 kolonluk ürün dosyası algılandı"
                    : "Barkod odaklı dosya algılandı"}
                </div>
                <div className="mt-3 grid gap-2 sm:grid-cols-2">
                  <div>Parsed satır: {uploadedFileData.rawCount}</div>
                  <div>Tekil barkod: {uploadedFileData.parsedCount}</div>
                  <div>Geçersiz: {uploadedFileData.invalidCount}</div>
                  <div>Silinen tekrar: {uploadedFileData.duplicatesRemoved}</div>
                </div>
                <button
                  type="button"
                  className="button-secondary mt-4 min-h-10 px-4"
                  onClick={clearUploadedFile}
                >
                  Dosyayı temizle
                </button>
              </div>
            ) : null}

            <button
              type="button"
              className="button-primary mt-5 min-h-11 w-full"
              onClick={handleCreateCandidates}
            >
              Adayları oluştur
            </button>
          </div>
        </div>

        {error ? (
          <div className="mt-5 rounded-2xl border border-amber-300/20 bg-amber-200/10 px-4 py-3 text-sm text-[color:var(--gold-soft)]">
            {error}
          </div>
        ) : null}
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {[
          ["Toplam parsed satır", textareaStats.rawCount + (uploadedFileData?.rawCount ?? 0)],
          ["Tekil barkod", textareaStats.parsedCount + (uploadedFileData?.parsedCount ?? 0)],
          ["Geçerli barkod", summary.total - summary.invalid],
          ["Geçersiz barkod", summary.invalid],
          ["Onaylanan", summary.approved],
          ["İnceleme gereken", summary.needsReview],
          ["Reddedilen", summary.rejected],
          ["Export’a hazır", summary.exportReady],
          [
            "Silinen tekrar",
            textareaStats.duplicatesRemoved + (uploadedFileData?.duplicatesRemoved ?? 0),
          ],
        ].map(([label, value]) => (
          <div key={label} className="card p-5">
            <div className="text-xs uppercase tracking-[0.2em] text-[color:var(--text-soft)]">
              {label}
            </div>
            <div className="mt-3 text-3xl font-semibold text-white">{value}</div>
          </div>
        ))}
      </div>

      <div className="card p-6">
        <div className="flex flex-col gap-4">
          <div>
            <h2 className="text-2xl font-semibold text-white">Migros URL ile test et</h2>
            <p className="mt-2 text-sm leading-7 text-[color:var(--text-muted)]">
              Tek bir Migros ürün linki girerek içerik, besin değeri, görsel ve kaynak alanlarının ayrıştırmasını test edebilirsin.
            </p>
          </div>

          <label className="flex flex-col gap-2 text-sm text-[color:var(--text-muted)]">
            <span className="text-white">Migros ürün URL’si</span>
            <input
              type="url"
              value={migrosUrl}
              onChange={(event) => setMigrosUrl(event.target.value)}
              placeholder="https://www.migros.com.tr/..."
              className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none placeholder:text-white/35"
            />
          </label>

          <div className="flex flex-wrap gap-3">
            <button
              type="button"
              onClick={() => void handleMigrosResolve()}
              disabled={migrosLoading}
              className="button-primary min-h-11 px-5 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {migrosLoading ? "Çözümleniyor..." : "Migros URL çözümle"}
            </button>

            {migrosPreview ? (
              <button
                type="button"
                onClick={handleAddMigrosCandidate}
                className="button-secondary min-h-11 px-5"
              >
                Aday listesine ekle
              </button>
            ) : null}
          </div>

          {migrosError ? (
            <div className="rounded-2xl border border-amber-300/20 bg-amber-200/10 px-4 py-3 text-sm text-[color:var(--gold-soft)]">
              {migrosError}
            </div>
          ) : null}

          {migrosPreview ? (
            <div className="rounded-[1.5rem] border border-white/8 bg-white/[0.03] p-5">
              {(() => {
                const suggestionPayload = getSourceSuggestionPayload(migrosPreview);
                const hasSuggestions =
                  Boolean(suggestionPayload.nutrition_basis_suggestion) ||
                  Boolean(suggestionPayload.category_suggestion);

                if (!hasSuggestions) return null;

                return (
                  <div className="mb-4 rounded-2xl border border-emerald-300/15 bg-emerald-200/10 p-4">
                    <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
                      <div className="space-y-2 text-sm text-[color:var(--text-muted)]">
                        <div className="text-xs uppercase tracking-[0.16em] text-[color:var(--text-soft)]">
                          Akıllı öneriler
                        </div>
                        {suggestionPayload.nutrition_basis_suggestion ? (
                          <p>
                            <span className="text-white">Besin bazı önerisi:</span>{" "}
                            {suggestionPayload.nutrition_basis_suggestion}
                            {suggestionPayload.nutrition_basis_suggestion_reason
                              ? ` — ${suggestionPayload.nutrition_basis_suggestion_reason}`
                              : ""}
                          </p>
                        ) : null}
                        {suggestionPayload.category_suggestion ? (
                          <p>
                            <span className="text-white">Kategori önerisi:</span>{" "}
                            {suggestionPayload.category_suggestion}
                            {suggestionPayload.category_suggestion_reason
                              ? ` — ${suggestionPayload.category_suggestion_reason}`
                              : ""}
                            {suggestionPayload.category_suggestion_confidence
                              ? ` (${suggestionPayload.category_suggestion_confidence})`
                              : ""}
                          </p>
                        ) : null}
                      </div>

                      <button
                        type="button"
                        onClick={handleApplyMigrosSuggestions}
                        className="button-secondary min-h-10 px-4"
                      >
                        Önerilen alanları uygula
                      </button>
                    </div>
                  </div>
                );
              })()}

              <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                {[
                  ["product_name", migrosPreview.product_name || "—"],
                  ["brand", migrosPreview.brand || "—"],
                  [
                    "quantity",
                    migrosPreview.quantity_display ||
                      (migrosPreview.quantity_value != null && migrosPreview.quantity_unit
                        ? `${migrosPreview.quantity_value} ${migrosPreview.quantity_unit}`
                        : "—"),
                  ],
                  ["category", migrosPreview.category || "—"],
                  ["ingredients", migrosPreview.ingredients || "—"],
                  ["nutrition_basis", migrosPreview.nutrition_basis || "—"],
                  ["energy_kcal_100g", migrosPreview.energy_kcal_100g ?? "—"],
                  ["fat_100g", migrosPreview.fat_100g ?? "—"],
                  ["saturated_fat_100g", migrosPreview.saturated_fat_100g ?? "—"],
                  ["carbohydrates_100g", migrosPreview.carbohydrates_100g ?? "—"],
                  ["sugars_100g", migrosPreview.sugars_100g ?? "—"],
                  ["fiber_100g", migrosPreview.fiber_100g ?? "—"],
                  ["protein_100g", migrosPreview.protein_100g ?? "—"],
                  ["salt_100g", migrosPreview.salt_100g ?? "—"],
                  ["sodium_100g", migrosPreview.sodium_100g ?? "—"],
                  ["image_front_url", migrosPreview.image_front_url || "—"],
                  ["source_url", migrosPreview.source_url || "—"],
                  ["source_product_id", migrosPreview.source_product_id || "—"],
                ].map(([label, value]) => (
                  <div key={String(label)} className="rounded-2xl border border-white/8 bg-black/10 p-4">
                    <div className="text-xs uppercase tracking-[0.16em] text-[color:var(--text-soft)]">
                      {label}
                    </div>
                    <div className="mt-2 break-words text-sm text-white/88">{String(value)}</div>
                  </div>
                ))}
              </div>

              <div className="mt-4 rounded-2xl border border-white/8 bg-black/10 p-4">
                <div className="text-xs uppercase tracking-[0.16em] text-[color:var(--text-soft)]">
                  Görsel önizleme
                </div>
                <div className="mt-3 flex items-center gap-4">
                  <RemoteImagePreview
                    src={migrosPreview.image_front_url}
                    alt={migrosPreview.product_name || "Ürün görseli"}
                    size={88}
                    compactLabel="Görsel yok"
                    failedLabel="Görsel yüklenemedi"
                  />
                  <div className="text-sm text-[color:var(--text-muted)]">
                    {migrosPreview.image_front_url ? (
                      <span className="break-all">{migrosPreview.image_front_url}</span>
                    ) : (
                      "Image URL bulunamadı."
                    )}
                  </div>
                </div>
              </div>

              <div className="mt-4">
                <div className="text-xs uppercase tracking-[0.16em] text-[color:var(--text-soft)]">
                  issue_list
                </div>
                <div className="mt-3 flex flex-wrap gap-2">
                  {migrosPreview.issue_list.length > 0 ? (
                    migrosPreview.issue_list.map((issue) => (
                      <span
                        key={`${issue.code}-${issue.message}`}
                        className="rounded-full border border-white/10 bg-white/6 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-white/82"
                      >
                        {issue.code}
                      </span>
                    ))
                  ) : (
                    <span className="text-sm text-[color:var(--text-muted)]">Issue yok</span>
                  )}
                </div>
              </div>
            </div>
          ) : null}
        </div>
      </div>

      <div className="card p-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <h2 className="text-2xl font-semibold text-white">Review tablosu</h2>
            <p className="mt-2 text-sm leading-7 text-[color:var(--text-muted)]">
              Barkod-only dosyalarda mock aday oluşur. 31 kolonluk import dosyalarında alanlar otomatik hydrate edilir.
            </p>
          </div>

          <div className="flex flex-wrap gap-3">
            <select
              value={filter}
              onChange={(event) => setFilter(event.target.value as FilterValue)}
              className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white outline-none"
            >
              {filters.map(([value, label]) => (
                <option key={value} value={value} className="bg-[#10241d]">
                  {label}
                </option>
              ))}
            </select>

            <button
              type="button"
              onClick={() => void handleIdentityResolve()}
              className="button-secondary min-h-11 px-5 disabled:cursor-not-allowed disabled:opacity-60"
              disabled={identityLoading}
            >
              {identityLoading ? "Kimlik bulunuyor..." : "Barkod kimliğini bul"}
            </button>

            <button
              type="button"
              onClick={() => void handleMarketResolve()}
              className="button-secondary min-h-11 px-5 disabled:cursor-not-allowed disabled:opacity-60"
              disabled={marketLoading}
              title="Deneysel akış. Arama sonucu koruma veya oturum sorunlarında başarısız olabilir."
            >
              {marketLoading ? "Migros aranıyor..." : "Deneysel: Migros arama ile tamamla"}
            </button>

            <button
              type="button"
              onClick={() => void handleMockResolve()}
              className="button-secondary min-h-11 px-5"
            >
              Mock kaynaklarla doldur
            </button>

            <button
              type="button"
              onClick={() => void handleExportXlsx()}
              className="button-secondary min-h-11 px-5"
            >
              Onaylananları XLSX indir
            </button>
          </div>
        </div>

        <div className="mt-6 overflow-x-auto rounded-2xl">
          <table className="min-w-[1120px] text-left">
            <thead className="bg-white/[0.03] text-xs uppercase tracking-[0.24em] text-[color:var(--text-soft)]">
              <tr>
                <th className="px-5 py-4">Durum</th>
                <th className="px-4 py-4">Barkod</th>
                <th className="px-4 py-4">Marka</th>
                <th className="px-4 py-4">Ürün adı</th>
                <th className="px-4 py-4">Miktar</th>
                <th className="px-4 py-4">Kaynak</th>
                <th className="px-4 py-4">Kalite</th>
                <th className="px-4 py-4">Issue</th>
                <th className="px-4 py-4">Verified</th>
                <th className="px-4 py-4">Aksiyonlar</th>
              </tr>
            </thead>
            <tbody>
              {filteredCandidates.map((candidate) => (
                <tr key={candidate.id} className="border-t border-white/8 align-top">
                  <td className="px-5 py-4 text-sm text-white/82">{candidate.status}</td>
                  <td className="px-4 py-4 text-sm text-white">{candidate.barcode}</td>
                  <td className="px-4 py-4 text-sm text-[color:var(--text-muted)]">
                    {candidate.brand || "—"}
                  </td>
                  <td className="px-4 py-4 text-sm text-white">
                    {candidate.product_name || "Ürün adı bekleniyor"}
                  </td>
                  <td className="px-4 py-4 text-sm text-[color:var(--text-muted)]">
                    {candidate.quantity_value != null && candidate.quantity_unit
                      ? `${candidate.quantity_value} ${candidate.quantity_unit}`
                      : "—"}
                  </td>
                  <td className="px-4 py-4 text-sm text-[color:var(--text-muted)]">
                    <div className="space-y-1">
                      <div>{candidate.data_source || "—"}</div>
                      {candidate.verification_notes.includes("identity_source:") ? (
                        <div className="text-xs uppercase tracking-[0.14em] text-[color:var(--text-soft)]">
                          {candidate.verification_notes
                            .split("\n")
                            .find((line) => line.startsWith("identity_source:"))
                            ?.replace("identity_source:", "") || ""}
                        </div>
                      ) : null}
                    </div>
                  </td>
                  <td className="px-4 py-4 text-sm text-[color:var(--text-muted)]">
                    {candidate.data_quality_status}
                  </td>
                  <td className="px-4 py-4">
                    <div className="flex max-w-xs flex-wrap gap-2">
                      {candidate.issue_list.map((issue) => (
                        <span
                          key={`${candidate.id}-${issue.code}`}
                          className="rounded-full border border-white/10 bg-white/6 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-white/82"
                        >
                          {issue.code}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="px-4 py-4 text-sm text-[color:var(--text-muted)]">
                    {candidate.is_verified ? "true" : "false"}
                  </td>
                  <td className="px-4 py-4">
                    <div className="flex flex-col gap-2">
                      <button
                        type="button"
                        className="button-secondary min-h-10 px-4"
                        onClick={() => openEditor(candidate)}
                      >
                        Düzenle
                      </button>
                      <button
                        type="button"
                        className="button-secondary min-h-10 px-4 disabled:cursor-not-allowed disabled:opacity-50"
                        onClick={() => handleApprove(candidate)}
                        disabled={candidate.issue_list.some((item) => item.code === "invalid_barcode")}
                        title={
                          candidate.issue_list.some((item) => item.code === "invalid_barcode")
                            ? "Geçersiz barkod düzeltilmeden onaylanamaz."
                            : undefined
                        }
                      >
                        Onayla
                      </button>
                      {candidate.issue_list.some((item) => item.code === "invalid_barcode") ? (
                        <p className="text-xs leading-5 text-[color:var(--gold-soft)]">
                          Geçersiz barkod düzeltilmeden onaylanamaz.
                        </p>
                      ) : null}
                      <input
                        value={rejectionReason[candidate.id] ?? ""}
                        onChange={(event) =>
                          setRejectionReason((current) => ({
                            ...current,
                            [candidate.id]: event.target.value,
                          }))
                        }
                        placeholder="Ret nedeni"
                        className="rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-white outline-none placeholder:text-white/35"
                      />
                      <button
                        type="button"
                        className="button-secondary min-h-10 px-4"
                        onClick={() => handleReject(candidate)}
                      >
                        Reddet
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {editingCandidate && draftCandidate ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
          <div className="card max-h-[92vh] w-full max-w-5xl overflow-y-auto p-6">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h3 className="text-2xl font-semibold text-white">Satırı düzenle</h3>
                <p className="mt-2 text-sm text-[color:var(--text-muted)]">
                  Virgül veya noktalı ondalık değerler kayıtta normalize edilir.
                </p>
              </div>
              <button
                type="button"
                className="button-secondary min-h-10 px-4"
                onClick={() => {
                  setDraftCandidate(null);
                  setDraftValues({});
                  setDraftError("");
                  setEditingId(null);
                }}
              >
                Kapat
              </button>
            </div>

            <div className="mt-6 grid gap-4 md:grid-cols-2">
              {editableFields.map((field) => (
                <label
                  key={field}
                  className="flex flex-col gap-2 text-sm text-[color:var(--text-muted)]"
                >
                  <span className="text-white">{field}</span>
                  {field === "is_current" || field === "is_verified" ? (
                    <select
                      value={draftValues[String(field)] ?? ""}
                      onChange={(event) => updateDraftValue(field, event.target.value)}
                      className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none"
                    >
                      <option value="true" className="bg-[#10241d]">
                        true
                      </option>
                      <option value="false" className="bg-[#10241d]">
                        false
                      </option>
                    </select>
                  ) : (
                    <input
                      type="text"
                      inputMode={decimalFields.has(field) ? "decimal" : undefined}
                      value={draftValues[String(field)] ?? ""}
                      onChange={(event) => updateDraftValue(field, event.target.value)}
                      className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none placeholder:text-white/35"
                    />
                  )}
                </label>
              ))}
            </div>

            <div className="mt-6 grid gap-4 lg:grid-cols-2">
              <div className="rounded-2xl border border-white/8 bg-white/[0.03] p-4">
                <h4 className="text-sm font-semibold uppercase tracking-[0.16em] text-[color:var(--text-soft)]">
                  Salt okunur alanlar
                </h4>
                <dl className="mt-4 space-y-3 text-sm text-[color:var(--text-muted)]">
                  <div>
                    <dt className="text-white">data_quality_status</dt>
                    <dd>{draftCandidate.data_quality_status}</dd>
                  </div>
                  <div>
                    <dt className="text-white">ingredients_status</dt>
                    <dd>{draftCandidate.ingredients_status}</dd>
                  </div>
                  <div>
                    <dt className="mb-2 text-white">nutrition_basis (iç kontrol)</dt>
                    <dd>
                      <select
                        value={draftCandidate.nutrition_basis ?? ""}
                        onChange={(event) =>
                          setDraftCandidate(
                            updateCandidateField(
                              draftCandidate,
                              "nutrition_basis",
                              event.target.value || null,
                            ),
                          )
                        }
                        className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none"
                      >
                        <option value="" className="bg-[#10241d]">
                          Seçilmedi
                        </option>
                        <option value="100g" className="bg-[#10241d]">
                          100g
                        </option>
                        <option value="100ml" className="bg-[#10241d]">
                          100ml
                        </option>
                      </select>
                    </dd>
                  </div>
                  <div>
                    <dt className="text-white">approved_for_export</dt>
                    <dd>{draftCandidate.approved_for_export ? "true" : "false"}</dd>
                  </div>
                  <div>
                    <dt className="text-white">edited_fields</dt>
                    <dd>{draftCandidate.edited_fields.join(", ") || "—"}</dd>
                  </div>
                </dl>
              </div>

              <div className="rounded-2xl border border-white/8 bg-white/[0.03] p-4">
                <h4 className="text-sm font-semibold uppercase tracking-[0.16em] text-[color:var(--text-soft)]">
                  issue_list
                </h4>
                <div className="mt-4 flex flex-wrap gap-2">
                  {draftCandidate.issue_list.map((issue) => (
                    <span
                      key={`${draftCandidate.id}-${issue.code}-modal`}
                      className="rounded-full border border-white/10 bg-white/6 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-white/82"
                    >
                      {issue.code}
                    </span>
                  ))}
                </div>
              </div>
            </div>

            {draftError ? (
              <div className="mt-6 rounded-2xl border border-amber-300/20 bg-amber-200/10 px-4 py-3 text-sm text-[color:var(--gold-soft)]">
                {draftError}
              </div>
            ) : null}

            <div className="mt-6 flex flex-wrap justify-end gap-3">
              <button
                type="button"
                className="button-secondary min-h-10 px-4"
                onClick={() => {
                  setDraftCandidate(null);
                  setDraftValues({});
                  setDraftError("");
                  setEditingId(null);
                }}
              >
                İptal
              </button>
              <button
                type="button"
                className="button-primary min-h-10 px-5"
                onClick={handleSaveDraft}
              >
                Kaydet ve kapat
              </button>
            </div>
          </div>
        </div>
      ) : null}

      <div className="rounded-2xl border border-white/8 bg-white/[0.03] p-4 text-sm text-[color:var(--text-muted)]">
        Export şablonu tam olarak {importTemplateHeaders.length} kolon kullanır ve mevcut import template sırası aynen korunur.
      </div>
    </div>
  );
}
