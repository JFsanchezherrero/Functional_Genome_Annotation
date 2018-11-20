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
print "Make dir and change to ./maker_annotation\n";
my $dir = "maker_annotation";
mkdir $dir, 0755; chdir $dir;

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
my $file_OUT = "maker_threads_commands_sent.txt";
print "Printing commands into $file_OUT\n";

my $maker_path = $configuration{"MAKER"}[0];
open (OUT, ">$file_OUT");
my @ids2wait; my @files = @{$files_ref};
for (my $i=0; $i < scalar @files; $i++) {
	
	my $hercules_queue = $configuration{"GRID_QUEUE"}[rand @{ $configuration{"GRID_QUEUE"} }]; ## get random queue
	my $name = "maker_".$i;
	$hercules_queue .= " 2 -N $name -cwd -V -b y ";
	print "Sending command for: $files[$i]\n";

	## just to equally fill hercules
	my $random_number = int(rand(10));
	my $grid_engine_queue;

	print "Sending command for: $files[$i]\n";
	my $command = $hercules_queue." ".$maker_path."/bin/maker -g ".$files[$i]." -b annotation";
	print OUT $command."\n";	

	my $call_id = myModules::sending_command($command);
	push (@ids2wait, $call_id);

	## only for the first command	
	if ($i == 0) { 
		print OUT "sleep 100\n";
		sleep(100);  ## send the first command and let it set folders and databases	
	} else { 
        print OUT "sleep 40\n";
		sleep(10);
	}
}
close (OUT);
## waiting to finish all 
myModules::waiting(\@ids2wait);
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
#for (my $i=0; $i < scalar @results_files; $i++) { system("rm $files[$i]"); }

## -dsindex and finish
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "DSINDEX command:\n";
my $command = $maker_path."/bin/maker -b annotation -g $file -dsindex";
system($command);

##merge
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "gff3 merge command:\n";
my $command_merge = $maker_path."/bin/gff3_merge -d ./annotation.maker.output/annotation_master_datastore_index.log";
system($command_merge);

## get proteins merge
print "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
print "fasta merge command:\n";
my $command_fasta_merge = $maker_path."/bin/fasta_merge -d ./annotation.maker.output/annotation_master_datastore_index.log";
system($command_fasta_merge);

sub print_help {
	print "\n################################################\n";
	print "Usage:\nperl $0\n\t-file fasta_file\n\t-cpus int\n\t-config -file";
	print "\n################################################\n";
	print "This script splits fasta in as many chunks (cpu/2) as stated and sends Maker Annotation Pipeline using several queues...\n\n";
	print "Maker control files must be set in the folder where the command is sent. Use 2 CPUs.\n\n\n";
	print "################################################\n";
	exit();	
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
