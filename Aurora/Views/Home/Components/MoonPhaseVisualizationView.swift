//
//  MoonPhaseVisualizationView.swift
//  Aurora
//
//  Accurate moon phase visualization with texture and shadow
//

import SwiftUI

struct MoonPhaseVisualizationView: View {
  let moonInfo: MoonPhase.MoonInfo
  @State private var animateGlow = false

  // Is the moon waxing (growing) or waning (shrinking)?
  private var isWaxing: Bool {
    moonInfo.age < 14.765  // Half of lunar cycle (~29.53 days)
  }

  var body: some View {
    ZStack {
      // Subtle outer glow
      Circle()
        .fill(
          RadialGradient(
            colors: [
              Color.white.opacity(0.1 * (moonInfo.illumination / 100)),
              Color.white.opacity(0.03),
              Color.clear,
            ],
            center: .center,
            startRadius: 90,
            endRadius: 150
          )
        )
        .frame(width: 300, height: 300)
        .blur(radius: 20)
        .opacity(animateGlow ? 0.6 : 1.0)

      // Moon with accurate phase shadow
      MoonWithPhase(
        illumination: moonInfo.illumination,
        isWaxing: isWaxing
      )
      .frame(width: 200, height: 200)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
        animateGlow = true
      }
    }
  }
}

// MARK: - Moon With Phase
// Renders the moon texture with accurate shadow overlay

private struct MoonWithPhase: View {
  let illumination: Double  // 0-100%
  let isWaxing: Bool

