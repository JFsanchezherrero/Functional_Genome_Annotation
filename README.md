# Introduction
This repository contains files, scripts and examples employed during the Functional Genome Annotation Workshop

# Commands
### 0) Configuration file

>perl ./Functional_Genome_Annotation/scripts/generate_config.pl [previous configuration file]
>source environment.sh ## For loading environment variables 

### 1) Quality Metrics
>perl ./Functional_Genome_Annotation/scripts/calling_Assembly-STATS-BUSCO.pl -genome genome.fasta -cpu $CPUS -config configuration_file.txt -busco_db /path/to/BUSCO_db1 [-busco_db /path/to/BUSCO_db2] [-sp augustus_species]

### 2) Get Tophat junctions
>tophat –p $CPUS genome.fasta RNAseq-reads_R1.fastq RNAseq-reads_R2.fastq

Output generated: accepted hits mapping bam file and insertions, junctions and deletions bed file

Convert into gff3 format file using tophat2gff3 (under maker/bin/)
>tophat2gff3 tophat_output_junctions.bed

## 3) Repeat Identification

# Bibliography & Sources:

## Format Specification:

GFF3: 
- http://gmod.org/wiki/GFF3
- https://www.ensembl.org/info/website/upload/gff3.html 

## Software
TOPHAT:
- https://ccb.jhu.edu/software/tophat/index.shtml


## Others

