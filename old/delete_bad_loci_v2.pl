#!/usr/bin/perl  
# delete_bad_loci_v2.pl by M'Óscar 

###################################################################################

#Use this script to delete from a file all the columns that have plenty missing values.
#This script is supposed to be run after "delete_bad_samples.pl" so the input file should be the output file from that script, by default: populations.structure_clean

#This is integrated in the dataset_fixer.sh and will read the input file from a subdirectory called "temp" unless you change that in line 105

#you can just run the script in a folder and will delete all the loci with more than 50% of missing (0.5) from the file "populations.structure_clean" as it is.
#That's all, no more settings needed. Just type in the command prompt $: delete_bad_loci.pl 

# If you want to specify a different file name, you can write it after the program name: $ delete_bad_loci.pl inputfile.txt

# It will automatically work with any file if the file name is not only a number. You need to configure the settings only if:
#   you file does not have a row with column headers, Any extra row you have can be commented out (#) and will ignored.
#   your file has extra columns, it will assume you have two initial columns to the left (usually individual and population) and then the third column until the last one is the data (loci).
#   your file is not tab separated. Or has only a row per individual.

# If you want to specify a different proportion of missing values per loci, you can write it after the program name: $ delete_bad_loci.pl 0.75

# And of course you can specify both in any order, the program will overwrite the default values. The file name must not be only a number:
# # $	delete_bad_loci.pl inputfilename 0.25
# # $	delete_bad_loci.pl 0.949 populations.structure


###########################################################################################################################
#######                                                                                                          ##########
#######         CHANGE LOG                                                                                       ##########
#######    2018-12-14  -  Version 2                                                                              ##########
#######     Implemented to run it remotely: from a directory that is not the actual local working directory      ##########
#######     Now it can be run automatically from the submission files after refmap + populations                 ##########
#######                                                                                                          ##########
###########################################################################################################################






# Edit only If your file in not tab separated, does not have two rows per individual, has more or less than 2 columns with metadata or does not have headers
#################################################################################################################
#########################################  DEFAULT ARGUMENTS  ###################################################
#################################################################################################################

my $inputname = "populations.structure_clean";	# input file name, should be a string either alphanumeric or alphabetic.

my $limitmiss = 0.3;						# the highest tolerable ratio of missing values.



########### Other Stuff

my $sep = '\t';								# symbol used to separate columns
#my $sep = ',';								# symbol used to separate columns

my $missing='0';							# Could be "-9";
#my $missing='-9';							# Could be "0";

my $rowsxind = 2;							# rows per individual, usually 1, but Structure is special and has 2. Not implemented for other values.
#my $rowsxind = 1;							# rows per individual, usually 1, but Structure is special and has 2. Not implemented for other values.

my $metadata = 2;							# number of columns in the file before the loci, usually two: individual ID and populations

my $headers = "yes";						# does the first row includes the loci names? yes/no. (rows starting with "#" will be ignored, so do not count them as headers.
#my $headers = "no";						# does the first row includes the loci names? yes/no. (rows starting with "#" will be ignored, so do not count them as headers.

#The output file will be automatically generated adding $tail to the input file name, it will delete any other "tail" at the right end of the input file name if they are after an underscore "_"
my $tail = "_neat";		#something to add at thze end of the inputfile name to name the output file

my $tempdir = "temp";		#to hold the results

use Cwd qw(cwd);
my $localdir = cwd;

#################################################################################################################
#################################################################################################################

my $argumentnumber = scalar (@ARGV);

