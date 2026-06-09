import SwiftUI

// MARK: - QuestionPromptView

/// Kind-aware question prompt card. Replaces the hardcoded "large kanji" display
/// in MainView so all QuestionKind types render correctly.
///
/// Layout types:
///  • singleWord  — kanji / compound / yojijukugo / synonym target / radical
///  • sentence    — cloze / errorcorrection / proverb (scrollable text)
struct QuestionPromptView: View {
    let question: Question
    let scale: CGFloat
    let isCorrect: Bool
    let isWrong: Bool

    @EnvironmentObject private var playFontManager: PlayFontManager

    private var corner: CGFloat   { scaled(24, min: 16) }
    private var cardHeight: CGFloat {
        question.isSentenceKind ? scaled(164, min: 130) : scaled(180, min: 144)
    }

    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: corner)
                .fill(OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                )
                .shadow(
                    color: .black.opacity(0.2),
                    radius: scaled(16, min: 8),
                    y: scaled(8, min: 4)
                )

            // Feedback flash
            if isCorrect {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.accentCorrect.opacity(0.25))
                    .transition(.opacity)
            } else if isWrong {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.accentWrong.opacity(0.25))
                    .transition(.opacity)
            }

            // Prompt content
            Group {
                if question.isSentenceKind {
                    sentenceContent
                } else if question.kind == .yojijukugo {
                    yojijukugoContent
                } else {
                    singleWordContent
                }
            }
            .id(question.id)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .frame(height: cardHeight)
    }

    // MARK: - Single Word / Kanji Layout

    private var singleWordContent: some View {
        VStack(spacing: scaled(6, min: 4)) {
            Text(question.displayPrompt)
                .font(playFontManager.font(size: scaled(108, min: 80), weight: .black))
                .foregroundColor(OniTanTheme.textPrimary)
                .minimumScaleFactor(0.3)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .shadow(color: .black.opacity(0.3), radius: 4)
                .padding(scaled(16, min: 8))
        }
    }

    // MARK: - Yojijukugo Layout (highlights □)

    private var yojijukugoContent: some View {
        let yoji = question.payload?.yoji ?? question.displayPrompt
        let fontSize = scaled(72, min: 56)

        return HStack(spacing: 2) {
            ForEach(Array(yoji.enumerated()), id: \.offset) { _, char in
                Text(String(char))
                    .font(playFontManager.font(size: fontSize, weight: .black))
                    .foregroundColor(
                        String(char) == "□"
                            ? OniTanTheme.accentPrimary
                            : OniTanTheme.textPrimary
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3)
            }
        }
        .minimumScaleFactor(0.4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(scaled(16, min: 8))
    }

    // MARK: - Sentence Layout (cloze / errorcorrection / proverb)

    private var sentenceContent: some View {
        ScrollView {
            Text(question.displayPrompt)
                .font(playFontManager.font(size: scaled(22, min: 17), weight: .medium))
                .foregroundColor(OniTanTheme.textPrimary)
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(scaled(18, min: 12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper

    private func scaled(_ value: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, value * scale)
    }
}
