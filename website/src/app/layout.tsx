import type { Metadata, Viewport } from "next";
import { Fraunces, Geist, Geist_Mono, Poppins } from "next/font/google";
import Footer from "@/components/Footer";
import MotionProvider from "@/components/MotionProvider";
import Nav from "@/components/Nav";
import PromoPopup from "@/components/PromoPopup";
import ScrollProgress from "@/components/ScrollProgress";
import Splash from "@/components/Splash";
import { SITE } from "@/lib/site";
import "./site.css";

const display = Fraunces({ subsets: ["latin"], display: "swap", variable: "--font-display", axes: ["opsz"] });
const sans = Geist({ subsets: ["latin"], display: "swap", variable: "--font-sans" });
const mono = Geist_Mono({ subsets: ["latin"], display: "swap", variable: "--font-mono" });
const brand = Poppins({ subsets: ["latin"], weight: ["500", "700"], display: "swap", variable: "--font-brand" });

const TITLE = `${SITE.name} — MTLE Review App for Medical Technology Students`;

export const metadata: Metadata = {
  metadataBase: new URL(SITE.url),
  title: { default: TITLE, template: `%s | ${SITE.name}` },
  description: SITE.description,
  alternates: { canonical: "/" },
  openGraph: {
    title: TITLE,
    description: SITE.description,
    type: "website",
    siteName: SITE.name,
    url: SITE.url,
    images: [{ url: "/screens/dashboard.png", width: 1080, height: 2400, alt: "Achievia app dashboard" }],
  },
  twitter: { card: "summary", title: TITLE, description: SITE.description },
};

export const viewport: Viewport = { themeColor: "#F4F0E6", width: "device-width", initialScale: 1 };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${display.variable} ${sans.variable} ${mono.variable} ${brand.variable}`}>
      <body>
        <a href="#main" className="skip">Skip to content</a>
        <Splash />
        <ScrollProgress />
        <Nav />
        <MotionProvider>
          <main id="main">{children}</main>
        </MotionProvider>
        <Footer />
        <PromoPopup />
      </body>
    </html>
  );
}