  var body: some View {
    ZStack {
      // Moon texture
      Image("8k_moon")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .clipShape(Circle())

      // Accurate shadow overlay
      GeometryReader { geo in
        let size = geo.size
        let radius = min(size.width, size.height) / 2
        let illuminationFraction = illumination / 100.0

        Canvas { context, canvasSize in
          let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

          // Create shadow path based on phase
          var shadowPath = Path()

          if illuminationFraction <= 0.01 {
            // New moon - full shadow
            shadowPath.addEllipse(in: CGRect(origin: .zero, size: canvasSize))
          } else if illuminationFraction >= 0.99 {
            // Full moon - no shadow
            return
          } else {
            // Partial phase
            // We draw the shadow covering the dark part.

            // Calculate width 'w' of the terminator from center.
            // w goes from R (New) to 0 (Quarter) to -R (Full).
            // Actually, cos(0) = 1 (Full width?).
            // For New Moon (illum=0), cos(0) = 1. Terminator at +R?
            // If shadow is "full", terminator is at edge.
            // Wait.
            // Illum 0 -> Dark. Terminator at Right Edge (if Lit from Left?)
            // If Waxing (Lit Right), Shadow is Left.
            // Illum 0 (New): Shadow covers All. Terminator at Right Edge (Center + R).
            // Eq: cos(0) = 1. w = R. Correct.
            // Illum 0.5 (Quarter): Shadow covers Left Half. Terminator at Center (0).
            // Eq: cos(pi/2) = 0. w = 0. Correct.
            // Illum 1.0 (Full): Shadow covers None. Terminator at Left Edge (Center - R).
            // Eq: cos(pi) = -1. w = -R. Correct.

            let w = cos(illuminationFraction * .pi) * radius
            let k: CGFloat = 0.55228475  // Approximate circle constant for Bezier

            if isWaxing {
              // Waxing: Light Right, Shadow Left.
              // Shadow Shape: Left Arc + Terminator (Bottom -> Top)

              shadowPath.move(to: CGPoint(x: center.x, y: center.y - radius))  // Top

              // 1. Left Semicircle Arc (Top -> Left -> Bottom)
              shadowPath.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                clockwise: true
              )
              // Current point is Bottom (center.x, center.y + radius)

              // 2. Terminator (Bottom -> Equator -> Top)
              // We approximate the semi-ellipse with two cubic bezier curves.

              // Curve 1: Bottom to Equator (center.x + w, center.y)
              // Start: (center.x, center.y + radius)
              // End:   (center.x + w, center.y)
              // CP1:   (center.x + w * k, center.y + radius) -- Horizontal tangent approx? No.
              // Tangent at Bottom is Horizontal. So CP1.y = Start.y
              // CP1 = (center.x + w * k, center.y + radius) matches quarter ellipse logic.
              // CP2:   (center.x + w, center.y + radius * k) -- Vertical tangent at Equator.

              shadowPath.addCurve(
                to: CGPoint(x: center.x + w, y: center.y),
                control1: CGPoint(x: center.x + w * k, y: center.y + radius),
                control2: CGPoint(x: center.x + w, y: center.y + radius * k)
              )

              // Curve 2: Equator to Top
              // Start: (center.x + w, center.y)
              // End:   (center.x, center.y - radius)
              // CP1:   (center.x + w, center.y - radius * k) -- Vertical tangent
              // CP2:   (center.x + w * k, center.y - radius) -- Horizontal tangent

              shadowPath.addCurve(
                to: CGPoint(x: center.x, y: center.y - radius),
                control1: CGPoint(x: center.x + w, y: center.y - radius * k),
                control2: CGPoint(x: center.x + w * k, y: center.y - radius)
              )

            } else {
              // Waning: Light Left, Shadow Right.
              // Shadow Shape: Right Arc + Terminator (Bottom -> Top)
              // Note: w is same formula.
              // Illum 0.1 (Crescent Moon, Gibbous Shadow).
              // w = cos(0.1pi) ~ 0.95R.
              // Shadow should cover Right Half + Bulge to Left.
              // Right Arc covers Right Half.
              // Terminator should go through (-w)?
              // If Light is on Left, Shadow is on Right.
              // Terminator boundaries:
              // Illum 0 (New): Shadow All. Terminator Left Edge (-R).
              // Eq: cos(0)=1. w=R.
              // We need -R. So use -w.
              // Illum 0.5 (Quarter): Shadow Right Half. Terminator Center (0).
              // Eq: w=0. Correct.
              // Illum 1.0 (Full): Shadow None. Terminator Right Edge (+R).
              // Eq: w=-R. We need +R. So -w.

              let waningW = -w

              shadowPath.move(to: CGPoint(x: center.x, y: center.y - radius))

              // 1. Right Semicircle Arc (Top -> Right -> Bottom)
              shadowPath.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                clockwise: false
              )

              // 2. Terminator (Bottom -> Equator -> Top)

              // Curve 1: Bottom to Equator
              shadowPath.addCurve(
                to: CGPoint(x: center.x + waningW, y: center.y),
                control1: CGPoint(x: center.x + waningW * k, y: center.y + radius),
                control2: CGPoint(x: center.x + waningW, y: center.y + radius * k)
              )

              // Curve 2: Equator to Top
              shadowPath.addCurve(
                to: CGPoint(x: center.x, y: center.y - radius),
                control1: CGPoint(x: center.x + waningW, y: center.y - radius * k),
                control2: CGPoint(x: center.x + waningW * k, y: center.y - radius)
              )
            }

            shadowPath.closeSubpath()
          }

          // Fill shadow
          context.fill(shadowPath, with: .color(Color(white: 0.015)))
        }
      }
      .clipShape(Circle())
    }
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()

    VStack(spacing: 20) {
      MoonPhaseVisualizationView(moonInfo: MoonPhase.getInfo())

      Text("Current: \(MoonPhase.current().rawValue) - \(Int(MoonPhase.illumination()))%")
        .foregroundStyle(.white)
        .font(.caption)

      HStack(spacing: 30) {
        // Waxing Crescent
        VStack {
          MoonWithPhase(illumination: 25, isWaxing: true).frame(width: 50, height: 50)
          Text("25%").foregroundStyle(.gray).font(.caption2)
        }
        // First Quarter
        VStack {
          MoonWithPhase(illumination: 50, isWaxing: true).frame(width: 50, height: 50)
          Text("50%").foregroundStyle(.gray).font(.caption2)
        }
        // Waxing Gibbous
        VStack {
          MoonWithPhase(illumination: 75, isWaxing: true).frame(width: 50, height: 50)
          Text("75%").foregroundStyle(.gray).font(.caption2)
        }
      }
    }
  }
}
