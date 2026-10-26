# JOŽINO – DOBRODRUŽSTVO

**Game Design Document (GDD) a technická špecifikácia MVP**

| | |
|---|---|
| Verzia | 1.3 |
| Stav | Schválený základný koncept, zapracované pripomienky z revízie |
| Engine | Godot 4.4.x |
| Jazyk | GDScript (statické typovanie) |
| Renderer | Compatibility (OpenGL ES 3) – najširšia podpora Android zariadení |
| Platforma | Android telefóny a tablety |
| Orientácia | Na šírku (senzorová) |
| Typ hry | 2D platformer + idle village builder |
| Logopedické funkcie | Nie sú súčasťou MVP, architektúra ich však pripravuje |

### Zmeny oproti verzii 1.0

1. **Dedina priamo ovplyvňuje plošinovku** – Kováčska dielňa pridáva srdce a magnet na mince (kap. 5.2). Herný cyklus je tým uzavretý.
2. **Prepočítaná ekonomika** – zlato v MVP pokrýva všetky stavby, celé MVP sa dá dohrať za 45–60 minút bez grindovania (kap. 4).
3. **Mäkší neúspech** – pri neúspechu sa zachová 50 % mincí; checkpointy sú súčasťou MVP (kap. 2.4).
4. **Ovládanie pre dotyk** – coyote time, jump buffer, benevolentné hitboxy a multitouch sú povinnou súčasťou fázy 1 (kap. 2.1, 2.2).
5. **Tri skryté hviezdy v každom leveli** – dôvod na opakovanie levelu cez prieskum, nie grind (kap. 3.2).
6. **Ladiaci násobič času** pre testovanie bane (kap. 5.3).
7. **Ukladanie sa implementuje spolu s ekonomikou** (fáza 3), nie dodatočne.
8. **Technické spresnenia** – `TileMapLayer`, dátové definície ako `Resource`, atomický zápis uloženia so zálohou, ukladanie pri pozastavení aplikácie, jeden vlastník herného stavu (kap. 7, 8, 11).
9. **Univerzálny zdroj odmien** `grant_reward(source, …)` – príprava na budúci logopedický režim (kap. 7.5, 16).

---

## 1. Vízia hry

Jožino – Dobrodružstvo je farebná 2D plošinovka, v ktorej hráč preskúmava herné úrovne, prekonáva prekážky, poráža nepriateľov a zbiera mince a vzácne zlato.

Získané bohatstvo investuje do vlastnej dediny. Opravuje domy, rozvíja baňu, stavia nové budovy a postupne odomyká ďalšie možnosti. **Niektoré budovy priamo zlepšujú Jožina v leveloch** (viac sŕdc, magnet na mince), takže budovanie a skákanie sa navzájom podporujú. Baňa produkuje mince aj počas neprítomnosti hráča, takže každá návšteva dediny prináša príležitosť na ďalší rozvoj.

Hra kombinuje tri hlavné motivácie:

1. **Akcia** – pohyb, skákanie, nepriatelia a objavovanie.
2. **Progres** – mince, zlato, hviezdy, odomykanie úrovní a vylepšenia.
3. **Budovanie** – viditeľná premena malej osady na rozvinutú dedinu, ktorá sa postupne zaľudňuje.

Základným princípom je, že hráč musí mať vždy jasný krátkodobý cieľ a zároveň dlhodobejší dôvod pokračovať.

### 1.1 Základný herný cyklus

1. Hráč si vyberie level na mape sveta.
2. Prejde level a zbiera mince, zlato, hviezdy a poklady.
3. Za dokončenie získa odmenu.
4. Vráti sa do dediny a vyzdvihne produkciu bane.
5. Investuje menu do budov a vylepšení.
6. Vylepšenia mu **uľahčia ďalšie levely** (srdce navyše, magnet) a baňa produkuje viac mincí.
7. Nový progres mu umožní pokračovať v ďalších leveloch a oblastiach.

### 1.2 Cieľová skupina

- Hráči, ktorí majú radi klasické 2D plošinovky.
- Príležitostní hráči preferujúci krátke herné relácie (3–10 minút).
- Hráči, ktorých motivuje zbieranie predmetov a postupné budovanie.
- Neskôr aj deti, pre ktoré bude hra rozšírená o samostatný vzdelávací režim.

Keďže sa počíta s detským publikom, hra od začiatku **nezbiera osobné údaje, nemá reklamy ani nákupy** a nevyžaduje sieťové pripojenie. To zjednoduší splnenie pravidiel Google Play pre aplikácie určené rodinám (*Families Policy*).

---

## 2. Herný dizajn

### 2.1 Pohyb postavy

Jožino sa pohybuje v horizontálnom 2D prostredí.

Základné schopnosti:

- Pohyb doľava a doprava so zrýchlením a spomalením (nie okamžitá rýchlosť).
- Skok.
- Premenlivá výška skoku – pustenie tlačidla počas stúpania skok skráti.
- Dopad na plošiny a zem.
- Odrazenie od nepriateľa po úspešnom skoku na jeho hlavu (podržaním skoku vyšší odraz).
- Zranenie pri kontakte s nepriateľom z boku.
- Dočasná ochrana po zásahu (blikanie).

