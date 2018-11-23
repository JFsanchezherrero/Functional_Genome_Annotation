# Introduction
This repository contains files, scripts and examples employed during the Functional Genome Annotation Workshop.

Presentation slides will be available soon. 

# Steps
### 0) Configuration file

Config path for necessary binaries and GRID Engine queues in order to split jobs and sent multiple threads.

### 1) Quality Metrics

Calculate assembly statistics (N50, assembly bases, etc) and run BUSCO for the dataset of interest.

### 2) Repeat Identification

Generate a de novo search and based on RepBase and DFam for the repeat identification using RepeatModeler and RepeatMasker.

### 3) Get Tophat junctions

Map RNA seq reads using Tophat and with the output generated, junctions bed file (others: accepted hits mapping bam file; insertions, and deletions bed file) generate information for later annotation. Convert junctions bed into gff3 format file using tophat2gff3 (under maker/bin/)

## 4) Generate



# Bibliography & Sources:
- Repeats: 

	http://www.repeatmasker.org/
	
	https://www.nature.com/articles/nrg2165

	https://www.ncbi.nlm.nih.gov/pubmed/18753783


- Gene Ontology (GO) Terms:

	http://www.geneontology.org/
	
	https://www.nature.com/articles/ng0500_25


- Figures:

	https://en.wikiversity.org/wiki/WikiJournal_of_Medicine/Eukaryotic_and_prokaryotic_gene_structure


- GFF3: 
	
	http://gmod.org/wiki/GFF3
	
	https://www.ensembl.org/info/website/upload/gff3.html 
	
- Annotation
	
	https://doi.org/10.1371/journal.pone.0050609
	https://academic.oup.com/bioinformatics/article/24/5/637/202844
		


## Software
TOPHAT: 
https://ccb.jhu.edu/software/tophat/index.shtml

BUSCO: 
https://busco.ezlab.org/

RepeatMasker: 
http://www.repeatmasker.org/RMDownload.html

RepeatModeler: 
http://www.repeatmasker.org/RepeatModeler/

MAKER:

AUGUSTUS: http://bioinf.uni-greifswald.de/augustus/

BRAKER:

BLAST:


## Others




