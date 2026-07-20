import Link from "next/link";

type Props = {
  title: string;
  message: string;
  actionLabel?: string;
  actionHref?: string;
};

export function AdminStatusCard({
  title,
  message,
  actionLabel,
  actionHref,
}: Props) {
  return (
    <div className="card w-full max-w-3xl p-8 text-center sm:p-10">
      <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
        Admin Panel
      </p>
      <h1 className="mt-4 font-display text-4xl text-white sm:text-5xl">
        {title}
      </h1>
      <p className="mt-5 text-base leading-8 text-[color:var(--text-muted)]">
        {message}
      </p>
      {actionLabel && actionHref ? (
        <div className="mt-8 flex justify-center">
          <Link href={actionHref} className="button-secondary">
            {actionLabel}
          </Link>
        </div>
      ) : null}
    </div>
  );
}
