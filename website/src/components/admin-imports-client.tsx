"use client";

import { useMemo, useState } from "react";
import { RemoteImagePreview } from "@/components/remote-image-preview";
import { importModeOptions } from "@/lib/admin/imports/constants";
import { formatDate } from "@/lib/admin/imports/helpers";
import type {
  ConfirmImportResult,
  ImportMode,
  PreviewPayload,
  PreviewRow,
} from "@/lib/admin/imports/types";

const previewFilters = [
  { value: "all", label: "Tümü" },
  { value: "valid", label: "Geçerli" },
  { value: "warning", label: "Uyarılı" },
  { value: "invalid", label: "Hatalı" },
  { value: "new", label: "Yeni ürünler" },
  { value: "update", label: "Güncellenecekler" },
  { value: "duplicate", label: "Tekrarlananlar" },
  { value: "stale", label: "Eski veriler" },
  { value: "missing-image", label: "Görselsiz" },
  { value: "missing-nutrition", label: "Besin eksiği" },
] as const;

type PreviewFilter = (typeof previewFilters)[number]["value"];

function formatIssueList(items: Array<{ message: string }>) {
  if (items.length === 0) {
    return "—";
  }

  return items.map((item) => item.message).join(" • ");
}

function matchesFilter(row: PreviewRow, filter: PreviewFilter) {
  switch (filter) {
    case "valid":
      return row.errors.length === 0 && row.warnings.length === 0;
    case "warning":
      return row.warnings.length > 0 && row.errors.length === 0;
    case "invalid":
      return row.errors.length > 0 || row.duplicateInFile;
    case "new":
      return row.isNewProduct;
    case "update":
      return row.isUpdate;
    case "duplicate":
      return row.duplicateInFile;
    case "stale":
      return row.warnings.some(
        (item) => item.code === "stale_data" || item.code === "stale_update_attempt",
      );
    case "missing-image":
      return !row.normalized.imageFrontUrl;
    case "missing-nutrition":
      return row.warnings.some((item) => item.code === "missing_nutrition_data");
    default:
      return true;
  }
}

