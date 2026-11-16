# Plottet die erste Datenspalte einer GROMACS-xvg-Datei gegen die Zeit.
# Aufruf: python3 plot.py <eingabe.xvg> <ausgabe.png>
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

xvg, png = sys.argv[1], sys.argv[2]
x, y = [], []
xlabel, ylabel, titel = "x", "y", ""

for line in open(xvg):
    if line.startswith("@") and "xaxis" in line and "label" in line:
        xlabel = line.split('"')[1]
    elif line.startswith("@") and "yaxis" in line and "label" in line:
        ylabel = line.split('"')[1]
    elif line.startswith("@ s0 legend"):
        titel = line.split('"')[1]   # Name des Terms, z. B. Temperature
    elif line.startswith(("#", "@")) or not line.strip():
        continue                      # Kommentare und Formatangaben überspringen
    else:
        spalten = line.split()
        x.append(float(spalten[0]))
        y.append(float(spalten[1]))

plt.plot(x, y)
plt.xlabel(xlabel)
plt.ylabel(ylabel)
plt.title(titel)
plt.savefig(png, dpi=150)
