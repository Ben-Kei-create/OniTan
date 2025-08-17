import json

# ファイルパス
unused_questions_path = "/Users/fumiaki/Desktop/OniTan/OniTan/OniTan/Resources/unused_questions.json"
stage1_path = "/Users/fumiaki/Desktop/OniTan/OniTan/OniTan/Resources/stage1.json"

# unused_questions.json を読み込む
with open(unused_questions_path, 'r', encoding='utf-8') as f:
    unused_questions_data = json.load(f)

# stage1.json を読み込む
with open(stage1_path, 'r', encoding='utf-8') as f:
    stage1_data = json.load(f)

# unused_questions から最初の質問を取り出す
if unused_questions_data:
    question_to_add = unused_questions_data.pop(0) # 最初の要素を削除しつつ取得
    stage1_data['questions'].append(question_to_add) # stage1 に追加
else:
    print("Error: unused_questions.json is empty. Cannot add question to stage1.json")
    exit()

# 修正した stage1.json を書き戻す
with open(stage1_path, 'w', encoding='utf-8') as f:
    json.dump(stage1_data, f, ensure_ascii=False, indent=2)

# 修正した unused_questions.json を書き戻す
with open(unused_questions_path, 'w', encoding='utf-8') as f:
    json.dump(unused_questions_data, f, ensure_ascii=False, indent=2)

print(f"Added one question to {stage1_path} and removed it from {unused_questions_path}.")
