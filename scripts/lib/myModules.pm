#!/usr/bin/perl
use strict;
use warnings;
####################################################################
###	myModules: 
####################################################################
# This package provides multiple subroutines for the Functional Genome annotation pipeline
## date 12/11/18

package myModules;

sub waiting {

	$| = 1; ## Flush output after every print and do not wait until full

	my $id_ref = $_[0];
	for (my $j=0; $j < scalar @$id_ref; $j++) {
		my $id = $$id_ref[$j];
		my $file = "info_".$id.".txt";
		while (1) {
			my $out = system("qstat -j $id > $file");	
			my $finish;
			if (-z $file) { 
				print "\nFinish job $id\n"; last;
			} else { 
				print "."; sleep (15);
}}}}

sub get_job_id {	
	my $string = $_[0]; #Your job 57752 ("python") has been submitted
	my $id;
	if ($$string =~ /Your job (\d+) \(\".*/) { $id = $1 }
	return $id;
}

sub sending_command {

	my $command = $_[0];
	my $stage = $_[1];
	my $round = $_[2];
	
	my @id;
	print "\n\n## Command: $command\n##\n";
	my $string = `$command`;
        my $id = &get_job_id(\$string);
	return $id;
}

sub get_size {
	my $size = -s $_[0]; #To get only size
	return $size;
}

sub fasta_file_splitter {
	# Splits fasta file and takes into account to add the whole sequence if it is broken
	my $file = $_[0];
	my $block = $_[1];
	my $ext = $_[2]; # fasta, fastq, loci, fa

	open (FH, "<$file") or die "Could not open source file. $!";
	print "\t- Splitting file into blocks of $block characters aprox ...\n";
	my @file_name = split("/", $file);
	my $j = 0; my @files;
	while (1) {
		my $chunk;
	   	my @tmp = split ("\.".$ext, $file_name[-1]);
		my $block_file = $tmp[0]."_part-".$j."_tmp.".$ext;
		push (@files, $block_file);
		open(OUT, ">$block_file") or die "Could not open destination file";
		if (!eof(FH)) { read(FH, $chunk,$block);  
			if ($j > 0) { $chunk = ">".$chunk; }
			print OUT $chunk;
		} ## Print the amount of chars	
		if (!eof(FH)) { $chunk = <FH>; print OUT $chunk; } ## print the whole line if it is broken	
		if (!eof(FH)) { 
			$/ = ">"; ## Telling perl where a new line starts
			$chunk = <FH>; chop $chunk; print OUT $chunk; 
			$/ = "\n";
		} ## print the sequence if it is broken
		$j++; close(OUT); last if eof(FH);
	}
	close(FH);
	return (\@files);
}

sub get_seq_sizes {
	
	my $file = $_[0];
	
	my $out = $file."_sizes";
	my $hash_size = &readFASTA_hashLength(\$file);
	open (OUT, ">$out");
	foreach my $keys (keys %{$hash_size}) {
		print OUT $$hash_size{$keys}."\t".$keys."\n";
	}
	close (OUT);
	return $out;	
}

sub file_splitter {
	
	my $file = $_[0];
	my $block = $_[1];
	my $ext = $_[2]; # fasta, fastq, loci, fa
	
	my @files;
	
	# Splits a file such a sam or whatever file that could be read for each line
	open (FH, "<$file") or die "Could not open file $file [DOMINO.pm:file_splitter]";
	print "+ Splitting file $file into blocks of $block characters...\n";
	my $j = 0; 
	while (1) {
    	my $chunk;
    	my @tmp = split (".".$ext, $file);
		my $file_name = $tmp[0];
		
	   	my $block_file = $file_name."_part-".$j."_tmp.".$ext;
		print "\t- Printing file: ".$block_file."\n";
    	push (@files, $block_file);
    	open(OUT, ">$block_file") or die "Could not open destination file [DOMINO.pm:file_splitter]";
    	$j++;
    	if (!eof(FH)) { read(FH, $chunk,$block);  print OUT $chunk; } ## Print the amount of chars
    	if (!eof(FH)) { $chunk = <FH>; print OUT $chunk; } ## print the whole line if it is broken
    	close(OUT); last if eof(FH);
	}
	close(FH);
	return (\@files);	
}

sub readFASTA_hash {

	my $file = $_[0];
	my %hash;
	open(FILE, $file) || die "Could not open the $file ...\n";
	$/ = ">"; ## Telling perl where a new line starts
	while (<FILE>) {		
		next if /^#/ || /^\s*$/;
		chomp;
    	my ($titleline, $sequence) = split(/\n/,$_,2);
    	next unless ($sequence && $titleline);
    	chop $sequence;
    	$hash{$titleline} = $sequence;
	}
	close(FILE); $/ = "\n";
	my $hashRef = \%hash;
	return $hashRef;
}

sub readFASTA_hashLength {

	my $file = $_[0];
	my %hash;
	my $counter;
	my $message;
	open(FILE, $file) || die "Could not open the $file ...\n";
	$/ = ">"; ## Telling perl where a new line starts
	while (<FILE>) {		
		next if /^#/ || /^\s*$/;
		chomp;
    	my ($titleline, $sequence) = split(/\n/,$_,2);
    	next unless ($sequence && $titleline);
    	$titleline =~ s/ /\t/g;
    	my @array_titleline = split("\t",$titleline);    	
		chomp $sequence;
		$sequence =~ s/\s+//g;
		$sequence =~ s/\r//g;
		$titleline =~ s/\r//g;
   		my $size = length($sequence);
	   	$hash{$array_titleline[0]} = $size;
	   	$counter++;
	   	
   		my $length;
   		my $same_counter = 0;
	   	if ($counter == 10) {
	   		my @ids = keys %hash;
			for (my $j=0; $j < scalar @ids; $j++) {
				if ($hash{$ids[0]} == $hash{$ids[$j]}) {
					$length = $hash{$ids[$j]}; $same_counter++;
		}}}
		## There is no need to continue if all the reads are the same
		if ($same_counter > 5) { 
			$message = "Fixed size for reads in $file -- $length";
			my %return = ("UNDEF" => $length); 
			return (\%return, $message); 
		} 
	}
	close(FILE); $/ = "\n"; 
	$message = "Different sequence lengths";
	return (\%hash, $message);
}

sub get_number_lines {
	my $file = $_[0];
	my $n=0;
	open (F, "$file");
	while(<F>) {
		$n++;
	}
	close(F);
	return $n;
}

sub read_dir {
	my $dir = $_[0];
	opendir(DIR, $dir);
	my @dir_files = readdir(DIR);
	my $array_ref = \@dir_files;
	return $array_ref;
}

sub get_config_file {
	my $file = $_[0];
	
	my %config;
	open (IN, "<$file");
	while (<IN>) {
		chomp;
		my @array = split("\t", $_);
		push ( @{ $config{$array[0]} }, $array[1]);
	}
	close (IN);
	return \%config;	
}

sub finish_time_stamp {

	my $start_time = $_[0];
	my $finish_time = time;
	print "\n\n";
	print "+++++++++++++++++++++++++++++++++++++++++++++++++++\n";
	print "++++++++++++++++ ANALYSIS FINISHED ++++++++++++++++\n"; 
	print "+++++++++++++++++++++++++++++++++++++++++++++++++++\n";
	print &time_stamp();
	my $secs = $finish_time - $start_time; 
	my $hours = int($secs/3600); $secs %= 3600; 	
	my $mins = int($secs/60); $secs %= 60; 
	printf (" Whole process took %.2d hours, %.2d minutes, and %.2d seconds\n", $hours, $mins, $secs); 
}

sub time_stamp { return "[ ".(localtime)." ]"; }

sub time_log {	
	my $given_step_time = $_[0];
	my $current_time = time;
	print &time_stamp."\t";
	my $secs = $current_time - $given_step_time; 
	my $hours = int($secs/3600); $secs %= 3600; 
	my $mins = int($secs/60); $secs %= 60; 
	printf ("Step took %.2d hours, %.2d minutes, and %.2d seconds\n", $hours, $mins, $secs); 
	return \$current_time;
}

1;