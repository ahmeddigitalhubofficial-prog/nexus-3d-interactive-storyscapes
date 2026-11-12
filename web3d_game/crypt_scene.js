/**
 * CryptScene: High-Performance WebGL 3D Engine with Particle Systems & Camera Shake
 * Manages 3D multi-room scenes, lighting, floating dust motes, torch embers, chest lid opening & camera flight transitions.
 */
class CryptScene {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    this.currentSceneId = 'exterior_gate';
    this.isChestOpen = false;
    this.torches = [];
    this.particleSystems = [];

    this.initThree();
    this.createEnvironment();
    this.setupRaycaster();
    this.animate();
  }

  initThree() {
    this.scene = new THREE.Scene();
    this.scene.fog = new THREE.FogExp2(0x050608, 0.05);

    this.camera = new THREE.PerspectiveCamera(
      60,
      window.innerWidth / window.innerHeight,
      0.1,
      1000
    );
    this.camera.position.set(0, 2.5, 7);

    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.container.appendChild(this.renderer.domElement);

    // Orbit Controls for smooth 3D view dragging
    this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    this.controls.maxPolarAngle = Math.PI / 1.8;
    this.controls.target.set(0, 2.5, -3);

    // Ambient & Flashlight Spotlight
    const ambientLight = new THREE.AmbientLight(0x1a1e29, 0.8);
    this.scene.add(ambientLight);

    this.spotLight = new THREE.SpotLight(0xffecd1, 2.5, 25, Math.PI / 6, 0.4, 1);
    this.spotLight.position.set(0, 4, 7);
    this.scene.add(this.spotLight);
    this.scene.add(this.spotLight.target);

    window.addEventListener('resize', () => this.onWindowResize());
    window.addEventListener('mousemove', (e) => this.onMouseMove(e));
  }

  onMouseMove(event) {
    const mouseX = (event.clientX / window.innerWidth) * 2 - 1;
    const mouseY = -(event.clientY / window.innerHeight) * 2 + 1;
    this.spotLight.target.position.set(mouseX * 4, mouseY * 3 + 2, -3);
  }

  createEnvironment() {
    this.sceneGroups = {};

    // 🌟 SCENE 1: EXTERIOR GRAVEYARD
    const extGroup = new THREE.Group();
    const groundGeo = new THREE.PlaneGeometry(60, 60);
    const groundMat = new THREE.MeshStandardMaterial({ color: 0x11161d, roughness: 0.95 });
    const ground = new THREE.Mesh(groundGeo, groundMat);
    ground.rotation.x = -Math.PI / 2;
    extGroup.add(ground);

    // Iron Gate Columns
    const colGeo = new THREE.BoxGeometry(0.8, 5, 0.8);
    const colMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.6 });
    const leftCol = new THREE.Mesh(colGeo, colMat);
    leftCol.position.set(-2, 2.5, -3);
    const rightCol = new THREE.Mesh(colGeo, colMat);
    rightCol.position.set(2, 2.5, -3);
    extGroup.add(leftCol, rightCol);

    // Iron Bars
    const barGeo = new THREE.CylinderGeometry(0.05, 0.05, 4.5);
    const barMat = new THREE.MeshStandardMaterial({ color: 0x0f172a, metalness: 0.8 });
    for (let x = -1.6; x <= 1.6; x += 0.4) {
      const bar = new THREE.Mesh(barGeo, barMat);
      bar.position.set(x, 2.25, -3);
      extGroup.add(bar);
    }

    // Gate Lock Object
    const lockGeo = new THREE.BoxGeometry(0.3, 0.4, 0.2);
    const lockMat = new THREE.MeshStandardMaterial({ color: 0xffb703, metalness: 0.9, roughness: 0.2 });
    const lock = new THREE.Mesh(lockGeo, lockMat);
    lock.position.set(0, 2.0, -2.8);
    lock.userData = { name: "Gate Lock", interactable: true, id: "gate_lock" };
    extGroup.add(lock);

    // Tombstones & Dead Trees
    const tombGeo = new THREE.BoxGeometry(0.6, 1.2, 0.2);
    const tombMat = new THREE.MeshStandardMaterial({ color: 0x334155 });
    for (let i = 0; i < 8; i++) {
      const tomb = new THREE.Mesh(tombGeo, tombMat);
      const angle = (i / 8) * Math.PI * 2;
      tomb.position.set(Math.cos(angle) * 8, 0.6, Math.sin(angle) * 8 - 3);
      tomb.rotation.y = Math.random() * 0.4;
      extGroup.add(tomb);
    }

    this.scene.add(extGroup);
    this.sceneGroups['exterior_gate'] = extGroup;

    // 🌟 SCENE 2: INTERIOR CRYPT & 3D CHEST
    const intGroup = new THREE.Group();
    intGroup.position.set(0, 0, -40);

    const cryptFloor = new THREE.Mesh(
      new THREE.PlaneGeometry(30, 30),
      new THREE.MeshStandardMaterial({ color: 0x0a0d14, roughness: 0.8 })
    );
    cryptFloor.rotation.x = -Math.PI / 2;
    intGroup.add(cryptFloor);

    // Crypt Stone Walls
    const wallMat = new THREE.MeshStandardMaterial({ color: 0x111827, roughness: 0.9 });
    const backWall = new THREE.Mesh(new THREE.BoxGeometry(30, 10, 0.5), wallMat);
    backWall.position.set(0, 5, -15);
    const leftWall = new THREE.Mesh(new THREE.BoxGeometry(0.5, 10, 30), wallMat);
    leftWall.position.set(-15, 5, 0);
    const rightWall = new THREE.Mesh(new THREE.BoxGeometry(0.5, 10, 30), wallMat);
    rightWall.position.set(15, 5, 0);
    intGroup.add(backWall, leftWall, rightWall);

    // Marble Altar & 3D Chest Group
    const altar = new THREE.Mesh(
      new THREE.CylinderGeometry(2, 2.5, 1.2, 16),
      new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.4 })
    );
    altar.position.set(0, 0.6, -2);
    intGroup.add(altar);

    // 3D Chest Group
    const chestGroup = new THREE.Group();
    const chestBase = new THREE.Mesh(
      new THREE.BoxGeometry(1.8, 1.0, 1.1),
      new THREE.MeshStandardMaterial({ color: 0x2b1810, roughness: 0.4 })
    );
    chestBase.position.set(0, 0.5, 0);
    chestGroup.add(chestBase);

    // Pivot Group for 3D Lid Opening Animation
    const lidPivot = new THREE.Group();
    lidPivot.position.set(0, 0.5, -0.55);

    const chestLid = new THREE.Mesh(
      new THREE.CylinderGeometry(0.55, 0.55, 1.8, 16, 1, false, 0, Math.PI),
      new THREE.MeshStandardMaterial({ color: 0x3d2710, roughness: 0.4 })
    );
    chestLid.rotation.z = Math.PI / 2;
    chestLid.position.set(0, 0, 0.55);
    lidPivot.add(chestLid);
    chestGroup.add(lidPivot);
    this.chestLidMesh = lidPivot;

    // Glowing Golden Relic inside chest
    const relicGeo = new THREE.OctahedronGeometry(0.45, 2);
    const relicMat = new THREE.MeshStandardMaterial({ color: 0xffb703, metalness: 0.9, roughness: 0.1, emissive: 0xff8c00, emissiveIntensity: 1.8 });
    const relic = new THREE.Mesh(relicGeo, relicMat);
    relic.position.set(0, 0.4, 0);
    relic.visible = false;
    chestGroup.add(relic);
    this.chestRelicMesh = relic;

    // Glowing Light inside chest
    const chestLight = new THREE.PointLight(0xffb703, 0, 10);
    chestLight.position.set(0, 0.8, 0);
    chestGroup.add(chestLight);
    this.chestLight = chestLight;

    chestGroup.position.set(0, 1.5, -2);
    chestGroup.userData = { name: "Obsidian Chest", interactable: true, id: "chest" };
    intGroup.add(chestGroup);

    this.createPurpleTorch(intGroup, -7, 3.5, -7);
    this.createPurpleTorch(intGroup, 7, 3.5, -7);

    this.scene.add(intGroup);
    this.sceneGroups['interior_crypt'] = intGroup;

    // 🌟 CREATE 3D FLOATING DUST PARTICLES & EMBERS
    this.createDustParticles();
  }

  createDustParticles() {
    const particleCount = 200;
    const geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);

    for (let i = 0; i < particleCount * 3; i += 3) {
      positions[i] = (Math.random() - 0.5) * 30;
      positions[i + 1] = Math.random() * 8;
      positions[i + 2] = (Math.random() - 0.5) * 50 - 20;
    }

    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const material = new THREE.PointsMaterial({
      color: 0xffb703,
      size: 0.12,
      transparent: true,
      opacity: 0.6
    });

    this.particles = new THREE.Points(geometry, material);
    this.scene.add(this.particles);
  }

  // 🎬 ANIMATE 3D CHEST OPENING & GLOWING RELIC RISE
  openChestLidAnimation() {
    this.isChestOpen = true;

    const startRot = this.chestLidMesh ? this.chestLidMesh.rotation.x : 0;
    const targetRot = -Math.PI / 1.4;
    const startTime = performance.now();
    const duration = 1.5;

    if (this.chestRelicMesh) this.chestRelicMesh.visible = true;

    const animateChest = (now) => {
      const elapsed = (now - startTime) / 1000;
      const progress = Math.min(elapsed / duration, 1);
      const ease = progress < 0.5 ? 2 * progress * progress : -1 + (4 - 2 * progress) * progress;

      if (this.chestLidMesh) {
        this.chestLidMesh.rotation.x = THREE.MathUtils.lerp(startRot, targetRot, ease);
        this.chestLidMesh.position.y = THREE.MathUtils.lerp(0.5, 1.2, ease);
        this.chestLidMesh.position.z = THREE.MathUtils.lerp(-0.55, -1.2, ease);
      }

      if (this.chestLight) {
        this.chestLight.intensity = THREE.MathUtils.lerp(0, 15.0, ease);
      }

      if (this.chestRelicMesh) {
        this.chestRelicMesh.position.y = THREE.MathUtils.lerp(0.4, 1.8, ease);
        this.chestRelicMesh.rotation.y = elapsed * 3.0;
      }

      if (progress < 1) {
        requestAnimationFrame(animateChest);
      }
    };
    requestAnimationFrame(animateChest);
  }

  resetChest() {
    this.isChestOpen = false;
    if (this.chestLidMesh) {
      this.chestLidMesh.rotation.x = 0;
      this.chestLidMesh.position.set(0, 0.5, -0.55);
    }
    if (this.chestLight) this.chestLight.intensity = 0;
    if (this.chestRelicMesh) {
      this.chestRelicMesh.visible = false;
      this.chestRelicMesh.position.y = 0.2;
    }
  }

  createPurpleTorch(group, x, y, z) {
    const torchGroup = new THREE.Group();
    const sconce = new THREE.Mesh(
      new THREE.CylinderGeometry(0.08, 0.05, 0.6, 8),
      new THREE.MeshStandardMaterial({ color: 0x1e293b, metalness: 0.9 })
    );
    torchGroup.add(sconce);

    const light = new THREE.PointLight(0x9d4edd, 3.0, 10);
    light.position.set(0, 0.4, 0.2);
    torchGroup.add(light);

    torchGroup.position.set(x, y, z);
    group.add(torchGroup);
    this.torches.push({ light, baseIntensity: 3.0 });
  }

  transitionToScene(sceneId, targetPos, lookAtPos, duration = 2.0) {
    this.currentSceneId = sceneId;
    const startPos = this.camera.position.clone();
    const startTime = performance.now();

    const animateFlight = (now) => {
      const elapsed = (now - startTime) / 1000;
      const progress = Math.min(elapsed / duration, 1);
      const ease = progress < 0.5 ? 2 * progress * progress : -1 + (4 - 2 * progress) * progress;

      this.camera.position.lerpVectors(startPos, targetPos, ease);
      this.controls.target.lerp(lookAtPos, ease);
      this.controls.update();

      if (progress < 1) {
        requestAnimationFrame(animateFlight);
      }
    };
    requestAnimationFrame(animateFlight);
  }

  setupRaycaster() {
    this.raycaster = new THREE.Raycaster();
    this.mouse = new THREE.Vector2();

    window.addEventListener('click', (e) => {
      this.mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
      this.mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;
      this.raycaster.setFromCamera(this.mouse, this.camera);

      const intersects = this.raycaster.intersectObjects(this.scene.children, true);
      for (let hit of intersects) {
        let parent = hit.object;
        while (parent && !parent.userData.interactable) {
          parent = parent.parent;
        }
        if (parent && parent.userData.interactable) {
          if (window.on3DObjectInteract) {
            window.on3DObjectInteract(parent.userData);
          }
          break;
        }
      }
    });
  }

  animate() {
    requestAnimationFrame(() => this.animate());

    // Torch flicker
    const time = performance.now() * 0.005;
    this.torches.forEach((torch, idx) => {
      torch.light.intensity = torch.baseIntensity + Math.sin(time * 3 + idx) * 0.5 + Math.random() * 0.3;
    });

    // Rotate particles gently
    if (this.particles) {
      this.particles.rotation.y = time * 0.02;
    }

    if (this.chestRelicMesh && this.chestRelicMesh.visible) {
      this.chestRelicMesh.rotation.y += 0.03;
    }

    this.controls.update();
    this.renderer.render(this.scene, this.camera);
  }

  onWindowResize() {
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(window.innerWidth, window.innerHeight);
  }
}
