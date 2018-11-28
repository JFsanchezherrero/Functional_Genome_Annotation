#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use POSIX qw(strftime); #my $datestring = strftime "%Y%m%d%H%M", localtime;
my $step_time; my $start_time = $step_time = time;

use FindBin;
use lib $FindBin::Bin."/lib";
require myModules;

### Get Options
my ($file, $cpus, $name, $config_file, $help, $maker_ctl_files);
GetOptions( 
	"file=s" => \$file,
	"cpu=i" => \$cpus,
	"config=s" => \$config_file,
	"name=s" => \$name,
	"h|help" => \$help,
	"maker_ctl_file=s" => \$maker_ctl_files
);
if (!$file || !$config_file || !$maker_ctl_files || !$cpus) { &print_help(); exit();}
if ($help) {&print_help(); exit();}

if ($help) {&print_help(); exit();}

print "########################\n";
print "Maker annotation pipeline started...\n";
print "########################\n";

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
my $dir = "maker_annotation_".$name;
print "Make dir and change to $dir\n";
mkdir $dir, 0755; chdir $dir;

my $files2cp = $maker_ctl_files."/maker_*ctl";
system ("cp $files2cp .");

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Splitting file into multiple chunks...\n";
my $ref_array_count = myModules::get_size($file);
my $chunks = int($cpus/2); my $block = int($ref_array_count/$chunks);
my $files_ref = myModules::fasta_file_splitter($file,$block,"fasta");
print "Spliting file into $chunks parts of $block bytes each...\n";
print "Stats for file: $file\n";
print "Chars: $ref_array_count\n";
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";

print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "+ Sending commands:\n";
my $file_OUT = "maker_".$name."_commands_sent.txt";
print "Printing commands into $file_OUT\n";

my $maker_path = $configuration{"MAKER"}[0];
open (OUT, ">$file_OUT");

my (@ids2wait, @results_files, @discard_files, @error_files);
my @files = @{$files_ref};
for (my $i=0; $i < scalar @files; $i++) {
	
	my $hercules_queue = $configuration{"GRID_QUEUE"}[rand @{ $configuration{"GRID_QUEUE"} }]; ## get random queue
	my $name = "maker_".$i;
	$hercules_queue .= " 2 -N $name -cwd -V -b y ";
	print "Sending command for: $files[$i]\n";
	my $command = $hercules_queue." ".$maker_path."/maker -g ".$files[$i]." -b annotation";
	print OUT $command."\n";	
	
	my $call_id = myModules::sending_command($command);
	push (@ids2wait, $call_id);

	## only for the first command	
	if ($i == 0) { 
		print OUT "sleep 100\n"; sleep(100);  ## send the first command and let it set folders and databases	
	} else { 
        print OUT "sleep 40\n"; sleep(40);
	}
	
	## get files generated
	my $out = "maker_".$i.".o".$call_id;
	my $out_e = "maker_".$i.".e".$call_id;
	my $out_po = "maker_".$i.".po".$call_id;
	my $out_pe = "maker_".$i.".pe".$call_id;
	push (@discard_files, $out_po);	push (@discard_files, $out_pe);	
	push (@results_files, $out); push (@error_files, $out_e);
}
close (OUT);
## waiting to finish all 
myModules::waiting(\@ids2wait);
print "\n";

### Keep folder tidy
print "+ Cleaning folder and discarding tmp files\n"; mkdir "tmp", 0755;
my $error_log = "error.log";
#my $final_tmp_file = "concat_tmp_maker_output.gff3";
for (my $i=0; $i < scalar @results_files; $i++) {
	#system("cat $results_files[$i] >> $final_tmp_file");	
	system("mv $results_files[$i] ./tmp"); system("mv $files[$i] ./tmp");
	system("cat $error_files[$i] >> $error_log"); system("mv $error_files[$i] ./tmp"); 
}
for (my $i=0; $i < scalar @discard_files; $i++) { system("rm $discard_files[$i]"); }
system("mv info_*txt ./tmp");
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";

## -dsindex and finish
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "DSINDEX command:\n";
my $command = $maker_path."/maker -b annotation -g $file -dsindex";
system($command);

##merge
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "gff3 merge command:\n";
my $command_merge = $maker_path."/gff3_merge -d ./annotation.maker.output/annotation_master_datastore_index.log";
system($command_merge);

## get proteins merge
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "fasta merge command:\n";
my $command_fasta_merge = $maker_path."/fasta_merge -d ./annotation.maker.output/annotation_master_datastore_index.log";
system($command_fasta_merge);

myModules::finish_time_stamp($start_time);


