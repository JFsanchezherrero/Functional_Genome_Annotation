#! /bin/bash -x
#$ -cwd
#$ -V

# $1 fasta_input_file
# $2 outputfile

grep '>' $1 | awk '{print $1":"$3}' | perl -ne '@array=split(":", $_); $array[0]=~ s/^>//; print $array[0]."\t".$array[2];' > $2 ## AED
##grep '>' $1 | awk '{print $1":"$4}' | perl -ne '@array=split(":", $_); @name=split("-",$array[0]);print $name[1]."\t".$array[2];' > $2 eAED

## get mean AED: 
awk '{ sum +=$2; n++ } END { if (n > 0) print sum / n; }' $2 
