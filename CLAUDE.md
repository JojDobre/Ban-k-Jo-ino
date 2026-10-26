# CLAUDE.md

Pokyny pre Claude (a ďalších vývojárov) pri práci na projekte **Jožino – Dobrodružstvo**.

## O projekte

2D plošinovka + idle budovanie dediny pre Android, **Godot 4.4.x, GDScript**.
Úplná špecifikácia je v [`docs/GDD.md`](docs/GDD.md) – pred väčšou zmenou si prečítaj príslušnú kapitolu.
Hra je po slovensky: texty v UI, komentáre a docstringy píš **po slovensky**; identifikátory v kóde **po anglicky**.

## Aktuálny stav

- **Fáza 1 (pohyb)** – hotové: `Player` s coyote time, jump bufferom, premenlivou výškou skoku, animáciami (baník), squash/stretch, prachom, kamerou s pohľadom dopredu; multitouch ovládanie.
- **Fáza 2 (prvý level)** – `level_01` hotový s grafikou: `TileMapLayer` (Kenney tráva + oblačné plošiny), parallax pozadie, mince, 3 hviezdy, zlatý poklad, checkpoint, pružina, sliz a slimák, cieľové dvere, zvuky, HUD s ikonami.
- **Fáza 3 (ekonomika, progres, ukladanie)** – autoloady hotové a pokryté testami; chýba mapa sveta a hlavné menu (boot ide priamo do `level_01`).
- **Fáza 4 (dedina)** – iba dáta (`data/buildings/*.tres`) a výpočet `MineProduction`; scéna dediny neexistuje.

Ďalší krok: otestovať level na skutočnom telefóne, potom hlavné menu a mapa sveta, dedina, levely 2–3.

## Príkazy

```bash
# Prvý import (vytvorí .godot/ a cache tried) – nutné pred testami na čistom klone
godot --headless --path . --import

# Automatické testy logiky (ekonomika, progres, ukladanie, baňa). Návratový kód 0 = OK.
godot --headless --path . -s res://tests/run_tests.gd

# Simulované hranie prvého levelu bez grafiky (overí, že scény sa načítajú a fyzika beží)
godot --headless --path . --fixed-fps 60 res://tests/smoke_level.tscn

# Dosiahnuteľnosť tajných miest level_01 (pružina, hviezdy, tajná jama) – výstup „VÝSLEDOK: OK“
godot --headless --path . --fixed-fps 60 res://tests/level_checks.tscn

# Screenshoty (potrebuje grafiku; v kontajneri cez xvfb). Argumenty: priečinok, body x,y, voliteľne „win“.
xvfb-run -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  res://tests/screenshots.tscn -- /cesta/k/priecinku 200,540 3700,150 win

# Spustenie hry
godot --path .
```

Varovania „Odmietnutá záporná odmena“ a „Poškodené uloženie“ počas testov sú očakávané – testujú chybové vstupy.
Hlásenia „ObjectDB instances leaked“ / „resources still in use at exit“ pri headless scénach sú tiež očakávané (tichý zvukový ovládač neuvoľní prehrávania).
Po každej zmene logiky spusti testy; po zmene scén smoke test a level_checks. Pri vizuálnych zmenách sprav screenshoty a pozri si ich. GitHub Actions spúšťa testy, smoke test aj level_checks pri každom pushi.

### Generátory (tools/)

Grafika a niektoré resources sa generujú skriptmi – výsledky sú v repozitári:

| Skript | Vytvára | Kedy spustiť |
|---|---|---|
| `tools/prepare_assets.py <kenney> <speech-therapy-game-v2>` | `assets/` (orezaný baník, Kenney dlaždice, parallax vrstvy, zvuky) | pri zmene zdrojových obrázkov |
| `godot --headless --path . -s res://tools/build_resources.gd` | `assets/tilesets/terrain.tres`, `*_frames.tres` | po zmene obrázkov postáv/terénu |
| `godot --headless --path . -s res://tools/build_level_01.gd` | `scenes/levels/level_01.tscn` z textovej mapy | po zmene mapy v skripte |

**Level sa upravuje v textovej mape v `tools/build_level_01.gd`** (legenda je v hlavičke) a potom sa vygeneruje. Ak ho niekto upraví ručne v editore, generátor už nespúšťaj, inak zmeny prepíše. Po zmene mapy spusti `level_checks` a uprav ho, ak sa presunuli hviezdy/pružina.

