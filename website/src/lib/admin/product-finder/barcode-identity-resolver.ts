import type {
  BarcodeIdentityProvider,
  ProductIdentityInput,
  ProductIdentityResult,
} from "@/lib/admin/product-finder/providers";
import type { ProductFinderIssue } from "@/lib/admin/product-finder/types";

export type BarcodeIdentityStatus =
  | "resolved"
  | "needs_review"
  | "not_found"
  | "invalid";

export type BarcodeIdentityResolution = {
  barcode: string;
  identity: ProductIdentityResult | null;
  status: BarcodeIdentityStatus;
  issues: ProductFinderIssue[];
  source_attempts?: Array<{
    providerId: string;
    success: boolean;
    message?: string;
  }>;
};

export type BarcodeIdentityBatchSummary = {
  total: number;
  resolved: number;
  needs_review: number;
  not_found: number;
  invalid: number;
};

function byPriority(providers: BarcodeIdentityProvider[]) {
  return [...providers].sort((left, right) => left.priority - right.priority);
}

function invalidBarcodeResolution(barcode: string): BarcodeIdentityResolution {
  return {
    barcode,
    identity: null,
    status: "invalid",
    issues: [
      {
        code: "invalid_barcode",
        message: "Barkod 8–14 haneli sayısal formatta olmalı.",
        severity: "error",
      },
    ],
  };
}

export async function resolveBarcodeIdentity(
  input: ProductIdentityInput,
  providers: BarcodeIdentityProvider[],
): Promise<BarcodeIdentityResolution> {
  if (!/^\d{8,14}$/.test(input.barcode)) {
    return invalidBarcodeResolution(input.barcode);
  }

  const providerErrors: ProductFinderIssue[] = [];
  const sourceAttempts: BarcodeIdentityResolution["source_attempts"] = [];

  for (const provider of byPriority(providers)) {
    try {
      const identity = await provider.lookupBarcode(input);
      sourceAttempts.push({
        providerId: provider.id,
        success: Boolean(identity),
      });

      if (!identity) {
        continue;
      }

      const issues = [...identity.issues, ...providerErrors];
      const needsReview = issues.some(
        (issue) =>
          issue.code === "brand_missing" ||
          issue.code === "quantity_missing" ||
          issue.code === "low_identity_confidence",
      );

      return {
        barcode: input.barcode,
        identity: {
          ...identity,
          issues,
        },
        status: needsReview ? "needs_review" : "resolved",
        issues,
        source_attempts: sourceAttempts,
      };
    } catch (error) {
      const issue =
        typeof error === "object" &&
        error !== null &&
        "issue" in error &&
        (error as { issue?: ProductFinderIssue }).issue
          ? (error as { issue: ProductFinderIssue }).issue
          : ({
              code: "source_error",
              message: `${provider.label} kaynağı okunamadı.`,
              severity: "warning",
            } satisfies ProductFinderIssue);

      providerErrors.push(issue);
      sourceAttempts.push({
        providerId: provider.id,
        success: false,
        message: issue.message,
      });
    }
  }

  const issues: ProductFinderIssue[] = providerErrors.length
    ? providerErrors
    : [
        {
          code: "identity_not_found",
          message: "Barkod kimliği bulunamadı.",
          severity: "warning",
        },
      ];

  if (!issues.some((issue) => issue.code === "identity_not_found")) {
    issues.push({
      code: "identity_not_found",
      message: "Barkod kimliği bulunamadı.",
      severity: "warning",
    });
  }

  return {
    barcode: input.barcode,
    identity: null,
    status: "not_found",
    issues,
    source_attempts: sourceAttempts,
  };
}

export async function resolveBarcodeIdentityBatch(
  barcodes: string[],
  providers: BarcodeIdentityProvider[],
) {
  const results = await Promise.all(
    barcodes.map((barcode) => resolveBarcodeIdentity({ barcode }, providers)),
  );

  const summary = results.reduce<BarcodeIdentityBatchSummary>(
    (acc, item) => {
      acc.total += 1;
      acc[item.status] += 1;
      return acc;
    },
    {
      total: 0,
      resolved: 0,
      needs_review: 0,
      not_found: 0,
      invalid: 0,
    },
  );

  return { results, summary };
}
