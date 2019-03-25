#!/usr/bin/perl  
use strict ; use warnings;
# delete_bad_samples_v3.1.pl by M'Óskar 

###################################################################################

# This version is adjusted to work in dataset_fixer.sh, but should work solo also.
# delete_bad_samples_standalone was the version to run by itself, may work better solo

#Use this script to delete from a file all the rows that have plenty missing values.
# you can just run the script in a folder and will delete all the samples with more than 50% of missing (0.5) from the file "populations.structure" as it is.
#That's all, no more settings needed. Just type in the command prompt $: delete_bad_samples.pl 

# If you want to specify a different file name, you can write it after the program name: $ delete_bad_samples.pl inputfile.csv

# It will automatically work with any file if the file name is not only a number. You need to configure the settings only if:
#   you file has extra rows, it will assume that you have column headers and will ignore comments.
#   your file has extra columns, it will assume you have to initial columns to the left and the the third column until the last one is the data (loci).
#   your file is not tab separated. Or has only a row per individual.

# If you want to specify a different proportion of missing values per sample, you can write it after the program name: $ delete_bad_samples.pl 0.75

# And of course you can specify both in any order, the program will overwrite the default values if the file name is not only a number:
# # $	delete_bad_samples.pl inputfilename 0.25
# # $	delete_bad_samples.pl 0.949 populations.structure_trimed


#############################################################################################################################
#######                                                                                                            ##########
#######                     CHANGE LOG                                                                             ##########
#######    2019-01-11  -  Version 3.1                                                                              ##########
#######     Fixed a bug that was messing up with heterozygosity.                                                   ##########
#######                                                                                                            ##########
#######    2018-12-14  -  Version 3.0                                                                              ##########
#######     Implemented to run it remotely: from a directory that is not the actual local working directory        ##########
#######                                                                                                            ##########
#######    2018-10-03     Version 2.0                                                                              ##########
#######     Changed a few parameters so it could work better in a pipeline                                         ##########
#######     Outputs in a temporary directory                                                                       ##########
#######                                                                                                            ##########
#############################################################################################################################



# Edit only If your file in not tab separated, does not have two rows per individual, does not have 2 columns with metadata or does not have headers
#################################################################################################################
#########################################  DEFAULT ARGUMENTS  ###################################################
#################################################################################################################

#this arguments can be set up from command line

my $inputname = "populations.structure";	# input file name, should be a string either alphanumeric or alphabetic.
#my $inputname = "populations.structure";	# input file name, should be a string either alphanumeric or alphabetic.

my $limitmiss = 0.85;						# the highest tolerable ratio of missing values.
#my $limitmiss = 0.85;						# the highest tolerable ratio of missing values.


####### Other arguments

my $sep = '\t';								# symbol used to separate columns
#my $sep = '\t';								# symbol used to separate columns
#my $sep = ' ';								# symbol used to separate columns

my $missing='0';							# Could be "-9" or "?" or "NA";
#my $missing='-9';							# Could be "0";
#my $missing='0';							# Could be "-9";

my $headers = "yes";						# does the first row includes the loci names? yes/no. (rows starting with "#" will be ignored anyway.
#my $headers = "no";						# does the first row includes the loci names? yes/no. (rows starting with "#" will be ignored anyway.

#for compatibility issues is better to leave this as it is
my $tempdir = "temp";		#to hold the results
#my $tempdir = "temp";		#to hold the results

#Change this parameter at your own risk, the handling of input files with one row per individual is still under development
my $rowsxind = 2;							# rows per individual, usually 1, but Structure is special and has 2 in despite of two columns per marker which will make everything easier
#my $rowsxind = 2;							# rows per individual, usually 1, but Structure is special and has 2 in despite of two columns per marker which will make everything easier
#my $rowsxind = 1;							# rows per individual, Still in beta for "1".

#Change this parameter at your own risk, the handling of input files with more or less than 2 columns of metadata is still under development
my $metadata = 2;							# number of columns in the file before the loci, usually two: individual ID and populations
#my $metadata = 2;							# number of columns in the file before the loci, usually two: individual ID and populations



#################################################################################################################
#################################################################################################################

my $argumentnumber = scalar (@ARGV);

