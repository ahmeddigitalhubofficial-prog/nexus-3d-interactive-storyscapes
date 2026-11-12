/**
 * StoryEngine: Restored Authentic Original Story ("سرداب الأسرار")
 * Preserves the original narrative nodes, choices, flashlight search, chest inspection, key discovery, monsters, and multiple endings.
 */
class StoryEngine {
  constructor() {
    this.currentLanguage = 'ar'; // Set default language to Arabic as originally preferred
    this.activeStoryId = 'horror_crypt';
    this.currentNodeId = 'intro';
    
    // Player State & Stats
    this.state = {
      fear: 0,
      battery: 100,
      sanity: 100,
      inventory: [],
      codex: []
    };

    // Story Catalog
    this.catalog = [
      {
        id: "chrono_core",
        icon: "⏳",
        title_en: "Chrono-Core: Echo of Prometheus",
        title_ar: "Chrono-Core: أصداء بروميثيوس",
        genre_en: "SCI-FI TIME-SWAP 3D ACTION",
        genre_ar: "خيال علمي وتنقل زمني 3D",
        desc_en: "Shift between 2088 and 2140 in real-time aboard a shattered space station to prevent temporal extinction.",
        desc_ar: "تنقل بين عامي 2088 و 2140 في الوقت الفعلي داخل محطة فضائية لمنع كارثة زمنية.",
        status: "available"
      },
      {
        id: "abyssal_archive",
        icon: "🏛️",
        title_en: "Crypt of Secrets: Abyssal Archive",
        title_ar: "سرداب الأسرار: الأرشيف السحيق",
        genre_en: "DARK GOTHIC HORROR 3D",
        genre_ar: "رعب غوطي مظلم 3D",
        desc_en: "Navigate subterranean catacombs beneath Victorian Europe where every unlocked door demands a sacrifice.",
        desc_ar: "استكشف سراديب مظلمة تحت أوروبا الفيكتورية حيث يتطلب كل باب مفتوح تضحية بالسر.",
        status: "available"
      },
      {
        id: "neon_phantom",
        icon: "🌆",
        title_en: "Neon Phantom: Tokyo 2099",
        title_ar: "شبح النيون: طوكيو 2099",
        genre_en: "CYBERPUNK DETECTIVE 3D",
        genre_ar: "تحقيق سايبربانك 3D",
        desc_en: "Walk inside 3D holographic memory reconstructions to alter past clues and unmask a cyber assassin.",
        desc_ar: "ادخل داخل ذكريات 3D هولوغرافية لضحايا الجرائم لتعديل أدلة الماضي وكشف القاتل.",
        status: "available"
      },
      {
        id: "last_beacon",
        icon: "❄️",
        title_en: "The Last Beacon",
        title_ar: "المنارة الأخيرة",
        genre_en: "SURVIVAL COSMIC DARKNESS 3D",
        genre_ar: "بقاء وعوالم مظلمة 3D",
        desc_en: "Traverse a frozen arctic tundra to repair light beacons keeping humanity safe from shadow hunters.",
        desc_ar: "اعبر عالماً متجمداً لإصلاح منارات الضوء العملاقة التي تحمي البشرية من صيادي الظلال.",
        status: "available"
      },
      {
        id: "valkyrie_down",
        icon: "⚔️",
        title_en: "Valkyrie Down: Ruins of Asgard",
        title_ar: "سقوط الفالكيري: أطلال أسجارد",
        genre_en: "NORDIC SCI-FI ACTION 3D",
        genre_ar: "أكشن نوردي خيال علمي 3D",
        desc_en: "Crash land on a mythic planet where ancient AI constructs are worshipped as Norse Gods.",
        desc_ar: "اصطدم بكوكب أسطوري تُعبد فيه الذكاءات الاصطناعية القديمة كآلهة نوردية.",
        status: "available"
      },
      {
        id: "horror_crypt",
        icon: "🧟",
        title_en: "Crypt of Secrets (Classic)",
        title_ar: "سرداب الأسرار (التقليدية)",
        genre_en: "CINEMATIC 3D HORROR",
        genre_ar: "رعب وسرداب سينمائي 3D",
        desc_en: "Explore the ancient crypt, discover the flashlight, unlock the wooden chest, and escape the nightmare.",
        desc_ar: "استكشف السرداب القديم، اعثر على الكشاف اليدوي، افتح الصندوق الخشبي 3D، وتجنب الوحوش للنجاة.",
        status: "available"
      },
      {
        id: "history_timetravel",
        icon: "🏺",
        title_en: "Guardian of Time",
        title_ar: "حارس بوابة الزمن",
        genre_en: "3D ANCIENT EGYPTIAN SCI-FI",
        genre_ar: "مصر القديمة وخيال علمي 3D",
        desc_en: "Stranded in 1332 BCE during pyramid construction. Decipher astronomical sundials before time collapses.",
        desc_ar: "عالق في عام 1332 قبل الميلاد أثناء بناء مقبرة توت عنخ آمون. فك شفرات الساعات الفلكية 3D.",
        status: "available"
      },
      {
        id: "comedy_treasure",
        icon: "🏴‍☠️",
        title_en: "The Accidental Treasure",
        title_ar: "رحلة الكنز... بالخطأ!",
        genre_en: "3D PIRATE ADVENTURE & COMEDY",
        genre_ar: "مغامرة وقراصنة 3D",
        desc_en: "A comedic pirate adventure of a failing captain who discovers a grocery list map leading to treasure.",
        desc_ar: "مغامرة كوميدية لقرصان فاشل يجد خريطة قديمة يكتشف لاحقاً أنها قائمة مشتريات لملك قديم.",
        status: "available"
      }
    ];

    // Arabic Story Nodes (Authentic Original Text)
    this.arabicNodes = {
      "horror_crypt": {
        "intro": {
          "title": "بوابة السرداب القديم",
          "chapter": "المقدمة • البوابة الحديدية",
          "text": "إنت واقف قدام البوابة الحديد المصدي بتاعة السرداب القديم. الضباب مالك المكان كله، وفي همسات غامضة كأنها بتناديك تدخل جوة. حاسس ببرد غريب ماشي في جسمك كله...",
          "hint": "💡 تقدر تدور حوالين السور الخارجي الأول عشان تلاقي كشاف يدوي يساعدك!",
          "choices": [
            { "text": "ادخل حوش السرداب الضلمة", "target": "garden", "fear": 15 },
            { "text": "دور حوالين السور الخارجي الأول", "target": "search_wall", "fear": 0 }
          ]
        },
        "search_wall": {
          "title": "السور الخارجي",
          "chapter": "المقدمة • اكتشاف الكشاف",
          "text": "دورت جنب السور القديم المهدوم، ولقيت كشاف يدوي قديم بين الشجر الناشف. شكله لسه شغال!",
          "hint": "💡 التقط الكشاف اليدوي لتقليل الخوف ورؤية الأماكن المظلمة!",
          "choices": [
            { "text": "خد الكشاف وارجع للبوابة الرئيسية", "target": "intro_have_flashlight", "item": "flashlight", "fear": -5, "battery": +20 }
          ]
        },
        "intro_have_flashlight": {
          "title": "البوابة الرئيسية (معك الكشاف)",
          "chapter": "المقدمة • الاستعداد للدخول",
          "text": "دلوقتي بعد ما أخدت الكشاف، البوابة الحديد شكلها يخوف أقل شوية، بس الهمسات لسه شغالة وبتناديك تدخل...",
          "hint": "💡 ادخل حوش السرداب بالكشاف الآن!",
          "choices": [
            { "text": "ادخل حوش السرداب بالكشاف", "target": "garden", "fear": 5 }
          ]
        },
        "garden": {
          "title": "حوش السرداب الضلمة",
          "chapter": "الفصل الأول • حوش السرداب",
          "text": "دخلت الحوش. الدنيا ضلمة كحل هنا والشجر الميت شكله كأنه إيدين وحوش عايزة تمسكك. في صندوق خشب غريب في الركن، وباب السرداب الرئيسي في النص.",
          "hint": "💡 اقترب من الصندوق الخشب 3D لفحصه والعثور على المفتاح!",
          "choices": [
            { "text": "قرب من الصندوق الخشب عشان تفحصه", "target": "inspect_chest", "fear": 5 },
            { "text": "حاول تفتح باب السرداب الرئيسي على طول", "target": "main_door", "fear": 10 },
            { "text": "اتجه لزاوية الحوش الضلمة عشان تدور على مخرج تاني", "target": "dark_trap", "fear": 20 }
          ]
        },
        "inspect_chest": {
          "title": "الصندوق الخشب الـ 3D",
          "chapter": "الفصل الأول • فحص الصندوق",
          "text": "إنت واقف قدام الصندوق الخشب القديم. في رموز أثرية غريبة محفورة عليه. شكله محتاج فحص دقيق وقريب عشان تعرف جواه إيه. اضغط على الصندوق الـ 3D لفتحه واستخراج المفتاح المصدي!",
          "hint": "💡 افتح غطاء الصندوق الـ 3D للحصول على المفتاح المصدي!",
          "choices": [
            { "text": "🔓 افتح غطاء الصندوق الـ 3D واخد المفتاح المصدي", "target": "chest_opened", "item": "rusty_key", "fear": -10 },
            { "text": "🗝️ ادخل الشفرة الرقمية (1-8-9-4) لفتح القفل", "target": "solve_lock_puzzle", "fear": 0 },
            { "text": "بعد ما لقيت المفتاح، روح عند باب السرداب الرئيسي", "target": "main_door", "fear": 0 },
            { "text": "ارجع لنص الحوش تاني", "target": "garden", "fear": 0 }
          ]
        },
        "chest_opened": {
          "title": "تم فتح الصندوق الخشبي! 🔑",
          "chapter": "الفصل الأول • المفتاح المصدي",
          "text": "ينفتح غطاء الصندوق الـ 3D منبعثاً منه ضوء برتقالي متوهج! عثرت داخل الصندوق على مفتاح نحاسي مصدي قديم! الآن يمكنك توجه لباب السرداب الرئيسي لفتحه والهرب!",
          "hint": "💡 توجه فوراً لباب السرداب الرئيسي وفتحه بالمفتاح!",
          "choices": [
            { "text": "🚪 اتجه لباب السرداب الرئيسي وافتحه بالمفتاح", "target": "main_door", "fear": 0 }
          ]
        },
        "main_door": {
          "title": "باب السرداب الرئيسي",
          "chapter": "الفصل الثاني • الباب الكبير",
          "text": "إنت واقف قدام باب السرداب الحجر الكبير. في قفل نحاس قديم قفله. شكله محتاج مفتاح مخصوص.",
          "hint": "💡 استخدم المفتاح المصدي الذي وجدته في الصندوق لفتح الباب!",
          "choices": [
            { "text": "🔑 افتح الباب بالمفتاح المصدي اللي لقيته", "target": "victory_escape", "fear": -50 },
            { "text": "الباب مقفول جامد. ارجع للحوش ودور على طريقة تفتحه بيها", "target": "garden", "fear": 10 }
          ]
        },
        "victory_escape": {
          "title": "النهاية: الناجي الشاطر 🏆",
          "chapter": "الخاتمة • الهروب الكبير",
          "text": "المفتاح المصدي لف في القفل النحاس بصعوبة والباب اتفتح بصوت تزييق عالي. جريت لجوة ولقيت ممر سري مليان دهب وكنوز، وقفلت الباب وراك بسرعة عشان تهرب من الوحوش اللي في الحوش الضلمة! النهاية: الناجي الشاطر!",
          "hint": "🏆 مبروك! نجحت في فتح الباب والهروب بجميع الكنوز!",
          "choices": [
            { "text": "🏛️ العودة لمركز القصص (Story Hub)", "target": "intro", "fear": -100 }
          ]
        },
        "dark_trap": {
          "title": "زاوية الحوش الضلمة ☠️",
          "chapter": "خطر • هجوم الوحش",
          "text": "فجأة! الكشاف اليدوي طفى وطلع صوت زئير مرعب من ورا الشجر! في حاجة بتجري ناحيتك بسرعة رهيبة في الضلمة الكحل!",
          "hint": "💡 اختبئ سريعاً خلف الصخرة للنجاة من الوحش!",
          "choices": [
            { "text": "🏃 نط بسرعة على اليمين ورا صخرة كبيرة واستخبى", "target": "hide_success", "fear": 25 },
            { "text": "🏃 اجري ناحية البوابة الحديد عشان تهرب برة", "target": "game_over_caught", "fear": 50 }
          ]
        },
        "hide_success": {
          "title": "الاختباء وراء الصخرة",
          "chapter": "نجاة مؤقتة",
          "text": "استخبيت ورا الصخرة وإيديك بتترعش. الكائن المرعب عدى من جنب الصخرة وهو بيتنفس بصوت عالي وبعدين مشي. حاسس بقلبك هيقف من كتر الخوف! لازم تهدي نفسك عشان تقدر تكمل المغامرة...",
          "hint": "💡 خذ نفساً عميقاً وعد إلى منتصف الحوش بحذر!",
          "choices": [
            { "text": "حاول تاخد نفس عميق وتهدي نفسك وتكمل في الحوش", "target": "garden", "fear": -10 },
            { "text": "الهلع يسيطر عليك وتجري وتصرخ!", "target": "game_over_panic", "fear": 50 }
          ]
        },
        "game_over_caught": {
          "title": "النهاية: ضحية الضلمة ☠️",
          "chapter": "خسارة • تم الإمساك بك",
          "text": "مكانتش سريع كفاية! الكائن الضلمة هجم عليك من ورا الشجر وسحبك لجوة الضلمة... مغامرتك خلصت هنا. النهاية: ضحية الضلمة",
          "hint": "☠️ أعد المحاولة واختر الاختباء خلف الصخرة!",
          "choices": [
            { "text": "🏃 المحاولة مجدداً (إعادة القصة)", "target": "intro", "fear": -100 }
          ]
        },
        "game_over_panic": {
          "title": "النهاية: مات من الخوف ☠️",
          "chapter": "خسارة • سيطر الهلع",
          "text": "الخوف تملكك بالكامل وبدأت تتنفس بصوت عالي! الكائن سمع صوت نفسك اللي بيترعش ولف ناحيتك فجأة... مغامرتك خلصت هنا. النهاية: مات من الخوف",
          "hint": "☠️ أعد المحاولة وتماسك للوصول للكنز!",
          "choices": [
            { "text": "🏃 المحاولة مجدداً (إعادة القصة)", "target": "intro", "fear": -100 }
          ]
        }
      }
    };

    // English Story Nodes (Authentic Original Text)
    this.englishNodes = {
      "horror_crypt": {
        "intro": {
          "title": "The Ancient Crypt Gate",
          "chapter": "PROLOGUE • THE IRON GATE",
          "text": "You stand before the rusty iron gate of the ancient crypt. The fog fills the air, and mysterious whispers seem to call your name from within. You feel a strange chill creeping down your spine...",
          "hint": "💡 You can search around the outer wall first to find a flashlight!",
          "choices": [
            { "text": "Enter the dark crypt courtyard", "target": "garden", "fear": 15 },
            { "text": "Search around the outer wall first", "target": "search_wall", "fear": 0 }
          ]
        },
        "search_wall": {
          "title": "The Outer Wall",
          "chapter": "PROLOGUE • FLASHLIGHT DISCOVERY",
          "text": "You searched near the crumbling wall and found an old flashlight among the dry bushes. It seems to still work!",
          "hint": "💡 Pick up the flashlight to lower your fear and see in pitch black areas!",
          "choices": [
            { "text": "Pick up the flashlight and return to the main gate", "target": "intro_have_flashlight", "item": "flashlight", "fear": -5, "battery": +20 }
          ]
        },
        "intro_have_flashlight": {
          "title": "Main Gate (Flashlight Equipped)",
          "chapter": "PROLOGUE • READY TO ENTER",
          "text": "Now that you have a flashlight, the iron gate seems slightly less terrifying, but the whispers continue to invite you inside...",
          "hint": "💡 Enter the crypt courtyard with your flashlight!",
          "choices": [
            { "text": "Enter the crypt courtyard with your flashlight", "target": "garden", "fear": 5 }
          ]
        },
        "garden": {
          "title": "The Dark Courtyard",
          "chapter": "CHAPTER 1 • THE COURTYARD",
          "text": "You entered the courtyard. The darkness here is pitch-black and the dead trees look like hands of monsters trying to grab you. There is a mysterious wooden chest in the corner, and the main crypt door is in the center.",
          "hint": "💡 Approach the 3D wooden chest to inspect it and find the key!",
          "choices": [
            { "text": "Approach the wooden chest to inspect it", "target": "inspect_chest", "fear": 5 },
            { "text": "Try to open the main crypt door directly", "target": "main_door", "fear": 10 },
            { "text": "Head towards the dark corner of the courtyard to look for another exit", "target": "dark_trap", "fear": 20 }
          ]
        },
        "inspect_chest": {
          "title": "The 3D Wooden Chest",
          "chapter": "CHAPTER 1 • INSPECTING CHEST",
          "text": "You stand before the ancient wooden chest. Strange ancient symbols are carved into it. Open the 3D chest lid to extract the rusty key inside!",
          "hint": "💡 Open the 3D chest lid to retrieve the rusty key!",
          "choices": [
            { "text": "🔓 Open 3D Chest Lid & Take Rusty Key", "target": "chest_opened", "item": "rusty_key", "fear": -10 },
            { "text": "🗝️ Enter 4-Digit Code (1-8-9-4) to unlock", "target": "solve_lock_puzzle", "fear": 0 },
            { "text": "Head to the main crypt door with the key", "target": "main_door", "fear": 0 },
            { "text": "Return to the center of the courtyard", "target": "garden", "fear": 0 }
          ]
        },
        "chest_opened": {
          "title": "Chest Opened! 🔑",
          "chapter": "CHAPTER 1 • RUSTY KEY REVEALED",
          "text": "The 3D chest lid opens wide, emitting a warm orange glow! Inside you discover an ancient rusty key! Head to the main crypt door to unlock your escape!",
          "hint": "💡 Head to the main crypt door and unlock it with your key!",
          "choices": [
            { "text": "🚪 Go to the main crypt door and unlock it", "target": "main_door", "fear": 0 }
          ]
        },
        "main_door": {
          "title": "The Main Crypt Door",
          "chapter": "CHAPTER 2 • THE HEAVY DOOR",
          "text": "You stand before the massive stone crypt door. A heavy brass lock secures it. It requires a specific key.",
          "hint": "💡 Use the rusty key you found inside the wooden chest!",
          "choices": [
            { "text": "🔑 Unlock the door with the rusty key", "target": "victory_escape", "fear": -50 },
            { "text": "The door is locked tight. Return to courtyard to search for a key", "target": "garden", "fear": 10 }
          ]
        },
        "victory_escape": {
          "title": "ENDING: Clever Survivor 🏆",
          "chapter": "EPILOGUE • ESCAPE & TREASURE",
          "text": "The rusty key turns heavily in the brass lock, and the door creaks open! You rush inside to discover a secret corridor filled with gold and treasures, locking the door behind you to escape the monsters in the dark courtyard! Ending: Clever Survivor!",
          "hint": "🏆 Congratulations! You unlocked the door and escaped with all the gold!",
          "choices": [
            { "text": "🏛️ Return to Story Hub", "target": "intro", "fear": -100 }
          ]
        },
        "dark_trap": {
          "title": "Dark Corner ☠️",
          "chapter": "DANGER • MONSTER AMBUSH",
          "text": "Suddenly! Your flashlight flickers and dies. A terrifying roar echoes behind the dry trees! Something is sprinting towards you at terrifying speed in total darkness!",
          "hint": "💡 Quickly jump behind the large boulder to hide!",
          "choices": [
            { "text": "🏃 Quickly jump behind the large boulder and hide", "target": "hide_success", "fear": 25 },
            { "text": "🏃 Run towards the iron gate to escape outside", "target": "game_over_caught", "fear": 50 }
          ]
        },
        "hide_success": {
          "title": "Hiding Behind the Boulder",
          "chapter": "TEMPORARY SURVIVAL",
          "text": "You hide behind the boulder with shaking hands. The terrifying creature passes right by, breathing heavily before moving away. Your heart is pounding in terror! Calm yourself to continue...",
          "hint": "💡 Take a deep breath and carefully return to the courtyard!",
          "choices": [
            { "text": "Take a deep breath to calm down and return to courtyard", "target": "garden", "fear": -10 },
            { "text": "Panic takes over and you scream & run!", "target": "game_over_panic", "fear": 50 }
          ]
        },
        "game_over_caught": {
          "title": "ENDING: Victim of the Dark ☠️",
          "chapter": "GAME OVER • CAUGHT",
          "text": "You weren't fast enough! The shadow creature pounced on you from behind the trees and dragged you into darkness... Your adventure ends here. Ending: Victim of the Dark",
          "hint": "☠️ Try again and choose to hide behind the boulder!",
          "choices": [
            { "text": "🏃 Try Again (Restart Crypt)", "target": "intro", "fear": -100 }
          ]
        },
        "game_over_panic": {
          "title": "ENDING: Died of Fear ☠️",
          "chapter": "GAME OVER • PANIC",
          "text": "Fear completely consumed you and your breath grew loud! The creature heard your trembling breaths and turned instantly... Your adventure ends here. Ending: Died of Fear",
          "hint": "☠️ Try again and hold your breath to survive!",
          "choices": [
            { "text": "🏃 Try Again (Restart Crypt)", "target": "intro", "fear": -100 }
          ]
        }
      }
    };
  }