**Povinné techniky „férového“ ovládania** (hráč ich nevidí, ale cíti):

| Technika | Popis | Počiatočná hodnota |
|---|---|---|
| Coyote time | Skok je možný ešte chvíľu po zídení z hrany. | 0,10 s |
| Jump buffer | Stlačenie skoku tesne pred dopadom sa zapamätá a vykoná pri dopade. | 0,12 s |
| Skrátenie skoku | Pustenie tlačidla počas stúpania zníži rýchlosť stúpania. | × 0,45 |
| Rýchlejší pád | Gravitácia pri páde je vyššia ako pri stúpaní – skok pôsobí pevnejšie. | × 1,6 |
| Benevolentný zásah zhora | Zásah zhora sa uzná aj pri miernom bočnom kontakte, ak hráč padá. | – |
| Menší hitbox hráča | Kolízny tvar je o niečo menší ako sprite. | ~80 % |

Všetky hodnoty sú exportované premenné, ladia sa na skutočnom zariadení.

Dvojskok, špeciálne útoky a ďalšie schopnosti nie sú súčasťou prvého MVP.

### 2.2 Ovládanie

Rozhranie je navrhnuté pre dotykové displeje.

Ľavá časť obrazovky:

- Tlačidlo doľava.
- Tlačidlo doprava.

Pravá časť obrazovky:

- Veľké tlačidlo skoku.

Herné UI:

- Aktuálny počet mincí.
- Aktuálny počet sŕdc.
- Nájdené hviezdy v leveli.
- Pauza.

Požiadavky:

- **Multitouch je povinný** – hráč musí súčasne držať smer a skákať. Každý prst sa sleduje samostatne.
- Posunutie prsta z tlačidla „doľava“ na „doprava“ bez zdvihnutia zmení smer.
- Tlačidlá majú aktívnu plochu väčšiu ako ich vizuál a nesmú prekrývať dôležité časti herného prostredia.
- Pre testovanie na počítači funguje aj klávesnica (šípky / A, D, medzerník, Esc).

Pre MVP sa používa pevné rozloženie s adaptáciou na pomer strán obrazovky (ukotvenie k rohom), nie úplne odlišné ovládanie pre telefóny a tablety.

### 2.3 Súbojový systém

Hráč poráža základných nepriateľov skokom na hlavu.

Pravidlá:

- Kontakt zhora pri klesajúcom pohybe znamená porazenie nepriateľa.
- Hráč sa po úspešnom zásahu odrazí nahor.
- Kontakt zboku alebo zdola spôsobí hráčovi poškodenie.
- Po zásahu hráč dostane krátku dobu nezraniteľnosti (1,2 s).
- Pád do jamy uberie jedno srdce a vráti hráča na posledný checkpoint.
- Po vyčerpaní všetkých sŕdc sa pokus ukončí neúspechom.

Druhy nepriateľov a nebezpečenstiev (od verzie 1.2):

| Nepriateľ | Správanie | Skok zhora |
|---|---|---|
| Sliz | Chodí tam a späť, poskakuje | porazí ho |
| Ostnatý sliz | Ako sliz, ale má ostne | zraní Jožina |
| Slimák | Pomalý, kolíše sa | porazí ho |
| Myš | Keď zbadá Jožina, poskočí („!“) a rozbehne sa | porazí ho |
| Žaba | Skáče oblúkom smerom k Jožinovi, nevyskočí z plošiny | porazí ho |
| Včela | Lieta tam a späť a vlní sa | porazí ho, vysoký odraz |
| Mucha | Mizne a objavuje sa na druhom mieste; neviditeľná je neškodná | porazí ho, keď je viditeľná |
| Drvič (nahnevaný blok) | Spadne, keď je Jožino pod ním, potom sa vráti | nedá sa; na vrchu sa dá stáť |
| Píla, ostne, láva | Nebezpečenstvo; láva = ako pád do jamy | – |

Nepriateľa stojaceho na bloku porazí aj úder do bloku zospodu.

### 2.4 Životy, checkpointy a neúspech

Hráč začína level s **tromi srdcami** (štyrmi po postavení Kováčskej dielne).

Každý level má aspoň **jeden checkpoint** približne v polovici. Po strate srdca pádom sa hráč vráti na posledný dosiahnutý checkpoint.

Pravidlá odmien:

- Pri **neúspechu** sa do trvalej meny pripíše **50 % mincí** zozbieraných počas pokusu (zaokrúhlené nadol). Hráč tak neodchádza s prázdnymi rukami, no úspech sa stále oplatí viac.
- Zlato, hviezdy a truhlice sa pripisujú **iba pri úspešnom dokončení** levelu.
- Po neúspechu môže hráč okamžite skúsiť level znova.
- Jednorazové odmeny (prvý priechod, truhlica, hviezdy) sa pri opakovaní neudeľujú duplicitne.

Neobmedzené zarábanie opakovaním je limitované tým, že mince v leveli sú konečné a odmena za dokončenie je malá v pomere k cenám vyšších stavieb.

