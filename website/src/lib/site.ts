export const SITE = {
  name: "Achievia",
  tagline: "Awaken Academic Ambition",
  description:
    "Achievia is the MTLE review app for Medical Technology board examinees: question bank, mock boards, reviewers, supplementals, Mother Notes and progress tracking in one place.",
  url: "https://achievia.app", // TODO: replace with your real domain
  // TODO: replace with the real support / privacy contact address before publishing
  contactEmail: "support@achievia.app",
  // TODO: replace with the Google Play listing URL once published
  playStoreUrl: "https://play.google.com/store/search?q=achievia&c=apps",
  lastUpdated: "October 16, 2026",
};

export const NAV = [
  { href: "#features", label: "The answer key" },
  { href: "#how", label: "How it works" },
  { href: "#pricing", label: "Pricing" },
  { href: "#faq", label: "FAQs" },
];

// Source of truth: supabase/proposed/20261014000000_paymongo_payments.sql (billing_plans)
export const PLANS = [
  { code: "sub_1m", label: "1 Month", months: 1, price: 299 },
  { code: "sub_3m", label: "3 Months", months: 3, price: 599 },
  { code: "sub_6m", label: "6 Months", months: 6, price: 999 },
  { code: "sub_12m", label: "12 Months", months: 12, price: 1699, featured: true },
];

export const peso = (n: number) => `₱${n.toLocaleString("en-PH")}`;
