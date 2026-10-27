# CLAUDE.md

Pokyny pre Claude (a ďalších vývojárov) pri práci na projekte **Jožino – Dobrodružstvo**.

## O projekte

2D plošinovka + idle budovanie dediny pre Android, **Godot 4.4.x, GDScript**.
Úplná špecifikácia je v [`docs/GDD.md`](docs/GDD.md) – pred väčšou zmenou si prečítaj príslušnú kapitolu.
Hra je po slovensky: texty v UI, komentáre a docstringy píš **po slovensky**; identifikátory v kóde **po anglicky**.

## Aktuálny stav

- **Fáza 1 (pohyb)** – hotové: `Player` s coyote time, jump bufferom, premenlivou výškou skoku, animáciami (baník), squash/stretch, prachom, kamerou s pohľadom dopredu; multitouch ovládanie.
- **Fáza 2 (prvý level)** – `level_01` hotový (216 dlaždíc): 9 druhov nepriateľov a nebezpečenstiev, bloky buchnuteľné zospodu, skryté bloky, kľúč a zámky, vypínač s modrými blokmi, pohyblivé a padajúce plošiny, láva, 2 tajné miesta za falošnými stenami, vylepšenia (štít, rýchlosť, magnet), hudba, gradient oblohy so slnkom, vietor v tráve.
- **Fáza 3 (ekonomika, progres, ukladanie)** – hotové: hlavné menu, mapa sveta Zelené údolie s 3 levelmi (`level_01`–`level_03`), nastavenia, uloženie verzie 2 (obleky, predmety, posledný level).
- **Fáza 4 (dedina)** – hotové: 3D dedina (farma v idle štýle, kamera s posunom a priblížením) s domom, baňou (vozík, offline produkcia), kováčskou dielňou, panelom vylepšení a obyvateľmi; obchod s 5 oblekmi a 2 predmetmi na štart levelu.

Ďalší krok: test celého toku na telefóne, ladenie ekonomiky, ďalší svet (Staré bane).

### Tok obrazoviek

Boot → hlavné menu → mapa sveta → level → výsledky → mapa. Z menu, mapy a dediny sa ide do dediny a obchodu.
Prechody iba cez `GameState.change_scene(cesta)` (stmavnutie, zapamätá `previous_scene`), návrat cez `GameState.go_back()`.
Cesty obrazoviek sú konštanty `GameState.SCENE_*`. Level sa spúšťa cez `ProgressionManager.start_level(id)`.
Androidové tlačidlo Späť rieši každá obrazovka v `_notification(NOTIFICATION_WM_GO_BACK_REQUEST)` (`quit_on_go_back` je vypnuté).

## Príkazy

```bash
# Prvý import (vytvorí .godot/ a cache tried) – nutné pred testami na čistom klone
godot --headless --path . --import

# Automatické testy logiky (ekonomika, progres, ukladanie, baňa). Návratový kód 0 = OK.
godot --headless --path . -s res://tests/run_tests.gd

# Simulované hranie prvého levelu bez grafiky (overí, že scény sa načítajú a fyzika beží)
godot --headless --path . --fixed-fps 60 res://tests/smoke_level.tscn

# Dosiahnuteľnosť kľúčových miest všetkých levelov (alebo jedného: -- level_02) – výstup „VÝSLEDOK: OK“
godot --headless --path . --fixed-fps 60 res://tests/level_checks.tscn

# Otvorí každú obrazovku (menu, mapa, dedina, obchod, nastavenia, levely) – výstup „OBRAZOVKY: OK“
godot --headless --path . --fixed-fps 60 res://tests/scene_smoke.tscn

# Ovládanie 3D dediny (ťuknutie na budovu a vozík, ťahanie, priblíženie) – výstup „DEDINA: OK“
godot --headless --path . --fixed-fps 60 res://tests/village_input.tscn

# Screenshot ľubovoľnej obrazovky s ukážkovým postupom
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  res://tests/scene_shot.tscn -- /cesta/obrazok.png res://scenes/village/village.tscn 1.5

# Screenshoty (potrebuje grafiku; v kontajneri cez xvfb). Argumenty: priečinok, body x,y, voliteľne „win“.
xvfb-run -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  res://tests/screenshots.tscn -- /cesta/k/priecinku level_02 200,540 3700,150 win

# Spustenie hry
godot --path .
```

