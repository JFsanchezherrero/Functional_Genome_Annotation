#!/usr/bin/perl
use strict;
use warnings;

print "\n\n########################################################################\n";
print "Generating a new configuration file for the Functional Genome Annotation Workshop\n";
print "########################################################################\n";
print "\nThis config file contains path for multiple binaries and GRID Engine queues...\n";
print "+ Edit the file and fill the path for each software binary executable file. Leave a dot (.) if not installed or not necessary\n";
print "+ Add as many as grid engine queues as necessary\n";
print "########################################################################\n\n";

my $config_file = "config.txt";
open (OUT, ">$config_file");
print OUT "BUSCO\t.\n ## /path/to/BUSCO_scripts/run_busco.py";
print OUT "AUGUSTUS\t.\n ## /path/to/augustus";
print OUT "INTERPRO\t.\n## /path/to/interproscan.sh";
print OUT "MAKER\t.\n## /path/to/maker_bin_folder/";
print OUT "RepeatMasker\t.\n## /path/to/RepeatMasker";
print OUT "RepeatModeler\t.\n## /path/to/RepeatModeler";
print OUT "GRID_QUEUE\t.\n## qsub -q xxx -pe yyyy";
print OUT "contig_stats\t.\n## /path/to/perl_script/contig_stats.pl";
close(OUT);