sub print_help {
	print "\n################################################\n";
	print "Usage:\nperl $0\n\t-file fasta_file\n\t-cpu int\n\t-config file -maker_ctl_file path";
	print "\n################################################\n";
	print "This script splits fasta in as many chunks (cpu/2) as stated and sends Maker Annotation Pipeline using several queues...\n\n";
	print "Maker control files must be set in the folder specified at maker_ctl_fikes option. Set to use 2 CPUs.\n\n\n";
	print "################################################\n";
}

sub time_log {	
	my $step_time_tmp = myModules::time_log($step_time); print "\n"; 
	$step_time = $$step_time_tmp;
}


__END__

## website: https://groups.google.com/forum/#!topic/maker-devel/PMz5A8cnMEk

Dear Maker-developers 

If i understood correctly, in order to increase speed and reduce needed resources 
one can split the genome into chunks and annotate each chunk separately. 
I would really like to use that as i am working with a 1.2 Gbasepair draftgenome 
and cant use MPI on the computing cluster.
I am a bit worried about how this might affect the annotation as the gene-predictor 
would get trained quite differently for each chunk, right? 

Or is there communication between the chunks using the -base function of maker? 
Could you maybe name some pros and cons of splitting your genome for the annotation with maker? 

Thank you very much, 
Michel 


####################

Michel,

It is about the size of your scaffolds rather than the whole genome. Presumably you don't 
have 1.2 Gb of contiguous sequence. If you have long scaffolds then the compute time will 
be constrained by the time taken to process the largest scaffold. 

regards
Dan

####################

Correct.  The level of splitting is going to be limited by the largest config.  

The largest config will then be your slowest job, but the total runtime will be based off 
how much splitting you can achieve.  Splitting into 10 jobs and running them all 
simultaneously will make total run time 1/10 as long.  

You can use the –base flag with MAKER to make all jobs write to the same directory.  
Use the –g flag to specify a different input fasta file for each job (then they can all 
share the same control files).  

You will then need to run maker once using the original assembly fasta and the –dsindex 
flag when all jobs complete to get MAKER to clean up the datastore log file 
(rebuilt to index all contigs). That only takes 2 minutes to run.

You can use the fasta_tool utility that comes with MAKER to conveniently split the input assembly fasta.  
MAKER does not train the gene predictors for you, and the hints it gives are on a per gene basis, 
so splitting contigs has no affect on that.  

For initial training of gene predictors, run MAKER on about 10-30 Mb of your largest contigs 
and use either the protein2genome or est2genome prediction options to build gene models 
to train the predictors on.  

You will need to train Augustus or SNAP yourself using those models and their own documentation.  

If training SNAP, you can use maker2zff to convert for SNAPs training format.  
You can also use the tool CEGMA from Ian Korf's lab to train SNAP. 

Use the cegma2zff script that comes with MAKER to do the conversion for training input.

If you have questions once you start training, just send them to the list.

Thanks,
Carson



MAKER:
Options:

     -genome|g <file>    Overrides the genome file path in the control files
     
     -RM_off|R           Turns all repeat masking options off.
     
     -datastore/         Forcably turn on/off MAKER's two deep directory
      nodatastore        structure for output.  Always on by default.

     -old_struct         Use the old directory styles (MAKER 2.26 and lower)

     -base    <string>   Set the base name MAKER uses to save output files.
                         MAKER uses the input genome file name by default.

     -tries|t <integer>  Run contigs up to the specified number of tries.

     -cpus|c  <integer>  Tells how many cpus to use for BLAST analysis.
                         Note: this is for BLAST and not for MPI!

     -force|f            Forces MAKER to delete old files before running again.
			 This will require all blast analyses to be rerun.

     -again|a            recaculate all annotations and output files even if no
			 settings have changed. Does not delete old analyses.

     -quiet|q            Regular quiet. Only a handlful of status messages.

     -qq                 Even more quiet. There are no status messages.

     -dsindex            Quickly generate datastore index file. Note that this
                         will not check if run settings have changed on contigs

     -nolock             Turn off file locks. May be usful on some file systems,
                         but can cause race conditions if running in parallel.

     -TMP                Specify temporary directory to use.
     -CTL                Generate empty control files in the current directory.
     -OPTS               Generates just the maker_opts.ctl file.
     -BOPTS              Generates just the maker_bopts.ctl file.
     -EXE                Generates just the maker_exe.ctl file.

     -MWAS    <option>   Easy way to control mwas_server for web-based GUI

                              options:  STOP
                                        START
                                        RESTART

     -version            Prints the MAKER version.
     -help|?             Prints this usage statement.




