import SwiftUI
import UIKit

struct QuizProblemReportContext: Identifiable {
    let id = UUID()
    let question: Question
    let sessionTitle: String
    let modeName: String
    let stageNumber: Int?

    var stageLabel: String {
        if let stageNumber, stageNumber > 0 {
            return "Stage \(stageNumber)"
        }
        return sessionTitle
    }
}

enum QuizProblemReportBuilder {
    private static let issueBaseURL = URL(string: "https://github.com/Ben-Kei-create/OniTan/issues/new")!

    static func issueTitle(for context: QuizProblemReportContext) -> String {
        "問題報告: \(context.question.kanji)"
    }

    static func issueURL(for context: QuizProblemReportContext) -> URL? {
        var components = URLComponents(url: issueBaseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "title", value: issueTitle(for: context)),
            URLQueryItem(name: "body", value: draftText(for: context))
        ]
        return components?.url
    }

    static func draftText(for context: QuizProblemReportContext) -> String {
        let question = context.question
        let readingKind = readingKindDescription(for: question)
        let explanation = trimmed(question.displayExplanation, maxLength: 700)

        return """
        ## 問題情報
        - セッション: \(context.sessionTitle)
        - モード: \(context.modeName)
        - ステージ: \(context.stageLabel)
        - 漢字: \(question.kanji)
        - 正解: \(question.answer)
        - 選択肢: \(question.choices.joined(separator: " / "))
        - 読みの扱い: \(readingKind)

        ## 解説
        \(explanation)

        ## どこがおかしいですか？
        - [ ] 正解が違う
        - [ ] 選択肢が不自然
        - [ ] 解説が誤っている
        - [ ] 音読み・訓読みの扱いが分かりづらい
        - [ ] その他

        ## 詳細メモ
        気づいたことをここに書いてください。

        ## 利用環境
        - アプリ: \(appVersionLabel)
        - iOS: \(UIDevice.current.systemVersion)
        """
    }

    private static func readingKindDescription(for question: Question) -> String {
        switch question.readingMetadata.answerKind(for: question.answer) {
        case .onyomi:
            return "音読み"
        case .kunyomi:
            return "訓読み"
        case .shared:
            return "音読み・訓読みの両方で使われる読み"
        case .unknown:
            return "不明"
        }
    }

    private static var appVersionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        return "\(version) (\(build))"
    }

    private static func trimmed(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }
        return String(text.prefix(maxLength)) + "…"
    }
}

struct ProblemReportSheet: View {
    let context: QuizProblemReportContext

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var copied = false

    private var draftText: String {
        QuizProblemReportBuilder.draftText(for: context)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OniTanTheme.backgroundGradientFallback
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard
                        draftCard
                        actionRow
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("問題を報告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(context.question.kanji)
                .font(.system(size: 60, weight: .black, design: .rounded))
                .foregroundColor(OniTanTheme.textPrimary)

            Text("現在の問題内容を添えて GitHub Issues に移動します。本文コピーだけでも使えます。")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .oniCard()
    }

    private var draftCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("送信される内容")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(OniTanTheme.textPrimary)

            Text(draftText)
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(OniTanTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .oniCard()
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            Button {
                if let url = QuizProblemReportBuilder.issueURL(for: context) {
                    openURL(url)
                }
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right.square")
                    Text("GitHub Issues を開く")
                }
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(OniTanTheme.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: OniTanTheme.radiusButton))
            }

            Button {
                UIPasteboard.general.string = draftText
                copied = true
            } label: {
                Text(copied ? "本文をコピーしました" : "本文をコピー")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(OniTanTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(OniTanTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: OniTanTheme.radiusButton)
                            .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: OniTanTheme.radiusButton))
            }
        }
    }
}