  loadStory(storyId) {
    this.activeStoryId = storyId;
    this.currentNodeId = 'intro';
    this.state.fear = 0;
    this.state.battery = 100;
    this.state.inventory = [];
  }

  getCurrentNode() {
    const nodesMap = this.currentLanguage === 'ar' ? this.arabicNodes : this.englishNodes;
    const storyNodes = nodesMap[this.activeStoryId] || nodesMap['horror_crypt'];
    return storyNodes[this.currentNodeId] || storyNodes['intro'];
  }

  selectChoice(choice) {
    if (choice.item && !this.state.inventory.includes(choice.item)) {
      this.state.inventory.push(choice.item);
    }
    if (choice.fear) {
      this.state.fear = Math.max(0, Math.min(100, this.state.fear + choice.fear));
    }
    if (choice.battery) {
      this.state.battery = Math.max(0, Math.min(100, this.state.battery + choice.battery));
    }
    this.currentNodeId = choice.target;
    return this.getCurrentNode();
  }

  toggleLanguage() {
    this.currentLanguage = this.currentLanguage === 'en' ? 'ar' : 'en';
    document.documentElement.lang = this.currentLanguage;
    document.documentElement.dir = this.currentLanguage === 'ar' ? 'rtl' : 'ltr';
    return this.currentLanguage;
  }
}
