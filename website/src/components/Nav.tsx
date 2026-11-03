"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { NAV, SITE } from "@/lib/site";
import Wordmark from "./Wordmark";

export default function Nav() {
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState("");

  useEffect(() => {
    const els = NAV.map((n) => document.getElementById(n.href.slice(1))).filter(Boolean) as HTMLElement[];
    if (!els.length) return;
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) if (e.isIntersecting) setActive(e.target.id);
      },
      { rootMargin: "-40% 0px -55% 0px" },
    );
    els.forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  return (
    <header className="nav">
      <div className="container nav-inner">
        <Link href="/" className="brand" aria-label="Achievia home">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo.svg" alt="" width={38} height={38} />
          <Wordmark />
        </Link>

        <nav className="nav-links" aria-label="Main">
          {NAV.map((n) => (
            <a
              key={n.href}
              href={`/${n.href}`}
              className={active === n.href.slice(1) ? "is-active" : ""}
              aria-current={active === n.href.slice(1) ? "true" : undefined}
            >
              {n.label}
            </a>
          ))}
        </nav>

        <div className="nav-actions">
          <a className="btn btn-sm nav-cta" href={SITE.playStoreUrl} rel="noopener">
            Get the app
          </a>
          <button
            className={`burger ${open ? "is-open" : ""}`}
            aria-label={open ? "Close menu" : "Open menu"}
            aria-expanded={open}
            aria-controls="mobile-menu"
            onClick={() => setOpen((v) => !v)}
          >
            <span />
            <span />
          </button>
        </div>
      </div>

      <div id="mobile-menu" className={`mobile-menu ${open ? "open" : ""}`} aria-hidden={!open}>
        <div className="container">
          {NAV.map((n) => (
            <a key={n.href} href={`/${n.href}`} onClick={() => setOpen(false)} tabIndex={open ? 0 : -1}>
              {n.label}
            </a>
          ))}
          <Link href="/privacy" onClick={() => setOpen(false)} tabIndex={open ? 0 : -1}>
            Privacy Policy
          </Link>
          <a className="btn" href={SITE.playStoreUrl} rel="noopener" tabIndex={open ? 0 : -1}>
            Download for Android
          </a>
        </div>
      </div>
    </header>
  );
}
