"use client";

import { useEffect, useRef, useState } from "react";

const R = 22;
const C = 2 * Math.PI * R;

/** Thin top bar + a floating ring that shows scroll percentage and jumps back to the top. */
export default function ScrollProgress() {
  const bar = useRef<HTMLDivElement>(null);
  const ring = useRef<SVGCircleElement>(null);
  const [pct, setPct] = useState(0);

  useEffect(() => {
    let raf = 0;
    const update = () => {
      raf = 0;
      const el = document.documentElement;
      const max = el.scrollHeight - el.clientHeight;
      const p = max > 0 ? Math.min(1, window.scrollY / max) : 0;
      if (bar.current) bar.current.style.transform = `scaleX(${p})`;
      if (ring.current) ring.current.style.strokeDashoffset = String(C * (1 - p));
      setPct(Math.round(p * 100));
    };
    const onScroll = () => {
      if (!raf) raf = requestAnimationFrame(update);
    };
    update();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);
    return () => {
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
      if (raf) cancelAnimationFrame(raf);
    };
  }, []);

  return (
    <>
      <div className="progress" aria-hidden="true">
        <div ref={bar} className="progress-bar" />
      </div>
      <button
        className={`to-top-ring ${pct > 4 ? "show" : ""}`}
        aria-label={`Scrolled ${pct} percent. Back to top`}
        tabIndex={pct > 4 ? 0 : -1}
        onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
      >
        <svg viewBox="0 0 52 52" aria-hidden="true">
          <circle cx="26" cy="26" r={R} className="ring-track" />
          <circle ref={ring} cx="26" cy="26" r={R} className="ring-fill" strokeDasharray={C} strokeDashoffset={C} />
        </svg>
        <span aria-hidden="true">{pct}%</span>
      </button>
    </>
  );
}
