#!/bin/bash
# Einfaches GROMACS-Setup für ein Protein aus der PDB – als r3-Job
# Die mdp-Dateien (ions, minim, nvt, npt, md) liegen im Job-Ordner unter mdp/.
set -e   # bei einem Fehler sofort abbrechen

PDB_ID=1AKI

# Alles, was entsteht, landet in output/ (der einzige beschreibbare Ordner des Jobs)
mkdir -p output
cp mdp/*.mdp output/
cd output

# 1. PDB-Datei herunterladen und Kristallwasser entfernen
wget https://files.rcsb.org/download/$PDB_ID.pdb
grep -v HOH $PDB_ID.pdb > ${PDB_ID}_clean.pdb

# 2. Topologie erstellen (Force Field und Wassermodell)
gmx pdb2gmx -f ${PDB_ID}_clean.pdb -o processed.gro -p topol.top -ff amber99sb-ildn -water tip3p -ignh

# 3. Simulationsbox definieren
gmx editconf -f processed.gro -o newbox.gro -c -d 1.0 -bt dodecahedron

# 4. Box mit Wasser füllen
gmx solvate -cp newbox.gro -cs spc216.gro -o solv.gro -p topol.top

# 5. Ionen hinzufügen
gmx grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr
echo SOL | gmx genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral -conc 0.15

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
