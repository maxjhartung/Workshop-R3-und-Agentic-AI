# Gyrationsradius über die Zeit.
# Liest die Simulation aus md/ (Link auf output/ des Simulations-Jobs)
# und den Auswertungs-Parameter aus config.yaml.
import yaml, MDAnalysis as mda, matplotlib.pyplot as plt
from MDAnalysis.transformations import unwrap
cfg = yaml.safe_load(open("config.yaml"))       # Parameter
u = mda.Universe("md/md.tpr", "md/md.xtc")      # die Simulation
pbc = unwrap(u.select_atoms("protein"))         # PBC: Protein ganz
u.trajectory.add_transformations(pbc)
atoms = u.select_atoms(cfg["selection"])

zeit, rg = [], []
for ts in u.trajectory:
    zeit.append(ts.time / 1000)                 # ps → ns
    rg.append(atoms.radius_of_gyration() / 10)  # Å → nm

plt.plot(zeit, rg); plt.title(cfg["selection"])
plt.xlabel("Zeit (ns)"); plt.ylabel("Rg (nm)")
plt.savefig("output/rg.png")
