import os
import json

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORIES_DIR = os.path.join(BASE_DIR, 'assets', 'stories', 'ar')
AUDIO_DIR = os.path.join(BASE_DIR, 'assets', 'audio', 'narration', 'ar')

def count_characters():
    print("=" * 60)
    print("      Arabic Narration Character & Audio Status Count")
    print("=" * 60)

    if not os.path.exists(STORIES_DIR):
        print("Stories directory not found!")
        return

    # All JSON files in the stories directory (excluding stories_list.json)
    story_files = [f for f in os.listdir(STORIES_DIR) if f.endswith('.json') and f != 'stories_list.json']
    
    total_all_chars = 0
    total_missing_chars = 0
    
    print(f"{'Story ID':<25} | {'Total Nodes':<11} | {'Total Chars':<11} | {'Generated':<10} | {'Missing Chars':<13}")
    print("-" * 80)
    
    for filename in sorted(story_files):
        story_id = filename[:-5]
        story_path = os.path.join(STORIES_DIR, filename)
        
        with open(story_path, 'r', encoding='utf-8') as f:
            try:
                story_data = json.load(f)
            except Exception as e:
                print(f"Error reading {filename}: {e}")
                continue
                
        nodes = story_data.get("nodes", {})
        story_total_chars = 0
        story_missing_chars = 0
        nodes_count = len(nodes)
        generated_count = 0
        
        for node_id, node_data in nodes.items():
            text = node_data.get("text", "")
            if not text:
                continue
            
            char_count = len(text)
            story_total_chars += char_count
            
            # Check if audio file exists
            audio_filename = f"{story_id}_{node_id}.mp3"
            audio_path = os.path.join(AUDIO_DIR, audio_filename)
            
            if os.path.exists(audio_path):
                generated_count += 1
            else:
                story_missing_chars += char_count
                
        total_all_chars += story_total_chars
        total_missing_chars += story_missing_chars
        
        generated_status = f"{generated_count}/{nodes_count}"
        print(f"{story_id:<25} | {nodes_count:<11} | {story_total_chars:<11} | {generated_status:<10} | {story_missing_chars:<13}")
        
    print("-" * 80)
    print(f"{'TOTAL':<25} | {'':<11} | {total_all_chars:<11} | {'':<10} | {total_missing_chars:<13}")
    print("=" * 60)

if __name__ == "__main__":
    count_characters()
