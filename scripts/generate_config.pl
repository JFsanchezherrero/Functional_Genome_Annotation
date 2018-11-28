#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use FindBin;
use lib $FindBin::Bin."/lib";
require myModules;

print "\n\n########################################################################\n";
print "Generating a new configuration file for the Functional Genome Annotation Workshop\n";
print "########################################################################\n";
print "\nThe config file contains path for multiple binaries and GRID Engine queues...\n";
print "+ Provide and fill the path for each software binary executable file. Leave a dot (.) if not installed or not necessary\n";
print "+ Add as many as grid engine queues as necessary\n";
print "########################################################################\n\n";
print "ATTENTION: If previously generated a config file, re-run using: perl $0 config_file\n";
print "########################################################################\n\n";

my %configuration;
if ($ARGV[0]) { 

	%configuration = %{ myModules::get_config_file( $ARGV[0] ) };
	print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
	print "+ Reading configuration file:\n";
	foreach my $keys (sort keys %configuration) {
		my @array_files = @{ $configuration{$keys} };
		for (my $i=0; $i < scalar @array_files; $i++) {
			next if ($array_files[$i] eq ".");
			print "\t".$keys."\t".$array_files[$i]."\n";
	}}
	print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";

} else { 

	print "Provide path for each binary stated:\n";
	print "BUSCO (/path/to/BUSCO_scripts/run_busco.py):\t"; my $BUSCO = <STDIN>; chomp $BUSCO; push ( @{ $configuration{"BUSCO"} } , $BUSCO );
	print "AUGUSTUS (/path/to/augustus_folder/):\t"; my $AUGUSTUS = <STDIN>; chomp $AUGUSTUS; push ( @{ $configuration{"AUGUSTUS"} } , $AUGUSTUS );
	print "INTERPRO (/path/to/interproscan.sh):\t"; my $INTERPRO = <STDIN>; chomp $INTERPRO; push ( @{ $configuration{"INTERPRO"} } , $INTERPRO );
	print "MAKER (/path/to/maker_bin_folder/):\t"; my $MAKER = <STDIN>; chomp $MAKER; push ( @{ $configuration{"MAKER"} } , $MAKER );
	print "RepeatMasker (/path/to/RepeatMasker_folder/):\t"; my $RepeatMasker = <STDIN>; chomp $RepeatMasker; push ( @{ $configuration{"RepeatMasker"} } , $RepeatMasker );
	print "RepeatModeler (/path/to/RepeatModeler_folder/):\t"; my $RepeatModeler = <STDIN>; chomp $RepeatModeler; push ( @{ $configuration{"RepeatModeler"} } , $RepeatModeler );
	print "contig_stats (/path/to/perl_script/contig_stats.pl):\t"; my $contig_stats = <STDIN>; chomp $contig_stats; push ( @{ $configuration{"contig_stats"} } , $contig_stats );
	print "BLAST_folder (/path/to/blast_bin_folder/):\t"; my $BLAST = <STDIN>; chomp $BLAST; push ( @{ $configuration{"BLAST"} } , $BLAST );
	
	print "GRID_QUEUE (qsub -q xxx -pe yyyy):\t"; my $GRID_QUEUE = <STDIN>; chomp $GRID_QUEUE; push ( @{ $configuration{"GRID_QUEUE"} } , $GRID_QUEUE );
	print "\nAnythin else?\n";
	while (1) {
		print "Answer: Exit or QUEUE to add an additional GRID_QUEUE\n";
		my $answer = <STDIN>;
		chomp $answer;
		if ($answer eq "Exit") { 
			last; 
		} else {
			print "GRID_QUEUE (qsub -q xxx -pe yyyy):\t"; my $GRID_QUEUE = <STDIN>; chomp $GRID_QUEUE; push ( @{ $configuration{"GRID_QUEUE"} } , $GRID_QUEUE );
}}}
#print Dumper \%configuration;

foreach my $keys (keys %configuration) {
	next if $keys eq "BUSCO"; next if $keys eq "GRID_QUEUE"; next if $keys eq "contig_stats"; next if $keys eq "INTERPRO";	
	my @array_files = @{ $configuration{$keys} };
		for (my $i=0; $i < scalar @array_files; $i++) {
			next if ($array_files[$i] eq ".");
			if ($array_files[$i] =~ /(.*)\/$/) {
			} else {
				$configuration{$keys}[$i] = $array_files[$i]."/";
}}}

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Writing configuration file:\n";
my $config_file = "config.txt";
open (OUT, ">$config_file");
print OUT "BUSCO\t".$configuration{"BUSCO"}[0]."\n";
print OUT "AUGUSTUS\t".$configuration{"AUGUSTUS"}[0]."\n";
print OUT "INTERPRO\t".$configuration{"INTERPRO"}[0]."\n";
print OUT "MAKER\t".$configuration{"MAKER"}[0]."\n";
print OUT "RepeatMasker\t".$configuration{"RepeatMasker"}[0]."\n";
print OUT "RepeatModeler\t".$configuration{"RepeatModeler"}[0]."\n";
print OUT "contig_stats\t".$configuration{"contig_stats"}[0]."\n";
print OUT "BLAST_folder\t".$configuration{"BLAST_folder"}[0]."\n";

my @array = @{ $configuration{"GRID_QUEUE"} }; 
for (my $i=0; $i < scalar @array; $i++) {
	print OUT "GRID_QUEUE\t".$array[$i]."\n";
}
close(OUT); sleep(1);