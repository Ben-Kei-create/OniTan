import SwiftUI

// MARK: - QuestionPromptView

/// Kind-aware question prompt card covering all Kanken Pre-1 exam formats.
///
/// Layout routing:
///  • yojijukugo       — 4-char HStack, □ in accent colour
///  • commonKanji      — blank-term chips side by side
///  • compoundReadingKun — compound with target kanji highlighted
///  • hyogaiReading    — word/compound + optional context line
///  • sentenceReading  — sentence context + target badge
///  • sentence kinds   — scrollable sentence text (errorCorrection, proverb, passage*)
///  • default          — single word/compound at large size
struct QuestionPromptView: View {
    let question: Question
    let scale: CGFloat
    let isCorrect: Bool
    let isWrong: Bool

    @EnvironmentObject private var playFontManager: PlayFontManager
    @State private var meaningPopoverTerm: TermMeaningInfo? = nil

    private var corner: CGFloat { scaled(24, min: 16) }

    private var cardHeight: CGFloat {
        switch question.kind {
        case .sentenceReading:
            return scaled(174, min: 140)
        case .passageReading, .passageVocabulary:
            return scaled(190, min: 152)
        case .errorCorrection, .proverb:
            return scaled(150, min: 122)
        default:
            return scaled(164, min: 132)
        }
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
                .shadow(color: .black.opacity(0.2), radius: scaled(16, min: 8), y: scaled(8, min: 4))

            // Answer feedback flash
            if isCorrect {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.accentCorrect.opacity(0.25))
                    .transition(.opacity)
            } else if isWrong {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.accentWrong.opacity(0.25))
                    .transition(.opacity)
            }

            // Animated feedback icon (checkmark / xmark) for clearer correct/incorrect cues
            if isCorrect || isWrong {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: scaled(54, min: 38), weight: .bold))
                            .foregroundColor(isCorrect ? OniTanTheme.accentCorrect : OniTanTheme.accentWrong)
                            .shadow(color: .black.opacity(0.25), radius: 6)
                            .accessibilityHidden(true)
                    }
                    Spacer()
                }
                .padding(scaled(14, min: 10))
                .transition(.scale(scale: 0.4).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isCorrect)
            }

            // Prompt content (lazy-switch on kind)
            Group {
                switch question.kind {
                case .yojijukugo:
                    yojijukugoContent
                case .commonKanji:
                    commonKanjiContent
                case .compoundReadingKun:
                    compoundReadingKunContent
                case .hyogaiReading:
                    hyogaiReadingContent
                case .sentenceReading:
                    sentenceReadingContent
                case .errorCorrection, .proverb,
                     .passageReading, .passageVocabulary:
                    sentenceContent
                default:
                    singleWordContent
                }
            }
            .id(question.id)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))

            // Kind label badge (top-left, subtle)
            VStack {
                HStack {
                    kindBadge
                    Spacer()
                }
                Spacer()
            }
            .padding(scaled(10, min: 7))
        }
        .frame(height: cardHeight)
    }

    // MARK: - Kind Badge

    private var kindBadge: some View {
        HStack(spacing: 3) {
            Text(question.kind.sealMark)
                .font(.system(size: scaled(9, min: 7), weight: .black, design: .serif))
            Text(question.kind.displayName)
                .font(.system(size: scaled(9, min: 7), weight: .medium, design: .rounded))
        }
        .foregroundColor(OniTanTheme.textTertiary.opacity(0.6))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(OniTanTheme.cardBackground.opacity(0.5))
        .clipShape(Capsule())
    }

    // MARK: - Default: Single Word / Compound

    private var singleWordContent: some View {
        Text(question.displayPrompt)
            .font(playFontManager.font(size: scaled(108, min: 80), weight: .black))
            .foregroundColor(OniTanTheme.textPrimary)
            .minimumScaleFactor(0.25)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .shadow(color: .black.opacity(0.3), radius: 4)
            .padding(scaled(16, min: 8))
    }

    // MARK: - Yojijukugo: 4-char HStack, □ highlighted

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

    // MARK: - Common Kanji: blank-term chips

    private var commonKanjiContent: some View {
        let terms = question.payload?.blankTerms ?? [question.displayPrompt]
        let fontSize = scaled(34, min: 24)

        return VStack(spacing: scaled(6, min: 4)) {
            HStack(spacing: scaled(12, min: 8)) {
                ForEach(terms.prefix(4), id: \.self) { term in
                    Text(term)
                        .font(playFontManager.font(size: fontSize, weight: .black))
                        .foregroundColor(OniTanTheme.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, scaled(8, min: 5))
                        .padding(.vertical, scaled(5, min: 3))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(OniTanTheme.accentPrimary.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(OniTanTheme.accentPrimary.opacity(0.25), lineWidth: 1)
                                )
                        )
                }
            }
            Text("共通する漢字は？")
                .font(playFontManager.font(size: scaled(12, min: 10), weight: .medium))
                .foregroundColor(OniTanTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(scaled(14, min: 8))
    }

    // MARK: - Compound Reading Kun: highlight target kanji

    private var compoundReadingKunContent: some View {
        let compound = question.payload?.targetCompound ?? question.displayPrompt
        let targetChar = question.payload?.targetKanjiInCompound
        let fontSize = scaled(68, min: 52)

        return VStack(spacing: scaled(6, min: 4)) {
            HStack(spacing: 2) {
                ForEach(Array(compound.enumerated()), id: \.offset) { _, char in
                    let charStr = String(char)
                    let isTarget = targetChar.map { $0 == charStr } ?? false
                    Text(charStr)
                        .font(playFontManager.font(size: fontSize, weight: .black))
                        .foregroundColor(isTarget ? OniTanTheme.accentPrimary : OniTanTheme.textPrimary)
                        .shadow(color: .black.opacity(0.3), radius: 3)
                }
            }
            .minimumScaleFactor(0.4)

            if targetChar != nil {
                Text("下線の漢字の読みは？")
                    .font(playFontManager.font(size: scaled(12, min: 10), weight: .medium))
                    .foregroundColor(OniTanTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(scaled(16, min: 8))
    }

    // MARK: - Hyogai Reading: word + optional context

    private var hyogaiReadingContent: some View {
        VStack(spacing: scaled(6, min: 4)) {
            Text(question.kanji)
                .font(playFontManager.font(size: scaled(80, min: 60), weight: .black))
                .foregroundColor(OniTanTheme.textPrimary)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 4)

            if let ctx = question.payload?.sentenceContext, !ctx.isEmpty {
                Text(ctx)
                    .font(playFontManager.font(size: scaled(14, min: 11), weight: .regular))
                    .foregroundColor(OniTanTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(scaled(16, min: 8))
    }

    // MARK: - Sentence Reading: sentence context + target

    private var sentenceReadingContent: some View {
        let context = question.payload?.sentenceContext ?? question.displayPrompt
        let target = question.kanji
        let bodyFont = playFontManager.font(size: scaled(22, min: 17), weight: .medium)
        let meaning = question.termMeaning

        return VStack(alignment: .leading, spacing: scaled(12, min: 8)) {
            if let range = context.range(of: target) {
                Text(attributedSentence(context: context, targetRange: range, bodyFont: bodyFont, linkable: meaning != nil))
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.openURL, OpenURLAction { url in
                        guard url.scheme == "onitan-meaning", let meaning else { return .systemAction }
                        meaningPopoverTerm = TermMeaningInfo(word: target, meaning: meaning)
                        return .handled
                    })

                if meaning != nil {
                    Text("下線部をタップすると意味を表示します")
                        .font(playFontManager.font(size: scaled(11, min: 9), weight: .medium))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
            } else {
                Text(target)
                    .font(playFontManager.font(size: scaled(26, min: 20), weight: .black))
                    .foregroundColor(OniTanTheme.accentWeak)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)

                Text(context)
                    .font(bodyFont)
                    .foregroundColor(OniTanTheme.textPrimary)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(scaled(18, min: 12))
        .popover(item: $meaningPopoverTerm) { item in
            meaningPopoverContent(word: item.word, meaning: item.meaning)
        }
    }

    /// Builds an AttributedString for the sentence with the target compound underlined
    /// and styled, optionally wired as a tappable link to reveal its meaning.
    private func attributedSentence(context: String, targetRange: Range<String.Index>, bodyFont: Font, linkable: Bool) -> AttributedString {
        var result = AttributedString(String(context[context.startIndex..<targetRange.lowerBound]))
        result.font = bodyFont
        result.foregroundColor = OniTanTheme.textPrimary

        var targetAttr = AttributedString(String(context[targetRange]))
        targetAttr.font = playFontManager.font(size: scaled(22, min: 17), weight: .black)
        targetAttr.foregroundColor = OniTanTheme.accentWeak
        targetAttr.underlineStyle = .single
        if linkable {
            targetAttr.link = URL(string: "onitan-meaning:///term")
        }
        result += targetAttr

        var trailing = AttributedString(String(context[targetRange.upperBound...]))
        trailing.font = bodyFont
        trailing.foregroundColor = OniTanTheme.textPrimary
        result += trailing

        return result
    }

    private func meaningPopoverContent(word: String, meaning: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word)
                .font(playFontManager.font(size: 18, weight: .black))
                .foregroundColor(OniTanTheme.accentWeak)
            Text(meaning)
                .font(playFontManager.font(size: 14, weight: .regular))
                .foregroundColor(OniTanTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: 280, alignment: .leading)
    }

    // MARK: - Sentence Layout (errorCorrection, proverb, passage)

    private var sentenceContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // For passage kinds, show the target indicator
                if let target = question.payload?.passageTarget {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: scaled(11, min: 9)))
                            .foregroundColor(OniTanTheme.accentPrimary)
                        Text("第\(target)問")
                            .font(.system(size: scaled(11, min: 9), weight: .semibold, design: .rounded))
                            .foregroundColor(OniTanTheme.accentPrimary)
                    }
                }

                Text(question.displayPrompt)
                    .font(playFontManager.font(size: scaled(19, min: 15), weight: .medium))
                    .foregroundColor(OniTanTheme.textPrimary)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(scaled(18, min: 12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper

    private func scaled(_ value: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, value * scale)
    }
}

// MARK: - TermMeaningInfo

/// Identifiable wrapper for showing a term's meaning in a popover.
struct TermMeaningInfo: Identifiable {
    let id = UUID()
    let word: String
    let meaning: String
}
