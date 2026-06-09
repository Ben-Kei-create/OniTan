import SwiftUI

// MARK: - ExplanationContentView

/// Kind-aware explanation body shown after a correct answer.
/// Covers all Kanken Pre-1 exam question formats.
struct ExplanationContentView: View {
    let question: Question

    @EnvironmentObject private var playFontManager: PlayFontManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            kindSpecificHeader
            Divider().background(Color.white.opacity(0.15))
            explanationBody
        }
    }

    // MARK: - Kind-specific header dispatch

    @ViewBuilder
    private var kindSpecificHeader: some View {
        switch question.kind {
        case .reading, .hyogaiReading:
            readingHeader
        case .compoundReadingKun:
            compoundReadingKunHeader
        case .commonKanji:
            commonKanjiHeader
        case .yojijukugo:
            yojijukugoHeader
        case .synonym, .antonym:
            synonymAntonymHeader
        case .errorCorrection:
            errorCorrectionHeader
        case .proverb:
            proverbHeader
        case .passageReading, .passageVocabulary:
            passageHeader
        case .writingSkipped:
            writingSkippedHeader
        default:
            genericHeader
        }
    }

    // MARK: - Reading (reading, hyogaiReading)

    private var readingHeader: some View {
        VStack(spacing: 8) {
            Text(question.displayPrompt.isEmpty ? question.kanji : question.kanji)
                .font(playFontManager.font(size: 70, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            correctBadge(answer: question.answer)

            if question.kind == .hyogaiReading {
                Text("表外の読み")
                    .font(playFontManager.font(size: 11, weight: .semibold))
                    .foregroundColor(OniTanTheme.accentPrimary.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(OniTanTheme.accentPrimary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Compound Reading Kun

    private var compoundReadingKunHeader: some View {
        let compound = question.payload?.targetCompound ?? question.kanji
        let targetChar = question.payload?.targetKanjiInCompound

        return VStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(Array(compound.enumerated()), id: \.offset) { _, char in
                    let charStr = String(char)
                    let isTarget = targetChar.map { $0 == charStr } ?? false
                    Text(charStr)
                        .font(playFontManager.font(size: 52, weight: .black))
                        .foregroundColor(isTarget
                            ? OniTanTheme.accentPrimary
                            : OniTanTheme.textSecondary)
                }
            }
            .minimumScaleFactor(0.5)

            correctBadge(answer: question.answer)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Common Kanji

    private var commonKanjiHeader: some View {
        let terms = question.payload?.blankTerms ?? []

        return VStack(spacing: 10) {
            // Large answer kanji
            Text(question.answer)
                .font(playFontManager.font(size: 64, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)

            correctBadge(answer: nil)

            // Completed terms
            if !terms.isEmpty {
                HStack(spacing: 10) {
                    ForEach(terms.prefix(4), id: \.self) { term in
                        Text(term.replacingOccurrences(of: "□", with: question.answer))
                            .font(playFontManager.font(size: 16, weight: .bold))
                            .foregroundColor(OniTanTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(OniTanTheme.cardBackground.opacity(0.6))
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Yojijukugo

    private var yojijukugoHeader: some View {
        VStack(spacing: 10) {
            let full: String = {
                guard let yoji = question.payload?.yoji else { return question.displayPrompt }
                return yoji.replacingOccurrences(of: "□", with: question.answer)
            }()
            Text(full)
                .font(playFontManager.font(size: 52, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            correctBadge(answer: question.answer)

            if let meaning = question.payload?.meaning {
                Text(meaning)
                    .font(playFontManager.font(size: 13))
                    .foregroundColor(OniTanTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Synonym / Antonym

    private var synonymAntonymHeader: some View {
        VStack(spacing: 8) {
            if let target = question.payload?.targetWord {
                HStack(spacing: 12) {
                    Text(target)
                        .font(playFontManager.font(size: 40, weight: .bold))
                        .foregroundColor(OniTanTheme.textSecondary)
                    Image(systemName: question.kind == .synonym
                          ? "equal.circle.fill"
                          : "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(OniTanTheme.accentPrimary)
                    Text(question.answer)
                        .font(playFontManager.font(size: 40, weight: .black))
                        .foregroundStyle(OniTanTheme.primaryGradient)
                }
            } else {
                Text(question.answer)
                    .font(playFontManager.font(size: 52, weight: .black))
                    .foregroundStyle(OniTanTheme.primaryGradient)
            }
            correctBadge(answer: nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Error Correction

    private var errorCorrectionHeader: some View {
        VStack(spacing: 10) {
            if let orig = question.payload?.originalSentence {
                Text(orig)
                    .font(playFontManager.font(size: 14))
                    .foregroundColor(OniTanTheme.accentWrong.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .strikethrough(color: OniTanTheme.accentWrong.opacity(0.5))
                    .lineLimit(3)
            }
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(OniTanTheme.accentWrong)
                    Text(question.payload?.wrongKanji ?? "?")
                        .font(playFontManager.font(size: 28, weight: .bold))
                        .foregroundColor(OniTanTheme.accentWrong)
                }
                Image(systemName: "arrow.right")
                    .foregroundColor(OniTanTheme.textTertiary)
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(OniTanTheme.accentCorrect)
                    Text(question.answer)
                        .font(playFontManager.font(size: 28, weight: .black))
                        .foregroundColor(OniTanTheme.accentCorrect)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Proverb

    private var proverbHeader: some View {
        VStack(spacing: 8) {
            Text(question.answer)
                .font(playFontManager.font(size: 40, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            correctBadge(answer: nil)

            if let meaning = question.payload?.proverbMeaning {
                Text(meaning)
                    .font(playFontManager.font(size: 13))
                    .foregroundColor(OniTanTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Passage

    private var passageHeader: some View {
        VStack(spacing: 8) {
            if let targetText = question.payload?.passageTargetText {
                Text(targetText)
                    .font(playFontManager.font(size: 20, weight: .bold))
                    .foregroundColor(OniTanTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Text(question.answer)
                .font(playFontManager.font(size: 44, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)
                .minimumScaleFactor(0.4)
                .lineLimit(2)

            correctBadge(answer: nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Writing Skipped

    private var writingSkippedHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "pencil.slash")
                .font(.system(size: 32))
                .foregroundColor(OniTanTheme.textTertiary)
            Text("書き取り問題（スキップ）")
                .font(playFontManager.font(size: 15, weight: .semibold))
                .foregroundColor(OniTanTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Generic Fallback

    private var genericHeader: some View {
        VStack(spacing: 8) {
            Text(question.displayPrompt)
                .font(playFontManager.font(size: 56, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            correctBadge(answer: question.answer)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Explanation Body

    private var explanationBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Kind badge
            HStack(spacing: 6) {
                Image(systemName: question.kind.systemImage)
                    .font(.system(size: 11))
                Text(question.kind.displayName)
                    .font(playFontManager.font(size: 12, weight: .semibold))
            }
            .foregroundColor(OniTanTheme.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(OniTanTheme.cardBackground.opacity(0.5))
            .clipShape(Capsule())

            // Main explanation text
            Text(question.displayExplanation)
                .font(playFontManager.font(size: 15))
                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.95))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Tags
            if let tags = question.tags, !tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(tags.prefix(5), id: \.self) { tag in
                        Text(tag)
                            .font(playFontManager.font(size: 10, weight: .medium))
                            .foregroundColor(OniTanTheme.accentPrimary.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(OniTanTheme.accentPrimary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Shared Components

    private func correctBadge(answer: String?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(OniTanTheme.accentCorrect)
            Text(answer.map { "正解：\($0)" } ?? "正解！")
                .font(playFontManager.font(size: 17, weight: .bold))
                .foregroundColor(OniTanTheme.accentCorrect)
        }
    }
}
