/**
 * AudioEngine: Handles 3D Positional Audio, Horror Sound Effects, Synthesizer & Arabic Voiceover Narration
 */
class AudioEngine {
  constructor() {
    this.audioCtx = null;
    this.isMuted = false;
    this.synth = window.speechSynthesis || null;
  }

  init() {
    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      this.audioCtx = new AudioContext();
    } catch (e) {
      console.warn("Web Audio API not supported in browser.");
    }
  }

  ensureContext() {
    if (this.audioCtx && this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
  }

  // Synthesize procedural horror drone ambient music
  playHorrorDrone() {
    if (this.isMuted || !this.audioCtx) return;
    this.ensureContext();

    const osc = this.audioCtx.createOscillator();
    const gain = this.audioCtx.createGain();

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(55, this.audioCtx.currentTime); // Low A note (55Hz)

    const filter = this.audioCtx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(180, this.audioCtx.currentTime);

    gain.gain.setValueAtTime(0.08, this.audioCtx.currentTime);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(this.audioCtx.destination);

    osc.start();
  }

  // Play Click / UI Sound
  playClickSound() {
    if (this.isMuted || !this.audioCtx) return;
    this.ensureContext();

    const osc = this.audioCtx.createOscillator();
    const gain = this.audioCtx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(800, this.audioCtx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(300, this.audioCtx.currentTime + 0.05);

    gain.gain.setValueAtTime(0.15, this.audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, this.audioCtx.currentTime + 0.05);

    osc.connect(gain);
    gain.connect(this.audioCtx.destination);

    osc.start();
    osc.stop(this.audioCtx.currentTime + 0.06);
  }

  // Play Unlock / Item Pickup Sound Effect
  playItemPickupSound() {
    if (this.isMuted || !this.audioCtx) return;
    this.ensureContext();

    const osc = this.audioCtx.createOscillator();
    const gain = this.audioCtx.createGain();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(440, this.audioCtx.currentTime);
    osc.frequency.setValueAtTime(880, this.audioCtx.currentTime + 0.1);

    gain.gain.setValueAtTime(0.2, this.audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, this.audioCtx.currentTime + 0.25);

    osc.connect(gain);
    gain.connect(this.audioCtx.destination);

    osc.start();
    osc.stop(this.audioCtx.currentTime + 0.25);
  }

  // 🎙️ DRAMATIC ARABIC & ENGLISH NARRATOR VOICE SYNTHESIS
  speakStoryText(text, lang = 'ar') {
    if (this.isMuted || !this.synth) return;
    this.synth.cancel(); // Stop previous narration

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = lang === 'ar' ? 'ar-SA' : 'en-US';
    utterance.rate = 0.95; // Slightly slower for dramatic atmosphere
    utterance.pitch = 0.85; // Deeper horror pitch

    // Try finding natural Arabic or English voice
    const voices = this.synth.getVoices();
    const voice = voices.find(v => v.lang.startsWith(lang));
    if (voice) utterance.voice = voice;

    this.synth.speak(utterance);
  }

  toggleSound() {
    this.isMuted = !this.isMuted;
    if (this.isMuted && this.synth) this.synth.cancel();
    return !this.isMuted;
  }
}
