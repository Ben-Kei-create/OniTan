# 問題データ JSON フォーマット

新しい問題を追加するときのテンプレート集。`kind` ごとにコピーして埋める。

## 共通フィールド

| フィールド | 必須 | 説明 |
|---|---|---|
| `id` | 任意 | 省略可。省略時は `"{kanji}-{answer}"` が自動生成される。重複しないIDを明示する場合は推奨（例: `"comk-005"`）。 |
| `kanji` | ◯ | 学習記録・お気に入り判定に使うキー。原則「見出しの漢字／熟語」。 |
| `prompt` | 任意 | 問題文の表示を上書きしたい場合のみ指定。通常は `kind`/`payload` から自動生成されるので省略可。 |
| `choices` | ◯ | 選択肢（通常4つ）。`answer` を含める必要あり（含まれていなければ自動追加される）。 |
| `answer` | ◯ | 正解。`choices` のいずれかと一致させる。 |
| `explain` | ◯ | 解説文。改行 `\n` で区切る。`意味:` で始まる行は語句の意味として特別扱いされる。`出典:` 行は表示時に除外される。 |
| `kind` | ◯ | 下記の問題種別のいずれか。 |
| `tags` | 任意 | `["準1級", ...]` など。 |
| `difficulty` | 任意 | 1〜5程度の整数。難易度ソートに使用（小さいほど易しい）。 |
| `payload` | kindによる | 種別ごとの追加情報。下記参照。 |

---

## 1. `reading`（読み・旧形式 / kanji_catalog_questions.json 用）

漢字一覧（KanjiCatalogView）に表示される単漢字の読み問題。クイズ進行には使われない。

```json
{
  "id": "乃-だい",
  "kanji": "乃",
  "choices": ["だん", "だち", "だつ", "だい"],
  "answer": "だい",
  "explain": "意味: すなわち／そこで／漸く\n正解の読み: だい\n音読み: の・だい・ない\n訓読み: すなわち・なんじ\n出典: モジナビ",
  "kind": "reading"
}
```

- `kanji`: 単漢字1文字。
- `explain`: `意味:` / `正解の読み:` / `音読み:` / `訓読み:` / `出典:` の行を含めるのが慣習。

---

## 2. `sentenceReading`（例文読み / stageX.json 用）

例文中の下線部の読みを答える。クイズの主要出題形式。

```json
{
  "kanji": "厩舎",
  "choices": ["きゅうしゃ", "きゅうや", "うまや", "げんしゃ"],
  "answer": "きゅうしゃ",
  "explain": "例文: 厩舎を毎朝掃除する。\n正解の読み: きゅうしゃ\n意味: 牛馬を飼育する小屋。",
  "kind": "sentenceReading",
  "tags": ["例文読み", "準1級"],
  "difficulty": 4,
  "payload": {
    "type": "sentenceReading",
    "targetKanji": "厩舎",
    "sentenceContext": "厩舎を毎朝掃除する。"
  }
}
```

- `payload.targetKanji`: 下線部の熟語（カタログ登録キーになる）。
- `payload.sentenceContext`: 表示される例文（下線部を含む）。

---

## 3. `hyogaiReading`（表外の読み）

```json
{
  "kanji": "鬩ぐ",
  "choices": ["せめぐ", "いきりぐ", "もつれぐ", "あらがう"],
  "answer": "せめぐ",
  "explain": "例文: 兄弟が遺産を巡って鬩ぎ合う。\n正解の読み: せめぐ\n意味: 互いに争う・いがみ合う。",
  "kind": "hyogaiReading",
  "tags": ["表外の読み", "準1級"],
  "difficulty": 5,
  "payload": {
    "type": "hyogaiReading",
    "targetKanji": "鬩ぐ",
    "readingType": "hyogai",
    "sentenceContext": "兄弟が遺産を巡って鬩ぎ合う。"
  }
}
```

- `payload.readingType`: `"on"` | `"kun"` | `"mixed"` | `"hyogai"`。
- `sentenceContext` が無い場合は `targetWord` が表示される。

---

## 4. `compoundReadingKun`（熟語の読み・一字訓）

熟語の中の特定の一字の読みを答える。

```json
{
  "kanji": "山河",
  "choices": ["やま", "さん", "せん", "かわ"],
  "answer": "やま",
  "explain": "「山河」の「山」を訓読みする。\n正解の読み: やま\n意味: 山と川。自然の風景。",
  "kind": "compoundReadingKun",
  "tags": ["熟語の読み", "準1級"],
  "difficulty": 3,
  "payload": {
    "type": "compoundReadingKun",
    "targetCompound": "山河",
    "targetKanjiInCompound": "山"
  }
}
```

- `payload.targetCompound`: 問題文に表示される熟語。
- `payload.targetKanjiInCompound`: 読みを問われる一字（単漢字。お気に入り登録のキーになる）。

---

## 5. `commonKanji`（共通漢字）

複数の空欄に共通して入る漢字を選ぶ。

```json
{
  "id": "comk-005",
  "kanji": "□国・□王・□族",
  "prompt": "□国・□王・□族 に共通する漢字を選べ。",
  "choices": ["皇", "帝", "王", "君"],
  "answer": "皇",
  "explain": "「皇国」「皇居」「皇族」すべてに「皇」が共通する。",
  "kind": "commonKanji",
  "tags": ["共通漢字", "準1級"],
  "difficulty": 3,
  "payload": {
    "blankTerms": ["□国", "□居", "□族"]
  }
}
```

