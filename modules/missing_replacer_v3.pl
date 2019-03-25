#!/usr/bin/perl
use strict ; use warnings;

# missing_replacer   			# by M'Óscar 
my $version = "missing_replacer_v3.pl";

############################

# Use this script to replace a specific value from a genepop file every time it appears.
#It has been done to replace every missing genotype with the most frequent genotype of each population.
#It requires a genepop input file as generated with PGDSpider.
# This is optimised to work as a dataset_fixer module. Although it should run also as stand alone.

# For options, usage and other information check the help typing the name of the program version and "help" or "--h" or so...
# missing_replacer_vX.pl -help



##########################################################################################################################################################
#######                                                                                                                                         ##########
#######                     CHANGE LOG                                                                                                          ##########
#######    2018-12-14  -  Version 3                                                                                                             ##########
#######     Implemented flags to pass arguments from command line, to be able to set more options from it                                       ##########
#######     Implemented again to replace regular missing values with the global most frequent genotype of the whole dataset                     ##########
#######     More customizable and with a better help information                                                                                ##########
#######                                                                                                                                         ##########
#######    [2018-12-14  -  Version 2.1 (lost)]                                                                                                  ##########
#######     [Implemented to replace the missing value of a population with the global most frequent genotype of the dataset]                    ##########
#######     Sadly there was an error in Isabella server and this version was lost. Will be implemented again at some point                      ##########
#######                                                                                                                                         ##########
#######    2018-12-14  -  Version 2                                                                                                             ##########
#######     Implemented to run it remotely: from a directory that is not the actual local working directory                                     ##########
#######                                                                                                                                         ##########
#######    2018-11-17  -  Version 1.5                                                                                                           ##########
#######     Fixed a bug that will not handle well when a genotype was missing for an entyre population                                          ##########
#######     When populations -p flag is smaller than the total number of populations, some populations may completely miss a genotype           ##########
#######     Those population-wise missing be replaced with either $input_value or with the most common genotype across all populations          ##########
#######                                                                                                                                         ##########
##########################################################################################################################################################







#######################   PARAMETERS   #########################
# Most of them can be set from the command line, check the help.



my $inputname = "temp/populations.structure.genepop";  		# input file name, should be a string either alphanumeric or alphabetic

#Are the population names in the individual tags? This is needed because when transforming to Genepop format the population names are lost.
#If the pop names are in the name tags this program will restore them
my $poplenght = 2;  		#How many characters has the population name. Assuming that the population name is in the first few letters of sample name.
#my $poplenght = 2;  		#How many characters has the population name. Assuming that the population name is in the first few letters of sample name.
#my $poplenght = 3;  		#How many characters has the population name. Assuming that the population name is in the first few letters of sample name.
#my $poplenght = 0;  		#The population name is not in the first few letters of sample name.

# Which value to input when locus is missing for most of population (there is more missing than no-missing). This will ojnly happen if parameter "p" in ref_maps is smaller than the number of populations.
my $input_value = "005005";   		# 5 to mark that is a different state from a regular allele (1-4)
#my $input_value = "000000";   		# 0 to keep it as missing
#my $input_value = "global";   		# this will input the most common genotype for that loci in all the dataset

#Which value input when missing in just a few samples per population.
my $input_glob = "pop";   			# will input the most frequent genotype for that locus in the population the sample belongs to
#my $input_glob = "global";   			# this will input the most common genotype for that locus in all the dataset
#my $input_glob = "000000";   			# 0 to keep it as missing

#Any other genotype you want to replace?
my $extramiss = "00000000";   			#add here any other genotype that you want considered as "missing" and therefore replaced
#my $extramiss = "00000000";   			#add here any other genotype that you want considered as "missing" and therefore replaced

my $headers = "yes";   			# the loci names are in the file and you want to include them as headers? (rows starting with "#" will be ignored, so do not count them as headers.
#my $headers = "no";   			# the loci names are in the file and you want to include them as headers? (rows starting with "#" will be ignored, so do not count them as headers.

my $sep = " ";		#symbol used to separate the columns
#my $sep = "\t";		#symbol used to separate the columns

my $tempfolder = "temp";		#name of the directory that will hold all the folders with the outputs
#my $tempfolder = "temp";		#name of the directory that will hold all the folders with the outputs

#filer low quality populations?
my $limpopsize = 5;  		#Minimum number of samples per populations, if the number of samples in a population is bellow this value, the population will be deleted
#my $limpopsize = 5;  		#Minimum number of samples per populations, if the number of samples in a population is bellow this value, the population will be deleted

# First row: Genepop files can have a title in the first row, sometimes is mandatory
my $first_row = "File generated from $inputname with $version: $input_glob mode input in missing, $input_value mode if missing in an entire population";		#add here whatever you want to appear in the first row of the final genepop input file as title
#my $first_row = "#File with no missing values, population mode was input in missing genotypes, $input_value was input when locus was missing in an entire population. Original file: $inputname";		#add here whatever you want to appear in the first row of the final genepop input file as title
#my $first_row = "no";		#this in command line will have the same effect than not passing any title (use default)

