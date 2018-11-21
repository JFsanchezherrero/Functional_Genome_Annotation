#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib $FindBin::Bin."/lib";
require myModules;

my ($file, $config_file, $nCPUs, $help, @busco_db, $augustus_species);
GetOptions( 
	"genome=s" => \$file,
	"cpu=i" => \$nCPUs,
	"h|help" => \$help,
	"busco_db=s" => \@busco_db,
	"config=s" => \$config_file,
	"sp=s" => \$augustus_species
);
if (!$file || !$config_file || !$nCPUs || !@busco_db ) { &print_help(); exit();}
if ($help) {&print_help(); exit();}

print "\n########################################################################\n";
print "\nStarting pipeline for checking the assembly statistics for the given genome\n";
print "\n########################################################################\n";

# read config file
my %configuration = %{ myModules::get_config_file( $config_file ) };
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Reading configuration file:\n";
foreach my $keys (sort keys %configuration) {
	my @array_files = @{ $configuration{$keys} };
	for (my $i=0; $i < scalar @array_files; $i++) {
		next if ($array_files[$i] eq ".");
		print "\t".$keys."\t".$array_files[$i]."\n";
}}
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n";

# read config file
print "Make dir and change to ./stats\n";
my $dir = "stats"; mkdir $dir, 0755; chdir $dir;

# send assembly stats
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Sending contig stats command:\n";
my $hercules_queue = $configuration{"GRID_QUEUE"}[0]; ## get first queue
my $contig_stats_perl = $configuration{"contig_stats"}[0]; ##
my $call_id = myModules::sending_command("$hercules_queue 1 -cwd -V -N assemblySTATS -b y perl $file");
print "+ Sending BUSCO(s) command for database(s) provided...\n";
my $number_db = scalar @busco_db;
my $cpus2use = int($nCPUs/$number_db);
if (!$augustus_species) {$augustus_species="fly"}
my @ids2wait;
for (my $i=0; $i < scalar @busco_db; $i++) {
	
	my $busco_bin = $configuration{"BUSCO"}[0];
	my @path = split("/", $busco_db[$i]);
	my $name_db = $path[-1];
	print "\tSending command for BUSCO db $name_db\n";
	my $name = "command_".$name_db."_buscoDB.sh";
		open (OUT, ">$name");
		print OUT "#! /bin/bash -x\n#\$ -cwd\n#\$ -V\n";
		print OUT "$busco_bin --blast_single_core --in $file --mode genome --out $name_db -l $busco_db[$i] -c $cpus2use -sp $augustus_species\n";
		close OUT;
	
	my $call_name = "BUSCO_".$name_db;
	$hercules_queue = $configuration{"GRID_QUEUE"}[0]; ## get first queue
	my $call_id = myModules::sending_command("$hercules_queue $cpus2use -cwd -V -N $call_name $name");
	push (@ids2wait, $call_id);
}
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
## waiting to finish all 
myModules::waiting(\@ids2wait);
print "Retrieve results and generate statistics\n";
print "Exit....\n";

print "##################################################\n";
print "\tStatistics pipeline finished...\n";
print "##################################################\n";

sub print_help {
    print "\n######################################################################################\n";
   	print "\tAssembly statistics call for file provided\n";
    print "######################################################################################\n";
    print "USAGE: perl $0\n\t-genome fasta\n\t-cpu int\n\t-config config_file\n\t-busco_db /path/to/BUSCO_db1\n\t-busco_db /path/to/BUSCO_db2\n\t[-sp augustus_species_model] [-h|--help]\n\n";    
    print "\nThis scripts calls multiple scripts and generates statistics for the given fasta file \n\n";
}