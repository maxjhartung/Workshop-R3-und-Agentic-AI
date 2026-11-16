# Hands-on-Jobs für den r3-Workshop

Zwei Jobs, die aufeinander aufbauen: die Simulation und eine Auswertung, die von ihr abhängt.

```curl -fsSL https://raw.githubusercontent.com/matthias-k/r3-tooling/builder-camp/bootstrap.sh | bash```

## Voraussetzungen
- r3 (Schritt 0 der Präsentation), `$R3_REPOSITORY` gesetzt
- GROMACS (`gmx` im PATH), `wget`
- Python mit MDAnalysis, matplotlib und PyYAML: `pip install MDAnalysis matplotlib pyyaml`

## Aufgabe 1: Die Simulation als r3-Job (`md-1aki/`)
1. Eure mdp-Dateien nach `md-1aki/mdp/` kopieren: `ions.mdp`, `minim.mdp`, `nvt.mdp`, `npt.mdp`, `md.mdp`.
   Für die Demo `nsteps` in `md.mdp` stark verkürzen (z. B. 25 000 Schritte = 50 ps) oder den Job vorher laufen lassen.
2. `run.sh` ist euer `gmx_setup_simple.sh`. Geändert sind nur die ersten Zeilen: `set -e`, und statt eines eigenen Projektordners schreibt das Skript alles nach `output/`.
3. Committen und ausführen:
   ```
   r3 commit md-1aki                     # gibt die Job-ID aus
   r3 checkout <ID> ~/runs/md && cd ~/runs/md && bash run.sh
   ```
   Die Ergebnisse (u. a. `md.tpr`, `md.xtc`) liegen danach im Repository in `output/` des Jobs.

## Aufgabe 2: Die Auswertung als zweiter Job (`rg-protein/`)
- `r3.yaml` bindet `output/` des neuesten Jobs mit `path: lysozyme/md` als `md/` ein.
- `config.yaml` enthält den Parameter (`selection: protein`).
- `run.py` berechnet den Gyrationsradius über die Zeit und speichert `output/rg.png`.
```
r3 commit rg-protein
r3 checkout <ID> ~/runs/rg && cd ~/runs/rg && python3 run.py
```

## Aufgabe 3: Eine Variante
```
cp -r rg-protein rg-backbone
# in rg-backbone/config.yaml:   selection: backbone
# in rg-backbone/metadata.yaml: tags: [backbone]
r3 commit rg-backbone
r3 checkout <ID> ~/runs/rg-backbone && cd ~/runs/rg-backbone && python3 run.py
r3 find -p lysozyme/analysis/rg -l     # zeigt beide Auswertungen mit ID und Tag
```

Hinweis: `run.py` ist mit MDAnalysis 2.11 an einer Test-Trajektorie geprüft. Der Simulations-Job ist nicht getestet (kein GROMACS in der Testumgebung).