# Final file tail
my $definitive = "_fixed";		#this will be added to the final file.
#my $definitive = "_fixed";		#this will be added to the final file.




###################### Other minor options ####################
###############################################################

my $outfolder = "bypop";		#output folder for the genepop files separated by population

# Transpose files 
my $transfilter = "genepop";		# a string that must be present in the input file name in order to process it
my $transout = "_trans";		#this will be added at the end of the transposed output files
my $results_folder = "trans" ;		#out folder for your transposed files

# Replace missing
my $replaced = "_nomiss";		#this will be added at the end of the transposed output files after processing them
my $replaceout = "nomiss" ;		#out folder for your files free of missing values

# Untranspose
my $untrans = "_untrans";		#this will be added at the end of the transposed output files
my $untransposed = "untrans" ;		#out folder for your transposed files

#output for the reference genotypes.
# Only used if $input_value ="global" and if there are loci missing for an entire population -> -p in Populations (Stacks) < number of populations
my $reffolder = "ref";
my $refout = "_ref";




#################################################################################################################
#################################################################################################################







#Help!
my %arguments = map { $_ => 1 } @ARGV;
if(exists($arguments{"help"}) || exists($arguments{"--help"}) || exists($arguments{"-help"}) || exists($arguments{"-h"}) || exists($arguments{"--h"})) {
	die "\n\n\t   $version   Help Information\n\t-------------------------------------------------\n
	This program will replace a specific genotype from a Genepop file (every time it appears) with a specific genotype.
	Its designed to find the missing genotypes and input the desired genotype.
	
	By default it will consider as missing any column coded as \"000000\", \"0000\", \"00\", \"0\", or (customizable): \"$extramiss\".
	By default in any individual missing data from a locus, it will input\n\tthe population mode (most frequent genotype in the population).
	By default if a loci is missing in a majority of individuals of a population (mode = 000000) it will input \"$input_value\".
	
	It has been tested with the Genepop file generated by the program PGDSpider,
	Usually those genepop files have a title in the first line and give errors if deleted.
	Default input file name: \"$inputname\".
	
	The output file will be saved in a subdirectory called \"$tempfolder\"
	The output file name will be the input file name + a tail,
	 output file name by default: $inputname$definitive;
	 first row (title) by default (number of samples, loci and population will be added at the end after processing the file):
 $first_row
	
	To run the default just call the program:
	
		$version
	
	Parameters to use if need to change defaults:
	--input            set a different file name or path to the input file (default: $inputname)
	--sep              symbol used to separate columns, usually space \' \', but can be tab \'\\t\', comma \',\', or semmicolon \';\'.
	-nohead            add this if your input file does not have loci names and/or you don't want them in your output file
	--popcode          if the individual tags start with the population code, how many characters long is it (default: $poplenght)
	                   this is neded because on transforming to genepop PGDSpider deletes population codes/tags
	                        HRV001 --> --popcode 3; ST042 --> --popcode 2;
	                        --popcode 0 <-- If you don't want or don't have population tags in your individual name tags
	--extra_gen        another genotype to be replaced, apart from \"000000\", \"0000\", \"00\", and \"0\". (default: $extramiss)
	--miss_gral        what to input with general missing genotypes: input population mode: \"pop\";
	                        input mode from all samples: \"global\"; leave it as missing: \"000000\" (default: $input_glob)
	--miss_pop         what to input if a locus is missing in most of the population: input mode from all samples: \"global\";
	                        leave it as missing: \"000000\"; or input something to underline the difference (default: $input_value)
	--minpop           minimum number of individuals per population in order for it to be processed (default: $limpopsize)
	--title            something different to print as a comment/title in the first row? Use quotation marks.
	                    if = \"no\" ( --title no ) or the flag is not used will use default title.
	--dir              subdirectory to save the results (default: $tempfolder)
	--tail             string to add at the end of the input file name to generate the output file name (default: $definitive)
	
	Example:
	
		$version --input /home/refmap/temp/input.genepop --popcode 4 --miss_gral pop --miss_pop global nohead
	
	This program is optimized to run as part of \"dataset_fixer.sh\" although it should also work as stand alone.
	Because of the dataset_fixer pipeline there were some redundancies with the output $tempfolder/ subdirectory:
	 If the input file was already in $tempfolder/ it could duplicated for the output: $tempfolder/$tempfolder/$inputname
	 To solve this, if needed, the program will change   $tempfolder/$tempfolder/  to   $tempfolder/
	This program has not been tested with other file formats, probably it will not work well.
	This program has not been tested on animals, but our dog seems ok with it.
	\n\n";
}



use Getopt::Long;