### 2.5 Herné predmety

**Mince** – bežná mena.

- Získavanie: zber v leveloch, odmena za dokončenie, pasívna produkcia bane.
- Použitie: opravy a vylepšenia budov, lacnejšie dekorácie.

**Zlato** – vzácnejšia mena.

- Získavanie: truhlica ukrytá v leveli, prvý úspešný priechod, všetky tri hviezdy v leveli.
- Použitie: vyššie úrovne budov, odomykanie stavebných možností, špeciálne dekorácie.
- Zlato nebude kupovateľné za reálne peniaze.

**Hviezdy** – zberateľský predmet, nie mena.

- V každom leveli sú tri, ukryté mimo hlavnej trasy.
- Zobrazujú sa na mape sveta pri leveli (☆☆☆ → ★★★).
- Všetky tri hviezdy v leveli = jednorazovo 1 zlato.

**Predmety a vylepšenia v leveli** (platia iba počas pokusu):

| Predmet | Účinok |
|---|---|
| Srdce | +1 srdce (pri plnom zdraví 5 mincí) |
| Modrý kryštál | Štít – zachytí jeden zásah |
| Zelený kryštál | Rýchlosť – 8 s rýchlejší beh a vyšší skok |
| Červený kryštál | Magnet – 12 s priťahuje mince |
| Kľúč | Otvorí zamknuté bloky (trezor so zlatom) |

**Bloky:** blok s mincou, blok s viacerými mincami (8 úderov), blok s predmetom (srdce, kryštál), tehla (rozbije sa), skrytý blok (neviditeľný, objaví sa po údere zospodu), zámok, vypínač a modré bloky, ktoré prepína.

**Plošiny:** oblak (priechodný zospodu), pohyblivá plošina (vodorovná, zvislá), padajúci mostík, pružina.

**Tajné miesta:** falošné steny, ktoré vyzerajú ako zem, ale dá sa nimi prejsť (napr. podzemná miestnosť pod prepadávajúcou sa zemou). Počet nájdených sa ukáže vo výsledkoch.

---

## 3. Herné svety a úrovne

### 3.1 Dlhodobá štruktúra

Plánovaná plná verzia obsahuje päť tematických oblastí.

1. **Zelené údolie** – trávnaté plošiny, drevené mosty, jamy, základní nepriatelia a jednoduché skryté poklady.
2. **Staré bane** – podzemné chodby, vozíky, kryštály, padajúce kamene a náročnejšie skoky.
3. **Čarovný les** – množstvo plošín, duté stromy, huby a tajné cesty.
4. **Ľadové vrchy** – šmykľavé povrchy, ľadové plošiny a náročnejšie načasovanie skokov.
5. **Zabudnutá pevnosť** – pasce, silnejší nepriatelia a záverečný súboj oblasti.

Každý svet bude v budúcnosti obsahovať približne desať bežných úrovní a jeden špeciálny level.

**MVP obsahuje iba Zelené údolie a tri bežné levely.**

### 3.2 Štruktúra jedného levelu

Každý level obsahuje:

- Štartovaciu pozíciu.
- Pozemné plošiny a prekážky (`TileMapLayer`).
- Mince (cieľovo 25–35 na level).
- Aspoň jedného nepriateľa, ak to zodpovedá obtiažnosti.
- Aspoň jeden checkpoint.
- Tri skryté hviezdy.
- Jednu truhlicu so zlatom.
- Cieľovú bránu.
- Odmenu za dokončenie.

Voliteľné prvky (po MVP): skrytá miestnosť, bonusová cesta, časová výzva.

Cieľová dĺžka levelu pri prvom priechode: **2–4 minúty**.

### 3.3 Prvé tri levely

**Level 1: Prvý krok** – naučiť pohyb, skákanie a zbieranie.

- Jednoduchá trasa s nízkymi plošinami.
- Mince na hlavnej trase.
- Truhlica a hviezdy ľahko dostupné, len mierne mimo cesty (hráč sa naučí, že prieskum sa oplatí).
- Cieľ na konci.

**Level 2: Prvé prekážky** – predstaviť nepriateľov a nebezpečenstvo.

- Jamy.
- Dvaja až štyria základní nepriatelia.
- Možnosť poraziť nepriateľa skokom (prvý nepriateľ v bezpečnom mieste bez jamy).
- Checkpoint pred prvou jamou.

**Level 3: Tajomstvo údolia** – podporiť prieskum.

- Odbočka mimo hlavnej trasy.
- Skrytá truhlica.
- Náročnejšie skoky.
- Hviezda dostupná iba odrazom od nepriateľa.

---

## 4. Ekonomika hry

### 4.1 Princíp

Hra má dve meny: mince a zlato. Mince sa získavajú často. Zlato je vzácne a používa sa na významnejšie investície.

Ekonomika musí zabezpečiť, že:

- hráč môže pravidelne vylepšovať dedinu bez neprimeraného opakovania tých istých levelov,
- **zlato dostupné v MVP pokryje všetky stavby MVP s malou rezervou**,
- **celé MVP sa dá dokončiť za 45–60 minút aktívneho hrania** plus jeden-dva návraty po offline produkcii.

