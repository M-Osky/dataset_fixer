#!/usr/bin/perl
use strict ; use warnings;

#delete_bad_loci   			# by M'Óscar 
my $version = "delete_bad_loci_v3.pl";

###################################################################################

# Use this script to delete all the columns from a file that have plenty missing values (0s or any other value coded).
# This is optimised to work as a dataset_fixer module, reading an input file from a subdirectory called "temp". Although it should run also as stand alone.

# For options, usage and other information check the help typing the name of the program version and "help" or "--h" or so...
# delete_bad_loci_vX.pl -help


###########################################################################################################################
#######                                                                                                          ##########
#######         CHANGE LOG                                                                                       ##########
#######                                                                                                          ##########
#######    2019-03-13  -  Version 3                                                                              ##########
#######     Implemented flags to pass arguments from command line, to be able to set more options from it        ##########
#######     More customizable and with a better help information                                                 ##########
#######                                                                                                          ##########
#######    2019-03-08  -  Version 2.1 (re done)                                                                  ##########
#######     Fixed it to delete some temp/temp doubled folders that were generated in some cases                  ##########
#######     Now it outputs a list of good loci that could be used for populations (Stacks)                       ##########
#######     I had to do this version twice because the original was deletd by a error from Isabella              ##########
#######     I am not sure if this version corrects all the bug that the previous did. Don't remember             ##########
#######                                                                                                          ##########
#######    2019-02-14  -  Version 2.0                                                                            ##########
#######     Fixed to work in dataset_fixer pipeline and output a structure file even if all loci are good        ##########
#######     Fixed it to delete only the last "_tag" if the file name has more than one                           ##########
#######                                                                                                          ##########
#######    2018-12-14  -  Version 2                                                                              ##########
#######     Implemented to run it remotely: from a directory that is not the actual local working directory      ##########
#######     Now it can be run automatically from the submission files after refmap + populations                 ##########
#######                                                                                                          ##########
###########################################################################################################################



#######################   PARAMETERS   #########################
# Most of them can be set from the command line, check the help.

my $inputname = "populations.structure_clean";	# input file name, should be a string either alphanumeric or alphabetic.
#my $inputname = "populations.structure_clean";	# input file name, should be a string either alphanumeric or alphabetic.


my $limitmiss = 0.3;						# the highest tolerable ratio of missing values.
#my $limitmiss = 0.3;						# the highest tolerable ratio of missing values.


# Edit only If your file in not tab separated, does not have two rows per individual, has more or less than 2 columns with metadata or does not have headers
#################################################################################################################
#########################################  DEFAULT ARGUMENTS  ###################################################
#################################################################################################################

my $sep = '\t';								# symbol used to separate columns
#my $sep = '\t';								# symbol used to separate columns
#my $sep = ',';								# symbol used to separate columns

# missing values coded as: 0, -9, NA
my $missing='0';							# Could be "-9";
#my $missing='0';							# Could be "-9";
#my $missing='-9';							# Could be "0";

my $headers = "yes";						# does the first row includes the loci names? yes/no. (rows starting with "#" will be ignored, so do not count them as headers).
#my $headers = "yes";						# does the first row includes the loci names? yes/no. (rows starting with "#" will be ignored, so do not count them as headers).
#my $headers = "no";						# does the first row includes the loci names? yes/no. (rows starting with "#" will be ignored, so do not count them as headers).

#The output file will be automatically generated adding $tail2 to the input file name, it will delete any other "tail" at the right end of the input file name if they are after an underscore "_"
my $tail2 = "_neat";		#something to add at thze end of the inputfile name to name the output file

my $tempdir = "temp";		#to hold the results

my $metadata = 2;							# number of columns in the file before the loci, usually two: individual ID and populations. Not implemented yet for other values, and it is not a priority.

my $rowsxind = 2;							# rows per individual, usually 1, but Structure is special and has 2. Not implemented for 1 row per individual yet, and is not a priority.
#my $rowsxind = 1;							# rows per individual, usually 1, but Structure is special and has 2. Not implemented for 1 row per individual yet, and is not a priority.



#################################################################################################################
#################################################################################################################

my @helpfilename = split ("_", $inputname);
my $tempname = $helpfilename[0];
my $helpinputname = "$tempname" . "$tail2";



