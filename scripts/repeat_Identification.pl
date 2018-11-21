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
	"h|help" => \$help,
);
if (!$file || !$config_file || !$cpus) { &print_help(); exit();}
if ($help) {&print_help(); exit();}

## START
print "\n####################################################################################\n";
print "\nStarting pipeline for the identification of repeats in the given genome\n";
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

# read config file
print "Make dir and change to ./repeat_annotation\n";
my $dir = "repeat_annotation";
mkdir $dir, 0755; chdir $dir;

my $dir2 = "RepeatModeler";
mkdir $dir2, 0755; chdir $dir2;

## paths
my $repeatmodeler_database = $configuration{"RepeatModeler"}[0]."BuildDatabase";
my $hercules_queue = $configuration{"GRID_QUEUE"}[0]; ## get random queue

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Generate a database for the given genome\n";
## Create RepeatModeler Database
my @ids2wait;
my $buildDatabase_command = "$hercules_queue 1 -cwd -V -N buildDB -b y $repeatmodeler_database -name myGenomeDB -engine ncbi $file";
#print "Command: $buildDatabase_command\n";
my $call_id = myModules::sending_command($buildDatabase_command);
push (@ids2wait, $call_id);
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
myModules::waiting(\@ids2wait); ## waiting to finish all 

## Get repeat library for my data 
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Classify repeats for the given genome\n";
my $repeatmodeler_Search = $configuration{"RepeatModeler"}[0]."RepeatModeler";
my $repeatLib_command = "$hercules_queue $cpus -cwd -V -N repeatmodeler_Search -b y $repeatmodeler_Search -database myGenomeDB -pa $cpus -engine ncbi $file";
#print "Command: $repeatLib_command\n";
$call_id = myModules::sending_command($repeatLib_command); $ids2wait[0] = $call_id;
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
myModules::waiting(\@ids2wait); ## waiting to finish all 
print "\n";

#### RepeatMasker
chdir ".."; my @files_dir = @{ myModules::read_dir("./RepeatModeler") };
my $dir3 = "RepeatMasker"; mkdir $dir3, 0755; chdir $dir3;

## Get repeats.lib
my $repeats_lib;
for (my $i=0; $i < scalar @files_dir; $i++) {
	if ($files_dir[$i] =~ /^RM_/) {
		$repeats_lib = "../RepeatModeler/.".$files_dir[$i]."/consensi.fa.classified";	
	}
}

## RepeatMasker Search
my $repeatmasker_Search = $configuration{"RepeatMasker"}[0]."RepeatMasker";
my $repeatMasker_command = "$hercules_queue $cpus -cwd -V -N repeatmasker_Search -b y $repeatmasker_Search -x -e ncbi -pa $cpus -lib repeats.lib -gff $file";
print "Repeat Classification obtained: $repeats_lib\n";

if (-e -r -s $repeats_lib) {
	print "Copying $repeats_lib into repats.lib file\n";
	system("cp $repeats_lib repeats.lib");

} else {

	print "\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
	print "\nERROR: Either RepeatLib command or RepeatModeler database failed. Re-run commands:\n";
	print $buildDatabase_command."\n";
	print $repeatLib_command."\n";
	print "\nAnd look for consensi.fa.classified file within the RM_* folder generated and run RepeatMasker where repeats.lib is consensi.fa.classified\n";
	print $repeatMasker_command."\n";	
	exit();
}

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Identify and mask repeats for the genome\n";
#print "Command: $repeatMasker_command\n";
$call_id = myModules::sending_command($repeatMasker_command); $ids2wait[0] = $call_id;
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
myModules::waiting(\@ids2wait); ## waiting to finish all 
print "\n";


#######
my @files_dir2 = @{ myModules::read_dir(".") };
## Get repeats.lib
my $output_file; my $tbl_file;
for (my $i=0; $i < scalar @files_dir2; $i++) {
	if ($files_dir2[$i] =~ /.*out$/) {
		$output_file = $files_dir2[$i];	
	} elsif ($files_dir2[$i] =~ /.*tbl$/) {
		$tbl_file = $files_dir2[$i];	
	}
}

print "Statistics for RepeatMasker identification\n";
print "File: $tbl_file\n";
system("cat $tbl_file");

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Convert GFF file generated into GFF3 compatible file\n";
my $rmOutToGFF3 = $configuration{"rmOutToGFF3"}[0];
my $rmOutToGFF3_command = "$hercules_queue $cpus -cwd -V -N rmOutToGFF3 -b y perl $rmOutToGFF3 -database myGenomeDB -pa $cpus -engine ncbi $file";
#print "Command: $rmOutToGFF3_command\n";
$call_id = myModules::sending_command($$rmOutToGFF3_command); $ids2wait[0] = $call_id;
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
myModules::waiting(\@ids2wait); ## waiting to finish all 
print "\n";

print "##################################################\n";
print "Finish Repeat Identification...\n";
print "##################################################\n";

sub print_help {
	print "\n################################################\n";
	print "Usage:\nperl $0\n\t-file fasta_file\n\t-cpu int\n\t-config -file";
	print "\n################################################\n";
	print "This script generates a database and sends repeat identification search using RepeatModeler and RepeatMasker\n\n\n";
	print "ATTENTION:\n";
	print "+ Please check that RepBase and NCBI BLAST (RMBLAST version) are installed and accesible\n";
	print "################################################\n";
}