### 4.2 Odmeny za level

| Zdroj | Odmena | Opakovateľné |
|---|---|---|
| Minca v leveli | 1 minca | áno |
| Dokončenie levelu | 20 mincí | áno |
| Prvý úspešný priechod | 1 zlato | nie |
| Truhlica | 1 zlato | nie |
| Všetky 3 hviezdy v leveli | 1 zlato | nie |
| Neúspešný pokus | 50 % zozbieraných mincí | áno |

**Zlato dostupné v MVP:** 3 levely × (1 + 1 + 1) = **9 zlata**.

**Mince za prvé prejdenie všetkých troch levelov:** približne 3 × (30 + 20) = **~150 mincí**. Opakovaný priechod levelu: ~50 mincí.

### 4.3 Budovy a ceny (MVP)

| Budova / úroveň | Mince | Zlato | Efekt |
|---|---|---|---|
| Jožinov dom – oprava | 0 | 0 | Tutoriál nákupu; odomkne stavebné miesta v dedine |
| Baňa, úroveň 1 | 50 | 0 | 30 mincí / h |
| Baňa, úroveň 2 | 120 | 1 | 60 mincí / h |
| Baňa, úroveň 3 | 250 | 2 | 120 mincí / h |
| Kováčska dielňa, úroveň 1 | 100 | 1 | **+1 srdce v leveloch** (4 namiesto 3) |
| Kováčska dielňa, úroveň 2 | 200 | 2 | **Magnet na mince** (malý dosah) |
| Dekorácie | 30–80 | 0–1 | Vizuálna zmena dediny |

**Súčet MVP:** ~720 mincí a 6 zlata (+ dekorácie). Pri 9 dostupných zlatách ostáva rezerva na dekorácie.

**Očakávaný priebeh:** prvé prejdenie troch levelov (~150 mincí) → oprava domu, baňa úr. 1, kováčska dielňa úr. 1. Baňa za 4–8 hodín vyprodukuje 120–240 mincí → ďalšie úrovne. Opakovanie levelov pre hviezdy dá zvyšok.

Ceny a produkcia sú **počiatočné testovacie parametre**, sú uložené v dátových súboroch (nie v kóde) a budú sa ladiť. Každé vylepšenie musí mať jasný účinok: vyššiu produkciu, novú schopnosť alebo viditeľnú zmenu.

**Obchod** (od verzie 1.3) predáva iba kozmetiku a pomôcky za herné meny:

| Položka | Cena | Účinok |
|---|---|---|
| Oblek Žltá prilba | 150 mincí | vzhľad |
| Oblek Modré nohavice | 200 mincí + 1 zlato | vzhľad |
| Oblek Červená košeľa | 250 mincí + 1 zlato | vzhľad |
| Oblek Starý majster | 400 mincí + 3 zlata | vzhľad |
| Štít na štart (max. 3) | 40 mincí | ďalší level začne so štítom |
| Magnet na štart (max. 3) | 30 mincí | prvých 20 s levelu priťahuje mince |

Predmety sa použijú automaticky na začiatku ďalšieho levelu.

---

## 5. Dedina a idle mechanika

### 5.1 Vizuálna podoba

Dedina používa rovnaký 2D bočný pohľad ako plošinovka – samostatná 2D scéna v rovnakom vizuálnom štýle, horizontálne posúvateľná.

Obsahuje:

- Pozadie s kopcami a oblohou.
- Zem a cestičky.
- Budovy s viacerými vizuálnymi úrovňami.
- Dekoračné prvky.
- Označené miesta, na ktorých sa objavia nové stavby.
- **Obyvateľov** – po postavení budovy sa do dediny nasťahuje postavička (baník, kováč), ktorá sa prechádza. Lacná, ale silná emocionálna odmena.

### 5.2 Budovy MVP

**Jožinov dom** – hlavná budova dediny.

- Začína ako malá chatrč.
- Oprava je zadarmo a slúži ako tutoriál nákupu.
- Po oprave sa odomknú stavebné miesta pre baňu a dielňu.

**Baňa** – hlavný zdroj pasívnej produkcie.

- Na prvej úrovni začne produkovať mince.
- Ďalšie úrovne zvyšujú rýchlosť produkcie.
- Pri bani stojí **vozík, ktorý sa vizuálne plní** podľa nazbieranej produkcie – hráč hneď vidí, že má čo vyzdvihnúť.
- Vyzdvihnutie: dotyk na vozík.

**Kováčska dielňa** – most medzi dedinou a plošinovkou.

- Úroveň 1: Jožino má v leveloch 4 srdcia.
- Úroveň 2: Jožino priťahuje mince v malom okruhu.
- Budúce úrovne: ďalšie schopnosti (dvojskok, silnejší odraz…).

### 5.3 Pasívna produkcia

Baňa produkuje mince aj počas zatvorenia aplikácie.

| Úroveň | Produkcia |
|---|---|
| 1 | 30 mincí / h |
| 2 | 60 mincí / h |
| 3 | 120 mincí / h |