if($argumentnumber == 0) {print "\nNo arguments specified, will trim samples with $limitmiss (or more) of missing in the file \"$inputname\"\n";
}
elsif($argumentnumber == 1) {
	my $argument = $ARGV[0];
	if ( $argument =~ /^[0-9,.E]+$/ ) {
		$limitmiss = $argument;
		print "\nOne numeric argument passed (proportion of missing), will trim samples with $limitmiss (or more) of missing in the file \"$inputname\"\n";
	}
	else {
		$inputname = $argument;
	print "\nOne argument passed (input file name), will trim samples with $limitmiss (or more) of missing in the file \"$inputname\"\n";
	}
}
elsif($argumentnumber == 2) {
	my $argument = $ARGV[0];
	if ( $argument =~ /^[0-9,.E]+$/ ) {
		$limitmiss = $argument;
		$inputname = $ARGV[1];
		print "\nTwo arguments passed (proportion of missing and file name), will trim samples with $limitmiss (or more) of missing in the file \"$inputname\"\n";
	}
	else {
		$inputname = $argument;
		$limitmiss = $ARGV[1];
		print "\nTwo arguments passed (input file name and proportion of missing), will trim samples with $limitmiss (or more) of missing in the file \"$inputname\"\n";
	}
}
else {
	die "\n\tSomething is wrong. Did you specify more than two arguments?\n\t  USAGE: For deleting samples with more than $limitmiss of missing from \"$inputname\" just type:      delete_bad_samples.pl\n\t  You can also specify a different ratio of missing, a different input file, or both a different missing ratio and file name. Examples:\n\t\tdelete_bad_samples.pl 0.4\n\t\tdelete_bad_samples.pl inputfile.txt\n\t\tdelete_bad_samples.pl file.txt 0.8\n\t\tdelete_bad_samples.pl 0.8 file.txt\n\n";
}


#####################################################################################################

# to deal with remote directories

use Cwd qw(cwd);
my $localdir = cwd;


my @directorypath = split('/' , $inputname);
my $pathlength = scalar @directorypath;
my $onlyfile = $directorypath[-1];
my $firstdir = $directorypath[0];
my $lastdir = $directorypath[-2];
my $subdir = 0;
my $logout = 0;
my $subdirpath = 0;
my $pathtemp = 0;

if ($pathlength >= 3 && $firstdir eq $tempdir && $lastdir ne $tempdir) {
	my @pathonly = @directorypath;
	pop (@pathonly);
	$onlyfile = "$tempdir" . "/" . "$onlyfile";
	shift (@pathonly);
	$subdir = join('/', @pathonly);
	$subdirpath = $subdir;
	$pathtemp = "$subdirpath" . "/" . "$tempdir";
	$logout = "$subdirpath" . "/" . "delete_bad_samples.log";
}
elsif ($pathlength > 1) {
	my @pathonly = @directorypath;
	pop (@pathonly);
	$subdir = join('/', @pathonly);
	$subdirpath = $subdir;
	
	if (-e "delete_bad_samples.log" && $subdir eq $tempdir) { $logout = "delete_bad_samples.log"; }
	else { $logout = "$subdirpath" . "/" . "delete_bad_samples.log"; }
	$pathtemp = "$subdirpath" . "/" . "$tempdir";
}
else {
	$onlyfile = $inputname;
	$logout = "$localdir" . "/" . "delete_bad_samples.log";
	$subdirpath = $localdir;
	$pathtemp = "$localdir" . "/" . "$tempdir";
}

#print "\n\n$pathlength elements at the input file passed, (@directorypath). Subdirectory is \"$subdir\", and file is \"$onlyfile\", temp should be at \"$pathtemp\".\n$firstdir eq $tempdir ?  $lastdir ne $tempdir ?\n\n";











my $filepath = "$subdirpath" . "/" . "$onlyfile";

my $outname = "$onlyfile" . "_clean";		#name for the output file

unless(-e $pathtemp or mkdir $pathtemp) {die "\nUnable to create \"$tempdir\" at\n$subdirpath\nMay be you don't have the rights: $!\n"; }


open my $FILE, '<', $filepath or die "\nUnable to find or open $onlyfile at $subdirpath: $!\n";


