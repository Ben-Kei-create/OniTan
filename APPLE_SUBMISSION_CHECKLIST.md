# OniTan Apple申請チェックリスト

最終更新: 2026-03-07

このファイルは、`OniTan` を App Store / TestFlight 申請するための現状整理と実行チェックリストです。

## 1. 現状サマリ

- [x] ネイティブ iOS アプリとして `Release` ビルドは成功
  - 実行コマンド: `xcodebuild -scheme OniTan -project OniTan.xcodeproj -configuration Release -destination 'generic/platform=iOS' build`
  - 環境: `Xcode 26.3 (17C529)`
- [x] 学習データは読み込み成功
  - 現状: `71 stages`, `2086 total questions`
- [x] 申請方針は iPhone専用
- [x] `version/build` と `Launch Screen` は設定済み
  - `MARKETING_VERSION = 1.0.0`
  - `CURRENT_PROJECT_VERSION = 1`
  - `UILaunchStoryboardName = LaunchScreen`
- [x] 広告はプレイ画面のみ表示
  - 現状の表示箇所: `OniTan/MainView.swift`, `OniTan/StreakChallengeView.swift`
- [ ] Apple申請向けのメタデータは未整備
- [ ] Apple申請向けの見た目資産は未整備
- [ ] 広告 / 課金 / プライバシー申告の方針が未確定
- [x] 単体テストはグリーン
- [ ] UI テスト基盤は未安定

## 2. 今すぐ詰まる項目

### P0: 申請前に必須

- [x] `CFBundleShortVersionString` を設定する
  - 現状: `MARKETING_VERSION = 1.0.0`
  - 影響箇所: `OniTan/SettingsView.swift`
- [x] `CFBundleVersion` を設定する
  - 現状: `CURRENT_PROJECT_VERSION = 1`
- [x] `Launch Screen` を設定する
  - 現状: `OniTan/Resources/LaunchScreen.storyboard` を追加済み
- [x] iPhone専用にする
  - 対応内容: `TARGETED_DEVICE_FAMILY = 1`
- [ ] App Icon を実画像で埋める
  - 現状: `OniTan/Assets.xcassets/AppIcon.appiconset/Contents.json` に画像ファイルの参照がない
- [ ] App Store Connect 用の `Privacy Policy URL` を用意する
- [ ] App Store Connect 用の `Support URL` を用意する
  - 下書きページ: `docs/privacy.html`, `docs/support.html`
  - GitHub Pages 候補:
    - `https://ben-kei-create.github.io/OniTan/privacy.html`
    - `https://ben-kei-create.github.io/OniTan/support.html`
  - GitHub 側で Pages を有効化したあとに疎通確認する

### P0: 広告まわり

- [ ] 広告を初回リリースに含めるか決める
  - 広告を含める場合:
    - [ ] 本番 AdMob App ID / Ad Unit ID に差し替える
    - [ ] `GADMobileAds.sharedInstance().start()` を有効化する
    - [ ] App Privacy を AdMob の収集データ込みで申告する
    - [ ] ATT を使うか方針を決める
    - [ ] 必要なら `NSUserTrackingUsageDescription` を追加する
  - 広告を含めない場合:
    - [ ] AdMob 依存を削除または初回リリースで無効化する
    - [ ] App Privacy の申告を軽くできる状態にする

### P0: 課金まわり

- [ ] `com.fumiakiMogi777.OniTan.donation` を App Store Connect に作成する
  - 種別: Non-Consumable
  - 実装前提: `OniTan/DonationManager.swift`
- [ ] 課金商品の表示名 / 説明 / 価格を設定する
- [ ] 初回アプリ申請時に IAP も一緒に `Add for Review` する
- [ ] Paid Apps Agreement / 税務 / 銀行口座を完了する

## 3. コード側の対応項目

### 設定ファイル

- [ ] `project.yml` と `OniTan.xcodeproj/project.pbxproj` の実態を揃える
  - `project.yml` では `DEVELOPMENT_TEAM` が空
  - 実際の `.pbxproj` では `DEVELOPMENT_TEAM = 7R927F3U4V`
  - 申請前は生成元を一本化した方が安全
- [x] `MARKETING_VERSION` と `CURRENT_PROJECT_VERSION` を定義する
- [x] `Launch Screen` のキーを追加する
- [x] `TARGETED_DEVICE_FAMILY` を `1` に絞る
- [ ] 必要なら `UIRequiresFullScreen` を使うか検討する

### 広告

- [ ] `OniTan/AdBannerView.swift` のテスト広告 ID を本番 ID に差し替える
  - 現状: `ca-app-pub-3940256099942544/2934735716`
- [ ] `OniTan/OniTanApp.swift` に Mobile Ads SDK 初期化を入れる
- [ ] 必要なら UMP による同意取得を実装する
- [ ] 初回申請で広告なしにするなら、表示条件と依存を整理する

### 設定画面

- [ ] `設定` 画面に以下のリンクを追加する
  - [ ] プライバシーポリシー
  - [ ] サポート
  - [ ] 利用規約 or 特商法表記が必要ならその導線
