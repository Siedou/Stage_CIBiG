#!/bin/bash
#SBATCH --job-name=map_CR5858
#SBATCH --output=map_CR5858.out
#SBATCH --error=map_CR5858.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=normal

# ===============================
# LOAD MODULES (adapter si besoin)
# ===============================

module load bwa
module load samtools

# ===============================
# VARIABLES
# ===============================

REF=GCF_009730915.1_TDr96_F1_v2_PseudoChromosome.rev07_lg8_w22_25.fasta_genomic.fna
R1=CR5859_L6_R1.fq.gz
R2=CR5859_L6_R2.fq.gz
OUT=CR5859_L6

THREADS=8

# ===============================
# INDEX REFERENCE (si pas déjà fait)
# ===============================

if [ ! -f "${REF}.bwt" ]; then
    echo "Indexing reference..."
    bwa index $REF
fi

# ===============================
# MAPPING + SORT (pipeline rapide)
# ===============================

echo "Starting mapping..."

bwa mem -t $THREADS $REF $R1 $R2 | \
samtools view -@ $THREADS -Sb - | \
samtools sort -@ $THREADS -o ${OUT}_sorted.bam -

# ===============================
# INDEX BAM
# ===============================

samtools index ${OUT}_sorted.bam

# ===============================
# FLAGSTAT
# ===============================

samtools flagstat ${OUT}_sorted.bam > ${OUT}_flagstat.txt

echo "Mapping completed!"
