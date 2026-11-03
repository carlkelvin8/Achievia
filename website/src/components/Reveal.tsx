"use client";

import { m, type TargetAndTransition } from "motion/react";
import { EASE } from "./MotionProvider";

type Variant = "up" | "scale" | "left" | "right" | "fade";

const FROM: Record<Variant, TargetAndTransition> = {
  up: { opacity: 0, y: 28 },
  scale: { opacity: 0, scale: 0.94, y: 16 },
  left: { opacity: 0, x: -36 },
  right: { opacity: 0, x: 36 },
  fade: { opacity: 0 },
};

/** Scroll-triggered reveal; each section picks a distinct variant. Plays once. */
export default function Reveal({
  children,
  delay = 0,
  variant = "up",
  className,
  as = "div",
}: {
  children: React.ReactNode;
  delay?: number;
  variant?: Variant;
  className?: string;
  as?: "div" | "li";
}) {
  const Tag = as === "li" ? m.li : m.div;
  return (
    <Tag
      className={className}
      initial={FROM[variant]}
      whileInView={{ opacity: 1, x: 0, y: 0, scale: 1 }}
      viewport={{ once: true, margin: "0px 0px -12% 0px" }}
      transition={{ duration: 0.8, delay: delay / 1000, ease: EASE }}
    >
      {children}
    </Tag>
  );
}

/** Heading with a masked line-rise reveal. */
export function MaskTitle({ children, className }: { children: string; className?: string }) {
  return (
    // The trigger lives on the (unclipped) heading, not the masked child, so it always intersects.
    <m.h2
      className={className}
      initial="hidden"
      whileInView="show"
      viewport={{ once: true, margin: "0px 0px -10% 0px" }}
    >
      <span className="mask-line">
        <m.span
          variants={{ hidden: { y: "110%" }, show: { y: "0%" } }}
          transition={{ duration: 0.9, ease: EASE }}
        >
          {children}
        </m.span>
      </span>
    </m.h2>
  );
}
