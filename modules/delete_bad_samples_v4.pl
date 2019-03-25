#!/usr/bin/perl  
use strict ; use warnings;

#delete_bad_samples   			# by M'Óskar 
my $version = "delete_bad_samples_v4.pl";

###################################################################################

# Use this script to delete all the rows from a file that have plenty missing values (0s or any other value coded).
# This is optimised to work as a dataset_fixer module, but should run also as stand alone

# For options, usage and other information check the help typing the name of the program version and "help" or "--h" or so...
# delete_bad_samples_vX.pl -help



#############################################################################################################################
#######                                                                                                            ##########
#######                     CHANGE LOG                                                                             ##########
#######                                                                                                            ##########
#######    2019-03-13  -  Version 4                                                                                ##########
#######     Implemented flags to pass arguments from command line, to be able to set more options from it          ##########
#######     More customizable and with a better help information                                                   ##########
#######     A popmap is generated with the "good" samples                                                          ##########
#######                                                                                                            ##########
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



#######################   PARAMETERS   #########################
# Most of them can be set from the command line, check the help.

my $inputname = "populations.structure";	# input file name, should be a string either alphanumeric or alphabetic.
#my $inputname = "populations.structure";	# input file name, should be a string either alphanumeric or alphabetic.

my $limitmiss = 0.85;						# the highest tolerable ratio of missing values.
#my $limitmiss = 0.85;						# the highest tolerable ratio of missing values.



# Edit only If your file in not tab separated, does not have two rows per individual, does not have 2 columns with metadata or does not have headers
#################################################################################################################
#########################################  DEFAULT ARGUMENTS  ###################################################
#################################################################################################################


my $sep = '\t';								# symbol used to separate columns
#my $sep = '\t';								# symbol used to separate columns
#my $sep = ' ';								# symbol used to separate columns

my $missing='0';							# Could be "-9" or "?" or "NA";
#my $missing='-9';							# Could be "0";
#my $missing='0';							# Could be "-9";

my $headers = "yes";						# does the first row includes the loci names? yes/no. (rows starting with "#" will be ignored anyway.
#my $headers = "yes";						# does the first row includes the loci names? yes/no. (rows starting with "#" will be ignored anyway.
#my $headers = "no";						# does the first row includes the loci names? yes/no. (rows starting with "#" will be ignored anyway.

#Subdirectory for the output file. For compatibility issues with other modules in dataset_fixer is better to leave this as it is;
my $tempdir = "temp";		#to hold the results
#my $tempdir = "temp";		#to hold the results

#this will be added at the end of the input file to generate the output name. For compatibility with other modules in dataset_fixer beter leave it as it is.
my $tail1 = "_clean";
#my $tail1 = "_clean";

#Change this parameter at your own risk, the handling of input files with any other number of columns with metadata than 2 is still a beta, I don't use it so not sure if it will work
my $metadata = 2;							# number of columns in the file before the loci, usually two: individual ID and populations
#my $metadata = 2;							# number of columns in the file before the loci, usually two: individual ID and populations

#Change this parameter at your own risk, the handling of input files with one row per individual is still under development and is not a priority
my $rowsxind = 2;							# rows per individual, usually 1, but Structure is special and has 2 in despite of two columns per marker which will make everything easier
#my $rowsxind = 2;							# rows per individual, usually 1, but Structure is special and has 2 in despite of two columns per marker which will make everything easier
#my $rowsxind = 1;							# rows per individual, Not implemented yet for 1




#################################################################################################################
#################################################################################################################


