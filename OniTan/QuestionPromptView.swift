import SwiftUI

// MARK: - QuestionPromptView

/// Kind-aware question prompt card covering all Kanken Pre-1 exam formats.
///
/// Layout routing:
///  • yojijukugo       — 4-char HStack, □ in accent colour
///  • commonKanji      — blank-term chips side by side
///  • compoundReadingKun — compound with target kanji highlighted
///  • hyogaiReading    — context sentence card with target underline
///  • synonym/antonym  — target word only, with relation-coloured frame
///  • sentenceReading  — context sentence card with target underline
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
    private var isRelationKind: Bool {
        question.kind == .synonym || question.kind == .antonym
    }
    private var isFeedbackVisible: Bool { isCorrect || isWrong }

    private var relationAccent: Color {
        question.kind == .antonym ? Color(hex: "F87171") : Color(hex: "60A5FA")
    }

    private var feedbackAccent: Color {
        isCorrect ? OniTanTheme.feedbackCorrect : OniTanTheme.accentWrong
    }

    private var cardHeight: CGFloat {
        switch question.kind {
        case .sentenceReading, .hyogaiReading:
            return scaled(208, min: 168)
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
                .overlay {
                    if isRelationKind {
                        RoundedRectangle(cornerRadius: corner)
                            .fill(relationAccent.opacity(0.06))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(
                            isFeedbackVisible
                                ? feedbackAccent.opacity(0.64)
                                : (isRelationKind ? relationAccent.opacity(0.5) : OniTanTheme.cardBorder),
                            lineWidth: isFeedbackVisible || isRelationKind ? 1.5 : 1
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: scaled(16, min: 8), y: scaled(8, min: 4))
                .shadow(
                    color: isRelationKind ? relationAccent.opacity(0.14) : .clear,
                    radius: scaled(12, min: 6),
                    y: 0
                )

            // Answer feedback flash
            if isCorrect {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.feedbackCorrect.opacity(0.18))
                    .transition(.opacity)
            } else if isWrong {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.accentWrong.opacity(0.2))
                    .transition(.opacity)
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
                case .synonym, .antonym:
                    synonymAntonymContent
                case .hyogaiReading, .sentenceReading:
                    contextReadingContent
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
        }
        .frame(height: cardHeight)
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

    // MARK: - Synonym / Antonym: target word only

    private var synonymAntonymContent: some View {
        let target = relationTargetWord

        return Text(target)
            .font(playFontManager.font(size: scaled(88, min: 66), weight: .black))
            .foregroundColor(OniTanTheme.textPrimary)
            .minimumScaleFactor(0.35)
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .shadow(color: relationAccent.opacity(0.24), radius: 10)
            .padding(scaled(18, min: 10))
            .accessibilityLabel("\(question.kind.displayName)の対象語: \(target)")
    }

    private var relationTargetWord: String {
        if let target = question.payload?.targetWord?.trimmingCharacters(in: .whitespacesAndNewlines),
           !target.isEmpty {
            return target
        }
        let kanji = question.kanji.trimmingCharacters(in: .whitespacesAndNewlines)
        return kanji.isEmpty ? question.displayPrompt : kanji
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
        let fontSize = scaled(46, min: 32)

        return VStack(spacing: scaled(14, min: 10)) {
            HStack(spacing: scaled(6, min: 4)) {
                Image(systemName: "square.dashed")
                    .font(.system(size: scaled(12, min: 10), weight: .bold))
                    .foregroundColor(OniTanTheme.accentPrimary)
                    .accessibilityHidden(true)

                Text("□に共通して入る漢字は？")
                    .font(.system(size: scaled(12, min: 10), weight: .black, design: .rounded))
                    .foregroundColor(OniTanTheme.accentPrimary)
            }
            .opacity(0.85)

            HStack(spacing: scaled(14, min: 9)) {
                ForEach(terms.prefix(4), id: \.self) { term in
                    HStack(spacing: 1) {
                        ForEach(Array(term.enumerated()), id: \.offset) { _, char in
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
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, scaled(14, min: 9))
                    .padding(.vertical, scaled(10, min: 7))
                    .background(
                        RoundedRectangle(cornerRadius: scaled(14, min: 10))
                            .fill(OniTanTheme.accentPrimary.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: scaled(14, min: 10))
                                    .stroke(OniTanTheme.accentPrimary.opacity(0.28), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(scaled(14, min: 8))
    }

    // MARK: - Compound Reading Kun: highlight target kanji

    private var compoundReadingKunContent: some View {
        let compound = question.payload?.targetCompound ?? question.displayPrompt
        let targetChar = question.payload?.targetKanjiInCompound
        let fontSize = scaled(68, min: 52)

        return HStack(spacing: 2) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(scaled(16, min: 8))
    }

    // MARK: - Context Reading: sentence card + target

    private var contextReadingContent: some View {
        let context = nonEmpty(question.payload?.sentenceContext) ?? question.displayPrompt
        let target = contextReadingTarget
        let bodyFont = playFontManager.font(size: scaled(34, min: 27), weight: .bold)
        let meaning = question.termMeaning

        return VStack(alignment: .leading, spacing: scaled(10, min: 7)) {
            HStack(spacing: scaled(6, min: 4)) {
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: scaled(12, min: 10), weight: .bold))
                    .foregroundColor(OniTanTheme.accentWeak)
                    .accessibilityHidden(true)

                Text(question.kind == .hyogaiReading ? "表外の読み" : "文中の読み")
                    .font(.system(size: scaled(12, min: 10), weight: .black, design: .rounded))
                    .foregroundColor(OniTanTheme.accentWeak)

                Spacer()
            }

            if let range = context.range(of: target) {
                Text(attributedSentence(context: context, targetRange: range, bodyFont: bodyFont, linkable: meaning != nil))
                    .lineSpacing(7)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, scaled(13, min: 10))
                    .padding(.vertical, scaled(13, min: 10))
                    .background(
                        RoundedRectangle(cornerRadius: scaled(14, min: 11))
                            .fill(Color.black.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: scaled(14, min: 11))
                                    .stroke(OniTanTheme.accentWeak.opacity(0.18), lineWidth: 1)
                            )
                    )
                    .environment(\.openURL, OpenURLAction { url in
                        guard url.scheme == "onitan-meaning", let meaning else { return .systemAction }
                        meaningPopoverTerm = TermMeaningInfo(word: target, meaning: meaning)
                        return .handled
                    })
            } else {
                Text(target)
                    .font(playFontManager.font(size: scaled(30, min: 23), weight: .black))
                    .foregroundColor(OniTanTheme.accentWeak)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)

                Text(context)
                    .font(bodyFont)
                    .foregroundColor(OniTanTheme.textPrimary)
                    .lineSpacing(7)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, scaled(13, min: 10))
                    .padding(.vertical, scaled(13, min: 10))
                    .background(
                        RoundedRectangle(cornerRadius: scaled(14, min: 11))
                            .fill(Color.black.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: scaled(14, min: 11))
                                    .stroke(OniTanTheme.accentWeak.opacity(0.18), lineWidth: 1)
                            )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(scaled(18, min: 12))
        .sheet(item: $meaningPopoverTerm) { item in
            meaningSheetContent(word: item.word, meaning: item.meaning)
        }
    }

    /// Builds an AttributedString for the sentence with the target compound underlined
    /// and styled, optionally wired as a tappable link to reveal its meaning.
    private func attributedSentence(context: String, targetRange: Range<String.Index>, bodyFont: Font, linkable: Bool) -> AttributedString {
        var result = AttributedString(String(context[context.startIndex..<targetRange.lowerBound]))
        result.font = bodyFont
        result.foregroundColor = OniTanTheme.textPrimary

        var targetAttr = AttributedString(String(context[targetRange]))
        targetAttr.font = playFontManager.font(size: scaled(25, min: 20), weight: .black)
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

    private func meaningSheetContent(word: String, meaning: String) -> some View {
        NavigationStack {
            ZStack {
                OniTanTheme.backgroundGradientFallback.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 12) {
                    Text(word)
                        .font(playFontManager.font(size: 30, weight: .black))
                        .foregroundColor(OniTanTheme.accentWeak)

                    Text(meaning)
                        .font(playFontManager.font(size: 17, weight: .regular))
                        .foregroundColor(OniTanTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("意味")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        meaningPopoverTerm = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(OniTanTheme.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(Color.black.opacity(0.16))
                            .overlay(Circle().stroke(OniTanTheme.cardBorder, lineWidth: 1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("閉じる")
                }
            }
        }
        .presentationDetents([.fraction(0.35), .medium])
    }

    // MARK: - Sentence Layout (errorCorrection, proverb, passage)

    private var sentenceContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // For passage kinds, show source citation and target indicator
                if question.kind == .passageReading || question.kind == .passageVocabulary {
                    HStack(spacing: 4) {
                        if let source = question.payload?.passageSource, !source.isEmpty {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: scaled(10, min: 8)))
                                .foregroundColor(OniTanTheme.accentWeak)
                            Text(source)
                                .font(.system(size: scaled(10, min: 8), weight: .semibold, design: .rounded))
                                .foregroundColor(OniTanTheme.accentWeak)
                                .lineLimit(1)
                        }

                        Spacer()

                        if let target = question.payload?.passageTarget {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: scaled(11, min: 9)))
                                .foregroundColor(OniTanTheme.accentPrimary)
                            Text("第\(target)問")
                                .font(.system(size: scaled(11, min: 9), weight: .semibold, design: .rounded))
                                .foregroundColor(OniTanTheme.accentPrimary)
                        }
                    }
                } else if let target = question.payload?.passageTarget {
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

    private func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private var contextReadingTarget: String {
        let candidates = [
            question.payload?.targetWord,
            question.payload?.targetKanji,
            question.kanji
        ]

        for candidate in candidates {
            if let value = nonEmpty(candidate) {
                return value
            }
        }
        return question.displayPrompt
    }
}

// MARK: - TermMeaningInfo

/// Identifiable wrapper for showing a term's meaning in a popover.
struct TermMeaningInfo: Identifiable {
    let id = UUID()
    let word: String
    let meaning: String
}
