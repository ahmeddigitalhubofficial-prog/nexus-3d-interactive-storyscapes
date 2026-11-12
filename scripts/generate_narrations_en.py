import os
import json
import asyncio
import edge_tts

# Voice mapping based on genre and tone
VOICE_MAPPING = {
    "horror_crypt": "en-US-AvaNeural",
    "forgotten_colony": "en-US-AvaNeural",  # Cosmic horror
    "comedy_treasure": "en-US-GuyNeural",
    "sugar_clouds": "en-US-AnaNeural",      # Kids / Fantasy
    "history_timetravel": "en-US-BrianNeural",
    "cloud_train_heist": "en-US-BrianNeural",
    "lost_sands": "en-US-BrianNeural",
    "museum_heist": "en-US-BrianNeural",
    "last_coffee": "en-US-BrianNeural",
    "jasmine_echoes": "en-US-JennyNeural",   # Warm / Nostalgic drama
    "chess_with_death": "en-US-BrianNeural"
}

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORIES_DIR = os.path.join(BASE_DIR, 'assets', 'stories', 'en')
NARRATION_DIR = os.path.join(BASE_DIR, 'assets', 'audio', 'narration', 'en')

def get_story_stats():
    """Returns stats about English stories and their voiceover completion."""
    if not os.path.exists(STORIES_DIR):
        return None
        
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
            "missing_chars": missing_chars,
            "voice": VOICE_MAPPING.get(story_id, "en-US-BrianNeural")
        }
    return story_stats

async def generate_node_narration(text, voice, file_path):
    """Generates a single narration file using edge-tts."""
    try:
        communicate = edge_tts.Communicate(text, voice)
        await communicate.save(file_path)
        return True
    except Exception as e:
        print(f"    ❌ Error generating audio: {e}")
        return False

async def main():
    import sys
    
    print("=" * 60)
    print("        Edge-TTS English Narration Generator Utility")
    print("=" * 60)
    
    if not os.path.exists(STORIES_DIR):
        print("❌ Error: Stories directory not found!")
        return

    if not os.path.exists(NARRATION_DIR):
        os.makedirs(NARRATION_DIR)
        print(f"Created directory: {NARRATION_DIR}")

    stats = get_story_stats()
    if not stats:
        print("❌ Error: Could not read stories.")
        return
        
    missing_stories = {k: v for k, v in stats.items() if v["missing_chars"] > 0}
    
    if not missing_stories:
        print("🎉 All English stories already have 100% generated narrations!")
        return

    # Parse arguments
    args = sys.argv[1:]
    run_all = "--all" in args
    skip_confirm = "--yes" in args
    force_overwrite = "--overwrite" in args

    print("\n📝 English stories voice-over generation status:")
    print("-" * 85)
    print(f" {'#':<2} | {'Story ID':<22} | {'Voice':<20} | {'Gen Status':<12} | {'Missing Chars':<13}")
    print("-" * 85)
    
    all_story_ids = sorted(list(stats.keys()))
    for idx, story_id in enumerate(all_story_ids, 1):
        s_data = stats[story_id]
        gen_status = f"{s_data['generated_nodes']}/{s_data['total_nodes']}"
        missing_text = f"{s_data['missing_chars']}" if s_data['missing_chars'] > 0 else "0 (Complete)"
        print(f" [{idx:<2}] {story_id:<22} | {s_data['voice']:<20} | {gen_status:<12} | {missing_text:<13}")
        
    total_missing_all = sum(s["missing_chars"] for s in missing_stories.values())
    print("-" * 85)
    print(f" {'Total characters needed to complete ALL remaining stories:':<68} {total_missing_all}")
    print("=" * 60)

    if run_all:
        print("\n🤖 Running in automated mode (--all)")
        target_stories = [k for k, v in stats.items() if v["missing_chars"] > 0]
    else:
        choice = input("\n👉 Enter numbers to generate (comma-separated, e.g. 4,5,6) or type 'all': ").strip().lower()
        
        target_stories = []
        if choice == 'all':
            target_stories = [k for k, v in stats.items() if v["missing_chars"] > 0]
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
        print("❌ No stories selected or all selected are complete. Exiting.")
        return

    if not run_all:
        overwrite_choice = input("Do you want to overwrite existing audio files? (y/n): ").strip().lower()
        force_overwrite = (overwrite_choice == 'y')

    selected_total_chars = 0
    for story_id in target_stories:
        if force_overwrite:
            selected_total_chars += stats[story_id]["total_chars"]
        else:
            selected_total_chars += stats[story_id]["missing_chars"]

    print(f"\n🚀 Starting generation for {len(target_stories)} stories. Total characters to generate: {selected_total_chars}")
    
    if not skip_confirm:
        confirm = input("Do you want to proceed? (y/n): ").strip().lower()
        if confirm != 'y':
            print("Cancelled.")
            return

    for story_id in target_stories:
        story_path = os.path.join(STORIES_DIR, f"{story_id}.json")
        voice = stats[story_id]["voice"]
        print(f"\n📖 Processing English story: {story_id} using voice: {voice}")
        
        with open(story_path, 'r', encoding='utf-8') as f:
            story_data = json.load(f)
            
        nodes = story_data.get("nodes", {})
        for node_id, node_data in nodes.items():
            text = node_data.get("text", "")
            if not text:
                continue
                
            filename = f"{story_id}_{node_id}.mp3"
            file_path = os.path.join(NARRATION_DIR, filename)
            
            if os.path.exists(file_path) and not force_overwrite:
                continue
                
            print(f"  🎙️ Generating narration for [{node_id}] ({len(text)} chars)...")
            success = await generate_node_narration(text, voice, file_path)
            if success:
                print(f"    ✓ Saved: {filename}")
            else:
                print(f"    ❌ Failed: {filename}")
                
    print("\n🎉 English generation process completed!")
    print(f"Audio files are saved in: {NARRATION_DIR}")

if __name__ == "__main__":
    asyncio.run(main())