#Help!
my %arguments = map { $_ => 1 } @ARGV;
if(exists($arguments{"help"}) || exists($arguments{"--help"}) || exists($arguments{"-help"}) || exists($arguments{"-h"}) || exists($arguments{"--h"})) {
	die "\n\n\t   $version   Help Information\n\t-------------------------------------------------\n
	This program will delete any row with a high rate of \"x\".
	Its designed to delete samples from a Structure input file with high missing rate.
	
	By default it will delete samples with a rate of missing above or equal to $limitmiss from \"$inputname\"
	By default it will consider as missing any column coded as: $missing
	
	It has been tested with the Structure file generated by the program populations (Stacks),
	that is: Structure file format: tab separated, with a row with locus names (headers), two rows per individual,
	         and two initial columns on the left with individual and population tags.
	Any row commented out (starting with: #) will be ignored.
	
	The output file will be saved in a subdirectory called \"$tempdir\"
	The output file name will be the input file name + a tail,\n\t output file name by default: $tempdir/$inputname$tail1
	
	To run the default just call the program:
	
		$version
	
	
	Parameters to use if need to change defaults:
	--input               set a different file name or path to the input file (default at local directory: $inputname)
	--sep                 symbol used to separate columns, usually tab \'\\t\' but can be space \' \', comma \',\', or semmicolon \';\' 
	-nohead               add this to declare that your input file does not have headers/loci names (default: loci names? = $headers)
	--misscode            how are the missing data coded? Usually \"0\", \"-9\", or \"NA\" (default: $missing)
	--miss_samples        (float) ratio of missing from which samples must be deleted (default: $limitmiss)
	--dir                 directory to save the results (default: $tempdir)
	--tail               string to be added at the end of the input file name to generate the output file name (default: $tail1)
	
	Example:
	
		$version --input /home/refmap/out/trial.str --misslimit_samples 0.5 --misscode -9 nohead --sep \' \'
	
	This program is optimized to run as part of \"dataset_fixer.sh\" although it should also work as stand alone.
	Because of the dataset_fixer pipeline there were some redundancies with the output $tempdir/ subdirectory:
	 If the input file was already in $tempdir/ subdirectory it was duplicated for the output: $tempdir/$tempdir/$inputname$tail1
	 To solve this the program will change   $tempdir/$tempdir/  to   $tempdir/
	This program has not been tested with other file formats but it may probably work if the data is sorted by rows
	This program will output a log file with the samples deleted and a list of the samples kept in popmap format.
	This program has not been tested on animals, but our dog seems ok with it.
	\n\n";
}



use Getopt::Long;

GetOptions( "input=s" => \$inputname,     #   --input
            "miss_samples=f" => \$limitmiss, #   --miss_samples
            "misscode=s" => \$missing,    #   --miss_coded
            "dir=s" => \$tempdir,            #   --temp
            "tail=s" => \$tail1,         #   --tail
            "sep=s" => \$sep);           #  


if(exists($arguments{"nohead"})) { $headers = "no";}
if(exists($arguments{"-nohead"})) { $headers = "no";}
if(exists($arguments{"--nohead"})) { $headers = "no";}

#debug
#die "\nParameters:\n  Input file name:  $inputname\n  Missing values coded as:  $missing\n  Headers?    $headers\n  Columns separated by  \"$sep\"\n  Allowed rate of missing values bellow:  $limitmiss\n  Tail added to the file name:  $tail1\n  Output file stored at:  $tempdir\n\n";

my $argumentnumber = keys %arguments;
if($argumentnumber == 0) {print "\n\nNo arguments specified, using defaults:\n";}
else { print "\n\n";}
print "$version will delete the samples from $inputname with $limitmiss or higher rate of missing values\n\n";

#################################################################################################################
#################################################################################################################



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
	$pathtemp = "$subdirpath" . "/" . "$tempdir" . "/";
	$logout = "$subdirpath" . "/" . "delete_bad_samples.log";
}
elsif ($pathlength > 1) {
	my @pathonly = @directorypath;
	pop (@pathonly);
	$subdir = join('/', @pathonly);
	$subdirpath = $subdir;
	
	if (-e "delete_bad_samples.log" && $subdir eq $tempdir) { $logout = "delete_bad_samples.log"; }
	else { $logout = "$subdirpath" . "/" . "delete_bad_samples.log"; }
	$pathtemp = "$subdirpath" . "/" . "$tempdir" . "/";
}
else {
	$onlyfile = $inputname;
	$logout = "$localdir" . "/" . "delete_bad_samples.log";
	$subdirpath = $localdir;
	$pathtemp = "$localdir" . "/" . "$tempdir" . "/";
}

