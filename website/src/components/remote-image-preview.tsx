"use client";

import { useState } from "react";

type RemoteImagePreviewProps = {
  src: string | null | undefined;
  alt: string;
  size?: number;
  compactLabel?: string;
  failedLabel?: string;
};

export function RemoteImagePreview({
  src,
  alt,
  size = 56,
  compactLabel = "Görsel yok",
  failedLabel = "Görsel yüklenemedi",
}: RemoteImagePreviewProps) {
  const [failed, setFailed] = useState(false);
  const url = src?.trim();

  if (!url || failed) {
    return (
      <div
        className="flex items-center justify-center rounded-2xl border border-white/8 bg-white/5 text-center text-[10px] text-[color:var(--text-soft)]"
        style={{ width: size, height: size }}
        title={failed ? failedLabel : compactLabel}
      >
        <span className="px-2">{failed ? failedLabel : compactLabel}</span>
      </div>
    );
  }

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={url}
      alt={alt}
      className="rounded-2xl border border-white/10 bg-white/5 object-cover"
      style={{ width: size, height: size }}
      onError={() => setFailed(true)}
    />
  );
}
