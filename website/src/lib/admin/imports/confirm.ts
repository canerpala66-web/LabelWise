import "server-only";

import { createConfirmationKey } from "@/lib/admin/imports/helpers";
import {
  createImportJob,
  findJobByConfirmationKey,
  getImportRowsByJobId,
  insertImportRows,
  processImportRows,
  updateImportJob,
} from "@/lib/admin/imports/products";
import type {
  ConfirmImportResult,
  ImportMode,
  PreviewPayload,
} from "@/lib/admin/imports/types";

export async function confirmImport(args: {
  preview: PreviewPayload;
  importMode: ImportMode;
  allowStaleOverride: boolean;
  createdBy: string;
}): Promise<ConfirmImportResult> {
  const confirmationKey = createConfirmationKey(args.preview.previewToken, args.createdBy);
  const existingJob = await findJobByConfirmationKey(args.createdBy, confirmationKey);

  if (existingJob) {
    if (existingJob.status === "completed" || existingJob.status === "partially_completed") {
      return {
        jobId: existingJob.id,
        status: existingJob.status,
        insertedRows: existingJob.inserted_rows,
        updatedRows: existingJob.updated_rows,
        skippedRows: existingJob.skipped_rows,
        failedRows: existingJob.failed_rows,
      };
    }

    if (existingJob.status === "importing") {
      return {
        jobId: existingJob.id,
        status: existingJob.status,
        insertedRows: existingJob.inserted_rows,
        updatedRows: existingJob.updated_rows,
        skippedRows: existingJob.skipped_rows,
        failedRows: existingJob.failed_rows,
      };
    }
  }

  let job;

  try {
    job = await createImportJob({
      file_name: args.preview.fileName,
      file_type: args.preview.fileType,
      file_size: args.preview.fileSize,
      status: "importing",
      import_mode: args.importMode,
      allow_stale_override: args.allowStaleOverride,
      confirmation_key: confirmationKey,
      total_rows: args.preview.summary.totalRows,
      valid_rows: args.preview.summary.validRows,
      warning_rows: args.preview.summary.warningRows,
      invalid_rows: args.preview.summary.invalidRows,
      created_by: args.createdBy,
      confirmed_at: new Date().toISOString(),
    });
  } catch (error) {
    if (
      error &&
      typeof error === "object" &&
      "message" in error &&
      `${(error as { message?: string }).message ?? ""}`.toLowerCase().includes("confirmation_key")
    ) {
      const concurrentJob = await findJobByConfirmationKey(args.createdBy, confirmationKey);
      if (concurrentJob) {
        return {
          jobId: concurrentJob.id,
          status: concurrentJob.status,
          insertedRows: concurrentJob.inserted_rows,
          updatedRows: concurrentJob.updated_rows,
          skippedRows: concurrentJob.skipped_rows,
          failedRows: concurrentJob.failed_rows,
        };
      }
    }

    throw error;
  }

  await insertImportRows(
    args.preview.rows.map((row) => ({
      import_job_id: job.id,
      row_number: row.rowNumber,
      barcode: row.normalized.barcode,
      normalized_data: row.normalized,
      validation_errors: row.errors,
      validation_warnings: row.warnings,
      status: row.status,
      existing_product_id: row.existingProduct?.id ?? null,
    })),
  );

  const rowRecordMap = new Map<number, string>();
  const persistedRows = await getImportRowsByJobId(job.id);
  persistedRows.forEach((item) => rowRecordMap.set(item.row_number, item.id));

  const processingResult = await processImportRows({
    jobId: job.id,
    rows: args.preview.rows.map((row) => ({
      ...row,
      rowRecordId: rowRecordMap.get(row.rowNumber) ?? "",
    })),
    importMode: args.importMode,
    allowStaleOverride: args.allowStaleOverride,
  });

  const finalStatus =
    processingResult.failedRows > 0 && processingResult.insertedRows + processingResult.updatedRows > 0
      ? "partially_completed"
      : processingResult.failedRows > 0
        ? "failed"
        : "completed";

  await updateImportJob(job.id, {
    status: finalStatus,
    inserted_rows: processingResult.insertedRows,
    updated_rows: processingResult.updatedRows,
    skipped_rows: processingResult.skippedRows,
    failed_rows: processingResult.failedRows,
    completed_at: new Date().toISOString(),
  });

  return {
    jobId: job.id,
    status: finalStatus,
    insertedRows: processingResult.insertedRows,
    updatedRows: processingResult.updatedRows,
    skippedRows: processingResult.skippedRows,
    failedRows: processingResult.failedRows,
  };
}
