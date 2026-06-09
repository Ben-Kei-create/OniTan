import SwiftUI

// MARK: - ExplanationContentView

/// Kind-aware explanation body shown inside ExplanationView after a correct answer.
/// Replaces the single-format explanation that assumed reading-only questions.
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

    // MARK: - Kind-Specific Header

    @ViewBuilder
    private var kindSpecificHeader: some View {
        switch question.kind {

        case .reading, .jukujikun:
            readingHeader

        case .writing:
            writingHeader

        case .yojijukugo:
            yojijukugoHeader

        case .composition:
            compositionHeader

        case .synonym, .antonym:
            synonymAntonymHeader

        case .okurigana:
            okuriganaHeader

        case .errorcorrection:
            errorCorrectionHeader

        case .cloze, .proverb:
            clozeProverbHeader

        default:
            genericHeader
        }
    }

    // Reading: large kanji + correct reading
    private var readingHeader: some View {
        VStack(spacing: 8) {
            Text(question.kanji)
                .font(playFontManager.font(size: 70, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)

            correctBadge(answer: question.answer)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // Writing: kana prompt → correct kanji
    private var writingHeader: some View {
        VStack(spacing: 8) {
            if let kana = question.payload?.kanaPrompt ?? question.rawPrompt {
                Text(kana)
                    .font(playFontManager.font(size: 36, weight: .bold))
                    .foregroundColor(OniTanTheme.textSecondary)
            }
            HStack(spacing: 6) {
                Image(systemName: "arrow.down")
                    .foregroundColor(OniTanTheme.textTertiary)
                Text(question.answer)
                    .font(playFontManager.font(size: 52, weight: .black))
                    .foregroundStyle(OniTanTheme.primaryGradient)
            }
            correctBadge(answer: nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // Yojijukugo: full idiom + meaning
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

    // Composition: compound + structure type
    private var compositionHeader: some View {
        VStack(spacing: 8) {
            Text(question.payload?.compound ?? question.displayPrompt)
                .font(playFontManager.font(size: 56, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(OniTanTheme.accentCorrect)
                Text(structureTypeName(question.payload?.structureType))
                    .font(playFontManager.font(size: 15, weight: .bold))
                    .foregroundColor(OniTanTheme.accentCorrect)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // Synonym / Antonym
    private var synonymAntonymHeader: some View {
        VStack(spacing: 8) {
            if let target = question.payload?.targetWord {
                HStack(spacing: 12) {
                    Text(target)
                        .font(playFontManager.font(size: 40, weight: .bold))
                        .foregroundColor(OniTanTheme.textSecondary)
                    Image(systemName: question.kind == .synonym ? "equal.circle.fill" : "arrow.left.arrow.right.circle.fill")
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

    // Okurigana
    private var okuriganaHeader: some View {
        VStack(spacing: 8) {
            Text(question.answer)
                .font(playFontManager.font(size: 52, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)
            correctBadge(answer: nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // Error Correction
    private var errorCorrectionHeader: some View {
        VStack(spacing: 10) {
            if let orig = question.payload?.originalSentence {
                Text(orig)
                    .font(playFontManager.font(size: 15))
                    .foregroundColor(OniTanTheme.accentWrong.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .strikethrough()
            }
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill").foregroundColor(OniTanTheme.accentWrong)
                Text(question.payload?.wrongKanji ?? "")
                    .font(playFontManager.font(size: 28, weight: .bold))
                    .foregroundColor(OniTanTheme.accentWrong)
                Image(systemName: "arrow.right")
                    .foregroundColor(OniTanTheme.textTertiary)
                Image(systemName: "checkmark.circle.fill").foregroundColor(OniTanTheme.accentCorrect)
                Text(question.answer)
                    .font(playFontManager.font(size: 28, weight: .black))
                    .foregroundColor(OniTanTheme.accentCorrect)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // Cloze / Proverb
    private var clozeProverbHeader: some View {
        VStack(spacing: 8) {
            Text(question.answer)
                .font(playFontManager.font(size: 44, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)
            correctBadge(answer: nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // Generic fallback
    private var genericHeader: some View {
        VStack(spacing: 8) {
            Text(question.displayPrompt)
                .font(playFontManager.font(size: 56, weight: .black))
                .foregroundStyle(OniTanTheme.primaryGradient)
                .minimumScaleFactor(0.4)
                .lineLimit(2)
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
                    ForEach(tags.prefix(4), id: \.self) { tag in
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
                .fontWeight(.bold)
                .foregroundColor(OniTanTheme.accentCorrect)
        }
    }

    private func structureTypeName(_ type: String?) -> String {
        switch type {
        case "synonym_chars":     return "意味が似た字の組み合わせ"
        case "antonym_chars":     return "意味が対の字の組み合わせ"
        case "modifier":          return "前の字が後の字を修飾"
        case "verb_object":       return "動詞＋目的語"
        case "subject_predicate": return "主語＋述語"
        default:                  return "熟語の構成"
        }
    }
}
