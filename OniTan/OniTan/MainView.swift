import SwiftUI

struct MainView: View {
    // MARK: - Properties
    @StateObject private var viewModel: MainViewModel
    
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    @AppStorage("kanjiFont") private var kanjiFont: String = "system"
    @AppStorage("themeColor") private var themeColor: String = "classic"

    // Custom initializer
    init(stage: Stage, isReviewMode: Bool = false, progressStore: ProgressStore, quizData: QuizData) {
        _viewModel = StateObject(wrappedValue: MainViewModel(stage: stage, 
                                                          isReviewMode: isReviewMode, 
                                                          progressStore: progressStore, 
                                                          allQuestions: quizData.stages.flatMap { $0.questions },
                                                          soundManager: SoundManager.shared,
                                                          hapticsManager: HapticsManager.shared))
    }

    // Computed property for selected kanji font
    private var selectedKanjiFont: Font {
        // ... (font logic remains here as it's a View concern)
        switch kanjiFont {
        case "hiragino":
            return .custom("Hiragino Kaku Gothic ProN", size: 150, relativeTo: .largeTitle)
        case "yuGothic":
            return .custom("YuGothic-Medium", size: 150, relativeTo: .largeTitle)
        case "mincho":
            return .custom("Hiragino Mincho ProN", size: 150, relativeTo: .largeTitle)
        default:
            return .system(size: 150, weight: .heavy, design: .rounded)
        }
    }
    
    // Computed property for selected theme color
    private var selectedThemeColor: Color {
        // ... (theme color logic remains here as it's a View concern)
        switch themeColor {
        case "natural":
            return .green
        case "passion":
            return .red
        case "elegant":
            return .purple
        case "sunshine":
            return .orange
        default:
            return .blue // classic
        }
    }

    var body: some View {
        ZStack {
            if viewModel.isStageCleared {
                StageClearedView(stage: viewModel.stage, onDismiss: { presentationMode.wrappedValue.dismiss() }, selectedThemeColor: selectedThemeColor, soundEnabled: $viewModel.soundEnabled, hapticsEnabled: $viewModel.hapticsEnabled)
            } else if viewModel.questions.isEmpty && viewModel.isReviewMode {
                // Review mode finished
                Color.clear.onAppear {
                    appState.showReviewCompletion = true
                    presentationMode.wrappedValue.dismiss()
                }
            }
            else {
                QuizView(viewModel: viewModel, selectedKanjiFont: selectedKanjiFont, selectedThemeColor: selectedThemeColor)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    selectedThemeColor.opacity(0.15),
                    selectedThemeColor.opacity(0.1),
                    Color(.systemBackground).opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
        )
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $viewModel.showingQuitAlert) {
            Alert(
                title: Text("確認"),
                message: Text("途中で辞めると、ステージクリアになりません。"),
                primaryButton: .destructive(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
        .overlay(
            viewModel.showExplanation ? ExplanationView(question: viewModel.currentQuestion, onDismiss: viewModel.onExplanationDismissed) : nil
        )
        .onAppear {
            viewModel.dismissAction = { presentationMode.wrappedValue.dismiss() }
        }
    }
}


// MARK: - Subviews
struct QuizView: View {
    @ObservedObject var viewModel: MainViewModel
    let selectedKanjiFont: Font
    let selectedThemeColor: Color
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button("辞める") {
                    if viewModel.isReviewMode {
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        viewModel.onQuit()
                    }
                }
                .foregroundColor(.red)
                
                Spacer()
                
                if !viewModel.isReviewMode {
                    Button(action: viewModel.toggleBookmark) {
                        Image(systemName: viewModel.isBookmarked() ? "bookmark.fill" : "bookmark")
                            .font(.title2)
                            .foregroundColor(viewModel.isBookmarked() ? .yellow : .gray)
                    }
                }
            }
            .padding(.horizontal)

            // Title and Progress
            Text(viewModel.isReviewMode ? "復習モード" : "ステージ \(viewModel.stage.stage)")
                .font(.largeTitle).fontWeight(.bold).foregroundColor(.accentColor).padding(.bottom)
            if !viewModel.isReviewMode {
                Text("進行度: \(viewModel.totalCorrect) / \(viewModel.goal) 問")
                    .font(.headline).foregroundColor(.secondary)
            }

            Spacer()

            // Kanji Display
            Text(viewModel.currentQuestion.kanji)
                .font(selectedKanjiFont)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background(Color(.systemBackground).opacity(0.1))
                .cornerRadius(20)
                .shadow(color: Color(.systemGray4).opacity(0.3), radius: 5, x: 0, y: 5)

            Spacer()

            // Choices or Result
            if !viewModel.showResult {
                ChoicesView(choices: viewModel.currentQuestion.choices, themeColor: selectedThemeColor) { choice in
                    viewModel.answer(selected: choice)
                }
                .disabled(viewModel.buttonsDisabled)
            } else {
                ResultView(isCorrect: viewModel.isCorrect, correctAnswer: viewModel.currentQuestion.answer)
            }

            Spacer()

            // Reset Button
            if viewModel.showBackToStartButton {
                Button(action: viewModel.resetGame) {
                    Text("最初からやり直す")
                        .font(.title2).fontWeight(.bold)
                        .frame(maxWidth: 250, minHeight: 60)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(color: Color.orange.opacity(0.4), radius: 10, x: 0, y: 10)
                }
                .padding(.bottom, 20)
            }
        }
        .padding()
    }
}

