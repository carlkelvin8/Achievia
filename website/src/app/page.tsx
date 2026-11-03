import AnswerKey from "@/components/AnswerKey";
import Faq from "@/components/Faq";
import Hero from "@/components/Hero";
import Pricing from "@/components/Pricing";
import Reveal, { MaskTitle } from "@/components/Reveal";
import Steps from "@/components/Steps";
import { SITE } from "@/lib/site";

const FAQS = [
  {
    q: "Who is Achievia for?",
    a: "Achievia is built for Medical Technology students and graduates preparing for the Medical Technologist Licensure Examination (MTLE).",
  },
  {
    q: "How do subscriptions work?",
    a: "Plans are one-time payments for access of 1, 3, 6 or 12 months. There is no recurring billing or auto-renewal. If you renew while still active, the new period is added on top of your current expiry. New accounts can also start a one-time 7-day free trial inside the app.",
  },
  {
    q: "What features are included?",
    a: "Achievia includes a question bank with rationales, timed subject exams, reviewers and supplementals (mnemonics, abbreviations, computations), progress tracking, and a focus timer with reminders and goals.",
  },
  {
    q: "What are Mother Notes?",
    a: "Mother Notes are Achievia study notes, offered as a separate one-time, lifetime purchase. They are not automatically included in a standard subscription, and once purchased they do not expire with your subscription.",
  },
  {
    q: "Is my data secure?",
    a: "Your account is protected by sign-in with optional multi-factor authentication and biometric unlock on your device. Payments are processed by PayMongo, so card details are never stored by Achievia. Read the details in our Privacy Policy.",
  },
  {
    q: "Can I delete my account?",
    a: `Yes. Email ${SITE.contactEmail} from your registered address with the subject "Delete my Achievia account" and we will process your request. See the Privacy Policy for details.`,
  },
  { q: "How can I contact support?", a: `Email us at ${SITE.contactEmail}.` },
];

const REASONS = [
  { t: "Structured review", d: "Subjects break into topics, so you always know what to study next instead of hunting through scattered files." },
  { t: "Exam-focused practice", d: "Timed 100-item exams train the pacing and endurance the board asks for, with a rationale behind every answer." },
  { t: "Visible progress", d: "Study time and streaks are charted, so it is easy to tell whether your routine is actually holding." },
  { t: "Organized habits", d: "A focus timer, daily goals and reminders turn good intentions into a schedule you can keep." },
  { t: "Confidence you can earn", d: "Every answered question and finished exam is evidence that you showed up for your preparation." },
];

export default function Home() {
  return (
    <>
      <Hero />

      {/* I. ANSWER KEY */}
      <section id="features" className="section">
        <div className="container">
          <Reveal className="sec-label"><span>Section I</span><i /><span>The answer key</span></Reveal>
          <MaskTitle className="sec-title">Six tools, one review.</MaskTitle>
          <AnswerKey />
        </div>
      </section>

      {/* II. RATIONALE */}
      <section id="why" className="section section-paper2">
        <div className="container why-wrap">
          <div className="why-head">
            <Reveal className="sec-label"><span>Section II</span><i /><span>Rationale</span></Reveal>
            <MaskTitle className="sec-title">Why it helps you prepare better.</MaskTitle>
            <Reveal delay={150}>
              <blockquote className="pull">
                “Rest if you must, but do not quit. Your future patients are counting on you.”
                <cite>A daily motivation inside Achievia</cite>
              </blockquote>
            </Reveal>
          </div>
          <ol className="reasons">
            {REASONS.map((r, n) => (
              <Reveal as="li" key={r.t} delay={n * 70} variant="up" className="reason">
                <span className="reason-n" aria-hidden="true">{n + 1}</span>
                <h3>{r.t}</h3>
                <p>{r.d}</p>
              </Reveal>
            ))}
          </ol>
        </div>
      </section>

      {/* III. INSTRUCTIONS */}
      <section id="how" className="section">
        <div className="container">
          <Reveal className="sec-label"><span>Section III</span><i /><span>Instructions</span></Reveal>
          <MaskTitle className="sec-title">Three steps. That is all.</MaskTitle>
          <Steps />
        </div>
      </section>

      {/* IV. FEES */}
      <section id="pricing" className="section section-paper2">
        <div className="container">
          <Reveal className="sec-label"><span>Section IV</span><i /><span>Fee schedule</span></Reveal>
          <MaskTitle className="sec-title">Pay once. No renewals.</MaskTitle>
          <Pricing />
        </div>
      </section>

      {/* V. FAQ */}
      <section id="faq" className="section">
        <div className="container faq-grid">
          <div>
            <Reveal className="sec-label"><span>Section V</span><i /><span>Questions</span></Reveal>
            <MaskTitle className="sec-title">Asked, answered.</MaskTitle>
            <Reveal delay={150}>
              <p className="faq-side">
                Still unsure? Write to <a href={`mailto:${SITE.contactEmail}`}>{SITE.contactEmail}</a>.
              </p>
            </Reveal>
          </div>
          <Faq items={FAQS} />
        </div>
      </section>

      {/* CTA */}
      <section className="final">
        <div className="container final-inner">
          <svg className="final-check" viewBox="0 0 120 120" aria-hidden="true">
            <path d="M14 66 L46 98 L106 22" fill="none" strokeWidth="14" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          <Reveal>
            <h2>Your board exam journey deserves better preparation.</h2>
            <p>
              Build your confidence, master important concepts, and make every study session count
              with Achievia.
            </p>
            <a className="btn btn-lg btn-paper" href={SITE.playStoreUrl} rel="noopener">
              Start Reviewing with Achievia
            </a>
          </Reveal>
        </div>
      </section>
    </>
  );
}