## Architektúra

```
autoload/      GameState, SaveManager, EconomyManager, ProgressionManager, Audio (poradie v project.godot je dôležité)
scripts/data/  PlayerProgress, LevelRun, MineProduction, LevelDefinition, BuildingDefinition
scripts/       player/, enemies/, items/, levels/, ui/
scenes/        zrkadlí scripts/
data/          .tres definície levelov a budov (balans sa ladí tu, nie v kóde)
tests/         headless testy, smoke test, level_checks, screenshoty
tools/         generátory assetov a levelu
assets/        grafika a zvuky (pôvod v CREDITS.md)
```

Pravidlá, ktoré treba dodržať:

1. **Jeden vlastník stavu.** `GameState.progress` je jediná inštancia `PlayerProgress`. Nikdy si ju nekopíruj do UI ani do iného systému.
2. **Mena iba cez `EconomyManager`.** Všetky príjmy idú cez `grant_reward(source, coins, gold)`, jednorazové cez `claim_one_time(id, …)`, nákupy cez `spend()` (atomický). Mena nikdy < 0.
3. **Herné objekty nevolajú `SaveManager`.** Mince/hviezdy/truhlice zapisujú iba do `GameState.current_run` (`LevelRun`). Do trvalého progresu ho prenesie `ProgressionManager.finish_run()`.
4. **Ukladanie:** systémy volajú `SaveManager.request_save()` (zlúči zmeny v jednej snímke do jedného zápisu). Zápis je atomický (`.tmp` → premenovanie, `.bak` záloha). Pri zmene `PlayerProgress` zvýš `SAVE_VERSION`, pridaj migráciu do `SaveManager._migrate()` a validáciu do `PlayerProgress.from_dict()`.
5. **UI iba zobrazuje.** Pripája sa na signály (`LevelRun.changed`, `EconomyManager.currency_changed`), nič nepočíta.
6. **Hráč nevie o srdciach.** `Player` iba vyšle `damaged`; srdcia, checkpointy a koniec rieši `LevelController`.
7. **Logopédia (budúcnosť)** sa pripojí iba cez `EconomyManager.grant_reward("speech_exercise", …)`.

### Pravidlá odmien (GDD kap. 2.4, 4.2)

- Neúspech: 50 % mincí z pokusu, žiadne zlato ani hviezdy.
- Úspech: mince z pokusu + `completion_coins`; jednorazovo zlato za prvý priechod, truhlicu a všetky 3 hviezdy.
- ID jednorazových odmien: `"<level_id>:first_clear"`, `"<level_id>:chest:<chest_id>"`, `"<level_id>:all_stars"`.

### Fyzikálne vrstvy

| Vrstva | Bit (hodnota) | Kto |
|---|---|---|
| world | 1 (1) | `TileMapLayer` terénu, neviditeľné steny levelu |
| player | 2 (2) | `Player` |
| enemies | 3 (4) | `BasicEnemy` (scény `slime.tscn`, `snail.tscn`) |
| pickups | 4 (8) | mince, hviezdy, poklad, checkpoint, pružina, cieľ |

Mriežka levelu je **64 px**; bežná výška zeme je riadok 9 (y = 576). Oblačné plošiny (`=`) sú one-way.
Fyzika hráča (plný skok ≈ 3 dlaždice, krátky ≈ 2,4, dĺžka skoku ≈ 4 dlaždice) určuje, aké medzery a výšky sú v leveli prekonateľné.

Hráč a nepriatelia sa fyzicky nezrážajú; kontakt rieši `Hitbox` (Area2D) nepriateľa.

## Konvencie kódu

- Statické typovanie všade (`var x: int`, `-> void`, `:=`). Projekt hlási netypované deklarácie ako varovania.
- Taby na odsadenie, `snake_case` pre funkcie a premenné, `PascalCase` pre `class_name`.
- Ladiace parametre (rýchlosť, skok, ceny) sú `@export` alebo v `.tres`, nie natvrdo v logike.
- Zvuky sa púšťajú iba cez `Audio.play(&"názov")`; nový zvuk pridaj do `Audio.SOUNDS`.
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