GetOptions( "input=s" => \$inputname,              #   --input
            "popcode=i" => \$poplenght,            #   --popcode
            "extra_gen=s" => \$extramiss,          #   --extra_gen
            "miss_gral=s" => \$input_glob,         #   --miss_gral
            "miss_pop=s" => \$input_value,         #   --miss_pop
            "minpop=i" => \$limpopsize,            #   --minpop
            "title=s" => \$first_row,              #   --title
            "dir=s" => \$tempfolder,               #   --dir
            "tail=s" => \$definitive,             #   --tail
            "sep=s" => \$sep );                    #   --sep


if(exists($arguments{"--nohead"})) { $headers = "no";}
if(exists($arguments{"-nohead"})) { $headers = "no";}
if(exists($arguments{"nohead"})) { $headers = "no";}

#update the default title with the new values if no new title is passed
if(!exists( $arguments{"--title"}) | $first_row eq "no" ) { 
$first_row = "#$inputname > $version: $input_glob mode input in missing, $input_value if missing in most of the population";		#in case something changed
}

#debug
#die "\nParameters:\n  Input file name:  $inputname\n  Print loci as headers?  $headers\n  Columns separated by  \"$sep\"\n  Minimum allowed population size:  $limpopsize\n  Tail added to the file name:  $definitive\n  Output file stored at:  $tempfolder\n  Missing will be replaced by:  $input_glob\n  Missing in an entire population by:  $input_value\n  Will consider a missing genotype this:  $extramiss\n  The population code is in the first letters of the tags:  $poplenght\n  Title:\n$first_row\n\n";

my $argumentnumber = keys %arguments;
if($argumentnumber == 0) {print "\n\nNo arguments specified, using defaults:\n";}
else { print "\n\n";}
print "$version will check missing genotypes at $inputname,\npopulation codes are in the first $poplenght characters of the individual tags.\nWill replace general missing genotypes with \"$input_glob mode\". If a locus is missing in most of the population \"$input_value\" will be input\nCheck the help information if needed.\n\n";







#################################################################################################################
#################################################################################################################



use Cwd qw(cwd);
my $localdir = cwd;




#DEALING WITH LONG WEIRD PATHS FROM dataset_fixer


my @directorypath = split('/' , $inputname);
my $pathlength = scalar @directorypath;
my $firstdir = 0;
my $lastdir = 0;
my $onlyfile = 0;
my $keepname = 0;
my $subdirpath = 0;
my $temp=0;
my $filepath = 0;
my $finalname = "$inputname" . "$definitive";
my $finalpath = 0;


if ($pathlength > 1) {
	my $firstdir = $directorypath[0]; #check
	my $lastdir = $directorypath[-2]; #temp
	$onlyfile = $directorypath[-1]; #populations.structure_neat_clean
	#print "Directory path: @directorypath\nFile name: $onlyfile\n";
	pop (@directorypath);
	$subdirpath = join ('/' , @directorypath);
	#print "Subdirpath: $subdirpath\n";
	$temp="$subdirpath" . "/" ."$tempfolder";
	if ($lastdir ne $tempfolder) {
		unless(-e $temp or mkdir $temp) {die "\nUnable to create \"$temp\" to hold the outputs\nMay be you don't have the rights: $!\n"; }
	}
	$filepath = $inputname;
	$finalpath = $finalname;
}
else {
	$temp = "$localdir" . "/" . "$tempfolder";
	$filepath = "$localdir" . "/" . "$inputname";
	$onlyfile = $inputname;
	$finalpath = "$localdir" . "/" . "$finalname";
}
#print "temp direct: $temp\n";



my $subdir = 0;
my $logout = 0;




my @namesplit = split ('_', $onlyfile);
my $length = scalar @namesplit;
#print "file name length: $length\n";
if ($length >= 2) { $keepname = $namesplit[0];}
else {$keepname = $onlyfile;}

#print "Filename to keep: $keepname\n";


my $refdir = "$temp" . "/" . "$reffolder";
$refdir=~ s/temp\/temp\//temp\//;
my $moda = 0;
my $samplenum = 0;
my $locinum = 0;
my %freqgenot = ();
my $column=0;
my @nomissing =();
my $refname = "$keepname$refout";
my $refpath ="$refdir/$refname";
my $transref = "$refpath$transout" ;
my $k = 0;
my %refgenotyped = ();








################################################################################################################################################################################
####			GENERATE REFERENCE GENOTYPES IN CASE THERE ARE LOCI MISSING IN ENTIRE POPULATIONS (If -p in populations (Stacks) is < number of populations					####
################################################################################################################################################################################