- [ ] バージョン表示が `1.0` フォールバックにならないようにする

### 寄付課金

- [ ] App Store Connect に登録した商品情報で `loadProduct()` が取得できることを確認する
- [ ] 実機 Sandbox で購入 / 復元を確認する
- [ ] 寄付完了後に広告が消える挙動を確認する
  - 利用箇所:
    - `OniTan/MainView.swift`
    - `OniTan/StreakChallengeView.swift`

## 4. App Store Connect 側の作業

### アプリ情報

- [ ] アプリレコードを作成する
- [ ] アプリ名を確定する
- [ ] サブタイトルを作成する
- [ ] カテゴリを設定する
- [ ] 年齢レーティング質問票を回答する
  - 2026年の新質問対応済みか確認する
- [ ] サポート URL を入力する
- [ ] プライバシーポリシー URL を入力する

### App Privacy

- [ ] 収集データを棚卸しする
  - アプリ本体:
    - `UserDefaults`
    - 学習進捗
    - 課金状態
  - SDK:
    - GoogleMobileAds
    - UserMessagingPlatform
- [ ] AdMob を入れる場合の申告内容を整理する
  - GoogleMobileAds の privacy manifest では `Device ID` を tracking 対象として宣言
  - 他にも `Advertising Data`, `Product Interaction`, `Coarse Location`, `Performance Data`, `Crash Data`, `Other Diagnostic Data` が含まれる
- [ ] ATT を出すか、追跡なしで配信するか決める

### 課金

- [ ] アプリ内課金契約状態を確認する
- [ ] IAP 商品を `Ready to Submit` にする
- [ ] スクリーンショットが必要な課金商品なら用意する
- [ ] 初回申請時にアプリ本体と一緒にレビューへ送る

### メタデータ

- [ ] 説明文を書く
- [ ] キーワードを設定する
- [ ] 新機能説明文を用意する
- [ ] 審査用メモを書く
  - 課金の導線
  - 広告の表示条件
  - ログイン不要であること
  - テストアカウント不要であること

## 5. 提出用素材

- [ ] 6.9-inch iPhone スクリーンショットを撮る
- [ ] 6.5-inch iPhone スクリーンショットを撮る
- [ ] App Icon 1024x1024 を用意する
- [ ] 必要ならプレビュー動画を用意する

撮影候補:

- [ ] ホーム
- [ ] ステージ選択
- [ ] 問題画面
- [ ] 解説表示
- [ ] 成績 / 統計
- [ ] 設定 / 寄付

## 6. 検証結果

### ビルド

- [x] `Release` ビルド成功
- [ ] アーカイブして Organizer から Validate App を通す
- [ ] TestFlight へアップロードする

### テスト

- [x] 単体テストを全件グリーンにする
  - 現状:
    - `xcodebuild test -scheme OniTan -project OniTan.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -derivedDataPath /tmp/OniTanUnitTestDerivedData -only-testing:OniTanTests`
    - 57 tests 実行、57件成功
- [ ] UI テストを安定して通す
  - 現状:
    - シミュレータで `xctrunner` 起動失敗 (`Mach error -308`)
    - 申請ブロッカーではないが、リグレッション確認の信頼性が低い

### 実機確認

- [ ] 初回起動
- [ ] 71ステージの読み込み
- [ ] ステージ選択から出題
- [ ] 今日の学習
- [ ] 成績保存 / 復元
- [ ] 課金購入 / 復元
- [ ] 広告表示 / 非表示
- [ ] オフライン動作
- [ ] 画面回転時の挙動

## 7. 先に決めるべき2つの方針

### 方針A: 初回リリースで広告を入れるか

広告ありにすると:

- AdMob 本番設定
- App Privacy 申告の増加
- ATT 方針の決定
- プライバシーポリシー整備

が必要になる。

初回リリースを軽くするなら、広告を外して先に学習アプリ本体だけ出す方が申請難易度は下がる。

### 方針B: iPhone専用で進める

- すでに iPhone専用に決定
- iPad用スクリーンショットは不要
- iPad向け回転要件の確認も不要

## 8. 推奨着手順

1. `App Icon` を作成して `Assets.xcassets` に反映する
2. `Privacy Policy URL`, `Support URL` を用意する
3. IAP を App Store Connect に登録し、実機 Sandbox で購入確認する
4. スクリーンショットを撮る
5. 広告を入れるなら最後に本番設定と App Privacy を揃える
6. アーカイブ -> Validate -> TestFlight -> App Review 提出

## 9. Apple公式確認リンク

- Upcoming Requirements:
  - https://developer.apple.com/news/upcoming-requirements/
- App Information:
  - https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- App Privacy:
  - https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy/
- Screenshot Specifications:
  - https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/
- Submit an App:
  - https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app
- Submit an In-App Purchase:
  - https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase
- Encryption Documentation:
  - https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation
- User Privacy and Data Use:
  - https://developer.apple.com/app-store/user-privacy-and-data-use/
- App Review Guidelines:
  - https://developer.apple.com/app-store/review/guidelines/
