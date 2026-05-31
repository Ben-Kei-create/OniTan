import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var page = 0

    private let totalPages = 3

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomeSlide.tag(0)
                    howItWorksSlide.tag(1)
                    notificationSlide.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: page)

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Slides

    private var welcomeSlide: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("鬼単")
                .font(.system(size: 90, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.75, green: 0.55, blue: 1.0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.7), radius: 20, y: 8)
                .padding(.bottom, 12)

            Text("漢字検定準１級 対策アプリ")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.85))
                .padding(.bottom, 32)

            VStack(spacing: 14) {
                featureRow(icon: "books.vertical.fill", color: Color(red: 0.55, green: 0.40, blue: 1.0),
                           text: "全 \(quizData.stages.count) ステージで段階的に学習")
                featureRow(icon: "bolt.fill", color: Color(red: 1.0, green: 0.60, blue: 0.10),
                           text: "今日の10問で毎日の習慣づくり")
                featureRow(icon: "star.fill", color: Color(red: 1.0, green: 0.85, blue: 0.20),
                           text: "XPを貯めてレベルアップ！")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var howItWorksSlide: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("こう使おう")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text("毎日少しずつが合格への近道")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }

            VStack(spacing: 16) {
                stepCard(
                    number: "1",
                    title: "今日の10問",
                    desc: "ホーム画面の「今日の10問」で毎日の学習を記録。ストリークを続けよう！",
                    gradient: LinearGradient(
                        colors: [Color(red: 1.0, green: 0.55, blue: 0.05), Color(red: 0.8, green: 0.30, blue: 0.0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                stepCard(
                    number: "2",
                    title: "ステージを攻略",
                    desc: "準１級の漢字をステージ制で完全網羅。クリアすると次のステージが解放！",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.40, green: 0.25, blue: 0.90), Color(red: 0.25, green: 0.10, blue: 0.65)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                stepCard(
                    number: "3",
                    title: "苦手を克服",
                    desc: "間違えた問題を自動で記録。苦手モードで集中的に復習できます。",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.90, green: 0.40, blue: 0.10), Color(red: 0.70, green: 0.20, blue: 0.0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var notificationSlide: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.55, blue: 0.05).opacity(0.2))
                        .frame(width: 100, height: 100)
                        .blur(radius: 16)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.70, blue: 0.20), Color(red: 1.0, green: 0.40, blue: 0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 1.0, green: 0.50, blue: 0.0).opacity(0.5), radius: 12)
                }
                .padding(.bottom, 8)

                Text("毎日リマインダー")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.white)

                Text("毎晩 20:00 に今日の分を\nやったかどうか通知でお知らせします")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer(minLength: 32)

            VStack(spacing: 12) {
                if notificationManager.authStatus == .authorized {
                    notifGrantedBadge
                } else {
                    notifRequestButton
                }

                Button {
                    finishOnboarding()
                } label: {
                    Text("あとで設定する")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .underline()
                }
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 48)
        }
    }

    // MARK: - Sub-components

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36)
                .accessibilityHidden(true)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }

    private func stepCard(number: String, title: String, desc: String, gradient: LinearGradient) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(gradient)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }

    private var notifRequestButton: some View {
        Button {
            Task {
                let granted = await notificationManager.requestPermission()
                if granted {
                    notificationManager.scheduleReminder()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("通知を有効にする（おすすめ）")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.55, blue: 0.05), Color(red: 0.8, green: 0.30, blue: 0.0)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color(red: 1.0, green: 0.40, blue: 0.0).opacity(0.4), radius: 10, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("毎日リマインダー通知を有効にする")
    }

    private var notifGrantedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(red: 0.20, green: 0.85, blue: 0.50))
            Text("通知が有効になりました！")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Color(red: 0.10, green: 0.40, blue: 0.20).opacity(0.7))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.20, green: 0.85, blue: 0.50).opacity(0.5), lineWidth: 1.5)
        )
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // Page indicator dots
            HStack(spacing: 7) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Color.white : Color.white.opacity(0.3))
                        .frame(width: i == page ? 22 : 7, height: 7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                }
            }

            Spacer()

            if page < totalPages - 1 {
                Button {
                    withAnimation { page += 1 }
                } label: {
                    HStack(spacing: 6) {
                        Text("次へ")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(red: 0.55, green: 0.35, blue: 1.0), Color(red: 0.35, green: 0.15, blue: 0.75)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    )
                    .shadow(color: Color(red: 0.45, green: 0.25, blue: 0.85).opacity(0.45), radius: 8, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("次へ")
            } else {
                Button {
                    finishOnboarding()
                } label: {
                    HStack(spacing: 6) {
                        Text("はじめる！")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.black)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(red: 1.0, green: 0.55, blue: 0.05), Color(red: 0.8, green: 0.30, blue: 0.0)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    )
                    .shadow(color: Color(red: 1.0, green: 0.40, blue: 0.0).opacity(0.45), radius: 8, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("オンボーディング完了、アプリを始める")
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.06, blue: 0.22),
                Color(red: 0.18, green: 0.04, blue: 0.28)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Actions

    private func finishOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}
