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
print OUT "BUSCO\t.	## /path/to/BUSCO_scripts/run_busco.py\n";
print OUT "AUGUSTUS\t.	## /path/to/augustus\n";
print OUT "INTERPRO\t.	## /path/to/interproscan.sh\n";
print OUT "MAKER\t.	## /path/to/maker_bin_folder/\n";
print OUT "RepeatMasker\t.	## /path/to/RepeatMasker\n";
print OUT "RepeatModeler\t.	## /path/to/RepeatModeler\n";
print OUT "GRID_QUEUE\t.	## qsub -q xxx -pe yyyy\n";
print OUT "contig_stats\t.	## /path/to/perl_script/contig_stats.pl\n";
close(OUT);
