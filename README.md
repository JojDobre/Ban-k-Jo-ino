# Jožino – Dobrodružstvo

Farebná 2D plošinovka pre Android s budovaním dediny. Jožino skáče cez levely, zbiera mince, zlato a hviezdy a za ne buduje dedinu – baňu, ktorá zarába aj keď hra nebeží, a kováčsku dielňu, ktorá mu pomáha v ďalších leveloch.

- **Engine:** Godot 4.4 (GDScript), renderer Compatibility
- **Platforma:** Android, na šírku
- **Dizajnový dokument:** [docs/GDD.md](docs/GDD.md)

## Stav

Hra má hlavné menu, mapu sveta Zelené údolie s tromi levelmi, dedinu s budovami a obchod. Všetko s grafikou, animáciami, hudbou a zvukmi. Pôvod grafiky je v [CREDITS.md](CREDITS.md).

| Fáza | Stav |
|---|---|
| 1. Pohyb a fyzika | ✅ hotové, čaká na test na telefóne |
| 2. Prvý level | ✅ veľký level s 9 druhmi nepriateľov, blokmi, tajnými miestami, vylepšeniami a hudbou |
| 3. Ekonomika, progres, ukladanie | ✅ menu, mapa sveta, 3 levely, nastavenia |
| 4. Dedina | ✅ budovy, baňa s vozíkom, kováčska dielňa, obchod s oblekmi |
| 5. Dokončenie MVP | ⬜ |

## Spustenie

1. Nainštaluj [Godot 4.4](https://godotengine.org/download) (štandardná verzia, nie .NET).
2. V Godote: **Import** → vyber `project.godot`.
3. **F5** spustí hru.

<details>
<summary><b>Podrobný návod krok za krokom (prvé spustenie)</b></summary>

**1. Stiahni hru z GitHubu**

- Na stránke repozitára klikni na zelené tlačidlo **Code** → **Download ZIP**.
- ZIP rozbaľ (pravý klik → *Extrahovať všetko*) do priečinka, napr. `Dokumenty\Jozino`.
- Skontroluj, že v priečinku priamo vidíš súbor `project.godot` (nie ďalší vnorený priečinok).

**2. Stiahni Godot 4.4.1**

- Otvor [godotengine.org/download/archive/4.4.1-stable](https://godotengine.org/download/archive/4.4.1-stable/).
- Stiahni verziu pre svoj systém – **Standard**, nie *.NET*.
- Godot sa neinštaluje: rozbaľ ZIP a spusti súbor `Godot_v4.4.1-stable_win64.exe`.

**3. Otvor projekt**

- Pri spustení sa ukáže **Project Manager** (zoznam projektov, na začiatku prázdny).
- Klikni **Import** (hore vľavo) → **Browse** → nájdi rozbalený priečinok → vyber `project.godot` → **Open** → **Import** (príp. **Import & Edit**).
- Prvé otvorenie chvíľu trvá (Godot si pripravuje súbory). Prípadné žlté varovania v spodnom paneli *Output* pri prvom importe sú v poriadku.

**4. Spusti hru**

- Stlač **F5** alebo klikni na trojuholník ▶ vpravo hore.
- Ovládanie: šípky/A, D, skok medzerník, pauza Esc.

**Aktualizácia:** keď sa v repozitári objaví nová verzia, stiahni ZIP znova a prepíš ním starý priečinok
(alebo použi [GitHub Desktop](https://desktop.github.com/) → *Clone repository* a potom len *Fetch / Pull*).

</details>

Ovládanie na počítači: šípky alebo A/D, skok medzerník/W/šípka hore, pauza Esc.
Na telefóne sa zobrazia dotykové tlačidlá.

### Testy

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . --fixed-fps 60 res://tests/smoke_level.tscn
godot --headless --path . --fixed-fps 60 res://tests/level_checks.tscn
godot --headless --path . --fixed-fps 60 res://tests/scene_smoke.tscn
```

### Android

V Godote: **Editor → Manage Export Templates** (stiahnuť), potom **Project → Export → Add… → Android**.
Podrobný návod: [Exporting for Android](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html).
Najrýchlejší test na telefóne: zapni na ňom ladenie cez USB a v editore klikni na ikonu Androidu vpravo hore (*Remote Debug / One-click deploy*).
