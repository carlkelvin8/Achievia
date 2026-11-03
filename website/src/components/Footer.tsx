import Link from "next/link";
import { NAV, SITE } from "@/lib/site";
import BackToTop from "./BackToTop";
import Wordmark from "./Wordmark";

export default function Footer() {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-top">
          <div className="footer-brand">
            <div className="brand">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/logo.svg" alt="" width={44} height={44} loading="lazy" />
              <Wordmark />
            </div>
            <p>
              {SITE.tagline}. A review app for Medical Technology board examinees preparing for the
              MTLE.
            </p>
          </div>

          <nav aria-label="Explore">
            <h3 className="mono-label">Explore</h3>
            <ul>
              {NAV.map((n) => (
                <li key={n.href}><a href={`/${n.href}`}>{n.label}</a></li>
              ))}
            </ul>
          </nav>

          <nav aria-label="Support and legal">
            <h3 className="mono-label">Support</h3>
            <ul>
              <li><Link href="/privacy">Privacy Policy</Link></li>
              <li><a href={`mailto:${SITE.contactEmail}`}>{SITE.contactEmail}</a></li>
            </ul>
          </nav>
        </div>

        <div className="footer-bottom">
          <span>© {new Date().getFullYear()} Achievia. All rights reserved.</span>
          <BackToTop />
        </div>
      </div>
    </footer>
  );
}
