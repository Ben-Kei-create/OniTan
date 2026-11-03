import unittest

import validate_questions as validator


class ErrorCorrectionValidationTests(unittest.TestCase):
    def setUp(self):
        validator.errors.clear()
        validator.warnings.clear()

    def question(self, original="説明に意議を唱えた。", kind="errorCorrection"):
        return {
            "kanji": original,
            "choices": ["意→異", "意→以", "意→委", "意→違"],
            "answer": "意→異",
            "explain": "反対の意見を申し立てる意味では異議を使う。",
            "kind": kind,
            "payload": {
                "originalSentence": original,
                "correctedSentence": "説明に異議を唱えた。",
                "wrongKanji": "意",
                "correctKanji": "異",
            },
        }

    def test_current_and_legacy_kinds_accept_single_character_correction(self):
        for kind in ("errorCorrection", "errorcorrection"):
            with self.subTest(kind=kind):
                validator.validate_question(self.question(kind=kind), kind)
                self.assertEqual(validator.errors, [])

    def test_two_character_typo_is_rejected(self):
        validator.validate_question(self.question(original="説明に意義を唱えた。"), "two changes")
        self.assertTrue(any("reconstruct" in error for error in validator.errors))

    def test_missing_wrong_character_is_rejected(self):
        validator.validate_question(self.question(original="説明に異議を唱えた。"), "no typo")
        self.assertTrue(any("reconstruct" in error for error in validator.errors))

    def test_answer_must_match_the_payload_correction(self):
        question = self.question()
        question["answer"] = "意→以"
        validator.validate_question(question, "wrong answer")
        self.assertTrue(any("answer does not match" in error for error in validator.errors))

    def test_duplicate_choices_are_rejected_in_standalone_files_too(self):
        question = self.question()
        question["choices"][-1] = "意→異"
        validator.validate_question(question, "duplicate choices")
        self.assertTrue(any("duplicate choices" in error for error in validator.errors))


if __name__ == "__main__":
    unittest.main()
