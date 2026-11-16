#!/bin/bash
# Auswertungs-Job: liest die Ausgabe einer Simulation aus md/
# (md/ ist ein Link auf output/ des Simulations-Jobs, siehe r3.yaml).
# Start (von Hand, nach dem Commit und erst wenn die Simulation fertig ist):
#   r3 checkout <JOB-ID> <zielordner> && cd <zielordner> && bash run.sh
set -e   # bei einem Fehler sofort abbrechen

# =========================== EINSTELLUNGEN ===========================
ENERGY_TERM=Temperature     # Energieterm für gmx energy (Name wie in dessen Auswahlliste)
# =====================================================================

mkdir -p output

# 1. Energieterm aus der Energiedatei der Simulation in eine xvg schreiben
#    (gmx energy fragt interaktiv nach dem Term, daher per echo übergeben)
echo $ENERGY_TERM | gmx energy -f md/md.edr -o output/energy.xvg

# 2. Plotten
python3 plot.py output/energy.xvg output/energy.png