if ($input_value eq "global" || $input_glob eq "global") {

	
	
	unless(-e $refdir or mkdir $refdir) {die "\nUnable to create \"$refdir:\n$!\n"; }
	print "\nReading $inputname ...\n";

	my @matrixref =();

	######################### Clean


	open my $FILER, '<', $filepath or die "\nUnable to find or open $filepath: $!\n";

	print "\nCleaning input file...\n";
	while (<$FILER>) {
		chomp;	#clean "end of line" symbols
		next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
		my $line = $_;
		$line =~ s/\s+$//;		#clean white tails in lines
		my @filelines = ();
		@filelines= split($sep, $line);	#split columns as different elements of an array
		
		next if ( ! defined $filelines[5] );		  #skip lines with only loci names or "pop";
		$line =~ s/ , //;
		push (@matrixref, $line); 
	}

	close $FILER;


	#save the file

	$refname = "$keepname$refout";
	$refpath ="$refdir/$refname";
	$refpath=~ s/temp\/temp\//temp\//;
	open my $OUTR, '>', $refpath or die "\nUnable to create or save \"$refname\" at \"$refdir\": $!\n";
	foreach (@matrixref) {print $OUTR "$_\n";} # Print each entry in our array to the file
	close $OUTR; 









	########## TRANSPOSE



	transpose_tabler($refname, $sep);









	######## SAVE MOST COMMON GENOTYPE
	print "Most common (global) genotype for each locus will be saved saved as a reference.\n\n";


	my $globalpath = "$refdir" . "/" . "$transref";
	#print "\nOpen path:\n$globalpath\n\n";
	#print "\nDirectory:\n$refdir\n\n";
	#print "\nFile:\n$transref\n\n";


	open my $FILEG, '<', $transref or die "\nUnable to find or open $transref: $!\n";

	

	
	


	while (<$FILEG>) {
		chomp;	#clean "end of line" symbols
		next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
		my $line = $_;
		$line =~ s/\s+$//;		#clean white tails in lines
		my @globalalleles= split($sep, $line);	#split columns as different elements of an array
		$samplenum = scalar (@globalalleles);
		
		if ($locinum == 0) {
			$locinum++;
		}
		else {
			#loop through the array and save the globalalleles, if it already appeared, add 1 to its value
			foreach (@globalalleles) {
				my $onegenotype = $_;
				if ($onegenotype eq "000000" | $onegenotype eq "0000" | $onegenotype eq "00" | $onegenotype eq "0"| $onegenotype eq $extramiss) {   			#changed this, may need debugging
					$column++;
				}
				elsif (exists $freqgenot{$onegenotype}) {
					$freqgenot{$onegenotype} = $freqgenot{$onegenotype} +1;
					$column++;
				}
				else { 
					$freqgenot{$onegenotype} = 1;
					$column++;
				}
			}
			
			#sort the hash acording to the values, times that each genotype appears
			for $k (sort {$freqgenot{$a} <=> $freqgenot{$b} || $a cmp $b } (keys %freqgenot) ) { $moda = $k; }
			
			$refgenotyped{$locinum} = "$moda";
			
			$locinum++;
		}
			%freqgenot =();
	}

	close $FILEG;
}







####################################################################################################################
####						SPLIT GENEPOP FILE BY POPULATION AND SAVE LOCI NAMES (if Headers)					####
####################################################################################################################


my $newfolder = "$temp" . "/" . "$outfolder";
#print "newfolder: $newfolder\n";
$newfolder=~ s/temp\/temp\//temp\//;
$newfolder=~ s/temp\/temp\//temp\//;
#print "newfolder: $newfolder\n";
#unless(-e $newfolder or mkdir $newfolder) {die "\nUnable to create \"$outfolder\" at $temp:\n$!\n"; }
unless(-e $newfolder or mkdir $newfolder) {die "\nUnable to create \"$newfolder\":\n$!\n"; }
print "Saving data from each population...\n";



#######################################


open my $FILE1, '<', $filepath or die "\nUnable to find or open $filepath: $!\n";

my $linenum = 0;
$samplenum = 0;
my $locinames = 0;
my $popname = 0;
my @onepop = ();
my $outpath = 0;
my $outname = 0;
my $popnum = 0;
my @locis = ();

my $popsize=0;