if($argumentnumber == 0) {print "\nNo arguments specified, will trim loci with $limitmiss (or more) of missing in the file \"$inputname\"\n";
}
elsif($argumentnumber == 1) {
	my $argument = $ARGV[0];
	if ( $argument =~ /^[0-9,.E]+$/ ) {
		$limitmiss = $argument;
		print "\nOne numeric argument passed (proportion of missing), will trim loci with $limitmiss (or more) of missing in the file \"$inputname\"\n";
	}
	else {
		$inputname = $argument;
	print "\nOne argument passed (input file name), will trim loci with $limitmiss (or more) of missing in the file \"$inputname\"\n";
	}
}
elsif($argumentnumber == 2) {
	my $argument = $ARGV[0];
	if ( $argument =~ /^[0-9,.E]+$/ ) {
		$limitmiss = $argument;
		$inputname = $ARGV[1];
		print "\nTwo arguments passed (proportion of missing and file name), will trim loci with $limitmiss (or more) of missing in the file \"$inputname\"\n";
	}
	else {
		$inputname = $argument;
		$limitmiss = $ARGV[1];
		print "\nTwo arguments passed (input file name and proportion of missing), will trim loci with $limitmiss (or more) of missing in the file \"$inputname\"\n";
	}
}
else {
	die "\n\tSomething is wrong. Did you specify more than two arguments?\n\t  USAGE: For deleting loci with more than 0.5 of missing from \"populations.structure_clean\" just type:      delete_bad_samples.pl\n\t  You can also specify a different ratio of missing, a different input file, or both a different missing ratio and file name. Examples:\n\t\tdelete_bad_loci.pl 0.4\n\t\tdelete_bad_loci.pl inputfile.txt\n\t\tdelete_bad_loci.pl file.txt 0.8\n\t\tdelete_bad_loci.pl 0.8 file.txt\n\n";
}


# to deal with remote directories

my @directorypath = split('/' , $inputname);
my $pathlength = scalar @directorypath;
my $onlyfile = $directorypath[-1];
my $subdir = 0;
my $pathtemp;
my $logout;

if ($pathlength >= 2) {
	@pathonly = @directorypath;
	pop (@pathonly);
	$subdir = join('/', @pathonly);
	$subdirpath = "$localdir" . "/" . "$subdir";
	$pathtemp = "$subdirpath" . "/" . "$tempdir";
	$logout = "$subdirpath" . "/" . "delete_bad_loci.log";
}
else {
	$onlyfile = $inputname;
	$logout = "$localdir" . "/" . "delete_bad_loci.log";
	$pathtemp = "$localdir" . "/" . "$tempdir";

}






# my $filepath = "$localdir" . "/" . "$inputname";  	  #If you want to run it as standalone
my $filepath = "$pathtemp" . "/" . "$onlyfile";  	  #If you want to run it in dataset_fixer.sh pipeline

my @filename = split("_", $onlyfile);
my $keepname = $filename[0];
my $outname = "$keepname" . "$tail";		#name for the output file

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
				$missingcount[$col] = $missingcount[$col]+1;	#this array will add one each time it found a "missing"
				$col++;
			}
			else {
				$missingcount[$col] = $missingcount[$col]+0;
				$col++;
			}
		}
		push (@alldata, $line);		#add the line processed in the array
		$row++;
	}
}
close $FILE;

$numloci = $numbercols - $metadata;

if ($headers eq "yes") {
	$samples = $row - 1;
}
else {$samples = $row;}

$samplenum = $samples / 2;
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
		$reportloci = "$lociname   \t$ratio";
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
open my $OUT3, '>', $logout or die "\nUnable to create or save \"delete_bad_loci.log\" at $subdirpath: $!\n";


if ($del > 0) { print "\nAnalysis concluded: $del loci were found with a missing ratio above $limitmiss; list saved in the log file.";}
else {
	print $OUT3 "As expected all loci from $inputname had a proportion of missing values below $limitmiss!\n\n\n";
	print "$del loci found with a missing ratio equal or over $limitmiss; Good quality data you have there!\nNo loci need to be deleted\n\n";
	
	my $outpath = "$pathtemp" . "/" . "$outname";
	open my $OUTL, '>', $outpath or die "\nUnable to create or save $outname at $pathtemp: $!\n";
	# Loop over the array
	foreach (@alldata) {print $OUTL "$_\n";} # Print each entry in our array to the file
	close $OUTL; 
	die "Done!\n\n";
	}



#DELETE THE COLUMNS IN THE POSSITION MARKED AS "DELETE" for all the lines
$col = 0;
@keepdata =();
@keepalleles=();
@newline =();
$row = 0;

foreach (@alldata) {
	$line = $_;
	@alleles= split($sep, $line);
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
	$newline = join ( "\t" , @keepalleles); ###PROBLEM WITH \t WRITEN AS A TEXT
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

print "Done!\n\n";


