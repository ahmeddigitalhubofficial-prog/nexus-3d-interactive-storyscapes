import sys
import requests

def list_premade_voices():
    print("=" * 60)
    print("         ElevenLabs Pre-made Voices Finder")
    print("=" * 60)
    
    api_key = input("Enter your ElevenLabs API Key: ").strip()
    if not api_key:
        print("❌ Error: API Key is required.")
        return
        
    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json"
    }
    
    print("\n🔍 Querying all available voices on your account...")
    try:
        r = requests.get("https://api.elevenlabs.io/v1/voices", headers=headers)
        if r.status_code == 200:
            voices = r.json().get("voices", [])
            
            # Separate pre-made voices
            premade_voices = [v for v in voices if v.get("category") in ["pre-made", "premade"]]
            
            print(f"\n✅ Found {len(premade_voices)} pre-made voices that work on the Free tier:")
            print("-" * 75)
            print(f" {'Name':<15} | {'Voice ID':<22} | {'Description'}")
            print("-" * 75)
            for v in premade_voices:
                name = v.get("name")
                voice_id = v.get("voice_id")
                # Get a brief description
                desc = v.get("labels", {}).get("description", "")
                if not desc:
                    desc = f"{v.get('labels', {}).get('gender', '')} {v.get('labels', {}).get('age', '')} ({v.get('labels', {}).get('accent', '')})"
                print(f" {name:<15} | {voice_id:<22} | {desc}")
            print("-" * 75)
            
            # List custom voices just in case
            cloned_voices = [v for v in voices if v.get("category") not in ["pre-made", "premade"]]
            if cloned_voices:
                print(f"\n⚠️ Note: You also have {len(cloned_voices)} custom/cloned voices on your dashboard:")
                for v in cloned_voices:
                    print(f" - {v.get('name')} (ID: {v.get('voice_id')}) [Category: {v.get('category')}]")
                print(" (Remember: Free tier API keys cannot use these custom/library voices via API, only premade ones!)")
        else:
            print(f"❌ Failed to fetch voices. HTTP {r.status_code}: {r.text}")
    except Exception as e:
        print(f"❌ Network error: {e}")

if __name__ == "__main__":
    list_premade_voices()
