import SwiftUI

// MARK: - Progress Ring Component
// Reusable circular progress indicator used on HomeView and StageSelectView.

struct ProgressRingView: View {
    let progress: Double          // 0.0 – 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let gradient: Gradient
    var label: String? = nil

    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 56,
        gradient: Gradient = Gradient(colors: [OniTanTheme.accentPrimary, OniTanTheme.accentCorrect]),
        label: String? = nil
    ) {
        self.progress = max(0, min(1, progress))
        self.lineWidth = lineWidth
        self.size = size
        self.gradient = gradient
        self.label = label
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: lineWidth)

            // Fill
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(gradient: gradient, center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            // Center label
            if let label {
                Text(label)
                    .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)
            } else {
                Text(progressText)
                    .font(.system(size: size * 0.22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .accessibilityHidden(true)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue(progressText)
    }

    private var progressText: String {
        "\(Int(progress * 100))%"
    }

    private var accessibilityDescription: String {
        "進捗"
    }
}

// MARK: - Stage Progress Ring (composite)

struct StageProgressRing: View {
    let stageNumber: Int
    let cleared: Bool
    let progress: Double   // weak-point ratio or cleared indicator

    var body: some View {
        ZStack {
            ProgressRingView(
                progress: cleared ? 1.0 : progress,
                lineWidth: 5,
                size: 48,
                gradient: cleared
                    ? Gradient(colors: [OniTanTheme.accentCorrect, Color(red: 0.0, green: 0.9, blue: 0.5)])
                    : Gradient(colors: [OniTanTheme.accentPrimary, OniTanTheme.accentWeak])
            )

            if cleared {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(OniTanTheme.accentCorrect)
            } else {
                Text("S\(stageNumber)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("ステージ\(stageNumber)")
        .accessibilityValue(cleared ? "クリア済み" : "進行中 \(Int(progress * 100))%")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OniTanTheme.backgroundGradientFallback.ignoresSafeArea()
        VStack(spacing: 24) {
            ProgressRingView(progress: 0.7, size: 80)
            ProgressRingView(progress: 1.0, size: 64, label: "完了")
            HStack(spacing: 16) {
                StageProgressRing(stageNumber: 1, cleared: true, progress: 1.0)
                StageProgressRing(stageNumber: 2, cleared: false, progress: 0.4)
                StageProgressRing(stageNumber: 3, cleared: false, progress: 0.0)
            }
        }
    }
}
