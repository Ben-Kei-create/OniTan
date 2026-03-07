#!/usr/bin/env python3

import hashlib
import json
import re
import ssl
import tempfile
import time
import unicodedata
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any
from urllib.parse import urljoin
from urllib.request import Request, urlopen

from bs4 import BeautifulSoup


ROOT = Path(__file__).resolve().parents[1]
RESOURCES_DIR = ROOT / "OniTan" / "Resources"
DOCS_DIR = ROOT / "docs"
CACHE_DIR = Path(tempfile.gettempdir()) / "onitan_quiz_rebuild_cache"
SSL_CONTEXT = ssl._create_unverified_context()
USER_AGENT = "Mozilla/5.0 (Codex; OniTan quiz rebuild)"
STAGE_COUNT = 66

KANJITISIKI_INDEX_URL = "https://kanjitisiki.com/kanken/1-2kyu-01.html"
MOJINAVI_INDEX_URL = "https://mojinavi.com/d/list-kanji-kanken-01j"


def ensure_dirs() -> None:
    DOCS_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)


def dedupe_keep_order(values: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        if value and value not in seen:
            seen.add(value)
            result.append(value)
    return result


def katakana_to_hiragana(text: str) -> str:
    converted: list[str] = []
    for char in text:
        if "ァ" <= char <= "ヶ":
            converted.append(chr(ord(char) - 0x60))
        elif char == "ヴ":
            converted.append("ゔ")
        else:
            converted.append(char)
    return "".join(converted)


def normalize_reading(text: str) -> str:
    value = katakana_to_hiragana(text.strip())
    replacements = {
        " ": "",
        "　": "",
        "・": "",
        "･": "",
        "、": "",
        ",": "",
        "，": "",
        ".": "",
        "．": "",
        "(": "",
        ")": "",
        "（": "",
        "）": "",
        "《": "",
        "》": "",
        "「": "",
        "」": "",
        "〜": "",
        "～": "",
        "~": "",
        "-": "",
        "‐": "",
        "‑": "",
        "―": "",
    }
    for source, target in replacements.items():
        value = value.replace(source, target)
    return value


def stable_sort_key(seed: str, value: str) -> tuple[int, int]:
    digest = hashlib.sha256(f"{seed}|{value}".encode("utf-8")).hexdigest()
    return (len(value), int(digest[:12], 16))


def kanji_identity_key(value: str) -> str:
    return unicodedata.normalize("NFKC", value)


def fetch_text(url: str, namespace: str) -> str:
    cache_path = cache_path_for(url, namespace)
    if cache_path.exists():
        return cache_path.read_text(encoding="utf-8")

    text = download_text(url)
    cache_path.write_text(text, encoding="utf-8")
    return text


def cache_path_for(url: str, namespace: str) -> Path:
    cache_key = hashlib.sha1(url.encode("utf-8")).hexdigest()
    return CACHE_DIR / f"{namespace}_{cache_key}.html"


def download_text(url: str) -> str:
    last_error: Exception | None = None
    for attempt in range(4):
        try:
            request = Request(url, headers={"User-Agent": USER_AGENT})
            with urlopen(request, context=SSL_CONTEXT, timeout=30) as response:
                return response.read().decode("utf-8", errors="ignore")
        except Exception as error:  # noqa: BLE001
            last_error = error
            time.sleep(0.5 * (attempt + 1))

    if last_error is not None:
        raise last_error
    raise RuntimeError(f"Failed to fetch {url}")


def fetch_valid_soup(url: str, namespace: str, validator) -> BeautifulSoup:
    cache_path = cache_path_for(url, namespace)
    for attempt in range(4):
        if cache_path.exists():
            text = cache_path.read_text(encoding="utf-8")
        else:
            text = download_text(url)
            cache_path.write_text(text, encoding="utf-8")

        soup = BeautifulSoup(text, "html.parser")
        if validator(soup):
            return soup

        cache_path.unlink(missing_ok=True)
        time.sleep(0.5 * (attempt + 1))

    raise RuntimeError(f"Invalid page after retries: {url}")


def parse_kanjitisiki_index() -> list[dict[str, str]]:
    html = fetch_text(KANJITISIKI_INDEX_URL, "kanjitisiki_index")
    soup = BeautifulSoup(html, "html.parser")

    entries: list[dict[str, str]] = []
    seen: set[str] = set()
    for link in soup.select("table.kanjiitiran a[href]"):
        kanji = link.get_text(strip=True)
        if len(kanji) != 1 or kanji in seen:
            continue
        seen.add(kanji)
        entries.append({"kanji": kanji, "url": link["href"]})

    if len(entries) != 3074:
        raise RuntimeError(f"Unexpected kanjitisiki index count: {len(entries)}")

    return entries


def parse_kanjitisiki_readings(soup: BeautifulSoup) -> tuple[list[str], list[str]]:
    header = next((h2 for h2 in soup.find_all("h2") if h2.get_text(strip=True) == "読み"), None)
    if header is None:
        return [], []

    paragraph = header.find_next_sibling("p")
    if paragraph is None:
        return [], []

    raw_html = paragraph.decode_contents()
    raw_html = re.sub(r'<img[^>]+alt="([^"]+)"[^>]*>', r"\1", raw_html)
    raw_html = raw_html.replace("<br/>", "\n").replace("<br>", "\n")
    lines = [
        BeautifulSoup(fragment, "html.parser").get_text("", strip=True)
        for fragment in raw_html.split("\n")
    ]

    onyomi: list[str] = []
    kunyomi: list[str] = []
    for line in lines:
        if not line:
            continue
        readings = [normalize_reading(value) for value in re.findall(r"「([^」]+)」", line)]
        readings = [value for value in readings if value]
        if "音読み" in line:
            onyomi.extend(readings)
        elif "訓読み" in line:
            kunyomi.extend(readings)

    return dedupe_keep_order(onyomi), dedupe_keep_order(kunyomi)


def parse_kanjitisiki_meaning(soup: BeautifulSoup) -> str:
    header = next((h2 for h2 in soup.find_all("h2") if h2.get_text(strip=True) == "意味"), None)
    if header is None:
        return ""

    node = header.find_next_sibling()
    while node is not None and getattr(node, "name", None) is None:
        node = node.find_next_sibling()
    if node is None:
        return ""

    if node.name == "ul":
        items = [item.get_text("", strip=True) for item in node.find_all("li", recursive=False)]
    else:
        items = [node.get_text("", strip=True)]

    cleaned = [re.sub(r"\s+", " ", value).strip() for value in items if value.strip()]
    return " / ".join(cleaned[:2])


def parse_kanjitisiki_detail(entry: dict[str, str]) -> dict[str, Any]:
    soup = fetch_valid_soup(
        entry["url"],
        "kanjitisiki_detail",
        lambda candidate: (
            candidate.find("h1") is not None
            and candidate.find("h1").get_text(strip=True) == entry["kanji"]
        ),
    )

    onyomi, kunyomi = parse_kanjitisiki_readings(soup)
    readings = dedupe_keep_order(onyomi + kunyomi)
    if not readings:
        raise RuntimeError(f"No kanjitisiki readings for {entry['kanji']}")

    return {
        "kanji": entry["kanji"],
        "url": entry["url"],
        "source": "漢字辞典",
        "primary_reading": onyomi[0] if onyomi else kunyomi[0],
        "onyomi": onyomi,
        "kunyomi": kunyomi,
        "readings": readings,
        "meaning": parse_kanjitisiki_meaning(soup),
    }


def parse_mojinavi_index() -> list[dict[str, str]]:
    html = fetch_text(MOJINAVI_INDEX_URL, "mojinavi_index")
    soup = BeautifulSoup(html, "html.parser")

    entries: list[dict[str, str]] = []
    seen: set[str] = set()
    for ruby in soup.select("tbody.itiran ruby"):
        anchor = ruby.find("a")
        reading = ruby.find("rt")
        if anchor is None:
            continue
        kanji = anchor.get_text(strip=True)
        if len(kanji) != 1 or kanji in seen:
            continue
        seen.add(kanji)
        entries.append(
            {
                "kanji": kanji,
                "url": urljoin("https://mojinavi.com", anchor["href"]),
                "primary_reading_raw": reading.get_text(strip=True) if reading else "",
            }
        )

    if len(entries) != 1238:
        raise RuntimeError(f"Unexpected mojinavi index count: {len(entries)}")

    return entries


def parse_mojinavi_reading_cell(cell: Any) -> list[str]:
    raw_html = cell.decode_contents()
    raw_html = raw_html.replace("<br/>", "\n").replace("<br />", "\n").replace("<br>", "\n")
    lines = [
        BeautifulSoup(fragment, "html.parser").get_text("", strip=True)
        for fragment in raw_html.split("\n")
    ]
    readings: list[str] = []
    for line in lines:
        cleaned = normalize_reading(line.replace("《外》", ""))
        if cleaned:
            readings.append(cleaned)
    return dedupe_keep_order(readings)


def parse_mojinavi_meaning(soup: BeautifulSoup, kanji: str) -> str:
    entry_content = soup.select_one("section.entry-content")
    if entry_content is None:
        return ""

    summary = ""
    for paragraph in entry_content.find_all("p", recursive=False):
        text = paragraph.get_text("", strip=True)
        if text.startswith(kanji) and "とは、" in text:
            summary = text
            break

    if not summary:
        return ""

    match = re.search(r"とは、(.+?)などの意味", summary)
    if match:
        return match.group(1)

    match = re.search(r"とは、(.+?)。", summary)
    return match.group(1) if match else summary


def parse_mojinavi_detail(entry: dict[str, str]) -> dict[str, Any]:
    soup = fetch_valid_soup(
        entry["url"],
        "mojinavi_detail",
        lambda candidate: (
            candidate.find("h1") is not None
            and f"「{entry['kanji']}」" in candidate.find("h1").get_text(strip=True)
        ),
    )

    table = soup.select_one("table.main")
    if table is None:
        raise RuntimeError(f"Missing mojinavi main table for {entry['kanji']}")

    onyomi: list[str] = []
    kunyomi: list[str] = []
    for row in table.find_all("tr"):
        headers = [th.get_text("", strip=True) for th in row.find_all("th")]
        cell = row.find("td")
        if cell is None:
            continue
        if "音読み" in headers:
            onyomi = parse_mojinavi_reading_cell(cell)
        elif "訓読み" in headers:
            kunyomi = parse_mojinavi_reading_cell(cell)

    primary_reading = normalize_reading(entry["primary_reading_raw"])
    if not primary_reading:
        primary_reading = onyomi[0] if onyomi else (kunyomi[0] if kunyomi else "")
    if not primary_reading:
        raise RuntimeError(f"No mojinavi primary reading for {entry['kanji']}")

    primary_is_kun = any(token in entry["primary_reading_raw"] for token in ["な.", "め", "たこ", "つ", "の", "ぐ", "える", "わる"])
    if primary_reading not in onyomi and primary_reading not in kunyomi:
        if primary_is_kun:
            kunyomi = dedupe_keep_order([primary_reading] + kunyomi)
        else:
            onyomi = dedupe_keep_order([primary_reading] + onyomi)

    readings = dedupe_keep_order([primary_reading] + onyomi + kunyomi)

    return {
        "kanji": entry["kanji"],
        "url": entry["url"],
        "source": "モジナビ",
        "primary_reading": primary_reading,
        "onyomi": onyomi,
        "kunyomi": kunyomi,
        "readings": readings,
        "meaning": parse_mojinavi_meaning(soup, entry["kanji"]),
    }


def scrape_entries(entries: list[dict[str, str]], parser, max_workers: int) -> list[dict[str, Any]]:
    details: list[dict[str, Any]] = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [executor.submit(parser, entry) for entry in entries]
        for future in as_completed(futures):
            details.append(future.result())

    detail_map = {detail["kanji"]: detail for detail in details}
    return [detail_map[entry["kanji"]] for entry in entries]


def load_existing_questions() -> dict[str, dict[str, Any]]:
    existing: dict[str, dict[str, Any]] = {}

    stage_pattern = re.compile(r"stage\d+\.json")
    for path in sorted(RESOURCES_DIR.glob("stage*.json")):
        if not stage_pattern.fullmatch(path.name):
            continue
        payload = json.loads(path.read_text(encoding="utf-8"))
        for question in payload.get("questions", []):
            kanji = question.get("kanji")
            if isinstance(kanji, str) and len(kanji) == 1 and kanji not in existing:
                existing[kanji] = question

    review_path = RESOURCES_DIR / "review_questions.json"
    if review_path.exists():
        payload = json.loads(review_path.read_text(encoding="utf-8"))
        for question in payload:
            kanji = question.get("kanji")
            if isinstance(kanji, str) and len(kanji) == 1 and kanji not in existing:
                existing[kanji] = question

    return existing


def build_explain(detail: dict[str, Any], answer: str) -> str:
    lines: list[str] = []
    if detail["meaning"]:
        lines.append(f"意味: {detail['meaning']}")
    lines.append(f"正解の読み: {answer}")
    if detail["onyomi"]:
        lines.append(f"音読み: {'・'.join(detail['onyomi'])}")
    if detail["kunyomi"]:
        lines.append(f"訓読み: {'・'.join(detail['kunyomi'])}")
    lines.append(f"出典: {detail['source']}")
    return "\n".join(lines)


def choose_distractors(
    answer: str,
    answer_type: str,
    detail: dict[str, Any],
    on_pool: list[str],
    kun_pool: list[str],
    all_pool: list[str],
) -> list[str]:
    excluded = set(detail["readings"])
    excluded.add(answer)

    primary_pool = on_pool if answer_type == "on" else kun_pool
    selected: list[str] = []

    def fill(pool: list[str], seed_suffix: str) -> None:
        candidates = [
            value
            for value in pool
            if value not in excluded and value not in selected and value
        ]
        ranked = sorted(
            candidates,
            key=lambda value: (
                abs(len(value) - len(answer)),
                0 if value[:1] == answer[:1] else 1,
                stable_sort_key(f"{detail['kanji']}|{answer}|{seed_suffix}", value),
            ),
        )
        for value in ranked:
            selected.append(value)
            if len(selected) == 3:
                return

    fill(primary_pool, "primary")
    if len(selected) < 3:
        fill(all_pool, "fallback")

    if len(selected) < 3:
        raise RuntimeError(f"Unable to build distractors for {detail['kanji']}")

    return selected[:3]


def build_choices(answer: str, distractors: list[str], seed: str) -> list[str]:
    choices = dedupe_keep_order(distractors + [answer])
    if len(choices) != 4:
        raise RuntimeError(f"Expected 4 choices for {seed}, got {len(choices)}")
    return sorted(choices, key=lambda value: stable_sort_key(f"{seed}|choice", value))


def select_question(
    detail: dict[str, Any],
    existing: dict[str, Any] | None,
    on_pool: list[str],
    kun_pool: list[str],
    all_pool: list[str],
) -> dict[str, Any]:
    valid_readings = set(detail["readings"])
    answer = ""
    if existing is not None:
        candidate = normalize_reading(str(existing.get("answer", "")))
        if candidate in valid_readings:
            answer = candidate

    if not answer:
        answer = detail["primary_reading"]

    answer_type = "on" if answer in detail["onyomi"] else "kun"

    choices: list[str] = []
    if existing is not None:
        candidate_choices = [normalize_reading(str(value)) for value in existing.get("choices", [])]
        candidate_choices = [value for value in dedupe_keep_order(candidate_choices) if value]
        matching_valid = {value for value in candidate_choices if value in valid_readings}
        if len(candidate_choices) == 4 and answer in candidate_choices and matching_valid == {answer}:
            choices = candidate_choices

    if not choices:
        distractors = choose_distractors(answer, answer_type, detail, on_pool, kun_pool, all_pool)
        choices = build_choices(answer, distractors, detail["kanji"])

    return {
        "kanji": detail["kanji"],
        "choices": choices,
        "answer": answer,
        "explain": build_explain(detail, answer),
    }


def write_stages(questions: list[dict[str, Any]]) -> None:
    total = len(questions)
    base = total // STAGE_COUNT
    remainder = total % STAGE_COUNT

    stage_buckets: list[list[dict[str, Any]]] = []
    offset = 0
    for stage_number in range(1, STAGE_COUNT + 1):
        size = base + (1 if stage_number <= remainder else 0)
        stage_buckets.append(questions[offset:offset + size])
        offset += size

    rebalance_stage_buckets(stage_buckets)

    for stage_number, stage_questions in enumerate(stage_buckets, start=1):
        payload = {
            "stage": stage_number,
            "questions": stage_questions,
        }
        (RESOURCES_DIR / f"stage{stage_number}.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    manifest = {
        "stages": [
            {
                "id": stage_number,
                "file": f"stage{stage_number}.json",
                "title": f"レベル{stage_number}",
                "difficulty": ((stage_number - 1) % 3) + 1,
            }
            for stage_number in range(1, STAGE_COUNT + 1)
        ]
    }
    (RESOURCES_DIR / "stages.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def remove_extra_stage_files() -> None:
    for path in RESOURCES_DIR.glob("stage*.json"):
        match = re.fullmatch(r"stage(\d+)\.json", path.name)
        if match and int(match.group(1)) > STAGE_COUNT:
            path.unlink(missing_ok=True)


def write_review_questions(questions: list[dict[str, Any]]) -> None:
    (RESOURCES_DIR / "review_questions.json").write_text(
        json.dumps(questions, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def write_kanji_doc(path: Path, title: str, sources: list[str], questions: list[dict[str, Any]]) -> None:
    lines: list[str] = []
    row: list[str] = []
    for question in questions:
        row.append(question["kanji"])
        if len(row) == 50:
            lines.append("".join(row))
            row = []
    if row:
        lines.append("".join(row))

    content = "\n".join(
        [
            f"# {title}",
            "",
            *[f"- Source: {source}" for source in sources],
            f"- Question count: {len(questions)}",
            f"- Unique kanji count: {len({question['kanji'] for question in questions})}",
            "",
            "## Kanji",
            "",
            *lines,
            "",
        ]
    )
    path.write_text(content, encoding="utf-8")


def update_submission_checklist(main_count: int, review_count: int) -> None:
    path = ROOT / "APPLE_SUBMISSION_CHECKLIST.md"
    text = path.read_text(encoding="utf-8")
    updated = re.sub(
        r"- 現状: `[^`]+`(?:, `[^`]+`)*(?:, `[^`]+`)*",
        f"- 現状: `{STAGE_COUNT} jun1 stages`, `{main_count} jun1 questions`, `{review_count} review questions`",
        text,
        count=1,
    )
    path.write_text(updated, encoding="utf-8")


def validate_counts(main_questions: list[dict[str, Any]], review_questions: list[dict[str, Any]]) -> None:
    if len(main_questions) != 1238:
        raise RuntimeError(f"Unexpected jun1 question count: {len(main_questions)}")
    if len({question['kanji'] for question in main_questions}) != len(main_questions):
        raise RuntimeError("Duplicate jun1 kanji detected")
    if len({question['kanji'] for question in review_questions}) != len(review_questions):
        raise RuntimeError("Duplicate review kanji detected")


def has_identity_conflict(questions: list[dict[str, Any]]) -> bool:
    seen: set[str] = set()
    for question in questions:
        key = kanji_identity_key(question["kanji"])
        if key in seen:
            return True
        seen.add(key)
    return False


def rebalance_stage_buckets(stage_buckets: list[list[dict[str, Any]]]) -> None:
    for stage_index, bucket in enumerate(stage_buckets):
        while True:
            seen: set[str] = set()
            duplicate_index: int | None = None
            for question_index, question in enumerate(bucket):
                key = kanji_identity_key(question["kanji"])
                if key in seen:
                    duplicate_index = question_index
                    break
                seen.add(key)

            if duplicate_index is None:
                break

            moved_question = bucket[duplicate_index]
            swap_found = False

            for later_stage_index in range(stage_index + 1, len(stage_buckets)):
                later_bucket = stage_buckets[later_stage_index]
                for later_question_index, later_question in enumerate(later_bucket):
                    candidate_bucket = bucket.copy()
                    candidate_later_bucket = later_bucket.copy()
                    candidate_bucket[duplicate_index] = later_question
                    candidate_later_bucket[later_question_index] = moved_question

                    if has_identity_conflict(candidate_bucket):
                        continue
                    if has_identity_conflict(candidate_later_bucket):
                        continue

                    bucket[duplicate_index] = later_question
                    later_bucket[later_question_index] = moved_question
                    swap_found = True
                    break

                if swap_found:
                    break

            if not swap_found:
                raise RuntimeError(
                    f"Unable to rebalance stage {stage_index + 1} for kanji {moved_question['kanji']}"
                )


def build_question_set(
    details: list[dict[str, Any]],
    existing: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    on_pool = dedupe_keep_order(
        sorted(
            {reading for detail in details for reading in detail["onyomi"]},
            key=lambda value: stable_sort_key("on-pool", value),
        )
    )
    kun_pool = dedupe_keep_order(
        sorted(
            {reading for detail in details for reading in detail["kunyomi"]},
            key=lambda value: stable_sort_key("kun-pool", value),
        )
    )
    all_pool = dedupe_keep_order(on_pool + kun_pool)

    return [
        select_question(detail, existing.get(detail["kanji"]), on_pool, kun_pool, all_pool)
        for detail in details
    ]


def main() -> None:
    ensure_dirs()
    existing = load_existing_questions()

    cumulative_entries = parse_kanjitisiki_index()
    cumulative_details = scrape_entries(cumulative_entries, parse_kanjitisiki_detail, max_workers=4)
    cumulative_questions = build_question_set(cumulative_details, existing)

    jun1_entries = parse_mojinavi_index()
    jun1_details = scrape_entries(jun1_entries, parse_mojinavi_detail, max_workers=4)
    jun1_questions = build_question_set(jun1_details, existing)

    jun1_kanji = {detail["kanji"] for detail in jun1_details}
    review_questions = [
        question for question in cumulative_questions
        if question["kanji"] not in jun1_kanji
    ]

    validate_counts(jun1_questions, review_questions)

    write_stages(jun1_questions)
    remove_extra_stage_files()
    write_review_questions(review_questions)

    write_kanji_doc(
        DOCS_DIR / "app_quiz_kanji_list.md",
        "Jun1 Quiz Kanji List",
        [MOJINAVI_INDEX_URL],
        jun1_questions,
    )
    write_kanji_doc(
        DOCS_DIR / "review_quiz_kanji_list.md",
        "Review Quiz Kanji List",
        [KANJITISIKI_INDEX_URL],
        review_questions,
    )
    update_submission_checklist(len(jun1_questions), len(review_questions))

    print(
        json.dumps(
            {
                "jun1_questions": len(jun1_questions),
                "review_questions": len(review_questions),
                "stage_count": STAGE_COUNT,
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
