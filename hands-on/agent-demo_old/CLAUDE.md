# GROMACS-Simulationen als r3-Jobs vorbereiten

Du bereitest in diesem Projekt Molekulardynamik-Simulationen mit GROMACS vor und committest sie als
Jobs in ein r3-Repository. **Du startest keine Simulation.** Am Ende steht eine Liste der committeten
Job-IDs, mit der ich jeden Job selbst prüfen und starten kann.

## Die wichtigste Regel: vorbereiten, nicht ausführen

Du darfst **nicht**:

- `gmx` aufrufen, in keiner Form (auch nicht `grompp`, `pdb2gmx` oder `-h` zum Testen),
- ein `run.sh` ausführen (`bash run.sh`, `./run.sh`, `source`, `sh`, …),
- Jobs abschicken oder starten (`sbatch`, `srun`, `xr3-slurm`, `nohup`, Hintergrundprozesse),
- `r3 checkout`, `r3 remove`, `r3 edit` oder `r3 rebuild-index` benutzen,
- im r3-Repository (`$R3_REPOSITORY`) direkt Dateien anlegen, ändern oder löschen,
- den Ordner `template/` ändern.

Wenn ein Schritt nur durch eines davon ginge: anhalten und mich fragen.

## Projektaufbau

```
./
├── CLAUDE.md               diese Datei
├── template/               Vorlage, wird nie verändert
│   ├── run.sh              GROMACS-Ablauf, Einstellungsblock oben
│   ├── metadata.yaml       Platzhalter für path, tags, description
│   └── mdp/                ions.mdp, minim.mdp, nvt.mdp, npt.mdp, md.mdp
├── jobs/                   hier legst du die Job-Ordner an
├── scratch/                für Hilfsdateien, z. B. eine PDB-Datei zum Ansehen (wird nie committet)
└── committed_jobs.txt      deine Liste der committeten Jobs (anhängen, nie überschreiben)
```

`template/run.sh` lädt die Struktur von der PDB herunter, erzeugt Topologie, Box, Wasser und Ionen,
und rechnet Minimierung, NVT, NPT und Produktion. Alles, was dabei entsteht, landet in `output/`.

## Ablauf

### 1. Auftrag lesen und Plan zeigen

Ich sage dir, welche Simulationen ich möchte, zum Beispiel: Protein (PDB-ID), Kraftfeld, Wassermodell,
Boxform und -abstand, Salzkonzentration, Temperatur(en), Anzahl Wiederholungen, Simulationsdauer und
den r3-Pfad. Was ich nicht nenne, übernimmst du aus dem Template.

Bevor du etwas anlegst, zeig mir **einen Plan als Tabelle**: eine Zeile pro Job mit Ordnername,
r3-Pfad, Tags und allen Einstellungen (auch den übernommenen Defaults), dazu jede geplante
mdp-Änderung und offene Fragen. Warte dann auf mein Okay. Nur wenn ich ausdrücklich sage, dass du
ohne Rückfrage arbeiten sollst, gehst du direkt weiter.

### 2. Job-Ordner anlegen

Pro Simulation: `cp -r template jobs/<name>`. Namen kurz und sprechend, z. B.
`jobs/1aki-amber-300K-rep1`. Existiert ein Ordner schon, nicht überschreiben, sondern nachfragen.

### 3. Einstellungen in `run.sh`

Ändere **nur den Block zwischen den `EINSTELLUNGEN`-Linien**. Alles darunter bleibt wie im Template.
Wenn ein Wunsch nur mit einer Änderung außerhalb des Blocks umsetzbar ist: nachfragen.

Prüfe dabei:

- **Kraftfeld:** Es muss als `<name>.ff` in der GROMACS-Installation oder im Job-Ordner existieren.
  Nachsehen darfst du per `ls` im Ordner `top` der Installation, ohne `gmx` aufzurufen:
  `ls "$GMXDATA/top"` oder `ls "$(dirname "$(which gmx)")/../share/gromacs/top"`.
  Wenn du es nicht findest: im Plan als offene Frage nennen.
- **Wasser und `SOLVENT`:** 3-Punkt-Modelle (spc, spce, tip3p) nutzen `spc216.gro`, `tip4p` nutzt
  `tip4p.gro`, `tip5p` nutzt `tip5p.gro`. Das Wassermodell muss zum Kraftfeld passen.
- **Ionen:** `PNAME`/`NNAME` müssen den Ionennamen des Kraftfelds entsprechen. Die meisten
  GROMACS-Kraftfelder nutzen `NA`/`CL`; CHARMM36-Portierungen nutzen `SOD`/`CLA`.
- **Box:** `BOX_DIST` unter 1.0 nm nur nach Rückfrage.

### 4. mdp-Dateien anpassen (nur wenn nötig)

