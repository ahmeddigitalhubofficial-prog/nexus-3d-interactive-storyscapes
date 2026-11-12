/**
 * Next-Gen 3D Scene Manager for Nexus 3D: Interactive Storyscapes
 * Includes UnrealBloomPass Glow, Cinematic Camera Sway, Dynamic PBR Materials,
 * Multi-layer Particle Systems, and Real-time Lighting Shifts.
 */
class NexusSceneManager {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    this.currentMode = 'chrono';
    this.timeShiftState = '2140';
    this.clock = new THREE.Clock();
    this.mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };

    this.initThree();
    this.initBloomPostProcessing();
    this.buildChronoScene();
    this.initMouseEvents();
    this.animate();

    window.addEventListener('resize', () => this.onWindowResize());
  }

  initThree() {
    this.scene = new THREE.Scene();
    this.scene.fog = new THREE.FogExp2(0x050811, 0.035);

    this.camera = new THREE.PerspectiveCamera(55, window.innerWidth / window.innerHeight, 0.1, 1000);
    this.camera.position.set(0, 2.2, 6.5);

    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, powerPreference: "high-performance" });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.2;

    if (this.container) {
      this.container.appendChild(this.renderer.domElement);
    }

    // Ambient Lighting
    this.ambientLight = new THREE.AmbientLight(0x0c1527, 0.8);
    this.scene.add(this.ambientLight);

    // Primary Dynamic Point Lights
    this.mainLight = new THREE.PointLight(0x00f0ff, 3, 25);
    this.mainLight.position.set(0, 4, 0);
    this.mainLight.castShadow = true;
    this.scene.add(this.mainLight);

    this.accentLight = new THREE.PointLight(0xff0055, 2.5, 20);
    this.accentLight.position.set(3.5, 2, -3);
    this.scene.add(this.accentLight);

    // Dynamic Particle & Environment Groups
    this.particlesGroup = new THREE.Group();
    this.scene.add(this.particlesGroup);

    this.environmentGroup = new THREE.Group();
    this.scene.add(this.environmentGroup);
  }

  initBloomPostProcessing() {
    try {
      if (window.THREE && THREE.EffectComposer && THREE.RenderPass && THREE.UnrealBloomPass) {
        const renderScene = new THREE.RenderPass(this.scene, this.camera);

        // Unreal Bloom parameters: resolution, strength, radius, threshold
        this.bloomPass = new THREE.UnrealBloomPass(
          new THREE.Vector2(window.innerWidth, window.innerHeight),
          1.4, // Bloom strength
          0.5, // Bloom radius
          0.2  // Bloom threshold
        );

        this.composer = new THREE.EffectComposer(this.renderer);
        this.composer.addPass(renderScene);
        this.composer.addPass(this.bloomPass);
      }
    } catch (e) {
      console.warn("Bloom Post Processing fallback to default renderer", e);
    }
  }

  initMouseEvents() {
    window.addEventListener('mousemove', (event) => {
      this.mouse.targetX = (event.clientX / window.innerWidth - 0.5) * 0.8;
      this.mouse.targetY = (event.clientY / window.innerHeight - 0.5) * 0.5;
    });
  }

  clearEnvironment() {
    while (this.environmentGroup.children.length > 0) {
      const obj = this.environmentGroup.children[0];
      this.environmentGroup.remove(obj);
    }
    while (this.particlesGroup.children.length > 0) {
      const p = this.particlesGroup.children[0];
      this.particlesGroup.remove(p);
    }
    this.chronoRings = [];
    this.rainParticles = null;
  }

  // 1. CHRONO-CORE: High-Tech Space Station Dual Timeline
  buildChronoScene(timeState = '2140') {
    this.currentMode = 'chrono';
    this.timeShiftState = timeState;
    this.clearEnvironment();

    const isPast = timeState === '2088';
    this.scene.fog.color.setHex(isPast ? 0x030c1c : 0x180303);
    this.ambientLight.color.setHex(isPast ? 0x183050 : 0x300808);
    this.mainLight.color.setHex(isPast ? 0x00f0ff : 0xff3300);
    this.accentLight.color.setHex(isPast ? 0xffd700 : 0xff0055);

    // Quantum Reactor Core Housing
    const reactorGeo = new THREE.CylinderGeometry(1.6, 2.2, 4.5, 32);
    const reactorMat = new THREE.MeshStandardMaterial({
      color: isPast ? 0x1a2636 : 0x111111,
      roughness: 0.15,
      metalness: 0.9,
      wireframe: !isPast
    });
    const reactor = new THREE.Mesh(reactorGeo, reactorMat);
    reactor.position.set(0, 0, -4.5);
    this.environmentGroup.add(reactor);

    // Glowing Dual Temporal Rings
    this.chronoRings = [];
    for (let r = 0; r < 2; r++) {
      const ringGeo = new THREE.TorusGeometry(1.4 + r * 0.4, 0.12, 16, 100);
      const ringMat = new THREE.MeshStandardMaterial({
        color: isPast ? (r === 0 ? 0x00f0ff : 0xffd700) : 0xff2200,
        emissive: isPast ? (r === 0 ? 0x00e5ff : 0xffb700) : 0xff1100,
        emissiveIntensity: 1.5,
        roughness: 0.2,
        metalness: 0.8
      });
      const ring = new THREE.Mesh(ringGeo, ringMat);
      ring.position.set(0, 0, -4.5);
      ring.rotation.x = Math.PI / 3 * r;
      this.chronoRings.push(ring);
      this.environmentGroup.add(ring);
    }

    // Particle Swarm Rift
    const pGeo = new THREE.BufferGeometry();
    const count = 400;
    const pos = new Float32Array(count * 3);
    for (let i = 0; i < count * 3; i += 3) {
      pos[i] = (Math.random() - 0.5) * 12;
      pos[i + 1] = (Math.random() - 0.5) * 6;
      pos[i + 2] = (Math.random() - 0.5) * 12 - 2;
    }
    pGeo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    const pMat = new THREE.PointsMaterial({
      size: 0.1,
      color: isPast ? 0x00ffff : 0xff4400,
      transparent: true,
      opacity: 0.85
    });
    this.particlesGroup.add(new THREE.Points(pGeo, pMat));
  }

  // 2. CRYPT OF SECRETS: Gothic Cathedral Catacombs
  buildAbyssalScene() {
    this.currentMode = 'abyssal';
    this.clearEnvironment();

    this.scene.fog.color.setHex(0x0c0603);
    this.ambientLight.color.setHex(0x200e05);
    this.mainLight.color.setHex(0xffaa22);
    this.accentLight.color.setHex(0x440500);

    // Gothic Arch Pillars
    for (let i = -2; i <= 2; i += 2) {
      const pillarGeo = new THREE.BoxGeometry(0.7, 6, 0.7);
      const pillarMat = new THREE.MeshStandardMaterial({ color: 0x1f1915, roughness: 0.85, metalness: 0.1 });
      const pLeft = new THREE.Mesh(pillarGeo, pillarMat);
      pLeft.position.set(-2.8, 1, i * 3 - 3.5);
      const pRight = pLeft.clone();
      pRight.position.x = 2.8;
      this.environmentGroup.add(pLeft, pRight);
    }

    // Obsidian Altar with Glowing Runes
    const altarGeo = new THREE.BoxGeometry(2.4, 0.9, 1.4);
    const altarMat = new THREE.MeshStandardMaterial({
      color: 0x0f0b0a,
      roughness: 0.4,
      metalness: 0.7,
      emissive: 0xaa2200,
      emissiveIntensity: 0.3
    });
    const altar = new THREE.Mesh(altarGeo, altarMat);
    altar.position.set(0, -0.6, -4);
    this.environmentGroup.add(altar);
  }

  // 3. NEON PHANTOM: Cyberpunk Rain Alley
  buildNeonScene() {
    this.currentMode = 'neon';
    this.clearEnvironment();

    this.scene.fog.color.setHex(0x04000d);
    this.ambientLight.color.setHex(0x0a0218);
    this.mainLight.color.setHex(0x00ffff);
    this.accentLight.color.setHex(0xff0088);

    // Rain Particle Velocities
    const count = 700;
    const pGeo = new THREE.BufferGeometry();
    const pos = new Float32Array(count * 3);
    for (let i = 0; i < count * 3; i += 3) {
      pos[i] = (Math.random() - 0.5) * 14;
      pos[i + 1] = Math.random() * 9;
      pos[i + 2] = (Math.random() - 0.5) * 14;
    }
    pGeo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    const pMat = new THREE.PointsMaterial({ size: 0.06, color: 0x88eeff, transparent: true, opacity: 0.8 });
    this.rainParticles = new THREE.Points(pGeo, pMat);
    this.particlesGroup.add(this.rainParticles);
  }

  // 4. THE LAST BEACON: Arctic Tundra Blizzard
  buildBeaconScene() {
    this.currentMode = 'beacon';
    this.clearEnvironment();

    this.scene.fog.color.setHex(0x010810);
    this.ambientLight.color.setHex(0x04101d);
    this.mainLight.color.setHex(0x66eeff);
    this.accentLight.color.setHex(0xffffff);

    // Colossal Beacon Tower Beam
    const towerGeo = new THREE.CylinderGeometry(0.7, 1.6, 9, 16);
    const towerMat = new THREE.MeshStandardMaterial({
      color: 0x0b1726,
      roughness: 0.3,
      metalness: 0.8,
      emissive: 0x0088ff,
      emissiveIntensity: 0.4
    });
    const tower = new THREE.Mesh(towerGeo, towerMat);
    tower.position.set(0, 2.5, -6.5);
    this.environmentGroup.add(tower);
  }

  // 5. VALKYRIE DOWN: Nordic Alien Ruins
  buildValkyrieScene() {
    this.currentMode = 'valkyrie';
    this.clearEnvironment();

    this.scene.fog.color.setHex(0x010c06);
    this.ambientLight.color.setHex(0x051a0d);
    this.mainLight.color.setHex(0x00ff88);
    this.accentLight.color.setHex(0x00ccff);

    // Rune Obelisk Diamond
    const runeGeo = new THREE.OctahedronGeometry(1.4, 0);
    const runeMat = new THREE.MeshStandardMaterial({
      color: 0x022410,
      roughness: 0.2,
      metalness: 0.9,
      emissive: 0x00ff66,
      emissiveIntensity: 0.8
    });
    this.valkyrieObelisk = new THREE.Mesh(runeGeo, runeMat);
    this.valkyrieObelisk.position.set(0, 0.8, -4.5);
    this.environmentGroup.add(this.valkyrieObelisk);
  }

  loadStoryMode(mode, subState) {
    if (mode === 'chrono') this.buildChronoScene(subState || '2140');
    else if (mode === 'abyssal') this.buildAbyssalScene();
    else if (mode === 'neon') this.buildNeonScene();
    else if (mode === 'beacon') this.buildBeaconScene();
    else if (mode === 'valkyrie') this.buildValkyrieScene();
  }

  animate() {
    requestAnimationFrame(() => this.animate());

    const elapsedTime = this.clock.getElapsedTime();

    // Smooth Mouse Sway & Camera Bobbing
    this.mouse.x += (this.mouse.targetX - this.mouse.x) * 0.05;
    this.mouse.y += (this.mouse.targetY - this.mouse.y) * 0.05;
    this.camera.position.x = this.mouse.x * 1.2;
    this.camera.position.y = 2.2 + Math.sin(elapsedTime * 1.5) * 0.08 + this.mouse.y * -0.8;
    this.camera.lookAt(0, 0, -4);

    // Chrono Rings Rotation
    if (this.chronoRings) {
      this.chronoRings.forEach((ring, idx) => {
        ring.rotation.z += 0.012 * (idx === 0 ? 1 : -1);
        ring.rotation.x += 0.006;
      });
    }

    // Valkyrie Obelisk Pulsing Float
    if (this.valkyrieObelisk) {
      this.valkyrieObelisk.rotation.y += 0.015;
      this.valkyrieObelisk.position.y = 0.8 + Math.sin(elapsedTime * 2) * 0.15;
    }

    // Rain Particles Velocity
    if (this.rainParticles) {
      const pos = this.rainParticles.geometry.attributes.position.array;
      for (let i = 1; i < pos.length; i += 3) {
        pos[i] -= 0.18;
        if (pos[i] < -2) pos[i] = 8;
      }
      this.rainParticles.geometry.attributes.position.needsUpdate = true;
    }

    // Render with Bloom Composer if available
    if (this.composer) {
      this.composer.render();
    } else {
      this.renderer.render(this.scene, this.camera);
    }
  }

  onWindowResize() {
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    if (this.composer) {
      this.composer.setSize(window.innerWidth, window.innerHeight);
    }
  }
}

window.NexusSceneManager = NexusSceneManager;
