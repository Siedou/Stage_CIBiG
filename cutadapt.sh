#!/bin/bash

module load cutadapt/4.5

ADAPT_R1=AGATCGGAAGAGCACACGTCTGAACTCCAGTCA
ADAPT_R2=AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT

for sample in CR5858 CR5859 CR5860 CR5861 CR5862 CR5863
do
  echo "Traitement de $sample"

  cutadapt \
    -a $ADAPT_R1 \
    -A $ADAPT_R2 \
    -q 20,20 \
    -m 30 \
    -o ${sample}_R1.trimmed.fq.gz \
    -p ${sample}_R2.trimmed.fq.gz \
    ${sample}_R1.fq.gz \
    ${sample}_R2.fq.gz
done