Maximálna akumulácia: **8 hodín** produkcie.

Výpočet:

```
uplynulé_s   = clamp(teraz - posledné_vyzdvihnutie, 0, limit_s)
odmena       = floor(uplynulé_s / 3600 × produkcia_za_hodinu)
```

Pri vyzdvihnutí sa čas posledného vyzdvihnutia posunie iba o čas, ktorý zodpovedá vyplatenej odmene (zvyšok sa neztratí). Ak bol limit dosiahnutý, nastaví sa na „teraz“.

Systém musí:

- Ukladať čas posledného vyzdvihnutia a úroveň bane.
- Obmedziť produkciu na stanovené maximum.
- Zabraňovať dvojitému vyzdvihnutiu tej istej produkcie (mena aj čas sa menia v jednej operácii a hneď sa ukladajú).
- Ošetriť zmenu systémového času: záporný rozdiel = 0 mincí a čas sa nastaví na „teraz“.
- Pri vylepšení bane najprv vyplatiť doterajšiu produkciu podľa starej úrovne.

**Ladiaci násobič času:** v ladiacom zostavení (debug build) možno nastaviť, že 1 hodina hry = 1 minúta reálneho času. V release zostavení je násobič vždy 1.

Pre MVP sa nepoužíva server. Výpočet je lokálny a nie je odolný voči všetkým formám manipulácie zariadenia – to je akceptované.

### 5.4 Interakcia s budovami

Hráč vyberie budovu dotykom. Zobrazí sa panel obsahujúci:

- Názov budovy a aktuálnu úroveň.
- Aktuálny efekt.
- Nasledujúce vylepšenie a jeho efekt.
- Cenu v minciach a zlate.
- Tlačidlo na nákup.

Ak hráč nemá dostatok meny, tlačidlo je neaktívne a panel zobrazí chýbajúcu sumu („Chýba 35 mincí“).

Po úspešnom nákupe sa zmení stav budovy aj jej vzhľad (krátka animácia + zvuk).

---

## 6. Ukladanie postupu

Ukladanie je povinnou súčasťou MVP a **implementuje sa spolu s ekonomikou (fáza 3)**.

Ukladá sa:

- Mince a zlato.
- Odomknuté a dokončené levely.
- Nájdené hviezdy podľa levelu.
- Vyzdvihnuté jednorazové odmeny.
- Úroveň každej budovy.
- Čas posledného vyzdvihnutia produkcie bane.
- Nastavenia (hlasitosť, vibrácie).
- Verzia uložených dát.

Dáta sa ukladajú ako JSON v `user://save.json`.

Kedy sa ukladá:

- Po dokončení levelu aj po neúspechu.
- Po nákupe vylepšenia.
- Po vyzdvihnutí produkcie.
- **Pri pozastavení aplikácie** (`NOTIFICATION_APPLICATION_PAUSED`) – Android často ukončí aplikáciu na pozadí bez ďalšieho upozornenia.
- Pri zatvorení aplikácie.

Načítané hodnoty sa vždy overujú. Poškodený alebo neúplný súbor nespôsobí pád – použije sa záloha alebo bezpečné predvolené hodnoty.

---

## 7. Technický dátový model

### 7.1 PlayerProgress

Globálny trvalý stav hráča. **Existuje práve jedna inštancia, vlastní ju `GameState`.** Ostatné systémy ho menia iba cez svoje verejné funkcie.

| Pole | Typ | Popis |
|---|---|---|
| save_version | int | Verzia uložených dát |
| coins | int | Aktuálne mince (≥ 0) |
| gold | int | Aktuálne zlato (≥ 0) |
| unlocked_levels | Array[String] | Odomknuté levely |
| completed_levels | Array[String] | Dokončené levely |
| stars | Dictionary | `level_id → Array[String]` nájdené hviezdy |
| claimed_rewards | Array[String] | Vyzdvihnuté jednorazové odmeny (`"level_01:first_clear"`) |
| building_levels | Dictionary | `building_id → int` |
| last_mine_claim | int | Unixový čas posledného vyzdvihnutia |
| settings | Dictionary | Nastavenia |

### 7.2 LevelDefinition (`Resource`)

| Pole | Typ | Popis |
|---|---|---|
| id | String | Jedinečný identifikátor |
| world_id | String | Identifikátor sveta |
| display_name | String | Názov levelu |
| scene_path | String | Cesta k scéne |
| order | int | Poradie |
| completion_coins | int | Odmena za dokončenie |
| first_clear_gold | int | Jednorazové zlato za prvý priechod |
| unlock_requirements | Array[String] | Levely, ktoré treba dokončiť |

### 7.3 BuildingDefinition (`Resource`)

| Pole | Typ | Popis |
|---|---|---|
| id | String | Identifikátor budovy |
| display_name | String | Názov |
| max_level | int | Maximálna úroveň |
| coin_costs | Array[int] | Cena v minciach pre každú úroveň |
| gold_costs | Array[int] | Cena v zlate pre každú úroveň |
| production_per_hour | Array[int] | Produkcia podľa úrovne (iba baňa) |
| effect_descriptions | Array[String] | Popis efektu každej úrovne |
| visual_variants | Array[Texture2D] | Vizuál každej úrovne |