Varovania „Odmietnutá záporná odmena“ a „Poškodené uloženie“ počas testov sú očakávané – testujú chybové vstupy.
Hlásenia „ObjectDB instances leaked“ / „resources still in use at exit“ pri headless scénach sú tiež očakávané (tichý zvukový ovládač neuvoľní prehrávania).
Po každej zmene logiky spusti testy; po zmene scén smoke test a level_checks, po zmene dediny aj village_input. Pri vizuálnych zmenách sprav screenshoty a pozri si ich. GitHub Actions spúšťa testy, smoke test aj level_checks pri každom pushi.

### Generátory (tools/)

Grafika a niektoré resources sa generujú skriptmi – výsledky sú v repozitári:

| Skript | Vytvára | Kedy spustiť |
|---|---|---|
| `tools/prepare_assets.py <kenney> <speech-therapy-game-v2> <kenney_extra>` | `assets/` (orezaný baník, Kenney dlaždice, parallax vrstvy, zvuky) | pri zmene zdrojových obrázkov |
| `godot --headless --path . -s res://tools/build_resources.gd` | `assets/tilesets/terrain.tres`, `assets/player/<oblek>/frames.tres`, `assets/enemies/*_frames.tres` | po zmene obrázkov postáv/terénu |
| `godot --headless --path . -s res://tools/build_levels.gd [-- level_02]` | `scenes/levels/level_0X.tscn` z máp v `data/levels/maps/` | po zmene mapy |

**Levely sa upravujú v textových mapách `data/levels/maps/level_0X.txt`** (legenda všetkých znakov je v hlavičke `tools/build_levels.gd`; sekcia `[secret]` určuje falošné steny) a potom sa vygenerujú. Nový level: mapa + `data/levels/level_0X.tres` (aj `map_position` na mape sveta) + záznam v `ProgressionManager.LEVELS` a `LEVEL_IDS` generátora. Generátor sám dopĺňa náhodné dekorácie na voľnú zem (pevné semienko, výsledok je stále rovnaký). Ak ho niekto upraví ručne v editore, generátor už nespúšťaj, inak zmeny prepíše. Po zmene mapy spusti `level_checks` a uprav ho, ak sa presunuli hviezdy/pružina.

## Architektúra

```
autoload/      GameState, SaveManager, EconomyManager, ProgressionManager, Audio, Music, VillageManager, ShopManager (poradie v project.godot je dôležité)
scripts/data/  PlayerProgress, LevelRun, MineProduction, LevelDefinition, BuildingDefinition
scripts/       player/, enemies/, items/, blocks/, hazards/, platforms/, effects/, levels/, ui/, menus/, world_map/, village/
scenes/        zrkadlí scripts/
data/          .tres definície levelov a budov (balans sa ladí tu, nie v kóde)
tests/         headless testy, smoke test, level_checks, screenshoty
tools/         generátory assetov a levelu
assets/        grafika a zvuky (pôvod v CREDITS.md); 3D diely dediny v assets/village3d/{town,survival,nature}
```

Pravidlá, ktoré treba dodržať:

