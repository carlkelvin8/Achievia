"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { SITE } from "@/lib/site";

const KEY = "achievia-promo-dismissed";

/** One-time dismissible banner introducing the free trial. Appears after a short delay. */
export default function PromoPopup() {
  const [open, setOpen] = useState(false);
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    try {
      if (sessionStorage.getItem(KEY)) return;
    } catch {
      /* ignore */
    }
    const t = setTimeout(() => setOpen(true), 6000);
    return () => clearTimeout(t);
  }, []);

  const close = () => {
    setOpen(false);
    try {
      sessionStorage.setItem(KEY, "1");
    } catch {
      /* ignore */
    }
  };

  useEffect(() => {
    if (!open) return;
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && close();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  if (!open) return null;

  return (
    <div className="promo" role="dialog" aria-labelledby="promo-title" aria-modal="false">
      <button ref={closeRef} className="promo-x" onClick={close} aria-label="Close banner">
        ×
      </button>
      <span className="promo-badge">New accounts</span>
      <h2 id="promo-title">Try Achievia free for 7 days</h2>
      <p>
        Start the one-time free trial inside the app and explore the question bank, mock exams and
        reviewers before you choose a plan.
      </p>
      <div className="promo-actions">
        <a className="btn btn-sm btn-cyan" href={SITE.playStoreUrl} rel="noopener" onClick={close}>
          Download for Android
        </a>
        <Link className="promo-link" href="/#pricing" onClick={close}>
          See pricing
        </Link>
      </div>
    </div>
  );
}
