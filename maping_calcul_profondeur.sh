#!/bin/bash
#SBATCH --job-name=map_depth_pipeline
#SBATCH --output=map_%A_%a.out
#SBATCH --error=map_%A_%a.err
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=normal
#SBATCH --array=1-100

###############################################################################
# PIPELINE GENOMIQUE COMPLET
#
# Etapes :
# 1 Mapping avec BWA
# 2 Tri du BAM
# 3 Index BAM
# 4 Statistiques mapping
# 5 Calcul profondeur
# 6 Calcul couverture genome
#
###############################################################################

module load bwa
module load samtools

###############################################################################
# PARAMETRES
###############################################################################

REF=GCF_009730915.1_TDr96_F1_v2_PseudoChromosome.rev07_lg8_w22_25.fasta_genomic.fna
THREADS=8
MEM_PER_THREAD=3G

###############################################################################
# CREATION LISTE ECHANTILLONS
###############################################################################

ls *_R1.fq.gz | sed 's/_R1.fq.gz//' > sample_list.txt

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample_list.txt)

R1=${SAMPLE}_R1.fq.gz
R2=${SAMPLE}_R2.fq.gz

echo "Processing sample: $SAMPLE"

###############################################################################
# INDEX GENOME SI NECESSAIRE
###############################################################################

if [ ! -f "${REF}.bwt" ]; then
    bwa index $REF
fi

###############################################################################
# MAPPING
###############################################################################

bwa mem -t $THREADS \
-R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tPL:ILLUMINA" \
$REF $R1 $R2 | \
samtools sort -@ $THREADS -m $MEM_PER_THREAD -o ${SAMPLE}_sorted.bam -

###############################################################################
# INDEX BAM
###############################################################################

samtools index ${SAMPLE}_sorted.bam

###############################################################################
# STATISTIQUES MAPPING
###############################################################################

samtools flagstat ${SAMPLE}_sorted.bam > ${SAMPLE}_flagstat.txt

###############################################################################
# CALCUL PROFONDEUR
###############################################################################

samtools depth -a ${SAMPLE}_sorted.bam > ${SAMPLE}_depth.txt

###############################################################################
# CALCUL STATISTIQUES PROFONDEUR
###############################################################################

awk '
{
sum+=$3
if($3>0) cov1++
if($3>=5) cov5++
if($3>=10) cov10++
if($3>=20) cov20++
}
END{
print "Average_depth",sum/NR
print "Coverage_>1X",cov1/NR*100
print "Coverage_>5X",cov5/NR*100
print "Coverage_>10X",cov10/NR*100
print "Coverage_>20X",cov20/NR*100
}' ${SAMPLE}_depth.txt > ${SAMPLE}_coverage_stats.txt

###############################################################################
# EXTRACTION PROFONDEUR MOYENNE
###############################################################################

AVG=$(awk '/Average_depth/ {print $2}' ${SAMPLE}_coverage_stats.txt)

COV1=$(awk '/Coverage_>1X/ {print $2}' ${SAMPLE}_coverage_stats.txt)
COV5=$(awk '/Coverage_>5X/ {print $2}' ${SAMPLE}_coverage_stats.txt)
COV10=$(awk '/Coverage_>10X/ {print $2}' ${SAMPLE}_coverage_stats.txt)
COV20=$(awk '/Coverage_>20X/ {print $2}' ${SAMPLE}_coverage_stats.txt)

###############################################################################
# CREATION TABLEAU GLOBAL
###############################################################################

echo -e "${SAMPLE}\t${AVG}\t${COV1}\t${COV5}\t${COV10}\t${COV20}" \
>> coverage_summary.tsv

echo "Finished sample: $SAMPLE"
