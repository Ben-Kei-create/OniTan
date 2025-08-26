import json
import os
import glob

def verify_quiz_data(resource_path):
    print(f"クイズデータの検証を開始します: {resource_path}\n")
    
    json_files = glob.glob(os.path.join(resource_path, "stage*.json"))
    print(f"ソート前: {json_files}") # デバッグ出力
    json_files.sort(key=lambda f: int(os.path.basename(f).replace('stage', '').replace('.json', '')))
    print(f"ソート後: {json_files}") # デバッグ出力

    # 全ステージを通しての漢字の出現を記録 (漢字: 初めて出現したステージ番号)
    all_kanji_first_appearance = {}
    
    # 各ステージの検証結果を保存するリスト
    stage_results = []

    for file_path in json_files:
        file_name = os.path.basename(file_path)
        stage_number_str = file_name.replace('stage', '').replace('.json', '')
        
        current_stage_issues = [] # このステージで検出された問題点

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            stage_data = data 

            stage_number = stage_data.get("stage", "Unknown")
            questions = stage_data.get("questions", [])
            
            # 1. 問題数30個の検証
            if len(questions) != 30:
                current_stage_issues.append(f"問題数が不正です: {len(questions)}問 (期待値: 30問)")

            # 2. 重複漢字の検証
            stage_kanji_set = set() # このステージ内の漢字を一時的に記録
            
            for question in questions:
                kanji = question.get("kanji")
                if kanji:
                    # ステージ内での重複チェック
                    if kanji in stage_kanji_set:
                        current_stage_issues.append(f"ステージ内で漢字が重複しています: '{kanji}'")
                    stage_kanji_set.add(kanji)
                    
                    # 全ステージを通しての重複チェック
                    if kanji in all_kanji_first_appearance:
                        first_stage = all_kanji_first_appearance[kanji]
                        current_stage_issues.append(f"漢字 '{kanji}' はステージ {first_stage} で既に使用されています。")
                    else:
                        all_kanji_first_appearance[kanji] = stage_number

        except json.JSONDecodeError as e:
            current_stage_issues.append(f"JSONの読み込みエラー: {e}")
        except Exception as e:
            current_stage_issues.append(f"予期せぬエラーが発生しました: {e}")
        
        # このステージの検証結果を保存
        stage_results.append({
            "stage_number": stage_number,
            "file_name": file_name,
            "issues": current_stage_issues
        })

    # 結果の出力
    print("\n--- 検証結果サマリー ---\n")
    
    overall_issues_found = False
    for result in stage_results:
        if result["issues"]:
            overall_issues_found = True
            print(f"ステージ {result['stage_number']} ({result['file_name']}):")
            for issue in result["issues"]:
                print(f"  ❌ {issue}")
            print("") # 空行で区切り
        else:
            print(f"ステージ {result['stage_number']} ({result['file_name']}): ✅ 問題なし")

    if overall_issues_found:
        print("\n--- 最終結果: いくつかのステージで問題が検出されました。 ---")
    else:
        print("\n--- 最終結果: 全てのステージで問題は見つかりませんでした。 ---")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    resource_path = os.path.join(script_dir, "OniTan", "OniTan", "Resources")
    
    if not os.path.exists(resource_path):
        print(f"エラー: リソースパスが見つかりません: {resource_path}")
        print("スクリプトがプロジェクトルートにあり、Resourcesフォルダの構造が正しいことを確認してください。")
    else:
        verify_quiz_data(resource_path)
