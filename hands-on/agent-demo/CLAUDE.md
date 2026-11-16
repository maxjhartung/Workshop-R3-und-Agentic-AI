# GROMACS-Jobs mit r3 vorbereiten

Du bereitest in diesem Projekt Jobs für ein r3-Repository vor und committest sie: **Simulationen**
mit GROMACS und **Auswertungen** dieser Simulationen. **Du startest keinen Job.** Am Ende steht eine
Liste der committeten Job-IDs, mit der ich jeden Job selbst prüfe und starte.

## Die wichtigsten Regeln

Du darfst **nicht**:

- `mdrun` ausführen, in keiner Form (`gmx mdrun`, `gmx_mpi mdrun`, `mdrun`, …),
- ein `run.sh` ausführen (`bash run.sh`, `./run.sh`, `source`, `sh`, …): einen Job starte ich selbst,
- Jobs abschicken oder im Hintergrund starten (`sbatch`, `srun`, `xr3-slurm`, `nohup`, `&`),
- `r3 checkout`, `r3 remove`, `r3 edit` oder `r3 rebuild-index` benutzen,
- im r3-Repository (`$R3_REPOSITORY`) Dateien anlegen, ändern oder löschen,
- die Ordner `template/` und `template-analysis/` ändern.

Du **darfst** andere GROMACS-Werkzeuge (`gmx energy`, `gmx rms`, `gmx gyrate`, `gmx trjconv`,
`gmx pdb2gmx`, `gmx grompp`, …) und Python benutzen, um Befehle und Skripte **auszuprobieren**, aber:

- alles, was dabei entsteht, landet in `scratch/`, nie in `jobs/` und nie im Repository;
- Eingabedateien aus dem Repository nur lesen (z. B. `$R3_REPOSITORY/jobs/<ID>/output/md.edr`);
- interaktive Werkzeuge bekommen ihre Auswahl immer per `echo … |`, sonst warten sie auf eine
  Eingabe und hängen.

Wenn ein Schritt nur durch etwas Verbotenes ginge: anhalten und mich fragen.

## Projektaufbau

```
./
├── CLAUDE.md
├── template/               Vorlage Simulation (nie ändern)
│   ├── run.sh              GROMACS-Ablauf, Einstellungsblock oben
│   ├── metadata.yaml
│   └── mdp/                ions.mdp, minim.mdp, nvt.mdp, npt.mdp, md.mdp
├── template-analysis/      Vorlage Auswertung (nie ändern)
│   ├── run.sh              gmx-Befehl(e) + Plot, Einstellungsblock oben
│   ├── plot.py             plottet eine GROMACS-xvg
│   ├── r3.yaml             Abhängigkeit auf die Simulation
│   └── metadata.yaml
├── jobs/                   hier legst du die Job-Ordner an
├── scratch/                zum Ausprobieren (wird nie committet)
└── committed_jobs.txt      Liste der committeten Jobs (anhängen, nie überschreiben)
```

## Ablauf für jeden Auftrag

1. **Plan zeigen und auf mein Okay warten.** Eine Tabelle mit einer Zeile pro Job: Ordnername,
   Job-Typ, r3-Pfad, Tags, alle Einstellungen (auch die aus dem Template übernommenen), geplante
   Änderungen an Skripten und mdp-Dateien, bei Auswertungen die Simulation(en), von denen sie
   abhängen. Dazu offene Fragen. Nur wenn ich ausdrücklich sage „ohne Rückfrage“, gehst du direkt weiter.
2. **Job-Ordner anlegen:** `cp -r template jobs/<name>` bzw. `cp -r template-analysis jobs/<name>`.
   Namen kurz und sprechend, z. B. `jobs/1aki-300K-rep1` oder `jobs/temp-1aki-300K-rep1`.
   Existiert ein Ordner schon: nicht überschreiben, sondern nachfragen.
3. **Anpassen** nach den Regeln für den jeweiligen Job-Typ (unten).
4. **Prüfen** (unten).
5. **Committen:** `r3 commit jobs/<name>`. Der Befehl gibt die Job-ID (eine UUID) aus; notiere sie
   sofort. Kontrolle: `r3 find -p <r3-pfad> -l`.
6. **Liste ergänzen** in `committed_jobs.txt` (Format unten).
7. **Abschluss melden:** wie viele Jobs, wo die Liste liegt, welche Defaults übernommen und welche
   Werte geändert wurden, in welcher Reihenfolge ich die Jobs starten muss, und ausdrücklich, dass
   nichts gestartet wurde.

