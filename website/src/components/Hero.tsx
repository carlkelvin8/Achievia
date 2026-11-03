"use client";

import { m } from "motion/react";
import Image from "next/image";
import { SITE } from "@/lib/site";
import { EASE } from "./MotionProvider";

const LINES = ["Your future", "RMT starts", "with smarter", "review."];

const container = { hidden: {}, show: { transition: { staggerChildren: 0.1, delayChildren: 0.2 } } };
const rise = {
  hidden: { opacity: 0, y: 18 },
  show: { opacity: 1, y: 0, transition: { duration: 0.7, ease: EASE } },
};
const mask = {
  hidden: { y: "105%" },
  show: { y: "0%", transition: { duration: 0.85, ease: EASE } },
};

const FIGS = [
  { cls: "fig-main", src: "/screens/dashboard.png", alt: "Achievia dashboard with the Question of the Day", cap: "Fig. 1", label: "Question of the Day", delay: 0.5, rot: -1.5, priority: true },
  { cls: "fig-left", src: "/screens/question-bank.png", alt: "Question bank showing a rationale", cap: "Fig. 2", label: "Answer + rationale", delay: 0.7, rot: 4, priority: true },
  { cls: "fig-right", src: "/screens/progress.png", alt: "Progress screen with daily study time and streaks", cap: "Fig. 3", label: "Daily progress", delay: 0.9, rot: 3, priority: true },
];

export default function Hero() {
  return (
    <section className="hero">
      <div className="container hero-grid">
        <m.div className="hero-copy" variants={container} initial="hidden" animate="show">
          <m.p variants={rise} className="mono-label">
            <span className="dot-live" /> Review booklet · Medical Technology Licensure
          </m.p>

          <h1 aria-label="Your future RMT starts with smarter review.">
            {LINES.map((l, n) => (
              <span className="mask-line" key={l} aria-hidden="true">
                <m.span variants={mask}>
                  {n === 1 ? (
                    <>
                      <span className="circled">
                        RMT
                        <svg viewBox="0 0 220 90" preserveAspectRatio="none" aria-hidden="true">
                          <m.path
                            d="M16 46 C 12 16, 80 6, 118 8 C 170 10, 212 24, 206 48 C 200 74, 130 84, 84 82 C 38 80, 8 68, 18 40"
                            fill="none"
                            strokeWidth="4"
                            strokeLinecap="round"
                            vectorEffect="non-scaling-stroke"
                            variants={{ hidden: { pathLength: 0 }, show: { pathLength: 1, transition: { duration: 1, delay: 0.9, ease: EASE } } }}
                          />
                        </svg>
                      </span>{" "}
                      starts
                    </>
                  ) : (
                    l
                  )}
                </m.span>
              </span>
            ))}
          </h1>

          <m.p variants={rise} className="lead">
            Question banks, timed mock exams and organized reviewers for the Medical Technologist
            Licensure Examination, with progress tracking, in one app.
          </m.p>

          <m.div variants={rise} className="cta">
            <a className="btn btn-lg" href={SITE.playStoreUrl} rel="noopener">
              Download for Android
            </a>
            <a className="link-arrow" href="#features">
              See what is inside <span aria-hidden="true">↓</span>
            </a>
          </m.div>

          <m.aside variants={rise} className="quiz" aria-label="A sample question">
            <p className="quiz-q"><b>Q1.</b> Where should your MTLE review live?</p>
            <ul>
              <li><b className="bub">A</b> Twenty scattered files</li>
              <li><b className="bub">B</b> Three group chats</li>
              <li className="picked"><b className="bub">C</b> One app. Achievia.</li>
              <li><b className="bub">D</b> Cramming the night before</li>
            </ul>
          </m.aside>
        </m.div>

        <div className="collage" aria-label="Screens from the Achievia app">
          {FIGS.map((f) => (
            <m.figure
              key={f.cls}
              className={`fig ${f.cls}`}
              initial={{ opacity: 0, y: 70, rotate: f.rot * 3 }}
              animate={{ opacity: 1, y: 0, rotate: f.rot }}
              transition={{ duration: 1, delay: f.delay, ease: EASE }}
            >
              <div className="fig-img">
                <Image src={f.src} alt={f.alt} width={1080} height={2400} sizes="(max-width: 700px) 60vw, 280px" priority={f.priority} quality={80} />
              </div>
              <figcaption><b>{f.cap}</b> {f.label}</figcaption>
            </m.figure>
          ))}
        </div>
      </div>
    </section>
  );
}
