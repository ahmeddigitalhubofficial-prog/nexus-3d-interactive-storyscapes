import os
import json

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORIES_DIR = os.path.join(BASE_DIR, 'assets', 'stories', 'ar')
EXPORT_DIR = os.path.join(STORIES_DIR, 'export_texts')

def export_texts():
    print("=" * 60)
    print("        Arabic Stories Text Exporter Utility")
    print("=" * 60)

    if not os.path.exists(STORIES_DIR):
        print("❌ Error: Stories directory not found!")
        return

    if not os.path.exists(EXPORT_DIR):
        os.makedirs(EXPORT_DIR)
        print(f"Created directory: {EXPORT_DIR}")

    # All JSON files in the stories directory (excluding stories_list.json)
    story_files = [f for f in os.listdir(STORIES_DIR) if f.endswith('.json') and f != 'stories_list.json']
    
    for filename in story_files:
        story_id = filename[:-5]
        story_path = os.path.join(STORIES_DIR, filename)
        export_file_path = os.path.join(EXPORT_DIR, f"{story_id}.txt")
        
        with open(story_path, 'r', encoding='utf-8') as f:
            try:
                story_data = json.load(f)
            except Exception as e:
                print(f"Error reading {filename}: {e}")
                continue
                
        nodes = story_data.get("nodes", {})
        
        with open(export_file_path, 'w', encoding='utf-8') as export_file:
            export_file.write("=" * 80 + "\n")
            export_file.write(f" Story ID: {story_id}\n")
            export_file.write(f" Title: {story_data.get('story_title', story_id)}\n")
            export_file.write("=" * 80 + "\n\n")
            export_file.write("Follow these steps on the ElevenLabs website:\n")
            export_file.write("1. Copy the text block below the line.\n")
            export_file.write("2. Paste it into ElevenLabs website and generate using the Egyptian voice.\n")
            export_file.write("3. Download the audio file and rename it EXACTLY to the specified filename.\n")
            export_file.write("4. Place the file inside the project directory: assets/audio/narration/ar/\n\n")
            export_file.write("-" * 80 + "\n\n")
            
            for node_id, node_data in nodes.items():
                text = node_data.get("text", "")
                if not text:
                    continue
                
                audio_filename = f"{story_id}_{node_id}.mp3"
                
                export_file.write(f"▶ FILENAME TO SAVE AS:\n{audio_filename}\n\n")
                export_file.write("💬 TEXT TO COPY AND PASTE:\n")
                export_file.write(f"{text}\n\n")
                export_file.write("-" * 80 + "\n\n")
                
        print(f"✓ Exported: {story_id}.txt")

    print("\n🎉 Export completed successfully!")
    print(f"Text files are saved in: {EXPORT_DIR}")

if __name__ == "__main__":
    export_texts()
