#!/bin/bash
#SBATCH --job-name=download_SRA_parallel
#SBATCH --output=download_SRA_parallel_%j.out
#SBATCH --error=download_SRA_parallel_%j.err
#SBATCH --time=140:00:00       # 140 heures
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=normal
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=siedoumafas@gmail.com

# ===================== CONFIG =====================
SraAccList="/scratch/sory_yamdiv/Africrop/SraAccList.txt"
OUTDIR="/scratch/sory_yamdiv/Africrop/SRA"
TMPDIR="/scratch/$USER/tmp"
PARALLEL_JOBS=4   # nombre de SRR à traiter en parallèle
# ================================================

module load sratoolkit
module load parallel  # si GNU parallel est disponible sur ton cluster

mkdir -p "$OUTDIR"
mkdir -p "$TMPDIR"
cd "$OUTDIR" || exit 1

# Fonction pour télécharger et convertir un seul SRR
download_srr() {
  local SRA="$1"
  echo "=============================="
  echo "Téléchargement de $SRA"
  echo "=============================="

  # Préfetch
  prefetch "$SRA" || { echo "Erreur : prefetch a échoué pour $SRA"; return; }

  # Conversion en FASTQ
  fasterq-dump "$SRA" \
    --split-files \
    --threads $SLURM_CPUS_PER_TASK \
    --mem 28G \
    --temp "$TMPDIR" || { echo "Erreur : fasterq-dump a échoué pour $SRA"; return; }

  # Compression
  gzip *.fastq || { echo "Erreur lors de la compression pour $SRA"; return; }

  # Suppression du .sra
  rm -f "$SRA.sra"

  echo "✔ Terminé : $SRA"
}

export -f download_srr
export TMPDIR
export SLURM_CPUS_PER_TASK

# Lancement parallèle
cat "$SraAccList" | parallel -j $PARALLEL_JOBS download_srr {}

echo "=============================="
echo "Tous les SRR sont terminés !"
echo "=============================="
