#!/bin/bash
# GROMACS-Setup und Simulation für ein Protein aus der PDB – als r3-Job.
# Die mdp-Dateien (ions, minim, nvt, npt, md) liegen im Job-Ordner unter mdp/.
# Start (von Hand, nach dem Commit):
#   r3 checkout <JOB-ID> <zielordner> && cd <zielordner> && bash run.sh
set -e   # bei einem Fehler sofort abbrechen

# =========================== EINSTELLUNGEN ===========================
PDB_ID=1AKI                 # PDB-Eintrag
FORCEFIELD=amber99sb-ildn   # Kraftfeld: Name des .ff-Ordners ohne ".ff"
WATER=tip3p                 # Wassermodell
SOLVENT=spc216.gro          # Wasserkoordinaten für solvate (3-Punkt-Wasser: spc216.gro)
BOXTYPE=dodecahedron        # Boxform: cubic, dodecahedron, octahedron, triclinic
BOX_DIST=1.0                # Mindestabstand Protein–Boxrand in nm
ION_CONC=0.15               # NaCl in mol/L, zusätzlich zur Neutralisierung
PNAME=NA                    # Name des Kations im Kraftfeld
NNAME=CL                    # Name des Anions im Kraftfeld
# =====================================================================

# Alles, was entsteht, landet in output/ (der einzige beschreibbare Ordner des Jobs)
mkdir -p output
cp mdp/*.mdp output/
cd output

# 1. PDB-Datei herunterladen und Kristallwasser entfernen
wget https://files.rcsb.org/download/$PDB_ID.pdb
grep -v HOH $PDB_ID.pdb > ${PDB_ID}_clean.pdb

# 2. Topologie erstellen (Kraftfeld und Wassermodell)
gmx pdb2gmx -f ${PDB_ID}_clean.pdb -o processed.gro -p topol.top -ff $FORCEFIELD -water $WATER -ignh

# 3. Simulationsbox definieren
gmx editconf -f processed.gro -o newbox.gro -c -d $BOX_DIST -bt $BOXTYPE

# 4. Box mit Wasser füllen
gmx solvate -cp newbox.gro -cs $SOLVENT -o solv.gro -p topol.top

# 5. Ionen hinzufügen
gmx grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr
echo SOL | gmx genion -s ions.tpr -o solv_ions.gro -p topol.top -pname $PNAME -nname $NNAME -neutral -conc $ION_CONC

# 6. Energieminimierung
gmx grompp -f minim.mdp -c solv_ions.gro -p topol.top -o em.tpr
gmx mdrun -v -deffnm em

# 7. NVT-Äquilibrierung (Temperatur)
gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
gmx mdrun -v -deffnm nvt

# 8. NPT-Äquilibrierung (Druck)
gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
gmx mdrun -v -deffnm npt

# 9. Produktions-MD
gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md.tpr
gmx mdrun -v -deffnm md