Definície sú **vlastné `Resource` triedy uložené ako `.tres`** v `data/`. Upravujú sa priamo v inšpektore Godotu, sú typované a netreba ich parsovať.

### 7.4 LevelRun

Dočasný stav aktuálneho pokusu (neukladá sa).

| Pole | Typ | Popis |
|---|---|---|
| level_id | String | Aktuálny level |
| coins | int | Mince získané počas pokusu |
| gold | int | Zlato z truhlíc počas pokusu |
| stars | Array[String] | Hviezdy nájdené počas pokusu |
| collected_items | Array[String] | Zozbierané jedinečné predmety |
| hearts | int | Zostávajúce srdcia |
| max_hearts | int | Maximum sŕdc (podľa dielne) |
| checkpoint | Vector2 | Pozícia posledného checkpointu |

Odmeny pokusu sa do `PlayerProgress` pripíšu až pri ukončení pokusu podľa pravidiel kap. 2.4.

### 7.5 Pravidlá ekonomiky

Ekonomické operácie sú centralizované v `EconomyManager`:

- `grant_reward(source: String, coins: int, gold: int)` – **jediný vstupný bod pre všetky príjmy**. `source` identifikuje pôvod (`"level"`, `"mine"`, `"chest"`, v budúcnosti `"speech_exercise"`).
- `can_afford(coins_cost, gold_cost) -> bool`
- `spend(coins_cost, gold_cost) -> bool` – atomický nákup.
- `claim_one_time(reward_id, coins, gold) -> bool` – jednorazová odmena, druhé volanie nič nepripíše.

Každá operácia validuje vstupy (žiadne záporné sumy). Mena nikdy neklesne pod nulu a nákup sa vykoná atomicky – nikdy sa neodpočíta iba jedna z dvoch mien.

Zmeny sa oznamujú signálom `currency_changed(coins, gold)`; UI sa naň iba pripája a stav si nikdy nedrží samo.

---

## 8. Štruktúra projektu v Godote

```
res://
├── project.godot
├── autoload/            # globálne systémy (singletony)
│   ├── game_state.gd
│   ├── save_manager.gd
│   ├── economy_manager.gd
│   └── progression_manager.gd
├── scripts/
│   ├── data/            # PlayerProgress, LevelRun, definície (Resource)
│   ├── player/
│   ├── enemies/
│   ├── items/
│   ├── levels/
│   ├── village/
│   └── ui/
├── scenes/
│   ├── boot/
│   ├── menus/
│   ├── world_map/
│   ├── levels/
│   ├── player/
│   ├── enemies/
│   ├── items/
│   ├── village/
│   └── ui/
├── data/
│   ├── levels/          # LevelDefinition .tres
│   └── buildings/       # BuildingDefinition .tres
├── assets/
│   ├── sprites/  tilesets/  backgrounds/  audio/  ui/
└── tests/               # automatické testy logiky (headless)
```

Štruktúra je východisková. Súbory sa pridávajú podľa reálnej implementácie, nie iba preto, že existujú v dokumente.

### 8.1 Autoload systémy

| Systém | Zodpovednosť |
|---|---|
| `GameState` | Vlastní `PlayerProgress` a aktuálny `LevelRun`; prechody medzi scénami. |
| `SaveManager` | Ukladanie, načítanie, verzie a migrácie, záloha, ukladanie pri pozastavení. |
| `EconomyManager` | Mince a zlato, odmeny, nákupy, signál `currency_changed`. |
| `ProgressionManager` | Odomykanie a dokončenie levelov, hviezdy, vyhodnotenie pokusu. |

Systémy majú jasne rozdelené zodpovednosti. Jeden systém nemá zároveň riadiť fyziku postavy, menu, ekonomiku aj ukladanie. Herné objekty (mince, nepriatelia) nevolajú `SaveManager` priamo.

---

## 9. Scény a ich zodpovednosti

**Boot** – inicializuje globálne systémy, načíta uložené dáta (pri prvom spustení vytvorí predvolený progres), otvorí hlavné menu.

**Main Menu** – Pokračovať, Mapa sveta, Dedina, Nastavenia.

**World Map** – zobrazuje levely, rozlišuje zamknuté / odomknuté / dokončené, ukazuje nájdené hviezdy, spúšťa level.

**Level Scene** – načíta prostredie a hráča, inicializuje `LevelRun`, spracúva checkpointy, dokončenie aj neúspech a odovzdá výsledok `ProgressionManager`.

**Village Scene** – zobrazuje budovy, stav meny a vozík bane; umožňuje interakciu s budovami a vyzdvihnutie produkcie.

---

## 10. Grafický smer

### 10.1 Vizuálny štýl

Farebný moderný cartoon.

- Čitateľné siluety postáv.
- Jasné odlíšenie bezpečných plošín od nebezpečenstva.
- Výrazné animácie skoku, dopadu a zásahu.
- Farebné mince a výrazný efekt ich získania.
- Prostredia s vrstvami pozadia (parallax).
- Budovy rozpoznateľné aj na menšom displeji.