1. **Jeden vlastník stavu.** `GameState.progress` je jediná inštancia `PlayerProgress`. Nikdy si ju nekopíruj do UI ani do iného systému.
2. **Mena iba cez `EconomyManager`.** Všetky príjmy idú cez `grant_reward(source, coins, gold)`, jednorazové cez `claim_one_time(id, …)`, nákupy cez `spend()` (atomický). Mena nikdy < 0.
3. **Herné objekty nevolajú `SaveManager`.** Mince/hviezdy/truhlice zapisujú iba do `GameState.current_run` (`LevelRun`). Do trvalého progresu ho prenesie `ProgressionManager.finish_run()`.
4. **Ukladanie:** systémy volajú `SaveManager.request_save()` (zlúči zmeny v jednej snímke do jedného zápisu). Zápis je atomický (`.tmp` → premenovanie, `.bak` záloha). Pri zmene `PlayerProgress` zvýš `SAVE_VERSION`, pridaj migráciu do `SaveManager._migrate()` a validáciu do `PlayerProgress.from_dict()`.
5. **UI iba zobrazuje.** Pripája sa na signály (`LevelRun.changed`, `EconomyManager.currency_changed`), nič nepočíta.
6. **Hráč nevie o srdciach.** `Player` iba vyšle `damaged`; srdcia, checkpointy a koniec rieši `LevelController`.
7. **Logopédia (budúcnosť)** sa pripojí iba cez `EconomyManager.grant_reward("speech_exercise", …)`.
8. **Nepriatelia dedia z `Enemy`** (`scripts/enemies/enemy.gd`): ten rieši kontakt, skok zhora (`stompable`) a porazenie s efektom. Potomok dopĺňa iba `_move()` a `_animate()` (procedurálne „oživenie“ – Kenney nepriatelia majú len 2 snímky). Scéna potrebuje uzly `Sprite` (animácie `walk`, `dead`), `Hitbox`, `CollisionShape2D`.
9. **Bloky reagujú na náraz hlavou** cez metódu `bump(player)` – volá ju `Player._bump_ceiling()` pre každý kolíziou zasiahnutý objekt nad hlavou. Nové interaktívne bloky stačí vybaviť touto metódou.
10. **Efekty** (`Effects.burst/poof/sparkle/floating_text/debris`) sa pridávajú do uzla v skupine `level` (mimo levelu v skupine `effects`), nie pod rušený objekt.
11. **Vylepšenia** sú v `Player` (`add_powerup`, `has_powerup`); HUD ich iba zobrazuje cez signál `powerups_changed` a `get_powerups()`. Kľúče a tajné miesta počíta `LevelRun`.
12. **Dedina a obchod:** budovy, ich ceny a baňu rieši `VillageManager` (dom musí byť opravený, kým sa dá stavať ďalej; pred vylepšením bane sa vyplatí produkcia). Obleky a predmety `ShopManager`; predmety sa spotrebujú automaticky na začiatku levelu (`LevelController._use_shop_items`). Obrazovky iba volajú tieto funkcie.
13. **3D dedina** (`scenes/village/village.tscn`, Node3D + CanvasLayer s UI): modely budov skladá `VillageModels` z Kenney dielov podľa úrovne (bunka 1×1, stena leží na okraji +X, `BUILDING_SCALE` = 2), okolie `VillageDecor` (pevné semienko). `VillageBuilding` má štítok, šípku a `StaticBody3D` s metadátom `pick`; ťuknutie rieši lúč v `village.gd`. `VillageCamera` drží posun a priblíženie, `Villager` je 2D postavička otočená ku kamere. Nature Kit má pastelové farby – prefarbujú sa podľa názvu materiálu (`VillageModels.NATURE_COLORS`).
14. **UI téma** je v `assets/ui/theme.tres` (písmo Baloo 2, tlačidlá, panely). Varianty: `RoundButton` (okrúhle s ikonou), `DangerButton` (červené), `Card`, `TitleLabel`, `OutlinedLabel`. Nové UI farbi cez ne, nie cez vlastné štýly.

### Pravidlá odmien (GDD kap. 2.4, 4.2)

- Neúspech: 50 % mincí z pokusu, žiadne zlato ani hviezdy.
- Úspech: mince z pokusu + `completion_coins`; jednorazovo zlato za prvý priechod, truhlicu a všetky 3 hviezdy.
- ID jednorazových odmien: `"<level_id>:first_clear"`, `"<level_id>:chest:<chest_id>"`, `"<level_id>:all_stars"`.

