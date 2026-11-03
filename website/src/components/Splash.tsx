"use client";

import { useEffect, useState } from "react";

const DURATION = 1900;

/**
 * Logo intro on every page load / refresh. The CSS animation hides it on its own
 * after ~2.3s, so it can never block the page even if JS fails.
 */
export default function Splash() {
  const [gone, setGone] = useState(false);
  const [pct, setPct] = useState(0);

  useEffect(() => {
    const start = performance.now();
    let raf = 0;
    const tick = (now: number) => {
      const t = Math.min(1, (now - start) / DURATION);
      // ease-out so the last digits settle
      setPct(Math.round((1 - Math.pow(1 - t, 3)) * 100));
      if (t < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    const done = setTimeout(() => setGone(true), DURATION + 600);
    return () => {
      cancelAnimationFrame(raf);
      clearTimeout(done);
    };
  }, []);

  if (gone) return null;

  return (
    <div className="splash" aria-hidden="true">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/logo.svg" alt="" width={150} height={150} className="splash-logo" />
      <div className="splash-word wordmark">
        {"Achie".split("").map((c, n) => (
          <span key={n} className="wm-a" style={{ animationDelay: `${0.5 + n * 0.07}s` }}>{c}</span>
        ))}
        {"via".split("").map((c, n) => (
          <span key={n} className="wm-b" style={{ animationDelay: `${0.85 + n * 0.07}s` }}>{c}</span>
        ))}
      </div>
      <div className="splash-tag">Awaken Academic Ambition</div>
      <div className="splash-load">
        <div className="splash-track"><span style={{ transform: `scaleX(${pct / 100})` }} /></div>
        <b>{pct}%</b>
      </div>
    </div>
  );
}