##########################
maker_bopts.ctl 
##########################

#-----BLAST and Exonerate Statistics Thresholds
blast_type=ncbi+ #set to 'ncbi+', 'ncbi' or 'wublast'

pcov_blastn=0.8 #Blastn Percent Coverage Threhold EST-Genome Alignments
pid_blastn=0.85 #Blastn Percent Identity Threshold EST-Genome Aligments
eval_blastn=1e-10 #Blastn eval cutoff
bit_blastn=40 #Blastn bit cutoff
depth_blastn=0 #Blastn depth cutoff (0 to disable cutoff)

pcov_blastx=0.5 #Blastx Percent Coverage Threhold Protein-Genome Alignments
pid_blastx=0.4 #Blastx Percent Identity Threshold Protein-Genome Aligments
eval_blastx=1e-06 #Blastx eval cutoff
bit_blastx=30 #Blastx bit cutoff
depth_blastx=0 #Blastx depth cutoff (0 to disable cutoff)

pcov_tblastx=0.8 #tBlastx Percent Coverage Threhold alt-EST-Genome Alignments
pid_tblastx=0.85 #tBlastx Percent Identity Threshold alt-EST-Genome Aligments
eval_tblastx=1e-10 #tBlastx eval cutoff
bit_tblastx=40 #tBlastx bit cutoff
depth_tblastx=0 #tBlastx depth cutoff (0 to disable cutoff)

pcov_rm_blastx=0.5 #Blastx Percent Coverage Threhold For Transposable Element Masking
pid_rm_blastx=0.4 #Blastx Percent Identity Threshold For Transposbale Element Masking
eval_rm_blastx=1e-06 #Blastx eval cutoff for transposable element masking
bit_rm_blastx=30 #Blastx bit cutoff for transposable element masking

ep_score_limit=20 #Exonerate protein percent of maximal score threshold
en_score_limit=20 #Exonerate nucleotide percent of maximal score threshold

##########################
maker_opts.ctl 
##########################

#-----Genome (these are always required)
genome= #genome sequence (fasta file or fasta embeded in GFF3 file)
organism_type=eukaryotic #eukaryotic or prokaryotic. Default is eukaryotic

#-----Re-annotation Using MAKER Derived GFF3
maker_gff= #MAKER derived GFF3 file
est_pass=0 #use ESTs in maker_gff: 1 = yes, 0 = no
altest_pass=0 #use alternate organism ESTs in maker_gff: 1 = yes, 0 = no
protein_pass=0 #use protein alignments in maker_gff: 1 = yes, 0 = no
rm_pass=0 #use repeats in maker_gff: 1 = yes, 0 = no
model_pass=0 #use gene models in maker_gff: 1 = yes, 0 = no
pred_pass=0 #use ab-initio predictions in maker_gff: 1 = yes, 0 = no
other_pass=0 #passthrough anyything else in maker_gff: 1 = yes, 0 = no

#-----EST Evidence (for best results provide a file for at least one)
est= #set of ESTs or assembled mRNA-seq in fasta format
altest= #EST/cDNA sequence file in fasta format from an alternate organism
est_gff= #aligned ESTs or mRNA-seq from an external GFF3 file
altest_gff= #aligned ESTs from a closly relate species in GFF3 format

#-----Protein Homology Evidence (for best results provide a file for at least one)
protein=  #protein sequence file in fasta format (i.e. from mutiple oransisms)
protein_gff=  #aligned protein homology evidence from an external GFF3 file

#-----Repeat Masking (leave values blank to skip repeat masking)
model_org=all #select a model organism for RepBase masking in RepeatMasker
rmlib= #provide an organism specific repeat library in fasta format for RepeatMasker
repeat_protein=/users/jfsanchez/JFSH_software/ANNOTATION/maker/data/te_proteins.fasta #provide a fasta file of transposable element proteins for RepeatRunner
rm_gff= #pre-identified repeat elements from an external GFF3 file
prok_rm=0 #forces MAKER to repeatmask prokaryotes (no reason to change this), 1 = yes, 0 = no
softmask=1 #use soft-masking rather than hard-masking in BLAST (i.e. seg and dust filtering)