Hra nekopíruje konkrétne postavy, grafiku, levely ani chránené prvky série Super Mario. Referenciou je všeobecný žáner klasických 2D plošinoviek.

### 10.2 Grafické assety MVP

- Jožino: idle, beh, skok, pád, dopad a zásah.
- Jeden typ nepriateľa.
- Trávnatý tileset.
- Pozadie údolia (2–3 parallax vrstvy).
- Mince, hviezda, truhlica, checkpoint, cieľová brána.
- Tri budovy dediny v 2–3 úrovniach, vozík bane, 2 obyvatelia.
- Základné UI ikony.
- Efekty zbierania mincí a porazenia nepriateľa.

**Aktuálne použité:** Jožino je kreslený baník (zelená varianta z projektu Speech-Therapy-Game-v2), prostredie, predmety a nepriatelia sú z balíka Kenney *New Platformer Pack* (CC0) – štýlovo ladia (hrubé obrysy, sýte farby). Úplný zoznam je v `CREDITS.md`. „Truhlicu“ v leveli zatiaľ predstavuje zlatý drahokam.

---

## 11. Ukladanie a odolnosť

Hra musí zvládnuť:

- Náhle ukončenie aplikácie.
- Návrat z pozadia.
- Reštart zariadenia.
- Chýbajúci alebo poškodený súbor uloženia.
- Neúplne zapísaný súbor.
- Zmenu systémového času.

Technické riešenie:

1. **Atomický zápis:** dáta sa zapíšu do `save.json.tmp`, potom sa existujúci `save.json` premenuje na `save.json.bak` a dočasný súbor na `save.json`.
2. **Načítanie:** `save.json` → pri chybe `save.json.bak` → pri chybe predvolený progres. Hra nikdy nespadne kvôli uloženiu.
3. **Validácia:** každé pole sa číta s typovou kontrolou a predvolenou hodnotou; mena sa orezáva na ≥ 0.
4. **Verzie:** pri zmene štruktúry dát sa zvýši `save_version` a `SaveManager` obsahuje migračný krok pre každú staršiu verziu.

Pri offline produkcii sa tá istá odmena nesmie pripísať dvakrát. Mena a čas posledného vyzdvihnutia sa menia v jednej operácii a hneď sa ukladajú.

---

## 12. Implementačný plán MVP

### Fáza 1: Pohyb a herná fyzika

- Vytvoriť projekt Godot 4.4, renderer Compatibility.
- Nastaviť Android orientáciu na šírku.
- Vytvoriť scénu hráča.
- Implementovať pohyb so zrýchlením, skok, premenlivú výšku skoku.
- **Coyote time a jump buffer.**
- Pridať kolízie, gravitáciu a kameru.
- Vytvoriť dotykové ovládanie **s multitouchom**.
- Otestovať pohyb na skutočnom Android zariadení.

Výstup: ovládateľná postava v testovacom prostredí, ktorá sa na telefóne „dobre cíti“.

### Fáza 2: Prvý level

- Vytvoriť tileset a terén (`TileMapLayer`).
- Pridať jamy, plošiny, mince.
- Implementovať checkpoint a cieľ levelu.
- Vytvoriť základného nepriateľa, skákanie na hlavu a stratu srdca.
- Pridať hviezdy a truhlicu.
- Pridať pauzu a reštart.

Výstup: jeden kompletne hrateľný level.

### Fáza 3: Ekonomika, progres a ukladanie

- Implementovať `EconomyManager`, `ProgressionManager`, `SaveManager`.
- Odmeny za dokončenie a neúspech, jednorazové bonusy.
- Mapa levelov a odomykanie.
- Ukladanie a načítanie vrátane zálohy a validácie.
- Automatické testy ekonomiky a ukladania.

Výstup: tri levely s funkčným systémom odmien, progresu a trvalým ukladaním.

### Fáza 4: Dedina

- Bočný pohľad na dedinu.
- Dom, baňa a kováčska dielňa s vizuálnymi úrovňami.
- Panel vylepšenia budovy s kontrolou cien.
- Pasívna produkcia, offline limit, vozík, ladiaci násobič času.
- **Prepojenie dielne s levelmi (srdce navyše, magnet).**

Výstup: dedina, v ktorej možno investovať a ktorá zlepšuje Jožina.

### Fáza 5: Dokončenie MVP

- Animácie, zvuky, obyvatelia dediny.
- Doladenie dotykového ovládania.
- Testovanie na telefónoch a tabletoch, rôzne pomery strán.
- Oprava chýb, Android build na interné testovanie.
- **Test s 3–5 ľuďmi z cieľovej skupiny** – pozorovať, kde sa zasekávajú.

Výstup: hrateľné MVP pripravené na testovanie.

---

## 13. Testovacie scenáre

Logika ekonomiky, produkcie a ukladania má **automatické testy** (`tests/`), ktoré sa spúšťajú bez grafiky. Ostatné scenáre sa testujú ručne.

**Pohyb a levely**

