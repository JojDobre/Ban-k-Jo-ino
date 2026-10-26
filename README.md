# Jožino – Dobrodružstvo

Farebná 2D plošinovka pre Android s budovaním dediny. Jožino skáče cez levely, zbiera mince, zlato a hviezdy a za ne buduje dedinu – baňu, ktorá zarába aj keď hra nebeží, a kováčsku dielňu, ktorá mu pomáha v ďalších leveloch.

- **Engine:** Godot 4.4 (GDScript), renderer Compatibility
- **Platforma:** Android, na šírku
- **Dizajnový dokument:** [docs/GDD.md](docs/GDD.md)

## Stav

Prvý technický míľnik – ovládateľná postava s dotykovým ovládaním v prototypovom leveli. Grafika je zatiaľ kreslená kódom (jednoduché tvary).

| Fáza | Stav |
|---|---|
| 1. Pohyb a fyzika | ✅ kostra, čaká na test na telefóne |
| 2. Prvý level | 🟡 prototyp zo sivých blokov |
| 3. Ekonomika, progres, ukladanie | 🟡 logika + testy, chýba mapa a menu |
| 4. Dedina | ⬜ iba dáta a výpočet bane |
| 5. Dokončenie MVP | ⬜ |

## Spustenie

1. Nainštaluj [Godot 4.4](https://godotengine.org/download) (štandardná verzia, nie .NET).
2. V Godote: **Import** → vyber `project.godot`.
3. **F5** spustí hru.

Ovládanie na počítači: šípky alebo A/D, skok medzerník/W/šípka hore, pauza Esc.
Na telefóne sa zobrazia dotykové tlačidlá.

### Testy

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . --fixed-fps 60 res://tests/smoke_level.tscn
```

### Android

V Godote: **Editor → Manage Export Templates** (stiahnuť), potom **Project → Export → Add… → Android**.
Podrobný návod: [Exporting for Android](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html).
Najrýchlejší test na telefóne: zapni na ňom ladenie cez USB a v editore klikni na ikonu Androidu vpravo hore (*Remote Debug / One-click deploy*).
