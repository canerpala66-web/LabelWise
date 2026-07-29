"use client";

import { useMemo, useState } from "react";
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
import {
  approveCandidate,
  rejectCandidate,
  summarizeCandidates,
  updateCandidateField,
  validateBarcodeBatch,
} from "@/lib/admin/product-finder/validation";

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

  const editingCandidate =
    candidates.find((candidate) => candidate.id === editingId) ?? null;

  const summary = useMemo(() => summarizeCandidates(candidates), [candidates]);
  const textareaStats = useMemo(
    () => finalizeParsedBarcodes(parseBarcodeTextarea(barcodeInput)),
    [barcodeInput],
  );
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
              onClick={() => void handleExportXlsx()}
              className="button-secondary min-h-11 px-5"
            >
              Onaylananları XLSX indir
            </button>
          </div>
        </div>

        <div className="mt-6 overflow-x-auto rounded-2xl">
          <table className="min-w-[1080px] text-left">
            <thead className="bg-white/[0.03] text-xs uppercase tracking-[0.24em] text-[color:var(--text-soft)]">
              <tr>
                <th className="px-4 py-4">Durum</th>
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
                  <td className="px-4 py-4 text-sm text-white/82">{candidate.status}</td>
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
                    {candidate.data_source || "—"}
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