my $k=0;
my $i=0;
my $del=0;
my $lin=1;
my @alldata = ();
$metadata = $metadata - 1;
my $name1 = 0;
my $name2 = 0;
my $name = 0;
my $good1 = 0;
my $good2 = 0;
my $good = 0;
my $missratio1 = 0;
my $missratio2 = 0;
my $missratio = 0;
my $numbercols = 0;
my $report = 0;
my @deletedlist=("#Deleted samples from $inputname with $limitmiss or higher missing values per loci", "", "Name\tmissing");
my $wholeline =0;
my $wholeline1 =0;
my $wholeline2 =0;
print "Now processing the data in the file\n";



while (<$FILE>) {
	chomp;	#clean "end of line" symbols
	
	next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
	
	my $line = $_;
	$line =~ s/\s+$//;		#clean white tails in lines
	
	my @newline= split($sep, $line);	#split columns as different elements of an array
	$numbercols = scalar (@newline);
	my $header=0;
	if ($rowsxind == 2) {
		# If is the first line being processed, copy the headers if any
		if ($k == 0 && $headers eq "yes") {
			$header = $line;
			$alldata[$i]= $header;		#add headers as first element of an array
			$k=1;	#keep track of lines processed
		}
		#If the input file first line does not have headers
		elsif ($k == 0 && $headers eq "no") {
			print "\n\n\nYour datafile has not headers, processing the first line\n\n\n";
			$wholeline1 = $line;				#save for afterwards
			my $max = $numbercols - 1;
			my @linedata = @newline[$metadata..$max];	#save only the allele info
			$name1 = $newline [0];		#name of the sample
			# Loop over the array and count missing
			my $emptycount = 0;
			my $locinum = scalar (@linedata);		#number of loci
			#foreach (@linedata) {if ($_ == $missing) {$emptycount ++;} } 
			foreach (@linedata) {$emptycount ++ if $_ eq $missing;} 
			$missratio1 = $emptycount / $locinum;
			# Compare proportion of missing with limit value
			if ($missratio1 >= $limitmiss) { $good1 = "BAD";}
			else { $good1 = "GOOD";}
			$i++;
			$k = 2;
		}
		#First line of data from a general file
		elsif ($k == 1) {
			$wholeline1 = $line;				#save for afterwards
			my $max = $numbercols - 1;
			my @linedata = @newline[$metadata..$max];	#save only the allele info
			$name1 = $newline [0];
			
			# Loop over the array and count missing
			my $emptycount = 0;
			my $locinum = scalar (@linedata);
			#foreach (@linedata) {if ($_ eq $missing) {$emptycount ++;} } 
			foreach (@linedata) {$emptycount ++ if $_ eq $missing;} 
			$missratio1 = $emptycount / $locinum;
			# Compare proportion of missing with limit value
			if ($missratio1 >= $limitmiss) {$good1 = "BAD";}
			else {$good1 = "GOOD";}
			$i++;
			$k++;
		}
		#Second line of data of any sample
		elsif ($k == 2 && $i >= 1) {
			$wholeline2 = $line;				#save for afterwards
			my $max = $numbercols - 1;
			my @linedata = @newline[$metadata..$max];	#save only the allele info
			$name2 = $newline [0];		#save the name tag of the sample from the first column
			
			# Loop over the array and count missing
			my $emptycount = 0;
			my $locinum = scalar (@linedata);
			foreach (@linedata) {if ($_ eq $missing) {$emptycount ++;} } 
			$missratio2 = $emptycount / $locinum;
			# Compare proportion of missing with limit value
			if ($missratio2 >= $limitmiss) { $good2 = "BAD";}
			else {$good2 = "GOOD";}
			$i++;
			$k++;
		}
		
		#Save both lines of data from the same sample if data is good
		if ($k == 3 && $i >= 2) {
			if ($good1 eq "GOOD" && $good2 eq "GOOD") {
				push (@alldata, $wholeline1);
				push (@alldata, $wholeline2);
				$k = 1;								#keep track of lines processed
			}
			else {
				if ($missratio1 > $missratio2) { 
					#print "Sample $name1 with $missratio1 of missing will be deleted\n";
					$report = "$name1\t$missratio1";
					push (@deletedlist, $report);
				}
				else {
					#print "Sample $name2 with $missratio2 of missing will be deleted\n";
					$report = "$name2\t$missratio2";
					push (@deletedlist, $report);
				}
				$del++;
				$k = 1;
			}
		}
	}
	
	# the handling of one row per individual structure datafiles still needs debugging!
	
	elsif ($rowsxind ==1) {
		print "\n\n\nThis option for one-row-per-individual Structure input file, mstill needs to be tested\n\n\n";
		exit;   		#Delete this when this is implemented
		# If is the first line being processed, copy the headers if any
		if ($k == 0 && $headers eq "yes") {   		#Needs to be checked
			$header = $line;
			$alldata[$i]= $header;		#add headers as first element of an array
			$k++;	#keep track of lines processed
		}   		#Needs to be checked
		#If the input file first line does not have headers
		elsif ($i == 0 && $headers eq "no") {   		#Needs to be checked
			my $wholeline = $line;				#save for afterwards
			my @linedata = @newline[$metadata..$numbercols];	#save only the allele info
			$name = $newline [0];
			# Loop over the array and count missing
			my $emptycount = 0;
			my $locinum = scalar (@linedata);
			foreach (@linedata) {if ($_ == $missing) {$emptycount ++;} } 
			$missratio = $emptycount / $locinum;
			# Compare proportion of missing with limit value
			if ($missratio >= $limitmiss) {
				#print "Sample $name with $missratio1 of missing will be deleted\n";
				$report = "$name\t$missratio1";
				push (@deletedlist, $report);
				$del++;
			}
			else { push (@alldata, $wholeline);}
			$i++;
			$k++;
		}   		#Needs to be checked
		#First line of data from a general file
		elsif ($k >= 1) {   		#Needs to be checked
			my $wholeline = $line;				#save for afterwards
			my @linedata = @newline[$metadata..$numbercols];	#save only the allele info
			$name = $newline [0];
			
			# Loop over the array and count missing
			my $emptycount = 0;
			my $locinum = scalar (@linedata);
			foreach (@linedata) {if ($_ == $missing) {$emptycount ++;} } 
			$missratio = $emptycount / $locinum;
			# Compare proportion of missing with limit value
			if ($missratio >= $limitmiss) {
				#print "Sample $name with $missratio of missing will be deleted\n";
				$del++;
				$report = "$name\t$missratio";
				push (@deletedlist, $report);
			}
			else { push (@alldata, $wholeline);}
			$i++;
			$k++;
		}   		#Needs to be checked
	}
	$lin++;
}
close $FILE;


