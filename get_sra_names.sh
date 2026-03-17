#!/bin/bash
#SBATCH --job-name=sra_metadata
#SBATCH --output=sra_metadata_%j.out
#SBATCH --error=sra_metadata_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G

module load entrez-direct 2>/dev/null || true

START=8451303
END=8451469

OUTPUT="sra_metadata.csv"

echo "Run,SampleName,LibraryName,BioProject,BioSample,Organism" > $OUTPUT

for i in $(seq $START $END); do
    SRR="SRR$i"
    echo "Processing $SRR ..."
    
    esearch -db sra -query $SRR | \
    efetch -format runinfo | \
    tail -n +2 | \
    cut -d',' -f1,8,12,24,25,29 >> $OUTPUT
    
    sleep 0.3
done

echo "Finished. Output file: $OUTPUT"
