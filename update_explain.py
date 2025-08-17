import json
import re
import sys

def update_explain_field(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if 'questions' in data:
        for question in data['questions']:
            explain_text = question['explain']
            
            meaning_match = re.search(r"意味:\s*(.*?)(?:\n|$)", explain_text)
            meaning = meaning_match.group(1).strip() if meaning_match else ""

            yojijukugo_match = re.search(r"四字熟語:\s*(.*?)(?:\n|$)", explain_text)
            yojijukugo = yojijukugo_match.group(1).strip() if yojijukugo_match else ""

            new_explain = meaning
            if yojijukugo:
                new_explain += f"。四字熟語: {yojijukugo}"
            
            question['explain'] = new_explain
    elif 'unused_questions' in data:
        for question in data['unused_questions']:
            explain_text = question['explain']
            
            meaning_match = re.search(r"意味:\s*(.*?)(?:\n|$)", explain_text)
            meaning = meaning_match.group(1).strip() if meaning_match else ""

            yojijukugo_match = re.search(r"四字熟語:\s*(.*?)(?:\n|$)", explain_text)
            yojijukugo = yojijukugo_match.group(1).strip() if yojijukugo_match else ""

            new_explain = meaning
            if yojijukugo:
                new_explain += f"。四字熟語: {yojijukugo}"
            
            question['explain'] = new_explain

    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Updated {file_path}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        file_to_update = sys.argv[1]
        update_explain_field(file_to_update)
    else:
        print("Usage: python update_explain.py <json_file_path>")
