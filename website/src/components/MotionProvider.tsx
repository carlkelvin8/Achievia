"use client";

import { LazyMotion, MotionConfig, domAnimation } from "motion/react";

/** Loads only the DOM animation features (small bundle) and honours prefers-reduced-motion. */
export default function MotionProvider({ children }: { children: React.ReactNode }) {
  return (
    <LazyMotion features={domAnimation} strict>
      <MotionConfig reducedMotion="user">{children}</MotionConfig>
    </LazyMotion>
  );
}

export const EASE = [0.22, 1, 0.36, 1] as const;
