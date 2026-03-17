#!/bin/bash

# ==============================================
# Script : rename_fastq.sh
# Objectif : Copier et renommer des fichiers FASTQ
#            à partir d'un CSV en vérifiant l'existence
# Auteur : Sory Siedou
# Date : 2026-03-04
# ==============================================

# ----------------------------
# 1. Définir les chemins
# ----------------------------
SRC="/scratch/sory_yamdiv/Africrop/SRA/fastq"        # Dossier contenant les fichiers sources
DEST="/scratch/sory_yamdiv/Africrop/renamed_fastq"  # Dossier de destination

# Crée le dossier de destination s'il n'existe pas
mkdir -p "$DEST"

# ----------------------------
# 2. Définir le fichier CSV
# ----------------------------
CSV_FILE="test_renom_SRA.csv"  # Fichier CSV contenant les noms anciens et nouveaux
# Le CSV doit avoir au moins deux colonnes :
# $1 -> nouveau nom
# $2 -> ancien nom
# Séparateur : ;

# ----------------------------
# 3. Parcourir le CSV et copier les fichiers
# ----------------------------
awk -F';' -v src="$SRC" -v dest="$DEST" 'NR>1 {
    # Construire les chemins source et destination
    src1 = src "/" $2 "_1.fastq.gz"
    src2 = src "/" $2 "_2.fastq.gz"
    dest1 = dest "/" $1 "_R1.fastq.gz"
    dest2 = dest "/" $1 "_R2.fastq.gz"

    # Vérifier si le fichier source existe avant de copier
    if (system("[ -f \"" src1 "\" ]") == 0) {
        print "cp " src1 " " dest1
    } else {
        print "# WARNING: " src1 " does not exist"
    }

    if (system("[ -f \"" src2 "\" ]") == 0) {
        print "cp " src2 " " dest2
    } else {
        print "# WARNING: " src2 " does not exist"
    }
}' "$CSV_FILE" | bash

# ----------------------------
# 4. Message de fin
# ----------------------------
echo "✅ Copie et renommage terminés. Vérifiez les warnings ci-dessus pour les fichiers manquants."
