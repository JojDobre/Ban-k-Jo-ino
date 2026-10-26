# CLAUDE.md

Pokyny pre Claude (a ďalších vývojárov) pri práci na projekte **Jožino – Dobrodružstvo**.

## O projekte

2D plošinovka + idle budovanie dediny pre Android, **Godot 4.4.x, GDScript**.
Úplná špecifikácia je v [`docs/GDD.md`](docs/GDD.md) – pred väčšou zmenou si prečítaj príslušnú kapitolu.
Hra je po slovensky: texty v UI, komentáre a docstringy píš **po slovensky**; identifikátory v kóde **po anglicky**.

## Aktuálny stav

- **Fáza 1 (pohyb)** – hotová kostra: `Player` s coyote time, jump bufferom, premenlivou výškou skoku; multitouch ovládanie; kamera.
- **Fáza 2 (prvý level)** – prototyp `level_01` zo sivých blokov (`Block`), mince, hviezdy, truhlica, checkpoint, cieľ, nepriateľ.
- **Fáza 3 (ekonomika, progres, ukladanie)** – autoloady hotové a pokryté testami; chýba mapa sveta a hlavné menu (boot ide priamo do `level_01`).
- **Fáza 4 (dedina)** – iba dáta (`data/buildings/*.tres`) a výpočet `MineProduction`; scéna dediny neexistuje.

Ďalší krok: otestovať ovládanie na skutočnom telefóne, potom `TileMapLayer` tileset a levely 2–3.

## Príkazy

```bash
# Prvý import (vytvorí .godot/ a cache tried) – nutné pred testami na čistom klone
godot --headless --path . --import

# Automatické testy logiky (ekonomika, progres, ukladanie, baňa). Návratový kód 0 = OK.
godot --headless --path . -s res://tests/run_tests.gd

# Simulované hranie prvého levelu bez grafiky (overí, že scény sa načítajú a fyzika beží)
godot --headless --path . --fixed-fps 60 res://tests/smoke_level.tscn

# Spustenie hry
godot --path .
```

Varovania „Odmietnutá záporná odmena“ a „Poškodené uloženie“ počas testov sú očakávané – testujú chybové vstupy.
Po každej zmene logiky spusti testy; po zmene scén aj smoke test. GitHub Actions spúšťa oboje pri každom pushi.

## Architektúra

```
autoload/      GameState, SaveManager, EconomyManager, ProgressionManager (poradie v project.godot je dôležité)
scripts/data/  PlayerProgress, LevelRun, MineProduction, LevelDefinition, BuildingDefinition
scripts/       player/, enemies/, items/, levels/, ui/
scenes/        zrkadlí scripts/
data/          .tres definície levelov a budov (balans sa ladí tu, nie v kóde)
tests/         headless testy
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
| world | 1 (1) | `Block`, budúci `TileMapLayer` |
| player | 2 (2) | `Player` |
| enemies | 3 (4) | `BasicEnemy` |
| pickups | 4 (8) | mince, hviezdy, truhlice, checkpoint, cieľ |

Hráč a nepriatelia sa fyzicky nezrážajú; kontakt rieši `Hitbox` (Area2D) nepriateľa.

## Konvencie kódu

- Statické typovanie všade (`var x: int`, `-> void`, `:=`). Projekt hlási netypované deklarácie ako varovania.
- Taby na odsadenie, `snake_case` pre funkcie a premenné, `PascalCase` pre `class_name`.
- Ladiace parametre (rýchlosť, skok, ceny) sú `@export` alebo v `.tres`, nie natvrdo v logike.
- Kým nie je grafika, objekty sa kreslia v `_draw()` – pri pridaní spritov tieto funkcie odstráň.
- Godot 4.4 generuje súbory `*.uid` – **commituj ich** spolu so skriptmi.
- Nepoužívaj `TileMap` (zastaraný), ale `TileMapLayer`.
- V skriptoch spúšťaných cez `-s` (napr. `tests/run_tests.gd`) nie sú autoloady dostupné ako identifikátory – použi `root.get_node("Názov")`.

## Pozor na

- Android ukončuje aplikácie na pozadí bez varovania → ukladanie pri `NOTIFICATION_APPLICATION_PAUSED` už rieši `SaveManager`; nerozbiť.
- Dotykové ovládanie musí ostať multitouch (`TouchControls` sleduje každý prst zvlášť). Bežné `Button` uzly pre pohyb nepoužívaj.
- `ProgressionManager.LEVELS` je explicitný zoznam `preload` – nový level treba pridať sem (DirAccess nad `res://` sa v exporte správa inak).
- Neodkazuj na postavy, grafiku ani levely zo série Super Mario (GDD kap. 10.1).
- Hra je bez reklám, nákupov, sieťových volaní a zberu dát (Google Play Families Policy). Nepridávaj SDK, ktoré by to porušili.
