#!/bin/bash
#SBATCH --job-name=map_all_samples
#SBATCH --output=map_%A_%a.out
#SBATCH --error=map_%A_%a.err
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=normal
#SBATCH --array=1-346

###############################################################################
# SCRIPT DE MAPPING AUTOMATIQUE AVEC BWA-MEM
#
# Ce script aligne plusieurs échantillons FASTQ (paired-end) sur un génome
# de référence et produit pour chaque individu :
#
# 1) BAM trié
# 2) Index BAM
# 3) Statistiques de mapping
#
###############################################################################

###############################################################################
# 1. Chargement des modules nécessaires
###############################################################################

module load bwa
module load samtools

###############################################################################
# 2. Paramètres principaux (à modifier selon le projet)
###############################################################################

# Génome de référence
REF=GCF_009730915.1_TDr96_F1_v2_PseudoChromosome.rev07_lg8_w22_25.fasta_genomic.fna

# Nombre de threads utilisés par bwa et samtools
THREADS=8

# Mémoire utilisée par thread pour samtools sort
MEM_PER_THREAD=3G

###############################################################################
# 3. Création de la liste des échantillons
###############################################################################

# On récupère tous les fichiers R1
ls *_R1.fq.gz | sed 's/_R1.fq.gz//' > sample_list.txt

# Nombre total d'échantillons
TOTAL=$(wc -l < sample_list.txt)

echo "Nombre total d'échantillons : $TOTAL"

###############################################################################
# 4. Sélection de l'échantillon correspondant au job array
###############################################################################

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample_list.txt)

# Définition des fichiers FASTQ
R1=${SAMPLE}_R1.fq.gz
R2=${SAMPLE}_R2.fq.gz

# Nom du fichier de sortie
OUT=${SAMPLE}

echo "====================================="
echo "Traitement de l'échantillon : $SAMPLE"
echo "Fichier R1 : $R1"
echo "Fichier R2 : $R2"
echo "====================================="

###############################################################################
# 5. Vérification de l'existence des fichiers FASTQ
###############################################################################

if [ ! -f "$R1" ]; then
    echo "ERREUR : fichier $R1 introuvable"
    exit 1
fi

if [ ! -f "$R2" ]; then
    echo "ERREUR : fichier $R2 introuvable"
    exit 1
fi

###############################################################################
# 6. Indexation du génome de référence (si nécessaire)
###############################################################################

# BWA nécessite un index du génome
if [ ! -f "${REF}.bwt" ]; then
    echo "Indexation du génome de référence..."
    bwa index $REF
fi

###############################################################################
# 7. Alignement des reads avec BWA-MEM
###############################################################################

# L'option -R ajoute les informations de Read Group
# nécessaires pour les analyses ultérieures (GATK, etc.)

bwa mem \
-t $THREADS \
-R "@RG\tID:${OUT}\tSM:${OUT}\tPL:ILLUMINA" \
$REF $R1 $R2 |

###############################################################################
# 8. Tri du fichier BAM
###############################################################################

samtools sort \
-@ $THREADS \
-m $MEM_PER_THREAD \
-o ${OUT}_sorted.bam -

###############################################################################
# 9. Indexation du BAM trié
###############################################################################

samtools index ${OUT}_sorted.bam

###############################################################################
# 10. Statistiques de mapping
###############################################################################

samtools flagstat ${OUT}_sorted.bam > ${OUT}_mapping_stats.txt

###############################################################################
# 11. Fin du traitement
###############################################################################

echo "Mapping terminé pour l'échantillon : $SAMPLE"
echo "Fichier BAM : ${OUT}_sorted.bam"
echo "Statistiques : ${OUT}_mapping_stats.txt"
