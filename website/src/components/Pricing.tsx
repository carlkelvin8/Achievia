"use client";

import { m } from "motion/react";
import { PLANS, SITE, peso } from "@/lib/site";
import { EASE } from "./MotionProvider";

export default function Pricing() {
  return (
    <div className="fees">
      <div className="fees-head" aria-hidden="true">
        <span>Plan</span>
        <span>Length of access</span>
        <span>Price</span>
        <span>Per month</span>
        <span />
      </div>

      <ul>
        {PLANS.map((p, n) => (
          <m.li
            key={p.code}
            className={`fee ${p.featured ? "fee-featured" : ""}`}
            initial="hidden"
            whileInView="show"
            viewport={{ once: true, margin: "0px 0px -10% 0px" }}
            variants={{
              hidden: { opacity: 0, x: -24 },
              show: { opacity: 1, x: 0, transition: { duration: 0.7, delay: n * 0.08, ease: EASE } },
            }}
          >
            {p.featured && <span className="stamp" aria-label="Best value, longest access">Best value</span>}
            <h3 className="fee-name">{p.label}</h3>
            <div className="fee-bar" aria-hidden="true">
              <m.span
                variants={{
                  hidden: { scaleX: 0 },
                  show: { scaleX: p.months / 12, transition: { duration: 1, delay: 0.25 + n * 0.1, ease: EASE } },
                }}
              />
            </div>
            <p className="fee-price">{peso(p.price)}</p>
            <p className="fee-per">{peso(Math.round(p.price / p.months))}/mo</p>
            <a className="fee-cta" href={SITE.playStoreUrl} rel="noopener" aria-label={`Get the app, ${p.label} plan`}>
              Get the app <span aria-hidden="true">→</span>
            </a>
          </m.li>
        ))}
        <li className="fee fee-addon">
          <h3 className="fee-name">Mother Notes</h3>
          <p className="fee-addon-text">
            Separate one-time purchase · lifetime access · not included in the plans above. Price is
            shown in the app at checkout.
          </p>
        </li>
      </ul>

      <p className="fees-note">
        One-time payments, no auto-renewal. Renewing while active adds time on top of your current
        expiry. New accounts can start a one-time 7-day free trial in the app. Payments are processed
        by PayMongo. Prices in Philippine pesos.
      </p>
    </div>
  );
}
