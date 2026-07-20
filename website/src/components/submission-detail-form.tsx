"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import type {
  SubmissionImagePreview,
  SubmittedProduct,
} from "@/lib/admin/types";

type Props = {
  submission: SubmittedProduct;
  images: SubmissionImagePreview[];
};

function inputClassName() {
  return "rounded-2xl border border-white/10 bg-white/6 px-4 py-3 text-white outline-none placeholder:text-white/35 focus:border-[color:var(--gold)]";
}

type NutritionField = {
  name: string;
  label: string;
  value: number | null;
};

export function SubmissionDetailForm({ submission, images }: Props) {
  const router = useRouter();
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const nutritionFields: NutritionField[] = [
    { name: "energy_kcal", label: "Enerji (kcal)", value: submission.energy_kcal },
    { name: "fat", label: "Yag", value: submission.fat },
    { name: "saturated_fat", label: "Doymus yag", value: submission.saturated_fat },
    { name: "sugars", label: "Seker", value: submission.sugars },
    { name: "fiber", label: "Lif", value: submission.fiber },
    { name: "protein", label: "Protein", value: submission.protein },
    { name: "salt", label: "Tuz", value: submission.salt },
  ];

  async function runAction(endpoint: string, formData: FormData) {
    setErrorMessage(null);
    setSuccessMessage(null);

    const response = await fetch(endpoint, {
      method: "POST",
      body: formData,
    });

    const payload = (await response.json().catch(() => null)) as
      | { message?: string }
      | null;

    if (!response.ok) {
      setErrorMessage(payload?.message ?? "Degisiklikler kaydedilemedi.");
      return;
    }

    setSuccessMessage(payload?.message ?? "Degisiklikler kaydedildi.");
    startTransition(() => {
      router.refresh();
    });
  }

  async function handleSaveDraft(formData: FormData) {
    await runAction(`/api/admin/submissions/${submission.id}/draft`, formData);
  }

  async function handleApprove(formData: FormData) {
    await runAction(`/api/admin/submissions/${submission.id}/approve`, formData);
  }

  async function handleReject(formData: FormData) {
    await runAction(`/api/admin/submissions/${submission.id}/reject`, formData);
  }

  return (
    <form className="grid gap-6">
      <div className="card p-8">
        <div className="grid gap-5 lg:grid-cols-2">
          <label className="grid gap-2">
            <span className="text-sm font-medium text-white">Barkod</span>
            <input
              name="barcode"
              defaultValue={submission.barcode}
              className={inputClassName()}
              required
            />
          </label>
          <label className="grid gap-2">
            <span className="text-sm font-medium text-white">Urun adi</span>
            <input
              name="name"
              defaultValue={submission.name}
              className={inputClassName()}
              required
            />
          </label>
          <label className="grid gap-2">
            <span className="text-sm font-medium text-white">Marka</span>
            <input
              name="brand"
              defaultValue={submission.brand ?? ""}
              className={inputClassName()}
            />
          </label>
          <label className="grid gap-2">
            <span className="text-sm font-medium text-white">Kategori</span>
            <input
              name="category"
              defaultValue={submission.category ?? ""}
              className={inputClassName()}
            />
          </label>
          <label className="grid gap-2 lg:col-span-2">
            <span className="text-sm font-medium text-white">Icerikler</span>
            <textarea
              name="ingredients_text"
              defaultValue={submission.ingredients_text ?? ""}
              rows={6}
              className={inputClassName()}
            />
          </label>
          {nutritionFields.map(({ name, label, value }) => (
            <label key={name} className="grid gap-2">
              <span className="text-sm font-medium text-white">{label}</span>
              <input
                name={name}
                defaultValue={value == null ? "" : String(value)}
                className={inputClassName()}
                inputMode="decimal"
              />
            </label>
          ))}
          <label className="grid gap-2 lg:col-span-2">
            <span className="text-sm font-medium text-white">Admin notu</span>
            <textarea
              name="review_note"
              defaultValue={submission.review_note ?? ""}
              rows={4}
              className={inputClassName()}
            />
          </label>
        </div>

        {successMessage ? (
          <p className="mt-5 rounded-2xl border border-emerald-400/20 bg-emerald-400/10 px-4 py-3 text-sm text-emerald-100">
            {successMessage}
          </p>
        ) : null}

        {errorMessage ? (
          <p className="mt-5 rounded-2xl border border-red-400/20 bg-red-400/10 px-4 py-3 text-sm text-red-100">
            {errorMessage}
          </p>
        ) : null}

        <div className="mt-6 flex flex-col gap-3 sm:flex-row">
          <button
            type="submit"
            formAction={handleSaveDraft}
            disabled={isPending}
            className="button-secondary min-h-12 px-6 disabled:cursor-not-allowed disabled:opacity-60"
          >
            Taslak olarak kaydet
          </button>
          <button
            type="submit"
            formAction={handleApprove}
            disabled={isPending}
            className="button-primary min-h-12 px-6 disabled:cursor-not-allowed disabled:opacity-60"
          >
            Onayla
          </button>
          <button
            type="submit"
            formAction={handleReject}
            disabled={isPending}
            className="inline-flex min-h-12 items-center justify-center rounded-full border border-red-300/25 bg-red-300/10 px-6 text-sm font-semibold text-red-100 disabled:cursor-not-allowed disabled:opacity-60"
          >
            Reddet
          </button>
        </div>
      </div>

      <div className="card p-8">
        <h2 className="text-2xl font-semibold text-white">Gorseller</h2>
        <p className="mt-2 text-sm leading-7 text-[color:var(--text-muted)]">
          Gonderilen urun fotograflari, signed URL ile guvenli sekilde
          goruntulenir.
        </p>

        {images.length === 0 ? (
          <p className="mt-6 text-sm leading-7 text-[color:var(--text-muted)]">
            Bu gonderimde goruntulenecek fotograf bulunmuyor.
          </p>
        ) : (
          <div className="mt-6 grid gap-5 lg:grid-cols-3">
            {images.map((image) => (
              <figure
                key={image.path}
                className="overflow-hidden rounded-[1.5rem] border border-white/8 bg-white/[0.04]"
              >
                <img
                  src={image.signedUrl}
                  alt={image.label}
                  className="h-60 w-full object-cover"
                />
                <figcaption className="px-4 py-3 text-sm text-white/85">
                  {image.label}
                </figcaption>
              </figure>
            ))}
          </div>
        )}
      </div>
    </form>
  );
}
