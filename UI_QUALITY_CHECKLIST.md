# UI バランス・視認性 品質チェックリスト

凡例: ○=問題なし / △=軽微な改善対象（本対応で修正） / ✕=明確な問題（本対応で修正）

| 画面 | 判定 | 内容 |
|---|---|---|
| HomeView.swift | ○ | – |
| SettingsView.swift | △ | 「購入を復元する」のタップ領域が狭い／広告プライバシー説明文がtextTertiaryで視認性低 |
| OnboardingView.swift | ○ | – |
| SplashView.swift | ○ | – |
| QuizModeSelectView.swift | △ | 「○問」バッジと説明文がtextTertiaryで視認性低 |
| TrainingModePickerView.swift | △ | ロック時説明文の二重減光／正答率%表示がバッジ未統一 |
| CategoryTrainingView.swift | ○ | – |
| ExamRoundSelectionView.swift | △ | ロック中バッジの塗り opacity が解放済みより濃く視覚的に逆転 |
| ExamResultView.swift | ○ | – |
| KanjiCatalogView.swift | ○ | – (軽微なタップ領域メモのみ、対応不要レベル) |
| DailySummaryView.swift | ○ | – |
| WrongAnswerNoteView.swift | ○ | – (onTapGesture自体は背景が全面塗りのため実害なし) |
| StreakChallengeView.swift | ✕ | 正解時に選択肢グリッドが消えてレイアウトが上下にジャンプする |
| MainView.swift (stageClearedView) | △ | 「ホームへ戻る」のタップ領域が狭い・視認性が低い |
| QuestionPromptView.swift (その他コンテンツ) | ○ | – |
| OniComponents.swift | ○ | – |
| ThemePalette / OniTanTheme | ○ | – |
| ExplanationContentView.swift | ○ | – |

△・✕ はすべて本対応で修正済み。
