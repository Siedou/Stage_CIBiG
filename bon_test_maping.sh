#!/bin/bash
#SBATCH --job-name=map_all_CR58
#SBATCH --output=map_all_CR58.out
#SBATCH --error=map_all_CR58.err
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=normal

module load bwa
module load samtools

REF=GCF_009730915.1_TDr96_F1_v2_PseudoChromosome.rev07_lg8_w22_25.fasta_genomic.fna
THREADS=8
MEM_PER_THREAD=3G   # pour samtools sort

# Index reference si besoin
if [ ! -f "${REF}.bwt" ]; then
    echo "Indexing reference..."
    bwa index $REF
fi

# Boucle sur tous les R1
for R1 in *_R1.fq.gz; do
    # Déduire le nom de l'échantillon
    SAMPLE=${R1%_R1.fq.gz}
    R2=${SAMPLE}_R2.fq.gz
    OUT=${SAMPLE}

    echo "=============================="
    echo "Mapping sample: $SAMPLE"
    echo "R1: $R1"
    echo "R2: $R2"
    echo "Output: ${OUT}_sorted.bam"
    echo "=============================="

    # Mapping + tri
    bwa mem -t $THREADS -R "@RG\tID:${OUT}\tSM:${OUT}\tPL:ILLUMINA" $REF $R1 $R2 | \
    samtools sort -@ $THREADS -m $MEM_PER_THREAD -o ${OUT}_sorted.bam -

    # Index BAM
    samtools index ${OUT}_sorted.bam

    # Flagstat
    samtools flagstat ${OUT}_sorted.bam > ${OUT}_flagstat.txt

    echo "Sample $SAMPLE mapping completed!"
done

echo "All samples processed!"