$wholeline =0;
$wholeline1 =0;
$wholeline2 =0;

my $goodsamples = 0;

if ($headers eq "yes") {
	$goodsamples = scalar (@alldata);
	$goodsamples = $goodsamples - 1;
}
else {$goodsamples = scalar (@alldata);}

my $numberloci = $numbercols - 2;

if ($del > 0) { print "$numberloci columns (loci) and $i lines procesed.\n\n$del samples deleted from a total of " . $i/$rowsxind . " samples. List of deleted samples written in the log file.\nSaving " . $goodsamples/$rowsxind . " 'good' samples in $outname...\t"; }
else { print "\n$i lines procesed. No samples with missing rate above $limitmiss were found. Good quality data you have there!\nSaving " . $goodsamples/$rowsxind . " samples (all of them!) in $outname...\t";}

my $outpath = "$pathtemp" . "/" . "$outname";

$outpath=~ s/temp\/temp\//temp\//;		#this line will fix the possible duplication of a temp folder to hold the results.

open my $OUT, '>', $outpath or die "\nUnable to create or save $outname at $pathtemp: $!\n";

# Loop over the array
foreach (@alldata) {print $OUT "$_\n";} # Print each entry in our array to the file
close $OUT; 


#print "\nSaving log at $logout\n";
open my $OUT2, '>>', $logout or die "\nUnable to create or save \"delete_bad_samples.log\" at $logout: $!\n";

if ($del > 0) {
	push (@deletedlist, "\n");
	push (@deletedlist, "\n");
	# Loop over the array
	foreach (@deletedlist) {print $OUT2 "$_\n";} # Print each entry in our array to the file
}
else {print $OUT2 "All samples from file $inputname had a proportion of missing values below $limitmiss\nThat's cool!\n\n\n";}

close $OUT2; 



print "Done!\n\n";

