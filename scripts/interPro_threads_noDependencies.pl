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

my $chunks = int($cpus/4); ## get number of chunks 

print "##################################################\n";
print "InterPro functional annotation pipeline started...\n";
print "##################################################\n";

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
print "Make dir and change to ./interpro_annotation\n";
my $dir = "interpro_annotation";
mkdir $dir, 0755; chdir $dir;

my $ref_array_count = myModules::get_size($file);
my $block = int($ref_array_count/$chunks);
my $files_ref = myModules::fasta_file_splitter($file,$block,"fasta");

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Splitting file into multiple chunks...\n";
print "Spliting file into $chunks parts of $block bytes each...\n";
print "Stats for file: $file\n";
print "Chars: $ref_array_count\n";

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Sending commands:\n";
my $file_OUT = "interpro_threads_commands_sent.txt";
print "Printing commands into $file_OUT\n";
open (OUT, ">$file_OUT");
my @ids2wait;
my @files = @{$files_ref};
for (my $i=0; $i < scalar @files; $i++) {
	
	## just to equally fill hercules
	my $random_number = int(rand(10));
	my $name = "InterPro".$i;

	my $hercules_queue = $configuration{"GRID_QUEUE"}[rand @{ $configuration{"GRID_QUEUE"} }]; ## get random queue
	$hercules_queue .= " 4 -N $name -cwd -V -b y ";
	print "Sending command for: $files[$i]\n";
	my $interpro = $configuration{"INTERPRO"}[0];
	
	my $command = $hercules_queue." $interpro -i ".$files[$i]." -appl TIGRFAM,SFLD,SUPERFAMILY,Gene3D,Hamap,Coils,ProSiteProfiles,SMART,PRINTS,ProSitePatterns,Pfam,ProDom,MobiDBLite,PIRSF -b $name -pa -dp -goterms";
	print OUT $command."\n";
	my $call_id = myModules::sending_command($command);
	push (@ids2wait, $call_id);
}
close (OUT);
## waiting to finish all 
myModules::waiting(\@ids2wait);
print "##################################################\n";
print "\tInterPro annotation pipeline finished...\n";
print "##################################################\n";

sub print_help {
	print "\n################################################\n";
	print "\tINTERPRO call for multiple threads\n";
	print "################################################\n";
	print "USAGE:\nperl $0\n\t-file fasta_file\n\t-cpus int\n\t-config -file\n\n";
	print "This script splits fasta in as many chunks as stated (cpus/4) and sends InterPro into hercules queue(s) provided...\n\n";
	print "Each process will be using:\n\t4 CPUs,\n\t-pa -dp -goterms\n\t-appl TIGRFAM,SFLD,SUPERFAMILY,PANTHER,Gene3D,Hamap,Coils,ProSiteProfiles,SMART,PRINTS,ProSitePatterns,Pfam,ProDom,MobiDBLite,PIRSF\n\n";
	print "\n################################################\n";
	exit();	
}


__END__

## RPSBLAST was given an error and CDD was discarded
## option CPU was providing an error too and do not let the interpro to finish, so we modify interproscan.properties file


Available analyses:
                      TIGRFAM (15.0) : TIGRFAMs are protein families based on Hidden Markov Models or HMMs
                         SFLD (3) : SFLDs are protein families based on Hidden Markov Models or HMMs
                  SUPERFAMILY (1.75) : SUPERFAMILY is a database of structural and functional annotation for all proteins and genomes.
                      PANTHER (12.0) : The PANTHER (Protein ANalysis THrough Evolutionary Relationships) Classification System is a unique resource that classifies genes by their functions, using published scientific experimental evidence and evolutionary relationships to predict function even in the absence of direct experimental evidence.
                       Gene3D (4.1.0) : Structural assignment for whole genes and genomes using the CATH domain structure database
                        Hamap (2017_10) : High-quality Automated and Manual Annotation of Microbial Proteomes
                        Coils (2.2.1) : Prediction of Coiled Coil Regions in Proteins
              ProSiteProfiles (2017_09) : PROSITE consists of documentation entries describing protein domains, families and functional sites as well as associated patterns and profiles to identify them
                        SMART (7.1) : SMART allows the identification and analysis of domain architectures based on Hidden Markov Models or HMMs
                          CDD (3.16) : Prediction of CDD domains in Proteins 
                       PRINTS (42.0) : A fingerprint is a group of conserved motifs used to characterise a protein family
              ProSitePatterns (2017_09) : PROSITE consists of documentation entries describing protein domains, families and functional sites as well as associated patterns and profiles to identify them
                         Pfam (31.0) : A large collection of protein families, each represented by multiple sequence alignments and hidden Markov models (HMMs)
                       ProDom (2006.1) : ProDom is a comprehensive set of protein domain families automatically generated from the UniProt Knowledge Database.
                   MobiDBLite (1.0) : Prediction of disordered domains Regions in Proteins
                        PIRSF (3.02) : The PIRSF concept is being used as a guiding principle to provide comprehensive and non-overlapping clustering of UniProtKB sequences into a hierarchical order to reflect their evolutionary relationships.

Deactivated analyses:
                        TMHMM (2.0c) : Analysis TMHMM is deactivated, because the resources expected at the following paths do not exist: bin/tmhmm/2.0c/decodeanhmm, data/tmhmm/2.0c/TMHMM2.0c.model
        SignalP_GRAM_POSITIVE (4.1) : Analysis SignalP_GRAM_POSITIVE is deactivated, because the resources expected at the following paths do not exist: bin/signalp/4.1/signalp
        SignalP_GRAM_NEGATIVE (4.1) : Analysis SignalP_GRAM_NEGATIVE is deactivated, because the resources expected at the following paths do not exist: bin/signalp/4.1/signalp
                  SignalP_EUK (4.1) : Analysis SignalP_EUK is deactivated, because the resources expected at the following paths do not exist: bin/signalp/4.1/signalp
                      Phobius (1.01) : Analysis Phobius is deactivated, because the resources expected at the following paths do not exist: bin/phobius/1.01/phobius.pl


The TSV format presents the match data in columns as follows:

1) Protein Accession (e.g. P51587)
2) Sequence MD5 digest (e.g. 14086411a2cdf1c4cba63020e1622579)
3) Sequence Length (e.g. 3418)
4) Analysis (e.g. Pfam / PRINTS / Gene3D)
5) Signature Accession (e.g. PF09103 / G3DSA:2.40.50.140)
6) Signature Description (e.g. BRCA2 repeat profile)
7) Start location
8) Stop location
9) Score - is the e-value (or score) of the match reported by member database method (e.g. 3.1E-52)
10) Status - is the status of the match (T: true)
11) Date - is the date of the run
12) (InterPro annotations - accession (e.g. IPR002093) - optional column; only displayed if -iprlookup option is switched on)
13) (InterPro annotations - description (e.g. BRCA2 repeat) - optional column; only displayed if -iprlookup option is switched on)
14) (GO annotations (e.g. GO:0005515) - optional column; only displayed if --goterms option is switched on)
15) (Pathways annotations (e.g. REACT_71) - optional column; only displayed if --pathways option is switched on)