- `id`: `"comk-XXX"` の連番を推奨。
- `prompt`: 必須に近い（`payload.blankTerms` からも自動生成されるが、明示推奨）。
- `payload.blankTerms`: 空欄を含む語句のリスト（表示に使用）。
- `answer`: 単漢字1文字。

---

## 6. `errorCorrection`（誤字訂正）

文中の誤った漢字を正しい漢字に置き換える。

```json
{
  "kanji": "誤字訂正",
  "choices": ["契", "係", "傾", "径"],
  "answer": "契",
  "explain": "「契約書に景印を押す」の「景」は誤り。正しくは「契」（契約・約束の意）。",
  "kind": "errorCorrection",
  "tags": ["誤字訂正", "準1級"],
  "difficulty": 4,
  "payload": {
    "type": "errorCorrection",
    "originalSentence": "契約書に景印を押す。",
    "wrongKanji": "景",
    "correctKanji": "契",
    "correctedSentence": "契約書に契印を押す。"
  }
}
```

- `choices`/`answer`: 正しい漢字（`correctKanji` と一致）。
- `payload.wrongKanji`: 文中の誤字（単漢字）。
- `payload.correctKanji`: 正しい漢字（単漢字、お気に入り登録キー）。

---

## 7. `yojijukugo`（四字熟語）

四字熟語の空欄に入る漢字を選ぶ。

```json
{
  "kanji": "温故知新",
  "choices": ["故", "古", "顧", "固"],
  "answer": "故",
  "explain": "「温故知新」＝故きを温ねて新しきを知る。昔のことを学び新たな知見を得ること。",
  "kind": "yojijukugo",
  "tags": ["四字熟語", "準1級"],
  "difficulty": 3,
  "payload": {
    "yoji": "温□知新",
    "missingIndex": 1,
    "meaning": "昔のことを学び新たな知見を得ること。"
  }
}
```

- `payload.yoji`: 4文字のうち答えの位置を `□` にした文字列。
- `payload.missingIndex`: 空欄の位置（0始まり）。
- `answer`: 単漢字1文字。

---

## 8. `synonym` / `antonym`（類義語・対義語）

```json
{
  "kanji": "倹約",
  "choices": ["浪費", "節約", "贅沢", "豪奢"],
  "answer": "節約",
  "explain": "「倹約」と「節約」はいずれも無駄遣いをしないこと。",
  "kind": "synonym",
  "tags": ["類義語", "準1級"],
  "difficulty": 3,
  "payload": {
    "targetWord": "倹約"
  }
}
```

- `kind`: 対義語の場合は `"antonym"`。
- `payload.targetWord`: 出題語（画面上部に大きく表示される）。
- `answer`: 類義語／対義語そのもの。

---

## 9. `proverb`（故事・成語・ことわざ）

ことわざの意味として正しい選択肢を選ぶ。

```json
{
  "kanji": "故事成語",
  "choices": [
    "苦労せず利益を得ること",
    "他人の力を借りて立派に見せること",
    "小さな失敗が大きな成果につながること",
    "争いの中で利益を得る第三者"
  ],
  "answer": "他人の力を借りて立派に見せること",
  "explain": "「虎の威を借る狐」＝自分には実力がないのに、強い者の権威を頼りにして威張ること。",
  "kind": "proverb",
  "tags": ["故事・ことわざ", "準1級"],
  "difficulty": 3,
  "payload": {
    "proverbText": "虎の威を借る狐",
    "proverbMeaning": "自分には実力がないのに、強い者の権威を頼りにして威張ること。"
  }
}
```

- `payload.proverbText`: ことわざ・故事成語本文（問題文として表示）。
- `choices`/`answer`: 意味の説明文（4択）。

---

## 10. `passageReading` / `passageVocabulary`（文章題）

長文中の下線部の読み（`passageReading`）または空欄に入る語句（`passageVocabulary`）。

```json
{
  "kanji": "文章題",
  "choices": ["かんよう", "ほうよう", "じゅうよう", "ようご"],
  "answer": "かんよう",
  "explain": "「寛容」＝心が広く、人の言動を受け入れること。",
  "kind": "passageReading",
  "tags": ["文章題", "準1級"],
  "difficulty": 4,
  "payload": {
    "type": "passageReading",
    "passageText": "彼の①寛容な態度は、周囲との関係を円滑にしている。",
    "passageTarget": 1,
    "passageTargetText": "寛容"
  }
}
```

- `payload.passageText`: 長文全体（下線部・空欄番号を含む）。
- `payload.passageTarget`: 設問番号（1始まり）。
- `payload.passageTargetText`: 設問対象の語句（カタログ登録に使用）。
- `passageVocabulary` の場合は `payload.passageBlankToken` で空欄トークンを指定し、`choices`/`answer` は埋める語句にする。

---

## バリデーションの目安

- `choices` は重複なし、`answer` を含む。
- `answer` は `choices` 内の表記と完全一致（全角/半角・送り仮名のゆらぎに注意）。
- `explain` の `意味:` 行は KanjiCatalogView 等で抽出表示されるため、できるだけ記載する。
- `tags` には `"準1級"` を含めるのが慣習。
- 既存の `id` と重複しないこと（特に `commonKanji` の `comk-XXX`）。
