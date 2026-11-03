#!/usr/bin/env python3
"""
validate_questions.py — OniTan question data validator

Usage:
    python3 Scripts/validate_questions.py [--dir OniTan/Resources] [--strict] [--stages]

Checks:
    - Required fields present and non-empty
    - answer is in choices
    - choices has at least 2 items (warns if < 4)
    - kind is a known QuestionKind value
    - Payload fields match the kind
    - No duplicate IDs across files
    - Yojijukugo: yoji is exactly 4 chars (counting □ as 1)
    - Cloze: blankToken appears in sentence
    - ErrorCorrection: wrongKanji != correctKanji
"""

import json
import sys
import os
import argparse
from pathlib import Path

VALID_KINDS = {
    # Current exam-aligned kinds
    "reading", "sentenceReading", "hyogaiReading", "compoundReadingKun",
    "commonKanji", "errorCorrection",
    "yojijukugo", "synonym", "antonym",
    "proverb", "passageReading", "passageVocabulary",
    "writingSkipped",
    # Legacy aliases accepted in JSON (remapped by the Swift decoder)
    "writing", "errorcorrection", "jukujikun", "cloze",
    "usage", "composition", "okurigana", "radical", "examMixed",
}

# Kinds that are exam-eligible (used when checking blueprints)
EXAM_ELIGIBLE_KINDS = {
    "sentenceReading", "hyogaiReading", "compoundReadingKun",
    "commonKanji", "errorCorrection",
    "yojijukugo", "synonym", "antonym",
    "proverb", "passageReading", "passageVocabulary",
}

VALID_STRUCTURE_TYPES = {
    "AB", "A→B", "A←B", "A=B", "A+B"
}

errors: list[str] = []
warnings: list[str] = []
seen_ids: dict[str, str] = {}  # id → filename


def err(tag: str, msg: str):
    errors.append(f"[ERROR] {tag}: {msg}")


def warn(tag: str, msg: str):
    warnings.append(f"[WARN]  {tag}: {msg}")


def validate_question(q: dict, tag: str):
    # Required fields
    for field in ("kanji", "choices", "answer", "kind", "explain"):
        if field not in q:
            err(tag, f"missing required field '{field}'")
        elif isinstance(q[field], str) and not q[field].strip():
            err(tag, f"field '{field}' is empty")

    if "choices" not in q or "answer" not in q:
        return  # can't continue safely

    choices = q.get("choices", [])
    answer = q.get("answer", "")
    kind = q.get("kind", "")

    if not isinstance(choices, list):
        err(tag, "choices must be an array")
        return

    if len(choices) < 2:
        err(tag, f"choices has {len(choices)} item(s) — minimum is 2")
    elif len(choices) < 4:
        warn(tag, f"choices has {len(choices)} item(s) — recommended is 4")

    if answer not in choices:
        err(tag, f"answer '{answer}' not in choices {choices}")

    if "" in choices:
        err(tag, "choices contains empty string(s)")

    if len(set(choices)) != len(choices):
        err(tag, "duplicate choices")

    if kind not in VALID_KINDS:
        err(tag, f"unknown kind '{kind}'")

    # Payload checks
    payload = q.get("payload")
    if payload is None:
        return

    p_type = payload.get("type", "")

    if kind == "yojijukugo":
        yoji = payload.get("yoji", "")
        if yoji:
            cleaned = yoji.replace("□", "X")
            if len(cleaned) != 4:
                err(tag, f"yoji '{yoji}' is {len(cleaned)} chars, expected 4")
        else:
            warn(tag, "yojijukugo payload missing 'yoji'")
        if "missingIndex" not in payload:
            warn(tag, "yojijukugo payload missing 'missingIndex'")

    elif kind == "cloze":
        sentence = payload.get("sentence", "")
        token = payload.get("blankToken", "")
        if sentence and token and token not in sentence:
            err(tag, f"blankToken '{token}' not found in sentence")

    elif kind in ("errorCorrection", "errorcorrection"):
        wrong = payload.get("wrongKanji", "")
        correct = payload.get("correctKanji", "")
        if len(wrong) != 1 or len(correct) != 1 or wrong == correct:
            err(tag, "error correction must replace one distinct character")
        orig = payload.get("originalSentence", "")
        corrected = payload.get("correctedSentence", "")
        if not orig or not corrected:
            err(tag, "error correction is missing originalSentence/correctedSentence")
        elif not wrong or orig.count(wrong) != 1 or orig.replace(wrong, correct, 1) != corrected:
            err(tag, "one-character correction does not reconstruct correctedSentence")
        if answer != f"{wrong}→{correct}":
            err(tag, "answer does not match wrongKanji→correctKanji")

    elif kind == "composition":
        st = payload.get("structureType", "")
        if st and st not in VALID_STRUCTURE_TYPES:
            err(tag, f"structureType '{st}' not in {sorted(VALID_STRUCTURE_TYPES)}")

    elif kind in ("synonym", "antonym"):
        if not payload.get("targetWord"):
            warn(tag, f"{kind} payload missing 'targetWord'")
        if not payload.get("relationWord"):
            warn(tag, f"{kind} payload missing 'relationWord'")

    elif kind == "commonKanji":
        terms = payload.get("blankTerms", [])
        if not terms:
            warn(tag, "commonKanji payload missing 'blankTerms'")
        else:
            for term in terms:
                if "□" not in term:
                    warn(tag, f"commonKanji blankTerm '{term}' has no □ placeholder")

    elif kind == "compoundReadingKun":
        if not payload.get("targetCompound"):
            warn(tag, "compoundReadingKun payload missing 'targetCompound'")

    elif kind in ("sentenceReading", "hyogaiReading"):
        if not payload.get("sentenceContext") and not payload.get("targetWord"):
            warn(tag, f"{kind} payload should have 'sentenceContext' or 'targetWord'")

    elif kind in ("passageReading", "passageVocabulary"):
        if not payload.get("passageText"):
            warn(tag, f"{kind} payload missing 'passageText'")

    elif kind in ("writing", "writingSkipped"):
        if not payload.get("kana") and not payload.get("kanaPrompt"):
            warn(tag, "writing payload missing 'kana'/'kanaPrompt'")

    elif kind == "okurigana":
        if not payload.get("baseWord"):
            warn(tag, "okurigana payload missing 'baseWord'")


