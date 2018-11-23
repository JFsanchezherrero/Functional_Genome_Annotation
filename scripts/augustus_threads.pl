#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib $FindBin::Bin."/lib";
require myModules;

### Get Options
my ($file, $cpus, $config_file, $hints_file, $augustus_species, $help);
GetOptions( 
	"file=s" => \$file,
	"cpu=i" => \$cpus,
	"config=s" => \$config_file,
	"hints=s" => \$hints_file,
	"sp=s" => \$augustus_species,
	"h|help" => \$help,
);
if (!$file || !$config_file || !$cpus) { &print_help(); exit();}
if ($help) {&print_help(); exit();}

## START
print "\n####################################################################################\n";
print "\nStarting pipeline for generating an annotation with augustus for the given genome\n";
print "\n####################################################################################\n";

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

# read config file
print "Make dir and change to ./augustus_annotation\n";
my $dir = "augustus_annotation";
mkdir $dir, 0755; chdir $dir;

##
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
my $ref_array_count = myModules::get_size($file);
print "+ Splitting file into multiple chunks...\n";
print "Stats for file: $file\n";
print "Chars: $ref_array_count\n";
my $block = int($ref_array_count/$cpus);
my $files_ref = myModules::fasta_file_splitter($file, $block, "fasta");
my @files = @{$files_ref};
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
my $additional ="";
if ($hints_file) { $additional = " --hintsfile=$hints_file";}
if (!$augustus_species) {$augustus_species= "fly"}

print "+ Sending commands:\n";
my $file_OUT = "augustus_threads_commands_sent.txt";
print "Printing commands into $file_OUT\n";
open (OUT, ">$file_OUT");
my (@ids2wait, @results_files, @discard_files, @error_files);
for (my $i=0; $i < scalar @files; $i++) {
	my $augustus_path = $configuration{"AUGUSTUS"}[0]."bin/augustus";
	my $hercules_queue = $configuration{"GRID_QUEUE"}[rand @{ $configuration{"GRID_QUEUE"} }]; ## get random queue
	my $augustus_call = "$hercules_queue 1 -cwd -V -N augustus_$i -b y $augustus_path --gff3=on".$additional." --species=$augustus_species $files[$i]";
	print OUT $augustus_call."\n";
	my $call_id = myModules::sending_command($augustus_call);
	push (@ids2wait, $call_id);

	## get files generated
	my $out = "augustus_".$i.".o".$call_id;
	my $out_e = "augustus_".$i.".e".$call_id;
	my $out_po = "augustus_".$i.".po".$call_id;
	my $out_pe = "augustus_".$i.".pe".$call_id;
	push (@discard_files, $out_po);	push (@discard_files, $out_pe);	
	push (@results_files, $out); push (@error_files, $out_e);

}
close (OUT);
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
## waiting to finish all 
myModules::waiting(\@ids2wait);
print "\n";

### Keep folder tidy
print "+ Cleaning folder and discarding tmp files\n"; mkdir "tmp", 0755;
my $error_log = "error.log";
my $final_tmp_file = "concat_tmp_maker_output.gff3";
for (my $i=0; $i < scalar @results_files; $i++) {
	system("cat $results_files[$i] >> $final_tmp_file");	
	system("mv $results_files[$i] ./tmp"); system("mv $files[$i] ./tmp");
	system("cat $error_files[$i] >> $error_log"); system("mv $error_files[$i] ./tmp"); 
}
for (my $i=0; $i < scalar @discard_files; $i++) { system("rm $discard_files[$i]"); }
system("mv info_*txt ./tmp");

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Fixing gene ids generated\n";
my $final_file = "concat_maker_output_fixed.gff3";
open (FIN, ">$final_file");
my $gene_counter = 0; my $id;
open (GFF, "<$final_tmp_file");
while (<GFF>) {
	if ($_ =~ /^\#/) {print FIN $_; next;}
	if ($_ =~ /^\s+/) {print FIN $_; next;} 
	chomp;
	my @array = split("\t", $_);
	if ($array[-1] =~ /ID\=(g\d+)$/) {
		$id = $1; $gene_counter++;
	}
	my $new = "g".$gene_counter;
	for (my $i = 0; $i < $#array; $i++) {
		print FIN $array[$i]."\t";
	}
	my $id_line = $array[-1];
	$id_line =~ s/$id/$new/g;
	#print "OLD: ".$_."\n";
	print FIN $id_line."\n";	
}
close (GFF); close (FIN);
print "Finishing annotation...\n";
print "Check for temporal files in tmp folder generated, for final results in $final_file and for putative errors in error.log files...\n";

print "##################################################\n";
print "\tAugustus annotation pipeline finished...\n";
print "##################################################\n";


sub print_help {
	print "\n################################################\n";
	print "\tAUGUSTUS call for multiple threads\n";
	print "################################################\n";
	print "USAGE:\nperl $0\n\t-file fasta_file\n\t-cpu int\n\t-config config_file\n\t[-hints hints_file -sp augustus_species] [-h|--help]\n\n";
	print "This script splits fasta in as many cpus as stated and sends via Grid Engine augustus commands using the queue(s) provided...\n";	
	print "\n\n";
}

