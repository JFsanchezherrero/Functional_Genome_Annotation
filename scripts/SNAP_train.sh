#! /bin/bash -x
#$ -cwd
#$ -V

## $1 gff file generated
## $2 tag
## $3 final_name.hmm

mkdir SNAP
cd SNAP

maker2zff ../$1
echo "Calling: maker - maker2zff $1"

fathom -categorize 1000 genome.ann genome.dna
echo "Calling: snap - fathom export"

fathom -export 1000 -plus uni.ann uni.dna
echo "Calling: snap - fathom categorize"

forge export.ann export.dna
echo "Calling: snap - forge"

hmm-assembler.pl $2 . > $3
echo "Calling: snap - hmm-assembler.pl"


echo "File has been generated ($3) in SNAP folder"