while (<$FILE1>) {
	chomp;	#clean "end of line" symbols
	next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
	
	my $line = $_;
	$line =~ s/\s+$//;		#clean white tails in lines
	my @newline= split($sep, $line);	#split columns as different elements of an array
	
	if($headers eq "no" && $linenum == 0) {$linenum++;}
	
	if ($headers eq "yes" && $linenum==0 && $newline[0] ne "Pop") {
		$locinames = $line;		#save names of the loci from the headers
		push (@locis, $locinames);
	}
	elsif($newline[0] eq "Pop" && $linenum <= 1) {$linenum++;}		#skip the first "pop" line
	elsif($newline[0] ne "Pop" && $linenum >= 1 && $poplenght >= 1) {   			# THIS OPTION IS NEW MAY NEED DEBUGGING!
		my $samplename = $newline[0];
		my @sample = split ('', $samplename);
		my $namelenght = scalar (@sample);
		my $todelete = $namelenght - $poplenght;
		my @population = @sample;
		splice @population, $poplenght, $todelete;
		$popname = join ('', @population);		#save the characters that correspond to the population name from the sample name
		$line =~ s/ , //;
		push (@onepop, $line);					#save the lines of data
		$linenum++;
		$samplenum++;
	}
		elsif($newline[0] ne "Pop" && $linenum >= 1 && $poplenght == 0) {   			# THIS OPTION IS NEW MAY NEED DEBUGGING!
		my $popname = $newline[0];
		$line =~ s/ , //;
		push (@onepop, $line);					#save the lines of data
		$linenum++;
		$samplenum++;
	}
	elsif($newline[0] eq "Pop" && $linenum >= 3) {
		$popsize = scalar (@onepop);
		if ($popsize >= $limpopsize) {
			#print "File name: $keepname and $popname\n";
			$outname = "$keepname" . "_" . "$popname";
			#print "Folder: $newfolder\n";
			$outpath = "$newfolder" . "/" . "$outname";
			#print "Outpath pre: $outpath\n";
			$outpath=~ s/temp\/temp\//temp\//;		#this line will fix the possible duplication of a temp folder to hold the results.
			#print "Outpath post: $outpath\n";
			open my $OUT1, '>', $outpath or die "\nUnable to create or save \"$outpath\": $!\n";
			# When the next "pop" is found, save the data stored in the array
			foreach (@onepop) {print $OUT1 "$_\n";} # Print each entry in our array to the file
			close $OUT1; 
		
			print "Data from population $popname saved at $outfolder" . "/" . "$outname\n";
		}
		else {print "Oh no, population $popname has only $popsize samples left. And will not be included in the final input file\n";}
		@onepop = ();
		$linenum++;
		$popnum++;
	}
	else { print "Dude, I'm afraid somethink is wrong in your code...\n\n";}
}

close $FILE1;

$locinum = scalar (@locis);


#save the last population

$popsize = scalar (@onepop);
if ($popsize >= $limpopsize) {
	$outname = "$keepname" . "_" . "$popname";
	$outpath = "$newfolder" . "/" . "$outname";
	$outpath=~ s/temp\/temp\//temp\//;
	open my $OUT1, '>', $outpath or die "\nUnable to create or save \"$outpath\": $!\n";
	# When the next "pop" is found, save the data stored in the array
	foreach (@onepop) {print $OUT1 "$_\n";} # Print each entry in our array to the file
	close $OUT1; 
	$linenum++;
	print "Data from population $popname saved at $outfolder" . "/" . "$outname\n";
	$popnum++;
}
else {print "Oh no, population $popname has only $popsize samples left. And will not be included in the final input file\n";}




print "\nOriginal file included data from $samplenum samples and $locinum loci\n";
print "$popnum files (one per population) saved in the directory \"$outfolder\".\n\n";




####################################################################################################################
####										TRANSPOSE ALL FILES GENERATED										####
####################################################################################################################


$newfolder = "$temp" . "/" . "$outfolder";
$newfolder=~ s/temp\/temp\//temp\//;
my $resultspath = "$temp" . "/" . "$results_folder";
$resultspath=~ s/temp\/temp\//temp\//;



################

unless(-e $resultspath or mkdir $resultspath) {die "\nUnable to create \"$resultspath: $!\n"; }


opendir(DIR, $newfolder) || die "can't open directory $newfolder: $!";						#open the directory with the files
my @genepopfiles = sort(grep(!/^(\.|\.\.)$/, readdir(DIR)));   			#extract file names
closedir(DIR);

#searching the bug
print "\n@genepopfiles\n";

my $filenumber = 0;
print "\nReading files from $newfolder:\n" ;
foreach my $popfile (@genepopfiles) {					#process all the files one by one
	next if ($popfile =~ /^\.$/);				#don't use any hidden file
	next if ($popfile =~ /^\.\.$/);			
	#next unless ($popfile =~ /.*$transfilter.*$/);		#read only genepop files
	transpose_table1($popfile, $sep);
	print "\t$popfile done!\n";
	$filenumber++;
}

print "\n$filenumber files were transposed and saved in directory \"$results_folder\".\n\n";






####################################################################################################################
####								REPLACE MISSING WITH THE MOST COMMON GENOTYPE 								####
####################################################################################################################


$resultspath = "$temp" . "/" . "$results_folder";		#results from transpose
my $replacedpath = "$temp" . "/" . "$replaceout";		#outputs from this script
$replacedpath=~ s/temp\/temp\//temp\//;
$resultspath=~ s/temp\/temp\//temp\//;


################


unless(-e $replacedpath or mkdir $replacedpath) {die "\nUnable to create \"$replaceout\" at\n$temp\nMay be you don't have the rights: $!\n"; }




opendir(DIR2, $resultspath) || die "can't open directory $resultspath: $!";						#open the directory with the files
my @transfiles = readdir(DIR2);					#extract filenames
closedir(DIR2);

print "\nNow looking for missing values in the files saved in \"$resultspath\":\n\n" ;

$filenumber = 0;
my $missn=0;

