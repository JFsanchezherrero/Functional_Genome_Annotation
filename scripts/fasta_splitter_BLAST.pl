#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Getopt::Long;

use FindBin;
use lib $FindBin::Bin."/lib";
require myModules;

### Get Options
my ($file, $cpus, $config_file, @dbs2check, $type, $help);
GetOptions( 
	"file=s" => \$file,
	"cpu=i" => \$cpus,
	"config=s" => \$config_file,
	"db=s" => \@dbs2check,
	"type=s" => \$type,
	"h|help" => \$help,
);
if (!$file || !$config_file || !$cpus || !@dbs2check ) { &print_help(); exit();}
if ($help) {&print_help(); exit();}

## START
print "\n####################################################################################\n";
print "\nStarting pipeline for the BLAST search of the given fasta file\n";
print "\n####################################################################################\n";

## check previous
print "ATTENTION:\n";
print "+ Please check that RepBase and NCBI BLAST (RMBLAST version) are installed and accesible\n";
sleep(2);

my %configuration = %{ myModules::get_config_file( $config_file ) };
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Reading configuration file:\n";
foreach my $keys (sort keys %configuration) {
	my @array_files = @{ $configuration{$keys} };
	for (my $i=0; $i < scalar @array_files; $i++) {
		next if ($array_files[$i] eq ".");
		print "\t".$keys."\t".$array_files[$i]."\n";
}}
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";

print "Make dir and change to ./BLAST_search\n";
my $dir = "BLAST_search";
mkdir $dir, 0755; chdir $dir;

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Splitting file into $cpus parts...\n";
my $ref_array_count = myModules::get_size($file);
print "Stats for file: $file\n";
print "Chars: $ref_array_count\n";
my $block = int($ref_array_count/$cpus);
my $files_ref = myModules::fasta_file_splitter($file,$block,"fasta");
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";


print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Sending commands:\n";
my (@ids2wait, @results_files, @discard_files, @error_files);
my @files = @{$files_ref};
my $out_file_header = "blast_search.sh";
open (OUT_SH, ">$out_file_header");
#print OUT_SH "#! /bin/bash -x\n#\$ -cwd\n#\$ -V\n";
for (my $i=0; $i < scalar @files; $i++) {
	for (my $j=0; $j < scalar @dbs2check; $j++) {
		my $dbName;
		my $out = $dbName."_".$files[$i]."-blast.out";
		my $hercules_queue = $configuration{"GRID_QUEUE"}[rand @{ $configuration{"GRID_QUEUE"} }]; ## get random queue
		my $jobID = $dbName."_".$i;
		my $blast_call = $hercules_queue." 1 -cwd -V -N $jobID -b y $type -db $dbs2check[$j] -query $files[$i] -out $out -outfmt "."\'\""."6 std qlen slen staxids"."\"\'";
		print OUT_SH $blast_call."\n";
		my $call_id = myModules::sending_command($blast_call);
		push (@ids2wait, $call_id);

		## get files generated
		my $out_o = $jobID.".o".$call_id;
		my $out_e = $jobID.".e".$call_id;
		my $out_po = $jobID.".po".$call_id;
		my $out_pe = $jobID.".pe".$call_id;
		
		push (@results_files, $out); push (@error_files, $out_e);
		push (@discard_files, $out_o); push (@discard_files, $out_po);	push (@discard_files, $out_pe);	
	}
}
close (OUT_SH);
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
## waiting to finish all 
myModules::waiting(\@ids2wait);
print "\n";

### Keep folder tidy
print 
mkdir "tmp", 0755;
my $error_log = "error.log";
my $final_tmp_file = "concat_BLAST_results.txt";
for (my $i=0; $i < scalar @results_files; $i++) {
	system("cat $results_files[$i] >> $final_tmp_file");	
	system("mv $results_files[$i] ./tmp"); system("mv $files[$i] ./tmp");
	system("cat $error_files[$i] >> $error_log"); system("mv $error_files[$i] ./tmp"); 
}
for (my $i=0; $i < scalar @discard_files; $i++) { system("rm $discard_files[$i]"); }
system("mv info_*txt ./tmp");

print "Finishing BLAST search...\n";
print "Check for temporal files in tmp folder generated, for final results in $final_tmp_file and for putative errors in error.log files...\n";

print "##################################################\n";
print "\tBLAST search pipeline finished...\n";
print "##################################################\n";

sub print_help {
	print "\n################################################\n";
	print "USAGE:\nperl $0 -file fasta_file -db DB_index_name [-db DB_index_name2] -cpu cpus -type [blastp|blastn|tblastn|tblastx] -config config_file\n\n";
	print "\n################################################\n";
	print "This script splits fasta in as many cpus as stated and prints search commands into a file using several queues...\n";
	print "Multiples DBs could be provided separated\n\n";
}