# 準1級 本番データ投入方針

## 目的

`docs/SUPPLEMENTAL_DATA_STATUS.md` で「開発用サンプル」と明記した
9つの補助問題ファイルを、将来的に本番品質の準1級データへ置き換える
ための方針・手順をまとめる。本ドキュメント自体は問題データを追加・
変更しない。

対象ファイル（各20問のサンプルデータ）:

- hyogai_reading_questions.json
- compound_reading_kun_questions.json
- common_kanji_questions.json
- error_correction_questions.json
- proverb_questions.json
- passage_questions.json
- yojijukugo_questions.json
- synonym_questions.json
- antonym_questions.json

## 基本方針

1. 本番データは「サンプルを増やす」のではなく、
   出典確認済みの語彙・成句を新たに収集して置き換える。
2. 1ファイルずつ・1出題形式ずつ進める（全形式同時並行はしない）。
3. 既存のJSONスキーマ・payload構造は変更しない
   （Question.swift / QuestionKind.swift のpayload定義に準拠）。
4. 既存のサンプル問題のID体系（例: hyogai-001〜020）は維持し、
   置き換え時もID重複が起きないようにする。
5. validate_questions.py を毎回実行し、0エラーを必須とする。

## 出典確認のルール

- 採用する語彙・四字熟語・ことわざ・読みは、
  公的に参照可能な辞書または漢検準1級の出題範囲に
  対応する一般的な参考資料に基づくこと。
- 出典は explain フィールドの「出典:」行に記録する
  （既存サンプルと同じ形式を踏襲）。
- 出典が確認できない語句・用例は採用しない。
  「それらしい」だけの語句は本番データに含めない。

## 難易度・表記の検証

- difficulty は 1〜5 の範囲で、実際の準1級過去問の
  難易度感に近づける（高難度語に1や2をつけない、など）。
- 選択肢（choices）は4つとも文脈上「もっともらしい」誤答で
  あること。複数正解になり得る選択肢は禁止。
- answer は choices に必ず含まれる（validatorで自動チェック）。

## 重複・曖昧表現レビュー

- 同一語句・同一テーマが複数ファイル間で重複していないか確認する
  （Phase 5Aで「杞憂」の重複回避を行った前例を踏襲）。
- 1問につき正解が一意に定まるか、第三者視点でレビューする。

## 進め方（推奨順序）

1. 形式ごとの優先度を決める（出題頻度の高い 読み系・四字熟語・
   類義語対義語 を優先）。
2. 1形式につき、20問→本番相当の問題数へ段階的に拡張する。
   一度に大量生成しない（Phase 5Aの反省点）。
3. 各バッチごとに validate_questions.py を実行。
4. レビュー後、SUPPLEMENTAL_DATA_STATUS.md の記載を該当ファイルのみ
   「本番データ反映済み」に更新する。

## 非対象

- writing_questions.json および stage1〜96 / review_questions.json
  （legacy）は本方針の対象外。
- 書き取り（writingSkipped）形式は引き続き未対応のまま。