foreach my $transfile (@transfiles) {					#process all the files one by one
	next if ($transfile =~ /^\.$/);				#don't use any hidden file
	next if ($transfile =~ /^\.\.$/);			
	next unless ($transfile =~ /$transout$/);		#read only transposed files


	my $filetranspath = "$resultspath" . "/" . "$transfile";
	open my $FILET, '<', $filetranspath or die "\nUnable to find or open $transfile at $resultspath: $!\n";

	my $nsamples = 0;
	my $nloci = 0;
	%freqgenot = ();
	$column=0;
	@nomissing =();
	$moda = 0;
	$k = 0;
	$missn = 0;
	my $nopop = 0;

	while (<$FILET>) {
		chomp;	#clean "end of line" symbols
		next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
		my $line = $_;
		$line =~ s/\s+$//;		#clean white tails in lines
		my @genotypes= split($sep, $line);	#split columns as different elements of an array
		$nsamples = scalar (@genotypes);
		
		if ($nloci == 0) {
			push (@nomissing, $line); 
			print "Procesing data of file $transfile:\n";
		}
		else {
			#loop through the array and save the genotypes, if it already appeared, add 1 to its value
			foreach (@genotypes) {
				my $onegenotype = $_;
				if ($onegenotype eq "000000" | $onegenotype eq "0000" | $onegenotype eq "00" | $onegenotype eq "0" | $onegenotype eq $extramiss) {   			#changed this, may need debugging
					$column++;
				}
				elsif (exists $freqgenot{$onegenotype}) {
					$freqgenot{$onegenotype} = $freqgenot{$onegenotype} +1;
					$column++;
				}
				else { 
					$freqgenot{$onegenotype} = 1;
					$column++;
				}
			}
			
			#foreach my $key (keys %freqgenot) {print "$key (" . "$freqgenot{$key}" . ") ";}
			
			#sort the hash acording to the values, times that each genotype appears
			for $k (sort {$freqgenot{$a} <=> $freqgenot{$b} || $a cmp $b } (keys %freqgenot) ) { $moda = $k; }
			
			#replace every missing ("0000") 
			
			$column = 0;
			
			foreach (@genotypes) {
				my $onegenotype = $_;
				if ($onegenotype eq "000000" | $onegenotype eq "0000" | $onegenotype eq "00" | $onegenotype eq "0" | $onegenotype eq $extramiss) {   			#changed this, may need debugging
					if ($input_glob eq "pop" && $moda != 0) {
						$genotypes[$column] = $moda;
						if ($missn == 0) {print "Found missing genotypes from some loci in some samples: The most common genotype for that loci in the population will be input\n";}
						$missn++;
					}
					elsif ($input_glob eq "global" && $moda != 0) {
						$moda = $refgenotyped{$nloci};
						$genotypes[$column] = $moda;
						if ($missn == 0) {print "Found missing genotypes from some loci in some samples: The most common global genotype for that loci will be input\n";}
						$missn++;
					}
					elsif ($moda != 0) {
						$moda = $input_glob;
						$genotypes[$column] = $moda;
						if ($missn == 0) {print "Found missing genotypes from some loci in some samples: \"$input_glob\" will be input in those missing genotypes\n";}
						$missn++;
					}
					elsif ($moda == 0 && $input_value eq "global") {
						$moda = $refgenotyped{$nloci};
						$genotypes[$column] = $moda;
						if ($nopop == 0) {print "Found genotypes from some loci that are missing for most of the population: The most common global genotype will be input\n";}
						$nopop++;
					}
					elsif ($moda == 0) {
						$moda = $input_value;
						$genotypes[$column] = $moda;
						if ($nopop == 0) {print "Found genotypes from loci that are missing for an entire population: $input_value will be input in those missing genotypes\n";}
						$nopop++;
					}
				}
				$column++;
			}
			
			$moda = 0;
			#save
			my $notmiss = join ($sep , @genotypes);
			push (@nomissing, $notmiss);
			
			$column = 0;
		}
		$nloci++;
		%freqgenot =();
	}

	close $FILET;




	my $fixed = "$transfile" . "$replaced";
	my $pathfixed = "$replacedpath" . "/" . "$fixed";
	open my $OUTR, '>', $pathfixed or die "\nUnable to create or save \"$fixed\" at \"$replacedpath\": $!\n";
	foreach (@nomissing) {print $OUTR "$_\n";} # Print each entry in our array to the file
	close $OUTR;
	print "$missn missing values replaced!\n\n";

	$filenumber++;
}


print "$filenumber Files processed and saved in directory \"$replaceout\".\n\n";









####################################################################################################################
####								UNTRANSPOSE DATA IN FILES and JOIN THEM BACK 								####
####################################################################################################################


$newfolder = "$temp" . "/" . "$replaceout";
$newfolder=~ s/temp\/temp\//temp\//;
$resultspath = "$temp" . "/" . "$untransposed";
$resultspath=~ s/temp\/temp\//temp\//;


################ Transpose

unless(-e $resultspath or mkdir $resultspath) {die "\nUnable to create \"$untransposed\" at\n$temp\nMay be you don't have the rights: $!\n"; }


