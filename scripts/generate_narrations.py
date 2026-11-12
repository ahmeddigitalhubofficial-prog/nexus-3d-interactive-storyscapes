import os
import json
import requests

# Default ElevenLabs configuration
# "Antoni" (ErXwobaYiN019PkySvjV) is verified to work on free tier API keys and supports Arabic
DEFAULT_VOICE_ID = "ErXwobaYiN019PkySvjV"
MODEL_ID = "eleven_multilingual_v2"

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORIES_DIR = os.path.join(BASE_DIR, 'assets', 'stories', 'ar')
NARRATION_DIR = os.path.join(BASE_DIR, 'assets', 'audio', 'narration', 'ar')

def get_story_char_counts():
    """Returns a dict of story_id to its character count and missing character count."""
    story_files = [f for f in os.listdir(STORIES_DIR) if f.endswith('.json') and f != 'stories_list.json']
    story_stats = {}
    
    for filename in sorted(story_files):
        story_id = filename[:-5]
        story_path = os.path.join(STORIES_DIR, filename)
        
        with open(story_path, 'r', encoding='utf-8') as f:
            try:
                story_data = json.load(f)
            except Exception:
                continue
                
        nodes = story_data.get("nodes", {})
        total_chars = 0
        missing_chars = 0
        nodes_count = len(nodes)
        generated_count = 0
        
        for node_id, node_data in nodes.items():
            text = node_data.get("text", "")
            if not text:
                continue
            
            char_count = len(text)
            total_chars += char_count
            
            audio_filename = f"{story_id}_{node_id}.mp3"
            audio_path = os.path.join(NARRATION_DIR, audio_filename)
            
            if os.path.exists(audio_path):
                generated_count += 1
            else:
                missing_chars += char_count
                
        story_stats[story_id] = {
            "total_nodes": nodes_count,
            "generated_nodes": generated_count,
            "total_chars": total_chars,
            "missing_chars": missing_chars
        }
    return story_stats

