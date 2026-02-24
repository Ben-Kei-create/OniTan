import SwiftUI

// MARK: - Question Prompt View
// Renders kind-specific prompt display for the quiz screen.
// Extracted from MainView to keep each question kind's rendering isolated.

struct QuestionPromptView: View {
    let question: Question
    let isShowingWrong: Bool
    let lastAnswerResult: AnswerResult
    let scale: CGFloat

    var body: some View {
        let corner = scaled(24, min: 16)
        let cardHeight: CGFloat = isShowingWrong
            ? scaled(160, min: 120)
            : scaled(220, min: 170)

        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: corner)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: scaled(16, min: 8), y: scaled(8, min: 4))

            // Flash on answer
            if lastAnswerResult == .correct {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.accentCorrect.opacity(0.25))
                    .transition(.opacity)
            } else if lastAnswerResult == .wrong {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.accentWrong.opacity(0.25))
                    .transition(.opacity)
            }

            // Kind-specific content
            VStack(spacing: scaled(4, min: 2)) {
                // Kind label badge (hidden for reading to keep current UX)
                if question.kind != .reading {
                    kindBadge
                }

                promptContent
            }
            .padding(scaled(16, min: 8))
        }
        .frame(height: cardHeight)
        .animation(.easeInOut(duration: 0.25), value: isShowingWrong)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(question.kind.accessibilityHint)
        .accessibilityIdentifier("quiz_kanji")
    }

    // MARK: - Kind Badge

    private var kindBadge: some View {
        Text(question.kind.promptLabel)
            .font(.system(size: scaled(11, min: 9), weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.15))
            .cornerRadius(8)
    }

    // MARK: - Prompt Content (kind-specific)

    @ViewBuilder
    private var promptContent: some View {
        switch question.kind {
        case .reading:
            readingPrompt
        case .writing:
            writingPrompt
        case .composition:
            compositionPrompt
        case .yojijukugo:
            yojijukugoPrompt
        case .synonym:
            labeledWordPrompt(instruction: "類義語は？")
        case .antonym:
            labeledWordPrompt(instruction: "対義語は？")
        case .okurigana:
            okuriganaPrompt
        case .errorcorrection:
            errorCorrectionPrompt
        case .cloze:
            clozePrompt
        case .usage:
            usagePrompt
        case .unknown:
            readingPrompt
        }
    }

    // MARK: - Reading (default)

    private var readingPrompt: some View {
        let fontSize: CGFloat = isShowingWrong
            ? scaled(90, min: 64)
            : scaled(130, min: 92)

        return Text(question.kanji)
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .shadow(color: .black.opacity(0.3), radius: 4)
            .id(question.id)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
    }

    // MARK: - Writing (かな → 漢字)

    private var writingPrompt: some View {
        let kana = question.payload?.kana ?? question.kanji
        let fontSize: CGFloat = isShowingWrong
            ? scaled(56, min: 40)
            : scaled(80, min: 56)

        return VStack(spacing: scaled(6, min: 3)) {
            Text(kana)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 4)

            if let instruction = question.kind.instructionText {
                Text(instruction)
                    .font(.system(size: scaled(14, min: 11), weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .id(question.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Composition (熟語の構成)

    private var compositionPrompt: some View {
        let compound = question.payload?.compound ?? question.kanji
        let fontSize: CGFloat = isShowingWrong
            ? scaled(64, min: 48)
            : scaled(90, min: 64)

        return VStack(spacing: scaled(6, min: 3)) {
            Text(compound)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 4)

            Text("この熟語の構成は？")
                .font(.system(size: scaled(14, min: 11), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .id(question.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Yojijukugo (四字熟語)

    private var yojijukugoPrompt: some View {
        let yoji = question.payload?.yoji ?? question.kanji
        let chars = Array(yoji)
        let missingIdx = question.payload?.missingIndex
        let charSize: CGFloat = isShowingWrong
            ? scaled(48, min: 36)
            : scaled(64, min: 48)

        return VStack(spacing: scaled(6, min: 3)) {
            HStack(spacing: scaled(4, min: 2)) {
                ForEach(chars.indices, id: \.self) { idx in
                    let ch = chars[idx]
                    if String(ch) == "□" || idx == missingIdx {
                        // Missing character placeholder
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(OniTanTheme.accentPrimary.opacity(0.3))
                                .frame(width: charSize, height: charSize)
                            Text("□")
                                .font(.system(size: charSize * 0.7, weight: .bold, design: .rounded))
                                .foregroundColor(OniTanTheme.accentPrimary)
                        }
                    } else {
                        Text(String(ch))
                            .font(.system(size: charSize * 0.8, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: charSize, height: charSize)
                    }
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 4)

            if let meaning = question.payload?.meaning {
                Text(meaning)
                    .font(.system(size: scaled(12, min: 10), weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            Text("□に入る字は？")
                .font(.system(size: scaled(14, min: 11), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .id(question.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Synonym / Antonym (shared layout)

    private func labeledWordPrompt(instruction: String) -> some View {
        let fontSize: CGFloat = isShowingWrong
            ? scaled(64, min: 48)
            : scaled(90, min: 64)

        return VStack(spacing: scaled(6, min: 3)) {
            Text(question.kanji)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 4)

            Text(instruction)
                .font(.system(size: scaled(14, min: 11), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .id(question.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Okurigana

    private var okuriganaPrompt: some View {
        let word = question.payload?.targetWord ?? question.kanji
        let fontSize: CGFloat = isShowingWrong
            ? scaled(64, min: 48)
            : scaled(90, min: 64)

        return VStack(spacing: scaled(6, min: 3)) {
            Text(word)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 4)

            Text("正しい送り仮名は？")
                .font(.system(size: scaled(14, min: 11), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .id(question.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Error Correction (誤字訂正)

    private var errorCorrectionPrompt: some View {
        let sentence = question.payload?.originalSentence ?? question.kanji
        let wrongKanji = question.payload?.wrongKanji
        let fontSize: CGFloat = isShowingWrong
            ? scaled(18, min: 14)
            : scaled(22, min: 16)

        return VStack(spacing: scaled(6, min: 3)) {
            if let wrongKanji = wrongKanji {
                sentenceWithHighlight(sentence: sentence, highlight: wrongKanji, fontSize: fontSize)
            } else {
                Text(sentence)
                    .font(.system(size: fontSize, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.6)
            }

            Text("誤字はどれ？")
                .font(.system(size: scaled(14, min: 11), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .id(question.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Cloze (文章穴埋め)

    private var clozePrompt: some View {
        let sentence = question.payload?.sentence ?? question.kanji
        let blank = question.payload?.blankToken ?? "＿＿"
        let display = sentence.replacingOccurrences(of: blank, with: "【　　】")
        let fontSize: CGFloat = isShowingWrong
            ? scaled(18, min: 14)
            : scaled(22, min: 16)

        return VStack(spacing: scaled(6, min: 3)) {
            Text(display)
                .font(.system(size: fontSize, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.6)

            Text("【　　】に入る語は？")
                .font(.system(size: scaled(14, min: 11), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .id(question.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Usage (語彙用法)

    private var usagePrompt: some View {
        let word = question.payload?.targetWord ?? question.kanji
        let fontSize: CGFloat = isShowingWrong
            ? scaled(64, min: 48)
            : scaled(90, min: 64)

        return VStack(spacing: scaled(6, min: 3)) {
            Text(word)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 4)

            Text("正しい使い方は？")
                .font(.system(size: scaled(14, min: 11), weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .id(question.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Helpers

    private func sentenceWithHighlight(sentence: String, highlight: String, fontSize: CGFloat) -> some View {
        let parts = sentence.components(separatedBy: highlight)
        var attributed = AttributedString(parts.first ?? "")
        attributed.foregroundColor = .white
        attributed.font = .system(size: fontSize, weight: .medium, design: .rounded)

        if parts.count > 1 {
            var highlighted = AttributedString(highlight)
            highlighted.foregroundColor = Color(red: 1, green: 0.3, blue: 0.3)
            highlighted.font = .system(size: fontSize, weight: .bold, design: .rounded)
            highlighted.underlineStyle = .single
            attributed.append(highlighted)

            var rest = AttributedString(parts.dropFirst().joined(separator: highlight))
            rest.foregroundColor = .white
            rest.font = .system(size: fontSize, weight: .medium, design: .rounded)
            attributed.append(rest)
        }

        return Text(attributed)
            .multilineTextAlignment(.center)
            .lineLimit(4)
            .minimumScaleFactor(0.6)
    }

    private var accessibilityText: String {
        switch question.kind {
        case .reading:
            return "漢字: \(question.kanji)"
        case .writing:
            let kana = question.payload?.kana ?? question.kanji
            return "読み: \(kana)"
        case .composition:
            let compound = question.payload?.compound ?? question.kanji
            return "熟語: \(compound)"
        case .yojijukugo:
            let yoji = question.payload?.yoji ?? question.kanji
            return "四字熟語: \(yoji)"
        case .synonym:
            return "語句: \(question.kanji)、類義語は？"
        case .antonym:
            return "語句: \(question.kanji)、対義語は？"
        case .okurigana:
            let word = question.payload?.targetWord ?? question.kanji
            return "漢字: \(word)、送り仮名は？"
        case .errorcorrection:
            let sentence = question.payload?.originalSentence ?? question.kanji
            return "文章: \(sentence)、誤字はどれ？"
        case .cloze:
            let sentence = question.payload?.sentence ?? question.kanji
            return "文章: \(sentence)"
        case .usage:
            let word = question.payload?.targetWord ?? question.kanji
            return "語句: \(word)、正しい使い方は？"
        case .unknown:
            return "問題: \(question.kanji)"
        }
    }

    private func scaled(_ value: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, value * scale)
    }
}