### Fyzikálne vrstvy

| Vrstva | Bit (hodnota) | Kto |
|---|---|---|
| world | 1 (1) | `TileMapLayer` terénu, neviditeľné steny levelu |
| player | 2 (2) | `Player` |
| enemies | 3 (4) | potomkovia `Enemy` (`scenes/enemies/*.tscn`) |
| pickups | 4 (8) | mince, predmety, checkpoint, pružina, cieľ |

Pevné bloky, plošiny (`AnimatableBody2D`) a drvič sú vo vrstve world. Ostne, píla, láva, vypínač a tajné miesta sú `Area2D` bez vlastnej vrstvy (maska player).

Mriežka levelu je **64 px**; bežná výška zeme je riadok 9 (y = 576). Oblačné plošiny (`=`) sú one-way.
Fyzika hráča (plný skok ≈ 3 dlaždice, krátky ≈ 2,4, dĺžka skoku ≈ 4 dlaždice) určuje, aké medzery a výšky sú v leveli prekonateľné.

Hráč a nepriatelia sa fyzicky nezrážajú; kontakt rieši `Hitbox` (Area2D) nepriateľa.

## Konvencie kódu

- Statické typovanie všade (`var x: int`, `-> void`, `:=`). Projekt hlási netypované deklarácie ako varovania.
- Taby na odsadenie, `snake_case` pre funkcie a premenné, `PascalCase` pre `class_name`.
- Ladiace parametre (rýchlosť, skok, ceny) sú `@export` alebo v `.tres`, nie natvrdo v logike.
- Zvuky sa púšťajú iba cez `Audio.play(&"názov")`; nový zvuk pridaj do `Audio.SOUNDS`. Hudba cez `Music.play(&"level")`.
- V `-s` skriptoch (generátory v tools/) nepoužívaj `class_name` triedy, ktoré odkazujú na autoloady (napr. `BumpBlock`) – skript sa neskompiluje. Použi číselnú hodnotu s komentárom.
- Po `respawn()` ostáva `is_on_floor()` do ďalšieho pohybu pôvodné – v testoch po premiestnení do vzduchu počkaj aspoň 7 snímok pred stlačením skoku (coyote time).
- Area2D hlási prekrytie s oneskorením jednej snímky – pri kontrole „dopadol zhora“ používaj `Player.get_previous_feet_y()`.
- Godot 4.4 generuje súbory `*.uid` – **commituj ich** spolu so skriptmi.
- Nepoužívaj `TileMap` (zastaraný), ale `TileMapLayer`.
- V skriptoch spúšťaných cez `-s` (napr. `tests/run_tests.gd`) nie sú autoloady dostupné ako identifikátory – použi `root.get_node("Názov")`.

## Pozor na

- Android ukončuje aplikácie na pozadí bez varovania → ukladanie pri `NOTIFICATION_APPLICATION_PAUSED` už rieši `SaveManager`; nerozbiť.
- Dotykové ovládanie musí ostať multitouch (`TouchControls` sleduje každý prst zvlášť). Bežné `Button` uzly pre pohyb nepoužívaj.
- `ProgressionManager.LEVELS` je explicitný zoznam `preload` – nový level treba pridať sem (DirAccess nad `res://` sa v exporte správa inak).
- Neodkazuj na postavy, grafiku ani levely zo série Super Mario (GDD kap. 10.1). V repozitári Speech-Therapy-Game-v2 sú súbory ako `platform_*.webp`, `special_block`, `enemies.png`, ktoré vyzerajú ako grafika z Maria – **nepoužívať**.
- Nové assety zapíš do `CREDITS.md` aj s licenciou.
- Hra je bez reklám, nákupov, sieťových volaní a zberu dát (Google Play Families Policy). Nepridávaj SDK, ktoré by to porušili.
