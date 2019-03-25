#!/usr/bin/perl
use strict;
use warnings;

#maker_refmaps.pl
#USAGE: This will make a submission file for every combination of max_obs_het, min_maf, r and p parameters of populations in ref_map.pl
# The will be stored in a directory called submissionfiles, it will use it if it exists, it will create it if it does not exist. As it should be.
# It will also create a launcher to submit them all and the directory for the outputs
# 

# Parameters to set

# 1) -- min_maf
my $m_min = 0.04;
my $m_max = 0.05;
#will be incremented by adding +0.01

# 2) -r
my $r_min = 0.6;
my $r_max = 0.7;
#will be incremented by adding +0.1

# 3) -p
my $p_min = 16;
my $number_pops = 20;
#will be incremented by adding +1

# 4) --max_obs_het
my $het_min = 0.5;
my $het_max = 0.8;
#will be incremented by adding +0.1

# 5) Your email address
my $emailaddress = 'omira@biol.pmf.hr';

# 6) Number of cores to use
my $cores = 16;

# 7) A prefix for the submission files
my $name = "refmap_poda";

# 8) Set the name of the output folder that will include each output from each submission file (once they are submited)
my $outfolder = "out/purged";

# 9) Requested memory
my $memo = "20G";

# 10) File locations #full path unless are in the working directory
my $samples = "/shared/omiraper/REFMAPS/snp/refmapop/Lizards/poda/podarcisdata";
my $popmap = "/shared/omiraper/REFMAPS/snp/refmapop/Lizards/poda/popmap";

# 11) Directory to store the submission files this script will produce
my $directory = "submissionfiles";

# 12) Length of the population name in each sample code: 2 for SY002, 3 for SYa016, 4 for ACAB042 (this is used to run dataset_fixer afterwards)
my $length = 2;

######################################################################################################

#Check also this before proceeding

# 12) Set the path to ref_map.pl.
my $programpath = "/shared/astambuk/bin/stacks_2.2/bin";
my $programfile = "ref_map.pl";  





use Cwd qw(cwd);
my $dir = cwd;																								######





unless(-e $directory or mkdir $directory) {die "Unable to create output directory $directory\n"};
print "\nRunning maker_refmaps. Submission files will be stored at: $directory\n\n";

my $count = 0;
my $minmaf = $m_min;
my $rflag = $r_min;
my $pflag = $p_min;
my $heteroz = $het_min;
my @alljobs = ("#!/bin/bash", "# launch_them_all.sh", "# quick script to submit all yor ref_map jobs at once", "# just \"bash\" or \"./\" this file", "\n", "#Jobs:");


until ($minmaf > $m_max) {
	$rflag = $r_min;
	until ($rflag > $r_max) {
		$pflag = $p_min;
		until ($pflag > $number_pops) {
			$heteroz = $het_min;
			until ($heteroz > $het_max) {

				# Use the open() function to create the submission file.
				my $mpart = $minmaf;
				$mpart =~ s/.*\.//;
				my $rpart = $rflag;
				$rpart =~ s/.*\.//;
				my $ppart = $pflag;
				$ppart =~ s/.*\.//;
				my $hetpart = $heteroz;
				$hetpart =~ s/.*\.//;
				
				
				my $submissionname = "$name" . "_m" . "$mpart" . "r" . "$rpart" . "p" . "$ppart" . "h" . "$hetpart" . ".sh";
				my $filepath ="$dir". "/"."$directory"."/"."$submissionname";														######fullpath
				open my $FILE, '>', $filepath or die "\nUnable to create $filepath: $!\n";######fullpath
				
				my $outdir = "$dir" . "/" . "$outfolder" ."/" . "m" . "$mpart" . "/" . "r" . "$rpart" . "/" . "p" . "$ppart" . "/" . "h" . "$hetpart";
				
				# Write text to the file.
				print $FILE "#!/bin/bash\n#\n# #$submissionname\n# Isabella submission file for refmaps\n";
				print $FILE "\n\n#\$ -cwd\t\t\t\t\t\t\t#print wd\n";
				print $FILE "#\$ -j y\t\t\t\t\t\t\t#report errors\n#\$ -m abe\t\t\t\t\t\t\#report beginning, end, and aborted\n";
				print $FILE "#\$ -M $emailaddress \t\t#email me\n#\$ -pe *mpisingle $cores\t\t\t\t\#$cores CPU\n#\$ -l h_vmem=$memo\t\t\t\t#Request memory\n\n";
				print $FILE "#set -e\n#set -u\n\n#CHR=\$SGE_TASK_ID\n\n";
				print $FILE "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/lib:/shared/astambuk/bin/lib:/shared/astambuk/bin/bin:/shared/astambuk/bin/lib64:/shared/astambuk/bin/stacks_2.2/bin:/shared/astambuk/bin/stacks_2.2:/shared/astambuk/bin/gcc8.2/lib64:/shared/astambuk/bin/gcc8.2/lib:/shared/astambuk/bin/gcc8.2/bin:$programpath\n";
				print $FILE "export PATH=\$PATH:/shared/astambuk/bin/bin:/shared/astambuk/bin/stacks_2.2/bin:/shared/astambuk/bin/stacks_2.2:$programpath\n";
				print $FILE "export PERL5LIB=\$PERL5LIB:/shared/astambuk/perl5:/shared/astambuk/perl5/scripts\n\n\n####################\n\n";
				print $FILE "#Checking and creating output directories\n\n";
				print $FILE "if [ -d \"$outdir\" ]\nthen\n\tprintf \"Already existing sub-directory will be used as output directory: $outdir\\n\"\n";
				print $FILE "else\n\tmkdir -p \"$outdir\"\nfi\n\n";
				print $FILE "#Run ref_map\n\n";
				#print $FILE "structure -K $count -o  $outdata/K$count\_\"\$SGE_TASK_ID\" > $outfolder/runseqK$count"."_\"\$SGE_TASK_ID\"\n\n\n##End\n";							#delete if full path
				print $FILE "$programpath"."/"."$programfile -T $cores -o $outdir --popmap $popmap --samples $samples -X \"populations: -t $cores --fstats --smooth --fst_correction p_value --vcf --structure --genepop --write_single_snp --min_maf $minmaf -r $rflag -p $pflag --max_obs_het $heteroz\"\n\n";			#fullpath
				print $FILE "dataset_fixer_v2.sh $outdir" ."/populations.structure $length\n\n";
				print $FILE "extract_output.pl $outdir/\n";
				# close the file.
				close $FILE;
				print "$submissionname created\n";
				#save the job name and the submission command
				my $currentjob = "qsub $filepath";
				push (@alljobs, "\n");
				push (@alljobs, $currentjob);
				
				$count++;
				
				$heteroz = $heteroz+0.1;
			}
			$pflag++;
		}
		$rflag = $rflag+0.1;
	}
	$minmaf = $minmaf+0.01;
}


print "\n $count submission files for Structure were created!\n\n";

my $launcher = "$dir" . "/" . "launch_them_all.sh";

#create a short script for submiting a bunch of similar jobs at once
open my $JOB, '>', $launcher or die "\nUnable to create $launcher: $!\n";
foreach (@alljobs) {print $JOB "$_\n";} # Print each entry in our array to the file
close $JOB;

print "created \"launch_them_all.sh\" to submit all jobs at once\n";
print "Done";