opendir(DIR3, $newfolder) || die "can't opendir $newfolder: $!";						#open the directory with the files
my @nomissfiles = readdir(DIR3);					#extract filenames
closedir(DIR3);

$filenumber = 0;
print "Reading files from $newfolder:\n" ;
foreach my $refillfile (@nomissfiles) {					#process all the files one by one
	next if ($refillfile =~ /^\.$/);				#don't use any hidden file
	next if ($refillfile =~ /^\.\.$/);			
	next unless ($refillfile =~ /$replaced$/);		#read only genepop files
	transpose_table2($refillfile, $sep);
	print "\tdone!\n";
	$filenumber++;
}


print "the $filenumber files were transposed back.\n\n";




############### Join files


my @finalfile =();
print "Now joining them together\n";

my $title = "$first_row: $samplenum samples from $filenumber populations and $locinum loci";

push (@finalfile, $title);
#If the original file has loci names in the first row, save them
if ($headers eq "yes") { push (@finalfile, @locis); }


opendir(DIR4, $resultspath) || die "can't open directory $untransposed at $temp: $!";						#open the directory with the files
my @filestojoin = readdir(DIR4);					#extract filenames
closedir(DIR4);


my $filecount = 0;
print "\nCopying data from files in directory \"$untransposed\":\n" ;


foreach my $filefixed (@filestojoin) {					#process all the files one by one
	next if ($filefixed =~ /^\.$/);				#don't use any hidden file
	next if ($filefixed =~ /^\.\.$/);			
	next unless ($filefixed =~ /$untrans$/);		#read only fixed files

	my $filetojoin = "$resultspath" . "/" . "$filefixed";
	open my $FILEU, '<', $filetojoin or die "\nUnable to find or open $filefixed at $resultspath: $!\n";
	push (@finalfile, "Pop");		#print "pop" before each population data
	while (<$FILEU>) {
		chomp;	#clean "end of line" symbols
		next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
		my $line = $_;
		$line =~ s/\s+$//;		#clean white tails in lines
		my @lastline= split($sep, $line);	#split columns as different elements of an array
		my $sample = $lastline[0];
		$line =~ s/$sample /$sample ,  /;
		push (@finalfile, $line);		#save each line of the file in an array
	}
	print "File $filefixed...  Processed\n";
	close $FILEU;
}


#save all data in a file

open my $OUTF, '>', $finalpath or die "\nUnable to create or save \"$finalpath\": $!\n";
foreach (@finalfile) {print $OUTF "$_\n";} # Print each entry in our array to the file
close $OUTF;
print "All files joined in $finalname\n\nThe script finished with no errors (hopefully)\n\n\t$version is done!\n\n";








###########################################################################################################################################
###########################################################################################################################################
















####################################################################################################################
####													SUBROUTINES												####
####################################################################################################################




sub transpose_table2 {
  my $refillfile = shift ;
  my $sep = shift ;

  my $file = "$newfolder/$refillfile" ;
  my $transposed_file = "$resultspath/$refillfile$untrans" ;
  my @data ;
  my $size ;
  my @size ;
  my $size_temp ;
  my @tmp ;
  my $line ;
  

  open F2, '<', $file or die "Couldn't read from $file file: $!";
  open T2, '>', $transposed_file or die "Couldn't write to $transposed_file file: $!";

	# test if the first 3 lines are identical, die if not
	for  my $i (1 .. 3 ){
		$line = (<F2>);
		chomp $line;
		@tmp  = $line =~ /$sep/g;
		$size[$i-1] =  @tmp +1 ; # table size, nb of columns in the non transposed table -> nb of lines after transposition
	}
	close(F2) ;
	($size[0]  == $size[1]  and $size[0] == $size[2]) ? print "transposing $refillfile" : die "Legth of the lines are different\n" ;

	
	open F2, '<', $file or die "Couldn't read from $file file: $!";
  #my $l = 1; # line #
  my $c = 1 ; # column #
  while ($line = <F2>)
    {
		chomp $line;
		$line =~ s/\s+$//;		#clean white tails in lines
	    @tmp  = split "$sep", $line;
	    $data[$c] = [ @tmp ];
        my @count  = $line =~ /$sep/g; # count the nb of separators
	    $size = @count +1 ; # table size, nb of columns in the non transposed table -> nb of lines after transposition
	    $size  ==  $size[1] ? 1 : die "Error the size of the table is not constant at line $c : $size  instead of  $size[1]\n" ;
	    ++$c ;
    } 
  print " ... " ;


  for (my $i = 0 ; $i < $size ; $i++){
    for (my $j = 1 ; $j < $c ; $j++){
      # print "i:$i , j:$j\n";
      if ($j < $c -1 ) {
          if (exists $data[$j][$i])  {
                #print "$data[$j][$i]"."$sep";
	            print T2 $data[$j][$i]."$sep" ;
          } else {
              print T2 "$sep" ;
          }
	    
      }
      else {
	    # suppress the last separator
        if (exists $data[$j][$i])  {
	        #print "$data[$j][$i]";
	        print T2 $data[$j][$i];
        }
      }
    }
    
    #print "\n";
    print T2 "\n";
  }
  close F2;
  close T2;
}