Wenn ein Commit fehlschlägt: anhalten, Fehlermeldung zeigen, nicht blind wiederholen. Wenn du nach
einem Commit einen Fehler bemerkst: nichts löschen und nicht neu committen, sondern mir sagen, welcher
Job betroffen ist. Ich entscheide.

## `metadata.yaml` (beide Job-Typen)

```yaml
path: <r3-Pfad>
tags: [...]
description: <ein Satz, was der Job tut, mit den wichtigsten Einstellungen>
```

Den r3-Pfad gebe ich vor. Bei mehreren Jobs mit einem Pfad schlägst du im Plan Unterpfade vor,
z. B. `<pfad>/300K/rep1`; nimm die Variante, die ich bestätige.

- Simulation: Tags `[<pdb-id klein>, <kraftfeld>, <wasser>, T<temperatur>, rep<n>]`
- Auswertung: Tags `[<was ausgewertet wird, z. B. temperature>, T<temperatur>, rep<n>]`

## Job-Typ 1: Simulation (`template/`)

### `run.sh`

Ändere **nur den Block zwischen den `EINSTELLUNGEN`-Linien**. Was nur mit Änderungen außerhalb des
Blocks ginge: nachfragen.

- **Kraftfeld:** muss als `<name>.ff` existieren. Nachsehen per `ls "$GMXDATA/top"` oder
  `ls "$(dirname "$(which gmx)")/../share/gromacs/top"`. Du darfst die Kombination aus Kraftfeld,
  Wassermodell und Struktur mit `gmx pdb2gmx` in `scratch/` ausprobieren.
- **Wasser und `SOLVENT`:** 3-Punkt-Modelle (spc, spce, tip3p) nutzen `spc216.gro`, `tip4p` nutzt
  `tip4p.gro`, `tip5p` nutzt `tip5p.gro`. Das Wassermodell muss zum Kraftfeld passen.
- **Ionen:** `PNAME`/`NNAME` müssen zu den Ionennamen des Kraftfelds passen: meist `NA`/`CL`,
  CHARMM36-Portierungen `SOD`/`CLA`.
- **Box:** `BOX_DIST` unter 1.0 nm nur nach Rückfrage.
- **Struktur:** Lade die PDB-Datei bei Bedarf nach `scratch/` und such nach `HETATM`-Einträgen,
  Lücken oder ungewöhnlichen Resten. Liganden oder Nichtstandard-Reste lassen `pdb2gmx` meist
  scheitern: im Plan als Warnung nennen.

### mdp-Dateien (nur ändern, was der Auftrag verlangt)

- **Temperatur:** `ref_t` in `nvt.mdp`, `npt.mdp` und `md.mdp`, ein Wert pro Gruppe in `tc-grps`
  (Anzahl prüfen!), dazu `gen_temp` in `nvt.mdp`. Alle gleich.
- **Dauer:** `nsteps` in `md.mdp` = Dauer in ps / `dt` in ps, Rechnung im Plan nennen
  (10 ns bei dt = 0.002 ps → 5 000 000 Schritte).
- **Wiederholungen:** pro Wiederholung ein eigener, fester `gen_seed` in `nvt.mdp` (z. B. 1001,
  1002, 1003), nicht `-1`.
- **Kraftfeldwechsel:** Cutoffs und Dispersionskorrektur müssen zum Kraftfeld passen (CHARMM36 z. B.
  `vdw-modifier = force-switch`, `rvdw-switch = 1.0`, `rvdw = 1.2`, `rcoulomb = 1.2`,
  `DispCorr = no`). Wenn du nicht sicher bist: fragen, nicht raten.

## Job-Typ 2: Auswertung (`template-analysis/`)

Eine Auswertung hängt von einer Simulation ab und liest deren Ausgabe über den Link `md/`.

### `r3.yaml`

- **Eine Simulation:** im Template `VOM_AGENTEN_ZU_SETZEN` durch den r3-Pfad der Simulation ersetzen
  (`find_latest` nimmt den neuesten Job unter diesem Pfad; `source: output` bindet nur dessen
  `output/` ein, als `md/`).
- **Mehrere Simulationen in einer Auswertung:** stattdessen
  `find_all: {path: {$glob: "<pfad>/*"}}` mit `destination: runs` und `recursive_checkout: false`.
  Jede Simulation liegt dann unter `runs/<job-id>/`, ihre Ausgabe unter `runs/<job-id>/output/`.
  `run.sh` muss dann über diese Ordner laufen.