LEGACY_FILES = {"review_questions.json", "unused_questions.json"}


def validate_file(path: Path, legacy: bool = False) -> int:
    with open(path, encoding="utf-8") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            err(str(path), f"JSON parse error: {e}")
            return 0

    if not isinstance(data, list):
        err(str(path), "top-level value must be an array")
        return 0

    for i, q in enumerate(data):
        qid = q.get("id", f"<index {i}>")
        kanji = q.get("kanji", "<?>")
        tag = f"{path.name}#{qid}({kanji})"

        if legacy:
            # Legacy files: only check the basics
            if not q.get("kanji"):
                err(tag, "missing 'kanji'")
            choices = q.get("choices", [])
            answer = q.get("answer", "")
            if isinstance(choices, list) and answer and answer not in choices:
                err(tag, f"answer '{answer}' not in choices")
            continue

        # Duplicate ID check (global across files)
        if qid != f"<index {i}>" and qid in seen_ids:
            err(tag, f"duplicate ID '{qid}' (also in {seen_ids[qid]})")
        else:
            seen_ids[qid] = path.name

        validate_question(q, tag)

    return len(data)


def validate_stages(resources: Path) -> int:
    """Validate the manifests and the stage files actually loaded by the app."""
    stage_ids = set()
    stage_files = set()
    total = 0
    for manifest_path in sorted(resources.glob("*_stages.json")):
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        prompts = set()
        for entry in manifest["stages"]:
            stage_id = entry["id"]
            filename = entry["file"]
            if stage_id in stage_ids:
                err(filename, f"duplicate stage ID {stage_id}")
            if filename in stage_files:
                err(filename, "stage file referenced more than once")
            stage_ids.add(stage_id)
            stage_files.add(filename)
            path = resources / filename
            if not path.is_file():
                err(filename, "manifest references missing file")
                continue
            stage = json.loads(path.read_text(encoding="utf-8"))
            if stage["stage"] != stage_id:
                err(filename, "stage number does not match manifest ID")
            if not stage["questions"]:
                err(filename, "empty stage")
            for index, q in enumerate(stage["questions"]):
                tag = f"{filename}#{index}"
                validate_question(q, tag)
                signature = (q["kanji"], q["answer"], q.get("payload", {}).get("sentenceContext", ""))
                if signature in prompts:
                    err(tag, f"repeated question within genre: {signature}")
                prompts.add(signature)
                payload = q.get("payload", {})
                if q["kind"] == "yojijukugo":
                    yoji = payload.get("yoji", "")
                    blank = payload.get("missingIndex", -1)
                    if (yoji.count("□") != 1 or yoji.find("□") != blank
                            or yoji.replace("□", q["answer"]) != q["kanji"]):
                        err(tag, "cloze answer does not reconstruct the idiom")
                if q["kind"] == "sentenceReading":
                    target = payload.get("targetKanji", q["kanji"])
                    if target not in payload.get("sentenceContext", ""):
                        err(tag, "reading target is missing from sentence")
            total += len(stage["questions"])
        print(f"  {manifest_path.name}: {len(manifest['stages'])} stages")
    return total


def main():
    parser = argparse.ArgumentParser(description="Validate OniTan question JSON files")
    parser.add_argument("--dir", default="OniTan/Resources", help="Resources directory")
    parser.add_argument("--strict", action="store_true", help="Exit non-zero on warnings too")
    parser.add_argument("--stages", action="store_true", help="Also validate all manifest-referenced stages")
    parser.add_argument("files", nargs="*", help="Specific files to validate (default: all *_questions.json)")
    args = parser.parse_args()

    resources = Path(args.dir)
    if args.files:
        paths = [Path(f) for f in args.files]
    else:
        paths = sorted(resources.glob("*_questions.json"))

    if not paths:
        print(f"No *_questions.json files found in {resources}")
        sys.exit(0)

    total = 0
    for p in paths:
        is_legacy = p.name in LEGACY_FILES
        count = validate_file(p, legacy=is_legacy)
        suffix = " (legacy)" if is_legacy else ""
        print(f"  {p.name}{suffix}: {count} questions")
        total += count

    print(f"\nTotal: {total} questions across {len(paths)} file(s)")
    if args.stages:
        stage_total = validate_stages(resources)
        print(f"\nMain stages: {stage_total} questions")

    if warnings:
        print(f"\n{len(warnings)} warning(s):")
        for w in warnings:
            print(f"  {w}")

    if errors:
        print(f"\n{len(errors)} error(s):")
        for e in errors:
            print(f"  {e}")
        sys.exit(1)
    elif args.strict and warnings:
        sys.exit(1)
    else:
        print("\nAll checks passed." if not warnings else "\nPassed with warnings.")
        sys.exit(0)


if __name__ == "__main__":
    main()