export function AdminImportsClient() {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<PreviewPayload | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isConfirming, setIsConfirming] = useState(false);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<PreviewFilter>("all");
  const [page, setPage] = useState(1);
  const [importMode, setImportMode] = useState<ImportMode>("insert_and_update");
  const [allowStaleOverride, setAllowStaleOverride] = useState(false);
  const [result, setResult] = useState<ConfirmImportResult | null>(null);

  const filteredRows = useMemo(() => {
    if (!preview) {
      return [];
    }

    const normalizedSearch = search.trim().toLowerCase();

    return preview.rows.filter((row) => {
      if (!matchesFilter(row, filter)) {
        return false;
      }

      if (!normalizedSearch) {
        return true;
      }

      return [row.normalized.barcode, row.normalized.productName, row.normalized.brand, row.normalized.category]
        .filter(Boolean)
        .some((value) => value!.toLowerCase().includes(normalizedSearch));
    });
  }, [filter, preview, search]);

  const pageSize = 15;
  const totalPages = Math.max(1, Math.ceil(filteredRows.length / pageSize));
  const pageRows = filteredRows.slice((page - 1) * pageSize, page * pageSize);

  async function handlePreviewSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!selectedFile) {
      setError("Lütfen bir dosya seçin.");
      return;
    }

    setIsUploading(true);
    setError(null);
    setResult(null);

    try {
      const formData = new FormData();
      formData.append("file", selectedFile);

      const response = await fetch("/api/admin/imports/preview", {
        method: "POST",
        body: formData,
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error ?? "Ön izleme hazırlanamadı.");
      }

      setPreview(data as PreviewPayload);
      setPage(1);
    } catch (requestError) {
      setPreview(null);
      setError(requestError instanceof Error ? requestError.message : "Ön izleme hazırlanamadı.");
    } finally {
      setIsUploading(false);
    }
  }

  async function downloadPreviewIssues() {
    if (!preview) return;

    const rows = preview.rows
      .filter((row) => row.errors.length > 0 || row.warnings.length > 0)
      .map((row) => ({
        rowNumber: row.rowNumber,
        barcode: row.normalized.barcode,
        productName: row.normalized.productName,
        brand: row.normalized.brand,
        errors: row.errors,
        warnings: row.warnings,
      }));

    const response = await fetch("/api/admin/imports/export-issues", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ rows }),
    });

    if (!response.ok) {
      setError("Hatalı satır CSV dosyası hazırlanamadı.");
      return;
    }

    const blob = await response.blob();
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "labelwise-import-issues.csv";
    anchor.click();
    URL.revokeObjectURL(url);
  }

  async function handleConfirm() {
    if (!preview) return;
    setIsConfirming(true);
    setError(null);

    try {
      const response = await fetch("/api/admin/imports/confirm", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          preview,
          importMode,
          allowStaleOverride,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error ?? "İçe aktarma başlatılamadı.");
      }

      setResult(data as ConfirmImportResult);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "İçe aktarma başlatılamadı.");
    } finally {
      setIsConfirming(false);
    }
  }

  return (
    <div className="space-y-8">
      <div className="card p-6 sm:p-8">
        <div className="grid gap-6 lg:grid-cols-[1.15fr_0.85fr]">
          <div>
            <h2 className="text-2xl font-semibold text-white">Yeni import yükle</h2>
            <p className="mt-3 max-w-2xl text-sm leading-7 text-[color:var(--text-muted)]">
              CSV, XLSX veya JSON dosyanızı yükleyin. Sistem önce satırları doğrular, ardından veri
              tabanına yazmadan önce ayrıntılı ön izleme gösterir.
            </p>
            <ul className="mt-5 grid gap-3 text-sm text-[color:var(--text-muted)] sm:grid-cols-3">
              <li className="rounded-2xl border border-white/8 bg-white/[0.03] px-4 py-3">Destek: CSV, XLSX, JSON</li>
              <li className="rounded-2xl border border-white/8 bg-white/[0.03] px-4 py-3">Maksimum boyut: 5 MB</li>
              <li className="rounded-2xl border border-white/8 bg-white/[0.03] px-4 py-3">Maksimum satır: 500</li>
            </ul>
          </div>
          <div className="rounded-[1.5rem] border border-white/8 bg-white/[0.03] p-5">
            <h3 className="text-base font-semibold text-white">Şablon ve hızlı başlangıç</h3>
            <p className="mt-2 text-sm leading-7 text-[color:var(--text-muted)]">
              Önce örnek CSV şablonunu indirip kolon adlarını aynı yapıda tutmanız önerilir.
            </p>
            <div className="mt-5 flex flex-wrap gap-3">
              <a href="/api/admin/imports/template" className="button-secondary min-h-11 px-5">
                CSV şablonunu indir
              </a>
            </div>
          </div>
        </div>

        <form onSubmit={handlePreviewSubmit} className="mt-8 grid gap-4 lg:grid-cols-[1fr_auto]">
          <label className="flex min-h-36 cursor-pointer flex-col items-center justify-center rounded-[1.75rem] border border-dashed border-white/16 bg-white/[0.03] px-6 py-8 text-center">
            <span className="text-base font-semibold text-white">Dosya seç veya sürükleyip bırak</span>
            <span className="mt-2 text-sm text-[color:var(--text-muted)]">
              Barkod, ürün adı, içindekiler ve veri tarihi alanlarını doldurmayı unutma.
            </span>
            <span className="mt-4 rounded-full border border-white/10 bg-white/6 px-4 py-2 text-sm text-white/88">
              {selectedFile ? selectedFile.name : "Henüz dosya seçilmedi"}
            </span>
            <input
              type="file"
              accept=".csv,.xlsx,.json"
              className="sr-only"
              onChange={(event) => setSelectedFile(event.target.files?.[0] ?? null)}
            />
          </label>
          <button
            type="submit"
            className="button-primary min-h-14 px-7 disabled:cursor-not-allowed disabled:opacity-60"
            disabled={isUploading}
          >
            {isUploading ? "Dosya okunuyor..." : "Ön izlemeyi hazırla"}
          </button>
        </form>

        {error ? (
          <div className="mt-5 rounded-2xl border border-amber-300/20 bg-amber-200/10 px-4 py-3 text-sm text-[color:var(--gold-soft)]">
            {error}
          </div>
        ) : null}

        {result ? (
          <div className="mt-5 rounded-2xl border border-emerald-300/20 bg-emerald-200/10 px-4 py-4 text-sm text-white/88">
            Import sonucu kaydedildi. Eklenen: {result.insertedRows}, güncellenen: {result.updatedRows},
            atlanan: {result.skippedRows}, hatalı: {result.failedRows}.{" "}
            <a href={`/admin/imports/${result.jobId}`} className="underline underline-offset-4">
              Detayı aç
            </a>
          </div>
        ) : null}
      </div>

      {preview ? (
        <div className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {[
              ["Toplam satır", preview.summary.totalRows],
              ["Geçerli", preview.summary.validRows],
              ["Uyarılı", preview.summary.warningRows],
              ["Hatalı", preview.summary.invalidRows],
              ["Yeni ürün", preview.summary.newRows],
              ["Güncellenecek", preview.summary.updateRows],
              ["Dosya içi tekrar", preview.summary.duplicateRows],
              ["Eski veri", preview.summary.staleRows + preview.summary.staleUpdateRows],
            ].map(([label, value]) => (
              <div key={label} className="card p-5">
                <div className="text-xs uppercase tracking-[0.2em] text-[color:var(--text-soft)]">{label}</div>
                <div className="mt-3 text-3xl font-semibold text-white">{value}</div>
              </div>
            ))}
          </div>

          <div className="card p-6">
            <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
              <div>
                <h2 className="text-2xl font-semibold text-white">Preview ve doğrulama</h2>
                <p className="mt-3 text-sm leading-7 text-[color:var(--text-muted)]">
                  {preview.fileName} dosyası analiz edildi. Ürünler veritabanına henüz yazılmadı.
                </p>
              </div>
              <div className="flex flex-wrap gap-3">
                <button type="button" onClick={downloadPreviewIssues} className="button-secondary min-h-11 px-5">
                  Hatalı/uyaırlı CSV indir
                </button>
              </div>
            </div>

            <div className="mt-6 grid gap-4 lg:grid-cols-[1fr_1fr_1.2fr]">
              <label className="flex flex-col gap-2 text-sm text-[color:var(--text-muted)]">
                Filtre
                <select
                  className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none"
                  value={filter}
                  onChange={(event) => {
                    setFilter(event.target.value as PreviewFilter);
                    setPage(1);
                  }}
                >
                  {previewFilters.map((item) => (
                    <option key={item.value} value={item.value} className="bg-[#10241d]">
                      {item.label}
                    </option>
                  ))}
                </select>
              </label>
              <label className="flex flex-col gap-2 text-sm text-[color:var(--text-muted)]">
                Arama
                <input
                  value={search}
                  onChange={(event) => {
                    setSearch(event.target.value);
                    setPage(1);
                  }}
                  placeholder="Barkod, ürün adı veya marka ara"
                  className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none placeholder:text-white/40"
                />
              </label>
              <label className="flex flex-col gap-2 text-sm text-[color:var(--text-muted)]">
                Import modu
                <select
                  className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none"
                  value={importMode}
                  onChange={(event) => setImportMode(event.target.value as ImportMode)}
                >
                  {importModeOptions.map((item) => (
                    <option key={item.value} value={item.value} className="bg-[#10241d]">
                      {item.label}
                    </option>
                  ))}
                </select>
              </label>
            </div>

            <label className="mt-5 flex items-start gap-3 rounded-2xl border border-white/8 bg-white/[0.03] px-4 py-4 text-sm text-[color:var(--text-muted)]">
              <input
                type="checkbox"
                className="mt-1"
                checked={allowStaleOverride}
                onChange={(event) => setAllowStaleOverride(event.target.checked)}
              />
              <span>
                Üç yıldan eski verilerin veya mevcut üründen daha eski güncelleme denemelerinin import edilmesine
                izin ver. Bu seçenek varsayılan olarak kapalıdır ve işlem geçmişine not düşülür.
              </span>
            </label>

            <div className="mt-6 overflow-x-auto">
              <table className="min-w-full text-left">
                <thead className="bg-white/[0.03] text-xs uppercase tracking-[0.24em] text-[color:var(--text-soft)]">
                  <tr>
                    <th className="px-4 py-4">Satır</th>
                    <th className="px-4 py-4">Görsel</th>
                    <th className="px-4 py-4">Barkod</th>
                    <th className="px-4 py-4">Ürün</th>
                    <th className="px-4 py-4">Marka</th>
                    <th className="px-4 py-4">Kategori</th>
                    <th className="px-4 py-4">Veri tarihi</th>
                    <th className="px-4 py-4">Kaynak</th>
                    <th className="px-4 py-4">Durum</th>
                    <th className="px-4 py-4">Hatalar</th>
                    <th className="px-4 py-4">Uyarılar</th>
                  </tr>
                </thead>
                <tbody>
                  {pageRows.map((row) => (
                    <tr key={`${row.rowNumber}-${row.normalized.barcode ?? "empty"}`} className="border-t border-white/8 align-top">
                      <td className="px-4 py-4 text-sm text-white/82">{row.rowNumber}</td>
                      <td className="px-4 py-4">
                        {row.normalized.imageFrontUrl ? (
                          <RemoteImagePreview
                            src={row.normalized.imageFrontUrl}
                            alt={row.normalized.productName ?? "Ürün görseli"}
                            size={56}
                            compactLabel="Görsel yok"
                            failedLabel="Görsel yüklenemedi"
                          />
                        ) : (
                          <div className="flex h-14 w-14 items-center justify-center rounded-2xl border border-white/8 bg-white/5 text-[10px] text-[color:var(--text-soft)]">
                            Görsel yok
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-4 text-sm text-white/92">{row.normalized.barcode || "—"}</td>
                      <td className="px-4 py-4">
                        <div className="text-sm font-semibold text-white">{row.normalized.productName || "—"}</div>
                        <div className="mt-1 text-xs text-[color:var(--text-soft)]">
                          {row.isNewProduct ? "Yeni ürün" : row.isCurrentProduct ? "Mevcut ve aynı" : "Mevcut ürün"}
                        </div>
                      </td>
                      <td className="px-4 py-4 text-sm text-[color:var(--text-muted)]">{row.normalized.brand || "—"}</td>
                      <td className="px-4 py-4 text-sm text-[color:var(--text-muted)]">{row.normalized.category || "—"}</td>
                      <td className="px-4 py-4 text-sm text-[color:var(--text-muted)]">{formatDate(row.normalized.dataUpdatedAt)}</td>
                      <td className="px-4 py-4 text-sm text-[color:var(--text-muted)]">{row.normalized.dataSource || "—"}</td>
                      <td className="px-4 py-4">
                        <span className="rounded-full border border-white/10 bg-white/6 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-white/82">
                          {row.status}
                        </span>
                      </td>
                      <td className="px-4 py-4 text-xs leading-6 text-rose-200">{formatIssueList(row.errors)}</td>
                      <td className="px-4 py-4 text-xs leading-6 text-amber-100">{formatIssueList(row.warnings)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="mt-5 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <p className="text-sm text-[color:var(--text-muted)]">
                {filteredRows.length} satır gösteriliyor · Sayfa {page} / {totalPages}
              </p>
              <div className="flex flex-wrap gap-3">
                <button
                  type="button"
                  onClick={() => setPage((current) => Math.max(1, current - 1))}
                  disabled={page === 1}
                  className="button-secondary min-h-11 px-5 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  Önceki
                </button>
                <button
                  type="button"
                  onClick={() => setPage((current) => Math.min(totalPages, current + 1))}
                  disabled={page === totalPages}
                  className="button-secondary min-h-11 px-5 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  Sonraki
                </button>
                <button
                  type="button"
                  onClick={handleConfirm}
                  disabled={isConfirming}
                  className="button-primary min-h-11 px-6 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  {isConfirming ? "İçe aktarılıyor..." : "İçe aktarmayı onayla"}
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