#print "\n\n$pathlength elements at the input file passed, (@directorypath). Subdirectory is \"$subdir\", and file is \"$onlyfile\", temp should be at \"$pathtemp\".\n$firstdir eq $tempdir ?  $lastdir ne $tempdir ?\n\n";











my $filepath = "$subdirpath" . "/" . "$onlyfile";

my $outname = "$onlyfile" . "$tail1";		#name for the output file



$pathtemp=~ s/$tempdir\/$tempdir\//$tempdir\//;
$pathtemp=~ s/$tempdir\/$tempdir\//$tempdir\//;


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
		print "\n\n\nThis option for one-row-per-individual Structure input file, still needs to be tested\n\n\n";
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

my $outpath = "$pathtemp" . "/" . "$outname";

################################   CHANGED THIS TO THE VARIABLE SO IT CAN BE DEFINED BY THE USER, MAY NEED ADJUSTMENT
#$outpath=~ s/temp\/temp\//temp\//;		#this line will fix the possible duplication of a temp folder to hold the results.
$outpath=~ s/$tempdir\/$tempdir\//$tempdir\//;		#this line will fix the possible duplication of a temp folder to hold the results.


if ($del > 0) { print "$numberloci columns (loci) and $i lines procesed.\n\n$del samples deleted from a total of " . $i/$rowsxind . " samples. List of deleted samples written in the log file.\nSaving " . $goodsamples/$rowsxind . " 'good' samples in $outpath...\t"; }
else { print "\n$i lines procesed. No samples with missing rate above $limitmiss were found. Good quality data you have there!\nSaving " . $goodsamples/$rowsxind . " samples (all of them!) in $outpath...\t";}


open my $OUT, '>', $outpath or die "\nUnable to create or save $outname at $pathtemp: $!\n";

# Loop over the array
foreach (@alldata) {print $OUT "$_\n";} # Print each entry in our array to the file
close $OUT; 


#print "\nSaving log at $logout\n";
$logout =~ s/$tempdir\///;   			#now it will be saved in the parent directory
open my $OUT2, '>>', $logout or die "\nUnable to create or save \"delete_bad_samples.log\" at $logout: $!\n";

if ($del > 0) {
	push (@deletedlist, "\n");
	push (@deletedlist, "\n");
	# Loop over the array
	foreach (@deletedlist) {print $OUT2 "$_\n";} # Print each entry in our array to the file
}


else {print $OUT2 "All samples from file $inputname had a proportion of missing values below $limitmiss\nThat's cool!\n\n\n";}

close $OUT2; 

print "Done!\n";

########################

print "Saving popmap with list of \"good\" samples...\t";
open my $NEWFILE, '<', $outpath or die "\nProblem finding, opening or reading the final file $outname at $pathtemp: $!\n";

my @popmap = ();

while (<$NEWFILE>) {
	chomp;	#clean "end of line" symbols
	next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
	my $samplerow = $_;
	my @sampleline= split($sep, $samplerow);	#split columns as different elements of an array
	next if ($sampleline[0] eq "");
	my $popmapline = "$sampleline[0]\t$sampleline[1]";
	print 
	$popmapline =~ s/^\s+|\s+$//g;	#trim spaces at the beginning and end of the line
	push (@popmap, $popmapline);
}

my $popmapfile = "popmap_goodsamples";
my $pathsamples = "$pathtemp" . "/" . "$popmapfile";
$pathsamples =~ s/$tempdir\///;
$pathsamples =~ s/$tempdir\///;
open my $OUTG, '>', $pathsamples or die "\nUnable to create or save $pathsamples: $!\n";
# Loop over the array
foreach (@popmap) {print $OUTG "$_\n";} # Print each entry in our array to the file
close $OUTG; 
print "Done!\n\n\tdelete_bad_samples finished!\n\n";

