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
                        colors: [OniTanTheme.washiText, OniTanTheme.mutedGold],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: OniTanTheme.sealRed.opacity(0.35), radius: 20, y: 8)
                .padding(.bottom, 12)

            Text("漢字検定準１級 対策アプリ")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.85))
                .padding(.bottom, 32)

            VStack(spacing: 14) {
                featureRow(icon: "道", color: OniTanTheme.mutedGold,
                           text: "分野別の道場で出題形式ごとに鍛える")
                featureRow(icon: "十", color: OniTanTheme.sealRed,
                           text: "ランダム10問で短く続ける")
                featureRow(icon: "試", color: OniTanTheme.mutedGold,
                           text: "ミニ模試で本番感覚を確認")
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
                    title: "ランダム10問",
                    desc: "短い稽古で読みと語彙を毎日少しずつ積み上げる。",
                    gradient: OniTanTheme.primaryGradient
                )
                stepCard(
                    number: "2",
                    title: "道場集中",
                    desc: "読み・共通漢字・四字熟語など、形式ごとに集中して鍛える。",
                    gradient: OniTanTheme.goldGradient
                )
                stepCard(
                    number: "3",
                    title: "ミニ模試",
                    desc: "混合問題で仕上がりを確認し、次に鍛える分野を見つける。",
                    gradient: OniTanTheme.primaryGradient
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
                        .fill(OniTanTheme.mutedGold.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .blur(radius: 16)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [OniTanTheme.mutedGold, OniTanTheme.sealRed],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: OniTanTheme.mutedGold.opacity(0.35), radius: 12)
                }
                .padding(.bottom, 8)

                Text("毎日リマインダー")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.white)

                Text("毎晩 20:00 に今日の稽古を\n忘れないよう通知します")
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
            Text(icon)
                .font(.system(size: 18, weight: .black, design: .serif))
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
                    colors: [OniTanTheme.sealRed, OniTanTheme.sealRedDark],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: OniTanTheme.sealRed.opacity(0.32), radius: 10, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("毎日リマインダー通知を有効にする")
    }

    private var notifGrantedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(OniTanTheme.mutedGold)
            Text("通知が有効になりました！")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(OniTanTheme.mutedGold.opacity(0.16))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(OniTanTheme.mutedGold.opacity(0.5), lineWidth: 1.5)
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
                                colors: [OniTanTheme.sealRed, OniTanTheme.sealRedDark],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    )
                    .shadow(color: OniTanTheme.sealRed.opacity(0.32), radius: 8, y: 4)
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
                                colors: [OniTanTheme.sealRed, OniTanTheme.sealRedDark],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    )
                    .shadow(color: OniTanTheme.sealRed.opacity(0.32), radius: 8, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("オンボーディング完了、アプリを始める")
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        OniTanTheme.inkGradient
    }

    // MARK: - Actions

    private func finishOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}