def generate_voiceovers():
    print("=" * 60)
    print("        ElevenLabs Arabic Narration Generator Utility")
    print("=" * 60)
    
    # 1. Check story stats
    if not os.path.exists(STORIES_DIR):
        print("❌ Error: Stories directory not found!")
        return

    # Create narration directory if it doesn't exist
    if not os.path.exists(NARRATION_DIR):
        os.makedirs(NARRATION_DIR)
        print(f"Created directory: {NARRATION_DIR}")

    stats = get_story_char_counts()
    
    # Filter stories that have missing narrations
    missing_stories = {k: v for k, v in stats.items() if v["missing_chars"] > 0}
    
    if not missing_stories:
        print("🎉 All stories already have 100% generated Arabic narrations!")
        return

    print("\n📝 Remaining stories needing Arabic narration generation:")
    print("-" * 75)
    print(f" {'#':<2} | {'Story ID':<25} | {'Generated Nodes':<17} | {'Missing Chars':<13}")
    print("-" * 75)
    
    selectable_stories = []
    for idx, (story_id, s_data) in enumerate(sorted(missing_stories.items()), 1):
        selectable_stories.append(story_id)
        gen_status = f"{s_data['generated_nodes']}/{s_data['total_nodes']}"
        print(f" {idx:<2} | {story_id:<25} | {gen_status:<17} | {s_data['missing_chars']:<13}")
    
    total_missing_all = sum(s["missing_chars"] for s in missing_stories.values())
    print("-" * 75)
    print(f" {'Total characters needed to complete ALL remaining stories:':<50} {total_missing_all}")
    print("=" * 60)

    # 2. Get API Key
    api_key = os.environ.get("ELEVENLABS_API_KEY")
    if not api_key:
        api_key = input("\nEnter your ElevenLabs API Key: ").strip()
        
    if not api_key:
        print("❌ Error: API Key is required to call ElevenLabs.")
        return

    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json"
    }

    # 3. Voice Configuration (Colloquial Egyptian support advice)
    print("\n🎙️ VOICE CONFIGURATION:")
    print("   To use an Egyptian Colloquial voice (لهجة مصرية عامية):")
    print("   1. Go to your ElevenLabs Dashboard -> Voices -> Explore (Voice Library).")
    print("   2. Search for 'Egyptian' or 'Egyptian Arabic' and add a voice to your account.")
    print("   3. Go to Voice Lab, copy the Voice ID, and paste it below.")
    print(f"   (If left empty, we will default to Antoni ID: '{DEFAULT_VOICE_ID}')")
    
    voice_id_input = input("\nEnter Voice ID (press Enter for default Antoni): ").strip()
    voice_id = voice_id_input if voice_id_input else DEFAULT_VOICE_ID

    # Test the API Key and verify voice selection
    if voice_id == DEFAULT_VOICE_ID:
        print("\n🔍 Validating voice and API key connection...")
        try:
            r = requests.get("https://api.elevenlabs.io/v1/voices", headers=headers)
            if r.status_code == 200:
                voices = r.json().get("voices", [])
                premade_voices = [v for v in voices if v.get("category") in ["pre-made", "premade"]]
                if premade_voices:
                    selected_voice = premade_voices[0]
                    for v in premade_voices:
                        if v.get("name") in ["Rachel", "Antoni", "Bella", "Adam", "Domi"]:
                            selected_voice = v
                            break
                    voice_id = selected_voice.get("voice_id")
                    print(f"🎤 Successfully connected! Using pre-made voice: '{selected_voice.get('name')}' (ID: {voice_id})")
                else:
                    print(f"🎤 Connected. Using default voice ID: {voice_id}")
            else:
                print(f"⚠️ API connection test returned status code {r.status_code}. Proceeding with Voice ID: {voice_id}")
        except Exception as e:
            print(f"⚠️ Network error checking voices: {e}. Proceeding with Voice ID: {voice_id}")
    else:
        print(f"🎤 Using custom Voice ID: {voice_id}")

    # 4. Choose Stories to Generate
    print(f"\n👉 Which stories would you like to generate? (Total remaining budget needed: {total_missing_all} chars)")
    print("Options:")
    print("  - Enter numbers separated by commas (e.g. 1, 2)")
    print("  - Type 'all' to attempt generating all remaining stories")
    
    # Also include already fully-generated stories if they want to overwrite
    all_story_ids = sorted(list(stats.keys()))
    print("\nAll available stories in the project:")
    for idx, story_id in enumerate(all_story_ids, 1):
        s_data = stats[story_id]
        gen_status = f"{s_data['generated_nodes']}/{s_data['total_nodes']}"
        print(f" [{idx}] {story_id:<25} ({s_data['total_chars']} chars total, generated: {gen_status})")
        
    choice = input("\nYour choice (comma-separated numbers or 'all'): ").strip().lower()
    
    target_stories = []
    if choice == 'all':
        target_stories = all_story_ids
    else:
        try:
            indices = [int(x.strip()) - 1 for x in choice.split(",") if x.strip()]
            for idx in indices:
                if 0 <= idx < len(all_story_ids):
                    target_stories.append(all_story_ids[idx])
        except ValueError:
            print("❌ Invalid input choice. Exiting.")
            return
            
    if not target_stories:
        print("❌ No stories selected. Exiting.")
        return

    # Check if they want to overwrite
    overwrite_choice = input("Do you want to overwrite existing audio files for the selected stories? (y/n): ").strip().lower()
    force_overwrite = (overwrite_choice == 'y')

    # Calculate required characters based on selection and overwrite choice
    selected_total_chars = 0
    for story_id in target_stories:
        if force_overwrite:
            selected_total_chars += stats[story_id]["total_chars"]
        else:
            selected_total_chars += stats[story_id]["missing_chars"]

    print(f"\n🚀 Starting generation for {len(target_stories)} stories. Total characters needed: {selected_total_chars}")
    confirm = input("Do you want to proceed? (y/n): ").strip().lower()
    if confirm != 'y':
        print("Generation cancelled.")
        return

    # 5. Generate narrations
    for story_id in target_stories:
        story_path = os.path.join(STORIES_DIR, f"{story_id}.json")
        print(f"\n📖 Processing story: {story_id}")
        with open(story_path, 'r', encoding='utf-8') as f:
            story_data = json.load(f)
            
        nodes = story_data.get("nodes", {})
        for node_id, node_data in nodes.items():
            text = node_data.get("text", "")
            if not text:
                continue
                
            filename = f"{story_id}_{node_id}.mp3"
            file_path = os.path.join(NARRATION_DIR, filename)
            
            # Check if file already exists
            if os.path.exists(file_path) and not force_overwrite:
                continue
                
            print(f"  🎙️ Generating narration for [{node_id}] ({len(text)} chars)...")
            
            url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
            payload = {
                "text": text,
                "model_id": MODEL_ID,
                "voice_settings": {
                    "stability": 0.5,
                    "similarity_boost": 0.75
                }
            }
            
            try:
                response = requests.post(url, json=payload, headers=headers)
                if response.status_code == 200:
                    with open(file_path, 'wb') as audio_file:
                        audio_file.write(response.content)
                    print(f"    ✓ Saved: {filename}")
                else:
                    try:
                        error_msg = response.json().get("detail", {}).get("message", "Unknown error")
                    except Exception:
                        error_msg = response.text
                    print(f"    ❌ Failed to generate {filename}. HTTP {response.status_code}: {error_msg}")
                    # If quota exceeded, stop to prevent continuous errors
                    if response.status_code == 402 or "quota" in error_msg.lower():
                        print("❌ Quota exceeded or subscription limit reached on ElevenLabs. Stopping generation.")
                        return
            except Exception as e:
                print(f"    ❌ Network error generating {filename}: {e}")
                
    print("\n🎉 Generation process completed!")
    print(f"Audio files are saved in: {NARRATION_DIR}")

if __name__ == "__main__":
    generate_voiceovers()