#-----Gene Prediction
snaphmm= #SNAP HMM file
gmhmm= #GeneMark HMM file
augustus_species= #Augustus gene prediction species model
fgenesh_par_file= #FGENESH parameter file
pred_gff= #ab-initio predictions from an external GFF3 file
model_gff= #annotated gene models from an external GFF3 file (annotation pass-through)
est2genome=0 #infer gene predictions directly from ESTs, 1 = yes, 0 = no
protein2genome=0 #infer predictions from protein homology, 1 = yes, 0 = no
trna=0 #find tRNAs with tRNAscan, 1 = yes, 0 = no
snoscan_rrna= #rRNA file to have Snoscan find snoRNAs
unmask=0 #also run ab-initio prediction programs on unmasked sequence, 1 = yes, 0 = no

#-----Other Annotation Feature Types (features MAKER doesn't recognize)
other_gff= #extra features to pass-through to final MAKER generated GFF3 file

#-----External Application Behavior Options
alt_peptide=C #amino acid used to replace non-standard amino acids in BLAST databases
cpus=1 #max number of cpus to use in BLAST and RepeatMasker (not for MPI, leave 1 when using MPI)

#-----MAKER Behavior Options
max_dna_len=100000 #length for dividing up contigs into chunks (increases/decreases memory usage)
min_contig=1 #skip genome contigs below this length (under 10kb are often useless)

pred_flank=200 #flank for extending evidence clusters sent to gene predictors
pred_stats=0 #report AED and QI statistics for all predictions as well as models
AED_threshold=1 #Maximum Annotation Edit Distance allowed (bound by 0 and 1)
min_protein=0 #require at least this many amino acids in predicted proteins
alt_splice=0 #Take extra steps to try and find alternative splicing, 1 = yes, 0 = no
always_complete=0 #extra steps to force start and stop codons, 1 = yes, 0 = no
map_forward=0 #map names and attributes forward from old GFF3 genes, 1 = yes, 0 = no
keep_preds=0 #Concordance threshold to add unsupported gene prediction (bound by 0 and 1)

split_hit=10000 #length for the splitting of hits (expected max intron size for evidence alignments)
single_exon=0 #consider single exon EST evidence when generating annotations, 1 = yes, 0 = no
single_length=250 #min length required for single exon ESTs if 'single_exon is enabled'
correct_est_fusion=0 #limits use of ESTs in annotation to avoid fusion genes

tries=2 #number of times to try a contig if there is a failure for some reason
clean_try=0 #remove all data from previous run before retrying, 1 = yes, 0 = no
clean_up=0 #removes theVoid directory with individual analysis files, 1 = yes, 0 = no
TMP= #specify a directory other than the system default temporary directory for temporary files

##########################
cat maker_exe.ctl 
##########################

#-----Location of Executables Used by MAKER/EVALUATOR
makeblastdb=/soft/ncbi-blast-2.4.0/bin/makeblastdb #location of NCBI+ makeblastdb executable
blastn=/soft/ncbi-blast-2.4.0/bin/blastn #location of NCBI+ blastn executable
blastx=/soft/ncbi-blast-2.4.0/bin/blastx #location of NCBI+ blastx executable
tblastx=/soft/ncbi-blast-2.4.0/bin/tblastx #location of NCBI+ tblastx executable
formatdb= #location of NCBI formatdb executable
blastall= #location of NCBI blastall executable
xdformat= #location of WUBLAST xdformat executable
blasta= #location of WUBLAST blasta executable
RepeatMasker=/users/jfsanchez/JFSH_software/RepeatSearch/RepeatMasker/RepeatMasker/RepeatMasker #location of RepeatMasker executable
exonerate=/users/jfsanchez/JFSH_software/ANNOTATION/exonerate-2.2.0-x86_64/bin/exonerate #location of exonerate executable

#-----Ab-initio Gene Prediction Algorithms
snap=/users/jfsanchez/JFSH_software/ANNOTATION/snap-2013-11-29/snap #location of snap executable
gmhmme3=/users/jfsanchez/JFSH_software/ANNOTATION/genemark/gm_et_linux_64/gmes_petap/gmhmme3 #location of eukaryotic genemark executable
gmhmmp= #location of prokaryotic genemark executable
augustus=/users/jfsanchez/JFSH_software/AUGUSTUS/augustus-3.1/bin/augustus #location of augustus executable
fgenesh= #location of fgenesh executable
tRNAscan-SE=/users/jfsanchez/JFSH_software/ANNOTATION/tRNAscan-SE-1.3.1/bin/tRNAscan-SE #location of trnascan executable
snoscan=/users/jfsanchez/JFSH_software/ANNOTATION/snoscan-0.9.1/bin/snoscan #location of snoscan executable

#-----Other Algorithms
probuild=/users/jfsanchez/JFSH_software/ANNOTATION/genemark/gm_et_linux_64/gmes_petap/probuild #location of probuild executable (required for genemark)