- Hráč sa môže pohybovať oboma smermi.
- Skok funguje na zemi aj tesne po zídení z hrany (coyote time).
- Skok stlačený tesne pred dopadom sa vykoná (jump buffer).
- Súčasné držanie smeru a skoku funguje na dotykovom displeji.
- Hráč porazí nepriateľa skokom na hlavu, kontakt zboku spôsobí zranenie.
- Pád do jamy vráti hráča na checkpoint a uberie srdce.
- Po vyčerpaní sŕdc sa pokus ukončí.
- Cieľ spustí obrazovku výsledkov.

**Ekonomika** (automaticky)

- Neúspešný pokus pripíše 50 % mincí, žiadne zlato ani hviezdy.
- Jednorazová odmena sa pripíše iba raz.
- Nákup bez dostatku meny sa nevykoná a nezmení stav.
- Nákup odpočíta správne množstvo oboch mien.
- Mena nikdy neklesne pod nulu; záporné vstupy sa odmietnu.

**Dedina** (automaticky + ručne)

- Baňa produkuje mince podľa úrovne.
- Produkcia neprekročí offline limit.
- Vyzdvihnutá produkcia sa nepripíše druhýkrát.
- Záporný časový rozdiel nepridá mince.
- Vylepšenie dielne zvýši počet sŕdc v leveli.
- Po reštarte zostanú vylepšenia zachované.

**Ukladanie** (automaticky + ručne)

- Progres prežije ukončenie aplikácie aj prepnutie do pozadia.
- Poškodený súbor nespôsobí pád; použije sa záloha.
- Nové uloženie obsahuje správnu verziu dát.

---

## 14. Kritériá dokončenia MVP

1. Hráč dokáže dokončiť všetky tri levely.
2. Ovládanie je použiteľné na telefóne aj tablete, vrátane súčasného pohybu a skoku.
3. Mince a zlato sa získavajú a míňajú správne; automatické testy prechádzajú.
4. Levely sa odomykajú podľa progresu, hviezdy sa zobrazujú na mape.
5. Dedina obsahuje funkčné vylepšovanie budov.
6. Kováčska dielňa viditeľne ovplyvňuje levely.
7. Baňa produkuje mince počas neprítomnosti hráča.
8. Progres sa bezpečne ukladá a načítava.
9. Celé MVP sa dá dohrať za 45–60 minút bez nudného opakovania.
10. Neexistujú známe kritické chyby blokujúce hranie.
11. Hra má základné zvuky, animácie a čitateľné UI.
12. Android build možno nainštalovať a otestovať mimo editora Godot.

---

## 15. Funkcie mimo rozsahu MVP

- Logopedické cvičenia a rozpoznávanie reči.
- Ďalšie štyri svety, boss súboje.
- Obchod a ďalšie budovy.
- Multiplayer, online účty, cloudové ukladanie.
- Reklamy, nákupy v aplikácii, prémiová mena.
- Denné úlohy, notifikácie.
- Výroba predmetov, rozsiahly inventár.

Ich pridanie bude závisieť od výsledkov testovania MVP.

---

## 16. Budúci rozvoj

Po dokončení MVP sa ďalší vývoj bude riadiť výsledkami testovania.

1. Nové svety a levely.
2. Ďalšie budovy, obyvatelia a suroviny.
3. Ďalšie úrovne kováčskej dielne (dvojskok, silnejší odraz).
4. Tajné miestnosti a bonusové úrovne.
5. Rozšírená idle ekonomika, lokálna notifikácia „vozík je plný“.
6. Logopedický režim.
7. Rodičovská sekcia a nastavenia vzdelávacích úloh.
8. Android TV alebo ďalšie platformy, ak to bude mať zmysel.

**Logopedická časť** sa pridá ako samostatný systém. S hrou bude prepojená iba cez `EconomyManager.grant_reward("speech_exercise", …)` – splnené cvičenie je ďalší zdroj mincí a zlata. Nebude priamo previazaná s fyzikou, levelmi ani ukladaním herného sveta takým spôsobom, ktorý by vyžadoval ich prepis.

---

## 17. Záverečné rozhodnutia

Základný herný koncept je uzavretý:

- Farebná 2D plošinovka s klasickým skákaním a porážaním nepriateľov.
- Mince, zlato a hviezdy.
- Dedina v bočnom pohľade, ktorá zlepšuje Jožina v leveloch.
- Pasívna produkcia bane.
- Lokálne ukladanie postupu.
- Godot 4.4 a GDScript, Android ako prvá platforma.
- Tri levely a základná dedina ako MVP.

**Prvý technický míľnik:** funkčná postava s pohybom, skokom (vrátane coyote time a jump buffera), kamerou a multitouch dotykovým ovládaním v jednoduchej testovacej úrovni.

Až po overení tohto základu na skutočnom telefóne sa začne implementovať ekonomika, ukladanie a dedina.

### Poznámka k názvu

Meno „Jožino“ si mnohí spoja s piesňou *Jožin z bažin*. Môže to pomôcť zapamätateľnosti, treba však sledovať, aby vizuál ani názov nepôsobili ako odkaz na ňu.
