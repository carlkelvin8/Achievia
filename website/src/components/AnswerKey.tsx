"use client";

import { AnimatePresence, m } from "motion/react";
import Image from "next/image";
import { useRef, useState } from "react";
import { EASE } from "./MotionProvider";

const ITEMS = [
  {
    k: "A",
    option: "Questions to practice with",
    title: "Question Bank",
    why: "Answer by subject and topic, see the correct choice right away, then read the rationale. Mark items as study again or already known, so your next session starts where you left off.",
    facts: ["Answer feedback with rationale", "Study again / already know", "Built-in focus timer"],
    src: "/screens/question-bank.png",
    alt: "Question bank study mode with an answer and its rationale",
  },
  {
    k: "B",
    option: "A way to rehearse exam day",
    title: "Mock Boards & Pre-Boards",
    why: "Sit a timed subject exam the way the board is run: 100 items, 60 minutes, one question at a time. Your result is saved to your account when you finish.",
    facts: ["100 items per subject exam", "60-minute countdown", "Results saved to your account"],
    src: "/screens/mock-exam.png",
    alt: "Timed subject exam showing question 1 of 100 with a countdown",
  },
  {
    k: "C",
    option: "Reference you can search fast",
    title: "Reviewers & Supplementals",
    why: "Mnemonics, abbreviations and computations are one search away, and anything worth revisiting can be bookmarked for the last week of review.",
    facts: ["Searchable resources", "Mnemonics, abbreviations, computations", "Bookmark favorites"],
    src: "/screens/supplementals.png",
    alt: "Supplementals screen with search and mnemonics",
  },
  {
    k: "D",
    option: "Notes worth keeping",
    title: "Mother Notes",
    why: "Concise study notes sold as a separate one-time, lifetime purchase. They are not part of a subscription, and they do not expire when a subscription does.",
    facts: ["One-time purchase", "Does not expire", "Separate from subscriptions"],
    src: null,
    alt: "",
  },
  {
    k: "E",
    option: "Proof that your routine works",
    title: "Progress Tracking",
    why: "Daily study time and monthly streaks turn good intentions into something you can see, so a slipping week is obvious before it becomes a slipping month.",
    facts: ["Daily study time", "Monthly and longest streaks", "Progress charts"],
    src: "/screens/progress.png",
    alt: "Progress screen with study time chart and streaks",
  },
  {
    k: "F",
    option: "Protection for your study time",
    title: "Pomodoro & Reminders",
    why: "A focus timer with pause and reset, plus daily goals and reminders, so review time is something you schedule instead of something you hope for.",
    facts: ["Focus timer", "Daily goals", "Reminders"],
    src: "/screens/question-bank.png",
    alt: "Study deck with a focus session timer",
    top: true,
  },
];

export default function AnswerKey() {
  const [i, setI] = useState(0);
  const refs = useRef<(HTMLButtonElement | null)[]>([]);
  const cur = ITEMS[i];

  const onKey = (e: React.KeyboardEvent) => {
    let n = i;
    if (e.key === "ArrowDown" || e.key === "ArrowRight") n = (i + 1) % ITEMS.length;
    else if (e.key === "ArrowUp" || e.key === "ArrowLeft") n = (i - 1 + ITEMS.length) % ITEMS.length;
    else return;
    e.preventDefault();
    setI(n);
    refs.current[n]?.focus();
  };

  return (
    <div className="key">
      <div className="key-q">
        <p className="key-prompt">
          <b>Q.</b> Which of these does a board examinee actually need?
        </p>
        <div role="radiogroup" aria-label="Choose what you need" className="key-options" onKeyDown={onKey}>
          {ITEMS.map((it, n) => (
            <button
              key={it.k}
              ref={(el) => {
                refs.current[n] = el;
              }}
              role="radio"
              aria-checked={n === i}
              tabIndex={n === i ? 0 : -1}
              className={`opt ${n === i ? "on" : ""}`}
              onClick={() => setI(n)}
            >
              <span className="bub" aria-hidden="true">{it.k}</span>
              <span className="opt-text">{it.option}</span>
              <span className="opt-arrow" aria-hidden="true">→</span>
            </button>
          ))}
        </div>
        <p className="key-hint">Every option is correct. Pick one to read its rationale.</p>
      </div>

      <div className="key-a" aria-live="polite">
        <AnimatePresence mode="wait" initial={false}>
          <m.div
            key={cur.k}
            className="rationale"
            initial={{ opacity: 0, y: 14 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.3, ease: EASE }}
          >
            <div className="rationale-text">
              <p className="mono-label">Rationale · Option {cur.k}</p>
              <h3>{cur.title}</h3>
              <p className="why">{cur.why}</p>
              <ul className="facts">
                {cur.facts.map((f) => (
                  <li key={f}>{f}</li>
                ))}
              </ul>
            </div>

            {cur.src ? (
              <figure className="fig fig-flat">
                <div className="fig-img">
                  <Image
                    src={cur.src}
                    alt={cur.alt}
                    width={1080}
                    height={2400}
                    sizes="(max-width: 700px) 60vw, 260px"
                    quality={80}
                    style={cur.top ? { objectPosition: "top" } : undefined}
                  />
                </div>
                <figcaption><b>Real screen</b> from the app</figcaption>
              </figure>
            ) : (
              <div className="note-card" aria-hidden="true">
                <span className="note-tag">Lifetime add-on</span>
                <i /><i /><i /><i /><i />
                <b>Bought once. Yours to keep.</b>
              </div>
            )}
          </m.div>
        </AnimatePresence>
      </div>
    </div>
  );
}
