"use client";

import type { CSSProperties } from "react";
import { useEffect, useMemo, useState } from "react";

function clamp(value: number, min: number, max: number) {
  return Math.min(Math.max(value, min), max);
}

export function HeroInteractiveStage() {
  const [pointer, setPointer] = useState({ x: 50, y: 24 });
  const [reducedMotion, setReducedMotion] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
    const updateMotionPreference = () => setReducedMotion(mediaQuery.matches);

    updateMotionPreference();
    mediaQuery.addEventListener("change", updateMotionPreference);

    return () => mediaQuery.removeEventListener("change", updateMotionPreference);
  }, []);

  useEffect(() => {
    if (reducedMotion) {
      return;
    }

    const onPointerMove = (event: PointerEvent) => {
      const x = (event.clientX / window.innerWidth) * 100;
      const y = (event.clientY / window.innerHeight) * 100;

      setPointer({
        x: clamp(x, 0, 100),
        y: clamp(y, 0, 100),
      });
    };

    window.addEventListener("pointermove", onPointerMove, { passive: true });

    return () => window.removeEventListener("pointermove", onPointerMove);
  }, [reducedMotion]);

  const spotlightStyle = useMemo(
    () =>
      ({
        "--spotlight-x": `${pointer.x}%`,
        "--spotlight-y": `${pointer.y}%`,
      }) as CSSProperties,
    [pointer.x, pointer.y],
  );

  return (
    <div className="hero-stage" style={spotlightStyle}>
      <div className="hero-stage__spotlight" aria-hidden="true" />
      <div className="hero-stage__grid" aria-hidden="true" />
      <div className="hero-stage__barcode" aria-hidden="true">
        {Array.from({ length: 18 }).map((_, index) => (
          <span
            key={index}
            className="hero-stage__barcode-line"
            style={
              {
                "--line-height": `${38 + ((index * 17) % 46)}%`,
                "--line-delay": `${index * 120}ms`,
                "--line-opacity": `${0.16 + ((index % 5) * 0.08)}`,
              } as CSSProperties
            }
          />
        ))}
      </div>

      <div className="hero-phone">
        <div className="hero-phone__glow" aria-hidden="true" />
        <div className="hero-phone__shell">
          <div className="hero-phone__topbar">
            <span className="hero-phone__camera" />
            <span className="hero-phone__brand">LabelWise</span>
          </div>

          <div className="hero-phone__screen">
            <div className="hero-phone__scan">
              <div className="hero-phone__scan-title">Barkod tarandı</div>
              <div className="hero-phone__scan-product">Fındık kreması</div>
              <div className="hero-phone__scan-bars" aria-hidden="true">
                {Array.from({ length: 20 }).map((_, index) => (
                  <span
                    key={index}
                    className="hero-phone__scan-bar"
                    style={
                      {
                        "--bar-height": `${28 + ((index * 11) % 45)}px`,
                      } as CSSProperties
                    }
                  />
                ))}
              </div>
            </div>

            <div className="hero-phone__score-card">
              <div>
                <p className="hero-phone__eyebrow">LabelWise skoru</p>
                <h3>74 / 100</h3>
              </div>
              <span className="hero-phone__score-pill">Dengeli seçim</span>
            </div>

            <div className="hero-phone__insight-grid">
              <article className="hero-phone__mini-card">
                <p>Şeker</p>
                <strong>Orta</strong>
              </article>
              <article className="hero-phone__mini-card">
                <p>İçerik</p>
                <strong>Sade değil</strong>
              </article>
              <article className="hero-phone__mini-card hero-phone__mini-card--accent">
                <p>AI notu</p>
                <strong>Günlük değil</strong>
              </article>
            </div>

            <div className="hero-phone__summary-card">
              <p className="hero-phone__eyebrow">AI destekli özet</p>
              <p>
                Şeker oranı ve işlenmiş içerik seviyesi nedeniyle ara sıra tercih
                etmek daha mantıklı olabilir.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