struct ChoicesView: View {
    let choices: [Choice]
    let themeColor: Color
    let onSelect: (Choice) -> Void

    var body: some View {
        VStack(spacing: 15) {
            ForEach(choices) { choice in
                Button(action: { onSelect(choice) }) {
                    Text(choice.text)
                        .font(.title2).fontWeight(.bold)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(themeColor)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ResultView: View {
    let isCorrect: Bool
    let correctAnswer: String

    var body: some View {
        VStack {
            Text(isCorrect ? "○ 正解！" : "× 不正解…")
                .font(.system(size: 60, weight: .heavy))
                .foregroundColor(isCorrect ? .green : .red)
                .transition(.scale)
            
            if !isCorrect {
                Text("正解は「\(correctAnswer)」")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StageClearedView: View {
    let stage: Stage
    let onDismiss: () -> Void
    let selectedThemeColor: Color
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    
    @State private var clearTextScale: CGFloat = 0.1
    @State private var clearTextOpacity: Double = 0
    @State private var confettiOpacity: Double = 0
    @State private var confettiRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    selectedThemeColor.opacity(0.2),
                    selectedThemeColor.opacity(0.1),
                    Color(.systemBackground).opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            // Confetti background
            ForEach(0..<30, id: \.self) { index in
                ConfettiPiece(index: index, opacity: confettiOpacity, rotation: confettiRotation)
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Stage clear text with animation
                VStack(spacing: 15) {
                    Text("ステージ \(stage.stage)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.primary)
                        .opacity(clearTextOpacity)
                        .scaleEffect(clearTextScale)
                    
                    Text("クリア！")
                        .font(.system(size: 80, weight: .heavy))
                        .foregroundColor(.green)
                        .opacity(clearTextOpacity)
                        .scaleEffect(clearTextScale)
                        .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: clearTextScale)
                .animation(.easeIn(duration: 0.5), value: clearTextOpacity)
                
                Text("おめでとうございます！")
                    .font(.title)
                    .foregroundColor(.primary)
                    .opacity(clearTextOpacity)
                    .animation(.easeIn(duration: 0.5).delay(0.3), value: clearTextOpacity)
                
                Spacer()
                
                // Return button with animation
                Button(action: onDismiss) {
                    Text("ステージ選択へ戻る")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: 280, minHeight: 65) // Larger button
                        .background(selectedThemeColor) // Use theme color
                        .foregroundColor(.white)
                        .cornerRadius(35) // More rounded
                        .shadow(color: selectedThemeColor.opacity(0.4), radius: 12, x: 0, y: 12) // Enhanced shadow
                }
                .opacity(clearTextOpacity)
                .scaleEffect(clearTextScale * 0.9) // Slightly smaller scale for button
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.6), value: clearTextScale)
                .animation(.easeIn(duration: 0.5).delay(0.6), value: clearTextOpacity)
                .padding(.bottom, 40) // More padding
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure ZStack fills available space
        .edgesIgnoringSafeArea(.all) // Ensure ZStack ignores safe area
        .onAppear {
            // Play success sound and haptics
            if soundEnabled { SoundManager.shared.playSound(sound: .correct, volume: 1.0) }
            if hapticsEnabled { HapticsManager.shared.play(.success) }
            
            // Start text animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                clearTextScale = 1.0
                clearTextOpacity = 1.0
            }
            
            // Start confetti animation
            withAnimation(.easeIn(duration: 0.5)) {
                confettiOpacity = 1.0
            }
            
            // Rotate confetti
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                confettiRotation = 360
            }
        }
    }
}

struct ExplanationView: View {
    let question: Question
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color(.systemBackground).opacity(0.9).edgesIgnoringSafeArea(.all)
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 20) {
                Text(question.explain)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6).opacity(0.8))
                    .cornerRadius(15)
                    .shadow(color: Color(.systemGray4).opacity(0.3), radius: 10, x: 0, y: 5)

                Text("タップして次へ")
                    .font(.headline)
                    .padding(.top, 20)
            }
            .padding()
        }
        .transition(.opacity)
    }
}

struct ConfettiPiece: View {
    let index: Int
    let opacity: Double
    let rotation: Double
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    private let shapes: [String] = ["circle.fill", "square.fill", "triangle.fill", "star.fill"]
    
    var body: some View {
        Image(systemName: shapes[index % shapes.count])
            .foregroundColor(colors[index % colors.count])
            .font(.system(size: CGFloat.random(in: 8...15)))
            .position(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
            )
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: opacity)
    }
}

// MARK: - Previews
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let quizData = QuizDataLoader().load()
        NavigationView {
            MainView(stage: quizData.stages[0], 
                     isReviewMode: false, 
                     progressStore: ProgressStore.shared,
                     quizData: quizData)
                .environmentObject(AppState())
                .environmentObject(ProgressStore.shared)
                .environment(\.quizData, quizData)
        }
    }
}
