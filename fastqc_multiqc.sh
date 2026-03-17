#!/bin/bash
#SBATCH --job-name=fastqc_multiqc
#SBATCH --output=fastqc_multiqc_%j.out
#SBATCH --error=fastqc_multiqc_%j.err
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --partition=normal

# Charger les modules
module load FastQC
module load MultiQC

OUTPUT_DIR="fastqc_results"
mkdir -p ${OUTPUT_DIR}

echo "=== Lancement FastQC ==="

fastqc *.trimmed.fq.gz \
    -o ${OUTPUT_DIR} \
    -t ${SLURM_CPUS_PER_TASK}

echo "=== FastQC terminé ==="

echo "=== Lancement MultiQC ==="

multiqc ${OUTPUT_DIR} -o ${OUTPUT_DIR}

echo "=== Analyse terminée ==="
echo "Date: $(date)"
