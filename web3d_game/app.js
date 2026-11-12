/**
 * Main Application Orchestrator
 * Connects Restored Authentic Story Narrative to 3D Camera Flights, 3D Chest Lid Animation, Arabic Voiceover & Jumpscare FX
 */
let currentDials = [0, 0, 0, 0];

window.adjustDial = function(index, delta) {
  currentDials[index] = (currentDials[index] + delta + 10) % 10;
  const el = document.getElementById(`dial-${index}`);
  if (el) el.textContent = currentDials[index];
};

document.addEventListener('DOMContentLoaded', () => {
  const scene = new CryptScene('canvas-container');
  const story = new StoryEngine();
  const audio = new AudioEngine();

  // DOM Elements
  const hubModal = document.getElementById('story-hub-modal');
  const hubGrid = document.getElementById('story-grid');
  const hubHeading = document.getElementById('hub-heading');
  const hubSubheading = document.getElementById('hub-subheading');
  const hubBtn = document.getElementById('hub-btn');
  const hintBtn = document.getElementById('hint-btn');
  const hintBanner = document.getElementById('hint-banner');
  const hintBannerText = document.getElementById('hint-banner-text');

  const dialogueBox = document.getElementById('dialogue-box');
  const dialogueContentBody = document.getElementById('dialogue-content-body');
  const toggleUiBtn = document.getElementById('toggle-ui-btn');
  const toggleUiIcon = document.getElementById('toggle-ui-icon');

  const puzzleModal = document.getElementById('puzzle-modal');
  const puzzleSubmitBtn = document.getElementById('unlock-submit-btn');
  const puzzleCloseBtn = document.getElementById('puzzle-close-btn');
  const lockFeedback = document.getElementById('lock-feedback');

  const batteryContainer = document.getElementById('battery-container');
  const fearContainer = document.getElementById('fear-container');
  
  const nodeTitle = document.getElementById('node-title');
  const locationTag = document.getElementById('location-tag');
  const storyText = document.getElementById('story-text');
  const choicesContainer = document.getElementById('choices-container');
  const batteryFill = document.getElementById('battery-fill');
  const fearFill = document.getElementById('fear-fill');
  const langBtn = document.getElementById('lang-btn');
  const audioBtn = document.getElementById('audio-btn');
  const audioIcon = document.getElementById('audio-icon');

  let isUiCollapsed = false;

  audio.init();
  setTimeout(() => audio.playHorrorDrone(), 1000);

  // Render 3D Story Selection Hub Cards
  function renderStoryHub() {
    const isAr = story.currentLanguage === 'ar';
    hubHeading.textContent = isAr ? "عالم القصص السينمائية 3D" : "3D CINEMATIC STORIES";
    hubSubheading.textContent = isAr ? "اختر مغامرتك ثلاثية الأبعاد التفاعلية واصنع مصيرك" : "Choose your interactive 3D adventure & shape your destiny";

    hubGrid.innerHTML = '';
    story.catalog.forEach((item) => {
      const card = document.createElement('div');
      card.className = 'story-card';

      const title = isAr ? item.title_ar : item.title_en;
      const genre = isAr ? item.genre_ar : item.genre_en;
      const desc = isAr ? item.desc_ar : item.desc_en;
      const playText = isAr ? "🎬 بدء القصة التفاعلية 3D" : "🎬 START 3D STORY";

      card.innerHTML = `
        <div class="story-card-header">
          <span class="story-card-icon">${item.icon}</span>
          <span class="genre-tag">${genre}</span>
        </div>
        <div>
          <h3>${title}</h3>
          <p>${desc}</p>
        </div>
        <button class="play-btn">${playText}</button>
      `;

      card.querySelector('.play-btn').addEventListener('click', () => {
        audio.playClickSound();
        story.loadStory(item.id);
        hubModal.classList.add('hidden');
        dialogueBox.classList.remove('hidden');
        dialogueContentBody.classList.remove('hidden');
        batteryContainer.classList.remove('hidden');
        fearContainer.classList.remove('hidden');
        hintBtn.classList.remove('hidden');
        hintBanner.classList.add('hidden');
        puzzleModal.classList.add('hidden');
        
        scene.resetChest();
        scene.transitionToScene('exterior_gate', new THREE.Vector3(0, 2.5, 7), new THREE.Vector3(0, 2.5, -3), 1.5);
        renderCurrentNode();
      });

      hubGrid.appendChild(card);
    });
  }

  // Render Active Story Node & Trigger 3D Animations & Camera Flight
  function renderCurrentNode() {
    const node = story.getCurrentNode();
    hintBanner.classList.add('hidden');

    nodeTitle.textContent = node.title;
    locationTag.textContent = node.chapter;
    storyText.textContent = node.text;

    batteryFill.style.width = `${story.state.battery}%`;
    fearFill.style.width = `${story.state.fear}%`;

    // 🎙️ AUTOMATIC DRAMATIC NARRATION VOICEOVER
    audio.speakStoryText(node.text, story.currentLanguage);

    choicesContainer.innerHTML = '';
    node.choices.forEach((choice) => {
      const btn = document.createElement('button');
      btn.className = 'choice-btn';
      btn.textContent = choice.text;
      btn.addEventListener('click', () => {
        audio.playClickSound();

        // 🗝️ TRIGGER INTERACTIVE 3D COMBINATION LOCK MODAL
        if (choice.target === 'solve_lock_puzzle') {
          puzzleModal.classList.remove('hidden');
          lockFeedback.textContent = '';
          return;
        }

        // 🎬 3D CAMERA FLIGHTS & CHEST ANIMATION MAPPINGS
        if (choice.target === 'search_wall') {
          scene.transitionToScene('exterior_gate', new THREE.Vector3(5, 2.0, 3.0), new THREE.Vector3(6, 0.6, -2), 1.5);
        } else if (choice.target === 'intro_have_flashlight' || choice.target === 'intro') {
          scene.transitionToScene('exterior_gate', new THREE.Vector3(0, 2.5, 7), new THREE.Vector3(0, 2.5, -3), 1.5);
        } else if (choice.target === 'garden') {
          scene.transitionToScene('interior_crypt', new THREE.Vector3(0, 2.5, -32), new THREE.Vector3(0, 1.5, -42), 2.5);
        } else if (choice.target === 'inspect_chest') {
          scene.transitionToScene('interior_crypt', new THREE.Vector3(0, 2.2, -40.5), new THREE.Vector3(0, 1.5, -42), 1.2);
        } else if (choice.target === 'chest_opened') {
          // 🔓 TRIGGER 3D CHEST OPENING CINEMATIC
          triggerChestOpeningCinematic();
          story.selectChoice(choice);
          renderCurrentNode();
          return;
        } else if (choice.target === 'main_door') {
          scene.transitionToScene('interior_crypt', new THREE.Vector3(0, 3.0, -42), new THREE.Vector3(0, 3.5, -47), 1.5);
        } else if (choice.target === 'victory_escape') {
          audio.playItemPickupSound();
          scene.transitionToScene('interior_crypt', new THREE.Vector3(0, 2.0, -45.0), new THREE.Vector3(0, 2.0, -50), 2.0);
        } else if (choice.target === 'dark_trap' || choice.target === 'game_over_caught') {
          // ☠️ JUMPSCARE SCREEN SHAKE & CAMERA SHIFT
          triggerJumpscareScreenShake();
          scene.transitionToScene('interior_crypt', new THREE.Vector3(-6, 2.0, -40.0), new THREE.Vector3(-8, 1.5, -42), 0.8);
        } else if (choice.text.includes("Hub") || choice.text.includes("العودة")) {
          hubModal.classList.remove('hidden');
          dialogueBox.classList.add('hidden');
          batteryContainer.classList.add('hidden');
          fearContainer.classList.add('hidden');
          hintBtn.classList.add('hidden');
          puzzleModal.classList.add('hidden');
          scene.transitionToScene('exterior_gate', new THREE.Vector3(0, 2.5, 7), new THREE.Vector3(0, 2.5, -3), 1.5);
          renderStoryHub();
          return;
        }

        story.selectChoice(choice);
        renderCurrentNode();
      });

      choicesContainer.appendChild(btn);
    });
  }

  // ☠️ JUMPSCARE SCREEN SHAKE FX
  function triggerJumpscareScreenShake() {
    dialogueBox.classList.add('shake-red');
    setTimeout(() => dialogueBox.classList.remove('shake-red'), 800);
  }

  // 🎬 FULL SCREEN CINEMATIC 3D CHEST UNLOCK ANIMATION
  function triggerChestOpeningCinematic() {
    audio.playItemPickupSound();
    
    // Fly camera directly in front of the 3D wooden chest
    scene.transitionToScene('interior_crypt', new THREE.Vector3(0, 2.0, -38.5), new THREE.Vector3(0, 1.5, -42), 1.5);
    scene.openChestLidAnimation();

    // Hide dialogue box completely to show full 3D spectacle for 3 seconds
    dialogueBox.classList.add('hidden');

    setTimeout(() => {
      dialogueBox.classList.remove('hidden');
      dialogueContentBody.classList.remove('hidden');
    }, 3000);
  }

  // 🔓 COMBINATION LOCK SUBMIT HANDLER
  puzzleSubmitBtn.addEventListener('click', () => {
    audio.playItemPickupSound();
    lockFeedback.style.color = '#00f5d4';
    lockFeedback.textContent = story.currentLanguage === 'ar' ? '✨ تم فك الشفرة بنجاح! ينفتح الصندوق الخشبي 3D...' : '✨ Correct Code! 3D Chest unlocking...';
    
    setTimeout(() => {
      puzzleModal.classList.add('hidden');
      triggerChestOpeningCinematic();
      story.currentNodeId = 'chest_opened';
      if (!story.state.inventory.includes('rusty_key')) story.state.inventory.push('rusty_key');
      renderCurrentNode();
    }, 800);
  });

  puzzleCloseBtn.addEventListener('click', () => {
    audio.playClickSound();
    puzzleModal.classList.add('hidden');
  });

  // 👁️ 3D View Toggle Button
  toggleUiBtn.addEventListener('click', () => {
    audio.playClickSound();
    isUiCollapsed = !isUiCollapsed;
    if (isUiCollapsed) {
      dialogueContentBody.classList.add('hidden');
      toggleUiIcon.textContent = '📖 إظهار النص القصصي';
    } else {
      dialogueContentBody.classList.remove('hidden');
      toggleUiIcon.textContent = '👁️ 3D View';
    }
  });

  // HINT BUTTON CLICK HANDLER
  hintBtn.addEventListener('click', () => {
    audio.playItemPickupSound();
    const node = story.getCurrentNode();
    if (node.hint) {
      hintBannerText.textContent = node.hint;
      hintBanner.classList.remove('hidden');
    }
  });

  // 3D Object Raycast Hook
  window.on3DObjectInteract = (data) => {
    if (data.id === 'gate_lock') {
      audio.playItemPickupSound();
      scene.transitionToScene('exterior_gate', new THREE.Vector3(0, 2.0, -1.5), new THREE.Vector3(0, 1.8, -2.8), 1.2);
      story.currentNodeId = 'inspect_gate_lock';
      renderCurrentNode();
    } else if (data.id === 'chest') {
      triggerChestOpeningCinematic();
      story.currentNodeId = 'chest_opened';
      if (!story.state.inventory.includes('rusty_key')) story.state.inventory.push('rusty_key');
      renderCurrentNode();
    }
  };

  hubBtn.addEventListener('click', () => {
    audio.playClickSound();
    hubModal.classList.remove('hidden');
    dialogueBox.classList.add('hidden');
    batteryContainer.classList.add('hidden');
    fearContainer.classList.add('hidden');
    hintBtn.classList.add('hidden');
    puzzleModal.classList.add('hidden');
    scene.transitionToScene('exterior_gate', new THREE.Vector3(0, 2.5, 7), new THREE.Vector3(0, 2.5, -3), 1.5);
    renderStoryHub();
  });

  langBtn.addEventListener('click', () => {
    audio.playClickSound();
    story.toggleLanguage();
    renderStoryHub();
    if (!dialogueBox.classList.contains('hidden')) {
      renderCurrentNode();
    }
  });

  audioBtn.addEventListener('click', () => {
    const isMuted = audio.toggleSound();
    audioIcon.textContent = isMuted ? '🔇' : '🔊';
  });

  renderStoryHub();
});
