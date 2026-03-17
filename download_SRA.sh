#!/bin/bash
#SBATCH --job-name=download_SRA
#SBATCH --output=download_SRA_%j.out
#SBATCH --error=download_SRA_%j.err
#SBATCH --time=140:00:00       # 140 heures
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=siedoumafas@gmail.com

# ===================== CONFIG =====================
SRA_final="/scratch/sory_yamdiv/Africrop/SRA_final.txt"
OUTDIR="/scratch/sory_yamdiv/Africrop/SRA"
# ================================================

module load sratoolkit

# Création des dossiers
mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit 1

# Lecture de la liste de SRR
while read -r SRA; do
  [[ -z "$SRA" ]] && continue

  echo "=============================="
  echo "Téléchargement de $SRA"
  echo "=============================="

  # Préfetch SRA
  prefetch "$SRA" || { echo "Erreur : prefetch a échoué pour $SRA"; continue; }

  # Conversion en FASTQ avec threads et dossier temporaire
  echo "Conversion en FASTQ pour $SRA"
  fasterq-dump "$SRA" \
    --split-files \
    --threads $SLURM_CPUS_PER_TASK \
    --mem 28G \
    #--temp "$TMPDIR" || { echo "Erreur : fasterq-dump a échoué pour $SRA"; continue; }

  # Compression des FASTQ
  gzip *.fastq || { echo "Erreur lors de la compression pour $SRA"; continue; }

  # Suppression du fichier .sra pour économiser l’espace
  rm -f "$SRA.sra"

  echo "✔ Terminé : $SRA"
done < "$SRA_final"

echo "=============================="
echo "Tous les jobs terminés"
echo "=============================="