#Help!
my %arguments = map { $_ => 1 } @ARGV;
if(exists($arguments{"help"}) || exists($arguments{"--help"}) || exists($arguments{"-help"}) || exists($arguments{"-h"}) || exists($arguments{"--h"})) {
	die "\n\n\t   $version   Help Information\n\t-------------------------------------------------\n
	This program will delete any column with a high rate of \"x\".
	Its designed to delete loci from a Structure input file with high missing rate.
	
	By default it will delete loci with a rate of missing above or equal to $limitmiss from \"$inputname\"
	By default it will consider as missing any column coded as: $missing
	
	It has been tested with the Structure file generated by the program populations (Stacks),
	that is: Structure file format: tab separated, with a row with locus names (headers), two rows per individual,
	         and two initial columns on the left with individual and population tags.
	Any row commented out (starting with: #) will be ignored.
	
	The output file will be saved in a subdirectory called \"$tempdir\"
	The output file name will be the input file name - any tail (anything at the right of a \"_\") + a tail,
	 output file name by default: $tempdir/$helpinputname;
	
	To run the default just call the program:
	
		$version
	
	Parameters to use if need to change defaults:
	--input            set a different file name or path to the input file (default at $tempdir/ subdir: $inputname)
	--sep              symbol used to separate columns, usually tab \'\\t\' but can be space \' \', comma \',\', or semmicolon \';\' 
	-nohead            add this to tell the program that your input file does not have headers (no locus names)
	--misscode         how are the missing data coded? Usually \"0\", \"-9\", or \"NA\" (default: $missing)
	--miss_loci        (float) ratio of missing from which samples must be deleted (default: $limitmiss)
	--dir              subdirectory to save the results (default: $tempdir)
	--tail            string to add/replace the end of the input file name to generate the output file name (default: $tail2)
	
	Example:
	
		$version --input /home/refmap/out/temp/trial.str --misslimit_loci 0.3 --misscode -9 nohead --sep \' \'
	
	This program is optimized to run as part of \"dataset_fixer.sh\" although it should also work as stand alone.
	Because of the dataset_fixer pipeline there were some redundancies with the output $tempdir/ subdirectory:
	 If the input file was already in $tempdir/ subdirectory it was duplicated for the output: $tempdir/$tempdir/$helpinputname
	 To solve this the program will change   $tempdir/$tempdir/  to   $tempdir/
	This program has not been tested with other file formats but it may probably work if the data is sorted by columns
	This program will output a log file with the loci deleted and a list of the loci kept.
	This program has not been tested on animals, but our dog seems ok with it.
	\n\n";
}



use Getopt::Long;

GetOptions( "input=s" => \$inputname,              #   --input
            "miss_loci=f" => \$limitmiss,          #   --misslimit_loci
            "misscode=s" => \$missing,             #   --misscode
            "dir=s" => \$tempdir,                  #   --dir
            "tail=s" => \$tail2,                  #   --tail2
            "sep=s" => \$sep );                    #   --sep


if(exists($arguments{"--nohead"})) { $headers = "no";}
if(exists($arguments{"-nohead"})) { $headers = "no";}
if(exists($arguments{"nohead"})) { $headers = "no";}

#debug
#die "\nParameters:\n  Input file name:  $inputname\n  Missing values coded as:  $missing\n  Headers?    $headers\n  Columns separated by  \"$sep\"\n  Allowed rate of missing values bellow:  $limitmiss\n  Tail added to the file name:  $tail2\n  Output file stored at:  $tempdir\n\n";

my $argumentnumber = keys %arguments;
if($argumentnumber == 0) {print "\n\nNo arguments specified, using defaults:\n";}
else { print "\n\n";}
print "$version will delete the loci from $inputname with $limitmiss or higher rate of missing values.\n\n";

#################################################################################################################
#################################################################################################################

# to deal with remote directories

use Cwd qw(cwd);
my $localdir = cwd;


my @directorypath = split('/' , $inputname);
my $pathlength = scalar @directorypath;
my $onlyfile = $directorypath[-1];
my $subdir = 0;
my $pathtemp;
my $logout;

if ($pathlength >= 2) {
	my @pathonly = @directorypath;
	pop (@pathonly);
	$subdir = join('/', @pathonly);
	my $subdirpath = $subdir;
	$subdirpath =~ s/$tempdir\/$tempdir/$tempdir/;
	$pathtemp = "$subdirpath" . "/" . "$tempdir";
	$logout = "$subdirpath" . "/" . "delete_bad_loci.log";
}
else {
	$onlyfile = $inputname;
	$logout = "$localdir" . "/" . "delete_bad_loci.log";
	$pathtemp = "$localdir" . "/" . "$tempdir";
}

################################   CHANGED THIS TO THE VARIABLE SO IT CAN BE DEFINED BY THE USER, MAY NEED ADJUSTMENT
#$logout =~ s/temp\/temp/temp/;
#$pathtemp =~ s/temp\/temp/temp/;
#$subdirpath =~ s/temp\/temp/temp/;
$logout =~ s/$tempdir\///;
$pathtemp =~ s/$tempdir\/$tempdir/$tempdir/;





# my $filepath = "$localdir" . "/" . "$inputname";  	  #If you want to run it as standalone
my $filepath = "$pathtemp" . "/" . "$onlyfile";  	  #If you want to run it in dataset_fixer.sh pipeline

################################   CHANGED THIS TO THE VARIABLE SO IT CAN BE DEFINED BY THE USER, MAY NEED ADJUSTMENT
#$filepath =~ s/temp\/temp/temp/;
$filepath =~ s/$tempdir\/$tempdir/$tempdir/;

my @filename = split("_", $onlyfile);
my @keepfilename = @filename;
my $namelength = scalar(@keepfilename);
my $keepname = 0;

if ($namelength > 1) {
	pop(@keepfilename);
	$keepname = join ('_' , @keepfilename);
}
else { $keepname = $filename[0];}

my $outname = "$keepname" . "$tail2";		#name for the output file

open my $FILE, '<', $filepath or die "\nUnable to find or open $onlyfile at $pathtemp: $!\n";

my @missingcount = ();
my $numloci = 0;
my $col = 0;
my $row = 0;
my @newline = ();
my @headerline=();
my $line = 0;
my $numbercols = 0;
my $allele = 0;
print "Processing the data...\n";

my @alldata =();






while (<$FILE>) {
	chomp;	#clean "end of line" symbols
	
	next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
	
	$line = $_;
	$line =~ s/\s+$//;		#clean white tails in lines
	
	@newline= split($sep, $line);	#split columns as different elements of an array
	$numbercols = scalar (@newline);
	$col = 0;
	if ($row == 0 && $headers eq "yes") {
		@headerline = @newline;
		push (@alldata, $line);
		$row++;
	}
	else {
		foreach (@newline) {
			$allele = $_;
			if ($allele eq $missing) {
				if (!defined ($missingcount[$col])) { $missingcount[$col] = 1; }
				else { $missingcount[$col] = $missingcount[$col]+1 }   			#add one for each missing
				$col++;
			}
			else {
				if (!defined ($missingcount[$col])) { $missingcount[$col] = 0; }
				else { $missingcount[$col] = $missingcount[$col] }   			#add one for each missing
				$col++;
			}
		}
		push (@alldata, $line);		#add the line processed in the array
		$row++;
	}
}
close $FILE;

$numloci = $numbercols - $metadata;

my $samples = 0;

if ($headers eq "yes") {
	$samples = $row - 1;
}
else {$samples = $row;}

my $samplenum = $samples / 2;
print "Data from $samplenum samples and $numloci loci processed, looking for loci that should be deleted\n";



#check if the missing ratio recorded is higher than the limit
$col=0;
my $nummissing=0;
my $ratio=0;
my @delete=();
my $del = 0;
my @shittyloci=("#Deleted loci from $inputname with $limitmiss or higher missing values per sample", "", "Loci name   \tmissing");


foreach (@missingcount) {
	$nummissing = $_;
	$ratio = $nummissing / $samples;
	if ($ratio >= $limitmiss) {
		$delete[$col] = "DELETE";
		my $lociname = $headerline[$col];
		#print "Loci $lociname with $ratio of missing should be deleted.\n";
		my $reportloci = "$lociname   \t$ratio";
		push (@shittyloci, $reportloci);
		$del++;
		$col++;
	}
	else {
		$delete[$col] = "KEEP";
		$col++;
	}
}



#my $logloci = "$localdir" . "/" . "delete_bad_loci.log";
open my $OUT3, '>', $logout or die "\nUnable to create or save \"$logout\": $!\n";


if ($del > 0) { print "\nAnalysis concluded: $del loci were found with a missing ratio above $limitmiss; list saved in the log file.";}
else {
	print $OUT3 "As expected all loci from $inputname had a proportion of missing values below $limitmiss!\n\n\n";
	print "$del loci found with a missing ratio equal or over $limitmiss; Good quality data you have there!\nNo loci need to be deleted\n\n";
	
	my $outpath = "$pathtemp" . "/" . "$outname";
	open my $OUTL, '>', $outpath or die "\nUnable to create or save $outname at $pathtemp: $!\n";
	# Loop over the array
	foreach (@alldata) {print $OUTL "$_\n";} # Print each entry in our array to the file
	close $OUTL;
	
	
	
	
	#List of loci
	print "Saving name list of loci...\t";
	open my $NEWFILE, '<', $outpath or die "\nProblem finding, opening or reading the final file $outname at $pathtemp: $!\n";

	my $goodloci = 0;

	while (<$NEWFILE>) {
		chomp;	#clean "end of line" symbols
		next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
		$goodloci = $_;
		last;
	}

	$goodloci =~ s/^\s+|\s+$//g;	#trim spaces at the beginning and end of the line
	my @locilist = split($sep, $goodloci);	#each loci as a different array element

	my $locifile = "loci_list";


	my $pathloci = "$pathtemp" . "/" . "$locifile";
	$pathloci =~ s/$tempdir\///;
	open my $OUTG, '>', $pathloci or die "\nUnable to create or save $pathloci: $!\n";
	# Loop over the array
	foreach (@locilist) {print $OUTG "$_\n";} # Print each entry in our array to the file
	close $OUTG; 
	
	
	print "Done!\n\n\tdelete_bad_loci finished!\n\n";
	die "";
}



#DELETE THE COLUMNS IN THE POSSITION MARKED AS "DELETE" for all the lines
$col = 0;
my @keepdata =();
my @keepalleles=();
@newline =();
$row = 0;

foreach (@alldata) {
	$line = $_;
	my @alleles= split($sep, $line);
	foreach (@alleles) {
		$allele = $_;
		if ($delete[$col] eq "DELETE") {
			$keepalleles[$col] = "DELETE_THIS";		#mark every column to delete of every row
			$col++;
		}
		else {
			$keepalleles[$col]=$allele;
			$col++;
		}
	}
	my $newline = join ( "\t" , @keepalleles); ###PROBLEM WITH \t WRITEN AS A TEXT
	#$tomach = "$sep" . "DELETE_THIS";
	$newline =~ s/\tDELETE\_THIS//g;						#delete the columns marked
	$keepdata[$row] = $newline;
	$col=0;
	$row++;
}



if ($del > 0) {
	push (@shittyloci, "\n");
	# Loop over the array
	foreach (@shittyloci) {print $OUT3 "$_\n";} # Print each entry in our array to the file
}


close $OUT3;



my $keptloci = $numloci - $del;

print "\n\nSaving $keptloci 'good' loci to the file $outname ...\t";

my $outpath = "$pathtemp" . "/" . "$outname";
open my $OUTL, '>', $outpath or die "\nUnable to create or save $outname at $pathtemp: $!\n";

# Loop over the array
foreach (@keepdata) {print $OUTL "$_\n";} # Print each entry in our array to the file
close $OUTL; 

print "Done!\n";
my $locifile = "good_loci";
print "Saving name list of kept loci (\"$locifile\")...\t";
open my $NEWFILE, '<', $outpath or die "\nProblem finding, opening or reading the final file $outname at $pathtemp: $!\n";

my $goodloci = 0;

while (<$NEWFILE>) {
	chomp;	#clean "end of line" symbols
	next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
	$goodloci = $_;
	last;
}

$goodloci =~ s/^\s+|\s+$//g;	#trim spaces at the beginning and end of the line
my @locilist = split($sep, $goodloci);	#each loci as a different array element

my $pathloci = "$pathtemp" . "/" . "$locifile";
$pathloci =~ s/$tempdir\///;
open my $OUTG, '>', $pathloci or die "\nUnable to create or save $pathloci: $!\n";
# Loop over the array
foreach (@locilist) {print $OUTG "$_\n";} # Print each entry in our array to the file
close $OUTG; 
print "Done!\n\n\tdelete_bad_loci finished!\n\n";







