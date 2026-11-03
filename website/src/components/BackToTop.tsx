"use client";

export default function BackToTop() {
  return (
    <button
      className="to-top"
      onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
      aria-label="Back to top"
    >
      Back to top ↑
    </button>
  );
}
