import json

file_path = "/Users/fumiaki/Desktop/OniTan/OniTan/OniTan/Resources/unused_questions.json"

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

unused_questions_array = data.get("unused_questions", [])

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(unused_questions_array, f, ensure_ascii=False, indent=2)

print(f"Modified {file_path} to be a top-level array.")
