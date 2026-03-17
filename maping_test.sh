#!/bin/bash
#SBATCH --job-name=yam_map
#SBATCH --cpus-per-task=16
#SBATCH --mem=60G
#SBATCH --time=48:00:00
#SBATCH --output=map_%j.out
#SBATCH --error=map_%j.err

module load bwa
module load samtools

REF=GCF_009730915.1_TDr96_F1_v2_PseudoChromosome.rev07_lg8_w22_25.fasta_genomic.fna
THREADS=16

# Boucle automatique sur tous les R1 présents
for R1 in *_R1.fq.gz
do
    # Détecte le nom du sample
    SAMPLE=$(basename $R1 _R1.fq.gz)
    R2=${SAMPLE}_R2.fq.gz

    # Vérifie que R2 existe
    if [[ ! -f $R2 ]]; then
        echo "⚠️  R2 manquant pour $SAMPLE, skipping..."
        continue
    fi

    echo "=============================="
    echo "Mapping $SAMPLE"
    echo "=============================="

    # Mapping + tri
    bwa mem -t $THREADS $REF $R1 $R2 | \
        samtools sort -@ $THREADS -o ${SAMPLE}_sorted.bam

    # Index BAM
    samtools index ${SAMPLE}_sorted.bam

    # Statistiques
    samtools flagstat ${SAMPLE}_sorted.bam > ${SAMPLE}_flagstat.txt

    echo "$SAMPLE finished ✅"
done

echo "All samples mapped 🚀"
