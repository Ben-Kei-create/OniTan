# Supplemental Question Data — Status

## ⚠️ Sample / Development Data Only

The following files in `OniTan/Resources/` contain **sample data for format and UI
verification purposes only**. They are **not** production-quality Kanken Pre-1
(準1級) content and must not be shipped or relied upon as-is:

- `hyogai_reading_questions.json`
- `compound_reading_kun_questions.json`
- `common_kanji_questions.json`
- `error_correction_questions.json`
- `proverb_questions.json`
- `passage_questions.json`
- `yojijukugo_questions.json`
- `synonym_questions.json`
- `antonym_questions.json`

Each file currently holds 20 questions, expanded from an initial set of 5 to allow:

- Validation of the JSON schema and `Scripts/validate_questions.py`
- UI/UX testing of each dojo (道場) category, including 10問クイック
- Cross-format coverage testing for ミニ模試

### Known limitations

- Question difficulty, vocabulary selection, and explanations were drafted
  without verification against official Kanken 準1級 source material
  (past exams, official word lists, dictionaries).
- Some entries may be too easy, too hard, or outside the official 準1級 scope.
- Distractor choices have not been checked for ambiguity or multiple valid answers.

### Before production release

Production-quality 準1級 data must be created via a separate effort that includes:

1. Sourcing vocabulary/idioms/proverbs from official Kanken word lists or
   reputable reference materials (with citations).
2. Level validation (difficulty calibration) against real past exams.
3. Review for ambiguous or multiple-correct-answer choices.
4. Expansion only after the above is in place — do **not** scale these files
   to thousands of questions based on the current sample data.

`writing_questions.json` and the legacy `stage1.json`–`stage96.json` /
`review_questions.json` files are unaffected by this note.