##################





sub transpose_table1 {
  my $popfile = shift ;
  my $sep = shift ;

  my $file = "$newfolder/$popfile" ;
  my $transposed_file = "$resultspath/$popfile$transout" ;
  my @data ;
  my $size ;
  my @size ;
  my $size_temp ;
  my @tmp ;
  my $line ;
  

  open F, '<', $file or die "Couldn't read from $file file: $!";
  open T, '>', $transposed_file or die "Couldn't write to $transposed_file file: $!";

	# test if the first 3 lines are identical, die if not
	for  my $i (1 .. 3 ){
		$line = (<F>);
		chomp $line;
		@tmp  = $line =~ /$sep/g;
		$size[$i-1] =  @tmp +1 ; # table size, nb of columns in the non transposed table -> nb of lines after transposition
	}
	close(F) ;
	($size[0]  == $size[1]  and $size[0] == $size[2]) ? print "transposing $popfile" : die "Legth of the lines are different\n" ;

	
	open F, '<', $file or die "Couldn't read from $file file: $!";
  #my $l = 1; # line #
  my $c = 1 ; # column #
  while ($line = <F>)
    {
		chomp $line;
		$line =~ s/\s+$//;		#clean white tails in lines
	    @tmp  = split "$sep", $line;
	    $data[$c] = [ @tmp ];
        my @count  = $line =~ /$sep/g; # count the nb of separators
	    $size = @count +1 ; # table size, nb of columns in the non transposed table -> nb of lines after transposition
	    $size  ==  $size[1] ? 1 : die "Error the size of the table is not constant at line $c : $size  instead of  $size[1]\n" ;
	    ++$c ;
    } 
  print " ... " ;


  for (my $i = 0 ; $i < $size ; $i++){
    for (my $j = 1 ; $j < $c ; $j++){
      # print "i:$i , j:$j\n";
      if ($j < $c -1 ) {
          if (exists $data[$j][$i])  {
                ##print "data[$j][$i]"."$sep";
	            print T $data[$j][$i]."$sep" ;
          } else {
              print T "$sep" ;
          }
	    
      }
      else {
	    # suppress the last separator
        if (exists $data[$j][$i])  {
	        #print "$data[$j][$i]";
	        print T $data[$j][$i];
        }
      }
    }
    
    #print "\n";
    print T "\n";
  }
  close F;
  close T;
}




##################





sub transpose_tabler {
  my $refname = shift ;
  my $sep = shift ;

  my $file = $refpath ;
  my $transposed_file = $transref;
  my @data ;
  my $size ;
  my @size ;
  my $size_temp ;
  my @tmp ;
  my $line ;
  

  open F, '<', $file or die "Couldn't read from $file file: $!";
  open T, '>', $transposed_file or die "Couldn't write to $transposed_file file: $!";

	# test if the first 3 lines are identical, die if not
	for  my $i (1 .. 3 ){
		$line = (<F>);
		chomp $line;
		@tmp  = $line =~ /$sep/g;
		$size[$i-1] =  @tmp +1 ; # table size, nb of columns in the non transposed table -> nb of lines after transposition
	}
	close(F) ;
	($size[0]  == $size[1]  and $size[0] == $size[2]) ? print "transposing $refname" : die "Legth of the lines are different\n" ;

	
	open F, '<', $file or die "Couldn't read from $file file: $!";
  #my $l = 1; # line #
  my $c = 1 ; # column #
  while ($line = <F>)
    {
		chomp $line;
		$line =~ s/\s+$//;		#clean white tails in lines
	    @tmp  = split "$sep", $line;
	    $data[$c] = [ @tmp ];
        my @count  = $line =~ /$sep/g; # count the nb of separators
	    $size = @count +1 ; # table size, nb of columns in the non transposed table -> nb of lines after transposition
	    $size  ==  $size[1] ? 1 : die "Error the size of the table is not constant at line $c : $size  instead of  $size[1]\n" ;
	    ++$c ;
    } 
  print " ...\n" ;


  for (my $i = 0 ; $i < $size ; $i++){
    for (my $j = 1 ; $j < $c ; $j++){
      # print "i:$i , j:$j\n";
      if ($j < $c -1 ) {
          if (exists $data[$j][$i])  {
                #print "$data[$j][$i]"."$sep";
	            print T $data[$j][$i]."$sep" ;
          } else {
              print T "$sep" ;
          }
	    
      }
      else {
	    # suppress the last separator
        if (exists $data[$j][$i])  {
	        #print "$data[$j][$i]";
	        print T $data[$j][$i];
        }
      }
    }
    
    #print "\n";
    print T "\n";
  }
  close F;
  close T;
}
