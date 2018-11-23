#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Getopt::Long;

use POSIX qw(strftime); #my $datestring = strftime "%Y%m%d%H%M", localtime;
my $step_time; my $start_time = $step_time = time;

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
print "\n"; &time_log(); print "\n";

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Sending commands:\n";
my (@ids2wait, %results_files, %discard_files, %error_files, %log_files);
my @files = @{$files_ref};
my $out_file_header = "blast_search.sh";
open (OUT_SH, ">$out_file_header");
#print OUT_SH "#! /bin/bash -x\n#\$ -cwd\n#\$ -V\n";
for (my $i=0; $i < scalar @files; $i++) {
	for (my $j=0; $j < scalar @dbs2check; $j++) {
		
		my $blast_bin = $configuration{"BLAST_folder"}[0].$type;
		my @name = split("/", $dbs2check[$j]);
		my $dbName = $name[-1]."_db";
		my $jobID = $dbName."_".$i;
		my $out = $jobID."_blast.out";

		my $hercules_queue = $configuration{"GRID_QUEUE"}[rand @{ $configuration{"GRID_QUEUE"} }]; ## get random queue
		my $blast_call = $hercules_queue." 1 -cwd -V -N $jobID -b y $blast_bin -db $dbs2check[$j] -query $files[$i] -out $out -outfmt "."\'\""."6 std qlen slen staxids"."\"\'";
		
		print OUT_SH $blast_call."\n";
		my $call_id = myModules::sending_command($blast_call);
		push (@ids2wait, $call_id);

		## get files generated
		my $out_o = $jobID.".o".$call_id;
		my $out_e = $jobID.".e".$call_id;
		my $out_po = $jobID.".po".$call_id;
		my $out_pe = $jobID.".pe".$call_id;
		
		push (@{ $results_files{$dbName} }, $out); 
		push (@{ $error_files{$dbName} }, $out_e);
		push (@{ $log_files{$dbName} }, $out_o); 
		push (@{ $discard_files{$dbName} }, $out_po);	push (@{ $discard_files{$dbName} }, $out_pe);	
	}
}
close (OUT_SH);
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
## waiting to finish all 
myModules::waiting(\@ids2wait);
print "\n"; &time_log(); print "\n";

### Keep folder tidy
print "+ Cleaning folder and discarding tmp files\n"; mkdir "tmp", 0755;

for (my $db=0; $db < scalar @dbs2check; $db++) {
	my @name = split("/", $dbs2check[$db]);
	my $dbName = $name[-1]."_db";
	my $final_tmp_file = "concat_BLAST_".$dbName."_results.txt";
	my $error_log = $dbName."_error.log"; my $log = $dbName.".log";
	
	for (my $i=0; $i < scalar @{ $results_files{$dbName} }; $i++) {
		system("cat $results_files{$dbName}[$i] >> $final_tmp_file"); system("mv $results_files{$dbName}[$i] ./tmp");
		system("cat $error_files{$dbName}[$i] >> $error_log"); system("mv $error_files{$dbName}[$i] ./tmp"); 
		system("cat $log_files{$dbName}[$i] >> $log"); system("mv $log_files{$dbName}[$i] ./tmp"); 
	}
	for (my $i=0; $i < scalar @{ $discard_files{$dbName} }; $i++) { system("rm $discard_files{$dbName}[$i]"); }
}
system("mv info_*txt ./tmp"); for (my $i=0; $i < scalar @files; $i++) { system("mv $files[$i] ./tmp"); }

print "Finishing BLAST search...\n";
print "Check for temporal files in tmp folder generated, for final results in concat_BLAST_*_file(s) generated and for putative errors in error.log files...\n";

print "##################################################\n";
print "\tBLAST search pipeline finished...\n";
print "##################################################\n";
myModules::finish_time_stamp($start_time);


sub print_help {
	print "\n################################################\n";
	print "USAGE:\nperl $0 -file fasta_file -db DB_index_name [-db DB_index_name2] -cpu cpus -type [blastp|blastn|tblastn|tblastx] -config config_file\n\n";
	print "\n################################################\n";
	print "This script splits fasta in as many cpus as stated and prints search commands into a file using several queues...\n";
	print "Multiples DBs could be provided separated\n\n";
}

sub time_log {	
	my $step_time_tmp = myModules::time_log($step_time); print "\n"; 
	$step_time = $$step_time_tmp;
}