- Die Simulation muss **vor** der Auswertung committet sein, sonst schlägt der Commit fehl. Laufen
  muss sie noch nicht: r3 trägt beim Commit trotzdem ihre exakte Job-ID ein.
- Nach dem Commit liest du aus `$R3_REPOSITORY/jobs/<ID>/r3.yaml` (Feld `job:`), von welcher
  Simulation die Auswertung abhängt, und schreibst das in die Liste.

### `run.sh` und Skripte

- Einstellungen in den `EINSTELLUNGEN`-Block; Befehle darunter dürfen sich hier je nach Auftrag
  ändern (andere `gmx`-Werkzeuge, mehrere Schritte, weitere Python-Skripte).
- Eingaben nur aus `md/` (bzw. `runs/`) und aus dem Job-Ordner, Ausgaben nur nach `output/`.
- **Wo was steht:** Energien, Temperatur, Druck, Dichte stehen in `md.edr` (→ `gmx energy`);
  Koordinaten in `md.xtc` (→ `gmx rms`, `gmx gyrate`, …, mit `md.tpr` als `-s`). Die Trajektorie
  enthält keine Temperatur.
- Vor Analysen auf Koordinaten ist meist eine PBC-Korrektur nötig (`gmx trjconv -pbc mol -center`).
- Jedes interaktive `gmx`-Werkzeug bekommt seine Auswahl per `echo … |` (Namen wie `Temperature`,
  `Protein` oder `Backbone` sind robuster als Nummern).
- Ein Skript, das nicht in `jobs/` liegt, existiert für den Job nicht: alles, was `run.sh` braucht,
  gehört in den Job-Ordner.

### Ausprobieren vor dem Commit

- Gibt es im Repository schon eine **fertige** Simulation (Datei `output/md.edr` bzw. `md.xtc`
  vorhanden), probiere die Befehle aus `run.sh` von Hand darauf aus, mit allen Ausgaben in `scratch/`:
  `echo Temperature | gmx energy -f $R3_REPOSITORY/jobs/<SIM-ID>/output/md.edr -o scratch/test.xvg`
  und danach `python3 jobs/<name>/plot.py scratch/test.xvg scratch/test.png`.
- Gibt es keine: teste wenigstens die Python-Skripte an einer kleinen, selbst gebauten Datei im
  passenden Format in `scratch/`.
- Sag im Abschluss, was du ausprobiert hast und was nicht.

## Prüfen vor jedem Commit

- `diff -r <template> jobs/<name>` zeigt nur gewollte Änderungen;
- im Job-Ordner liegen keine Ausgaben, kein `output/`, keine Test- oder PDB-Dateien;
- Simulation: Temperatur, Dauer und Seed stimmen in allen mdp-Dateien überein;
- Auswertung: der Pfad in `r3.yaml` passt zu einer committeten Simulation
  (`r3 find -p <pfad> -l` liefert mindestens einen Job).

## `committed_jobs.txt`

Häng pro Auftrag einen Abschnitt an (nie überschreiben). Simulationen zuerst, dann Auswertungen:

```
# <Datum Uhrzeit> · <Auftrag in einem Satz>
<JOB-ID>  <r3-pfad>  [Simulation]
    <Protein> | <Kraftfeld>/<Wasser> | <Box> <Abstand> nm | <Salz> M NaCl | <T> K | <Dauer> ns | Seed <n>
    ansehen:  $R3_REPOSITORY/jobs/<JOB-ID>/
    starten:  r3 checkout <JOB-ID> ~/runs/<ordnername> && cd ~/runs/<ordnername> && bash run.sh

<JOB-ID>  <r3-pfad>  [Auswertung]
    <was ausgewertet wird, z. B. Temperatur über die Zeit (gmx energy) → energy.xvg, energy.png>
    hängt ab von: <SIM-JOB-ID> (<sim-pfad>) – erst starten, wenn diese Simulation fertig ist
    ansehen:  $R3_REPOSITORY/jobs/<JOB-ID>/
    starten:  r3 checkout <JOB-ID> ~/runs/<ordnername> && cd ~/runs/<ordnername> && bash run.sh
```

Die Start-Befehle sind nur für mich zum Kopieren. Du führst sie nicht aus.

## Sonstiges

- r3 lesen ist immer erlaubt: `r3 find`, `r3 ls`, Dateien unter `$R3_REPOSITORY/jobs/<ID>/` ansehen.
- Wenn ein r3-Skill installiert ist, darfst du ihn für r3-Fragen nutzen. Die Regeln dieser Datei
  haben Vorrang.
