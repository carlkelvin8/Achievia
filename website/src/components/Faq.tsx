"use client";

import { AnimatePresence, m } from "motion/react";
import { useId, useState } from "react";
import { EASE } from "./MotionProvider";

export default function Faq({ items }: { items: { q: string; a: string }[] }) {
  const [open, setOpen] = useState<number | null>(0);
  const uid = useId();

  return (
    <div className="faqs">
      {items.map((f, n) => {
        const isOpen = open === n;
        return (
          <div key={f.q} className={`faq ${isOpen ? "is-open" : ""}`}>
            <h3>
              <button
                id={`${uid}-q${n}`}
                aria-expanded={isOpen}
                aria-controls={`${uid}-a${n}`}
                onClick={() => setOpen(isOpen ? null : n)}
              >
                <span className="faq-n" aria-hidden="true">{String(n + 1).padStart(2, "0")}</span>
                <span className="faq-q">{f.q}</span>
                <span className="faq-ico" aria-hidden="true" />
              </button>
            </h3>
            <AnimatePresence initial={false}>
              {isOpen && (
                <m.div
                  id={`${uid}-a${n}`}
                  role="region"
                  aria-labelledby={`${uid}-q${n}`}
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.35, ease: EASE }}
                  style={{ overflow: "hidden" }}
                >
                  <p>{f.a}</p>
                </m.div>
              )}
            </AnimatePresence>
          </div>
        );
      })}
    </div>
  );
}