Ändere nur die Parameter, die der Auftrag verlangt, und lass alles andere stehen.

- **Temperatur:** `ref_t` in `nvt.mdp`, `npt.mdp` und `md.mdp`, mit einem Wert pro Gruppe in
  `tc-grps` (Anzahl prüfen!), dazu `gen_temp` in `nvt.mdp`. Alle müssen dieselbe Temperatur haben.
- **Dauer:** `nsteps` in `md.mdp` = Dauer in ps / `dt` in ps. Rechne es aus und nenne die Rechnung
  im Plan (Beispiel: 10 ns bei dt = 0.002 ps → 5 000 000 Schritte).
- **Wiederholungen:** Für jede Wiederholung einen eigenen, festen `gen_seed` in `nvt.mdp` setzen
  (z. B. 1001, 1002, 1003), nicht `-1`. Nur so ist der Startpunkt im Job festgehalten.
- **Kraftfeldwechsel:** Cutoffs und Dispersionskorrektur müssen zum Kraftfeld passen (CHARMM36 z. B.
  `vdw-modifier = force-switch`, `rvdw-switch = 1.0`, `rvdw = 1.2`, `rcoulomb = 1.2`,
  `DispCorr = no`). Wenn du dir nicht sicher bist, welche Werte gelten: nicht raten, sondern fragen.

### 5. `metadata.yaml`

```yaml
path: <r3-Pfad>
tags: [<pdb-id klein>, <kraftfeld>, <wasser>, T<temperatur>, rep<n>]
description: <ein Satz: Protein, Kraftfeld, Wasser, Box, Salz, Temperatur, Dauer, Seed>
```

Den r3-Pfad gebe ich vor. Bei mehreren Simulationen mit einem Pfad schlägst du im Plan Unterpfade vor,
z. B. `<pfad>/300K/rep1`; nimm die Variante, die ich bestätige.

### 6. Vor dem Commit prüfen

Für jeden Job:

- `diff -r template jobs/<name>` zeigt nur die gewollten Änderungen;
- im Job-Ordner liegen nur `run.sh`, `metadata.yaml` und `mdp/` (keine PDB-Dateien, keine Ausgaben,
  kein `output/`);
- die Temperatur, die Dauer und der Seed stimmen in allen mdp-Dateien überein.

### 7. Committen, nicht starten

```bash
r3 commit jobs/<name>
```

`r3 commit` gibt die Job-ID (eine UUID) aus. Notiere sie sofort. Danach kontrollieren:

```bash
r3 find -p <r3-pfad> -l
```

Wenn ein Commit fehlschlägt: anhalten, Fehlermeldung zeigen, nicht blind wiederholen. Wenn du nach
einem Commit einen Fehler bemerkst: nicht löschen und nicht neu committen, sondern mir sagen, welcher
Job betroffen ist. Ich entscheide, was passiert.

**Nach dem Commit nichts ausführen.** Kein Checkout, kein Start, kein Test.

### 8. Liste schreiben: `committed_jobs.txt`

Häng für jeden Lauf deiner Sitzung einen Abschnitt an (Datei nie überschreiben):

```
# <Datum Uhrzeit> · <Auftrag in einem Satz>
<JOB-ID>  <r3-pfad>
    <Protein> | <Kraftfeld>/<Wasser> | <Box> <Abstand> nm | <Salz> M NaCl | <T> K | <Dauer> ns | Seed <n>
    ansehen:  $R3_REPOSITORY/jobs/<JOB-ID>/
    starten:  r3 checkout <JOB-ID> ~/runs/<ordnername> && cd ~/runs/<ordnername> && bash run.sh
```

Der Start-Befehl ist nur für mich zum Kopieren. Du führst ihn nicht aus.

### 9. Abschluss

Zum Schluss meldest du: wie viele Jobs committet sind, wo die Liste liegt, welche Defaults du
übernommen und welche mdp-Werte du geändert hast, und ausdrücklich, dass nichts gestartet wurde.

## Hilfen, die du nutzen darfst

- Struktur ansehen: PDB-Datei nach `scratch/` laden (`curl -o scratch/<ID>.pdb …`) und nach
  `HETATM`-Einträgen, Lücken oder ungewöhnlichen Resten suchen. Liganden oder Nichtstandard-Reste
  lässt `pdb2gmx` meist scheitern: im Plan als Warnung nennen. Die Datei kommt nie in einen Job-Ordner.
- r3 lesen: `r3 find`, `r3 ls`, Dateien unter `$R3_REPOSITORY/jobs/<ID>/` ansehen (nur lesen).
- Wenn ein r3-Skill installiert ist, darfst du ihn für r3-Fragen nutzen. Die Regeln dieser Datei
  haben Vorrang.
