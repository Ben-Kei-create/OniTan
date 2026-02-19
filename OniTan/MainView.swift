import SwiftUI

struct MainView: View {
    @StateObject private var vm: QuizSessionViewModel
    @Environment(\.dismiss) private var dismiss

    init(stage: Stage, appState: AppState, statsRepo: StudyStatsRepository) {
        _vm = StateObject(wrappedValue: QuizSessionViewModel(
            stage: stage,
            appState: appState,
            statsRepo: statsRepo
        ))
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 20) {
                quitButton

                switch vm.phase {
                case .stageCleared:
                    stageClearedView
                default:
                    quizContentView
                }
            }
            .padding()
            .navigationBarBackButtonHidden(true)
        }
        .alert("確認", isPresented: $vm.showingQuitAlert) {
            Button("OK", role: .destructive) { dismiss() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("途中で辞めると、ステージクリアになりません。")
        }
        .overlay {
            if vm.phase == .showingExplanation {
                ExplanationView(question: vm.currentQuestion)
                    .onTapGesture { vm.proceed() }
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Sub-views

    private var quitButton: some View {
        HStack {
            Button("辞める") {
                if vm.phase == .stageCleared {
                    dismiss()
                } else {
                    vm.showingQuitAlert = true
                }
            }
            .foregroundColor(.red)
            Spacer()
        }
        .padding(.horizontal)
    }

    private var quizContentView: some View {
        VStack(spacing: 20) {
            Text("ステージ \(vm.stageNumber)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
                .padding(.bottom)

            Text("進行度: \(vm.clearedCount) / \(vm.totalGoal) 問")
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            kanjiDisplay

            Spacer()

            switch vm.phase {
            case .answering:
                choiceButtons
            case .showingWrongAnswer(let correct):
                wrongAnswerView(correctAnswer: correct)
            default:
                EmptyView()
            }

            Spacer()
        }
    }

    private var kanjiDisplay: some View {
        Text(vm.currentQuestion.kanji)
            .font(.system(size: 150, weight: .heavy, design: .rounded))
            .foregroundColor(.primary)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 200)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
    }

    private var choiceButtons: some View {
        VStack(spacing: 15) {
            ForEach(vm.currentQuestion.choices, id: \.self) { choice in
                Button(action: { vm.answer(selected: choice) }) {
                    Text(choice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 5)
                }
            }
        }
        .padding(.horizontal)
    }

    private func wrongAnswerView(correctAnswer: String) -> some View {
        VStack(spacing: 16) {
            Text("× 不正解…")
                .font(.system(size: 60, weight: .heavy))
                .foregroundColor(.red)
            Text("正解は「\(correctAnswer)」")
                .font(.title2)
                .foregroundColor(.secondary)
            Button("次へ") { vm.proceed() }
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: 200, minHeight: 50)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(15)
        }
    }

    private var stageClearedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("ステージ \(vm.stageNumber) クリア！")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
            Text("🎉 おめでとうございます！ 🎉")
                .font(.title)
                .foregroundColor(.primary)
            Spacer()
            Button(action: { dismiss() }) {
                Text("ステージ選択へ戻る")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: 250, minHeight: 60)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 10)
            }
            Spacer()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Explanation Overlay

struct ExplanationView: View {
    let question: Question

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(question.kanji)
                            .font(.system(size: 60, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(question.explain)
                            .font(.body)
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 10)
                .frame(maxHeight: 400)

                Text("タップして次へ")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
    }
}
