"use client";

import { m } from "motion/react";
import { EASE } from "./MotionProvider";

const STEPS = [
  { title: "Create your account", text: "Set up your profile, school and target exam date so your review is built around you." },
  { title: "Review and practice", text: "Work through the question bank, study materials and timed mock exams, one subject at a time." },
  { title: "Track your progress", text: "See your streaks and study time, spot weak areas and walk into the boards prepared." },
];

export default function Steps() {
  return (
    <ol className="steps">
      {STEPS.map((s, n) => (
        <m.li
          key={s.title}
          className="step"
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "0px 0px -12% 0px" }}
          transition={{ duration: 0.7, delay: n * 0.1, ease: EASE }}
        >
          <span className="step-n" aria-hidden="true">{n + 1}</span>
          <div className="step-body">
            <h3>{s.title}</h3>
            <p>{s.text}</p>
          </div>
          <svg className="step-box" viewBox="0 0 48 48" aria-hidden="true">
            <rect x="3" y="3" width="42" height="42" rx="6" fill="none" strokeWidth="2.5" />
            <m.path
              d="M12 25 L21 34 L37 13"
              fill="none"
              strokeWidth="5"
              strokeLinecap="round"
              strokeLinejoin="round"
              initial={{ pathLength: 0 }}
              whileInView={{ pathLength: 1 }}
              viewport={{ once: true, margin: "0px 0px -12% 0px" }}
              transition={{ duration: 0.6, delay: 0.5 + n * 0.25, ease: EASE }}
            />
          </svg>
        </m.li>
      ))}
    </ol>
  );
}
