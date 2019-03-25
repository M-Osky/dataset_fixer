#!/usr/bin/perl
#missing_replacer_v2.pl
use strict ; use warnings;
#by M'Ósky 2018

#This will replace every missing value with the most frequent genotype of each population.
#It requires a genepop input file generated with Spider.

#Defaults that can be overwritten from command prompt
my $inputname = "temp/populations.structure.genepop";  		# input file name, should be a string either alphanumeric or alphabetic. Can be overwritten from command prompt
my $poplenght = 2;  		#How many characters has the population name. Assuming that the population name is in the first few letters of sample name. Can be overwritten from command prompt

# Check the help information from command line if needed


##########################################################################################################################################################
#######                                                                                                                                         ##########
#######                     CHANGE LOG                                                                                                          ##########
#######    2018-12-14  -  Version 2                                                                                                             ##########
#######     Implemented to run it remotely: from a directory that is not the actual local working directory                                     ##########
#######                                                                                                                                         ##########
#######    2018-11-17  -  Version 1.5                                                                                                           ##########
#######     Fixed a bug that will not handle well when a genotype was missing for an entyre population                                          ##########
#######     When populations -p flag is smaller than the total number of populations, some populations may completely miss a genotype           ##########
#######     Those population-wise missing be replaced with either $input_value or with the most common genotype across all populations          ##########
#######                                                                                                                                         ##########
##########################################################################################################################################################



################ Other options that you can change, but may be better to not touch ##############################
#################################################################################################################

#Missing values for a loci in an entire population
#my $input_value = "005005";   		# 5 2to mark that is a different state from a regular allele (1-4)
#my $input_value = "000000";   		# 0 to keep it as missing
my $input_value = "global";   		# this will input the most common genotype for that loci in all the dataset

#Input file
my $headers = "yes";						# the first rows include the loci names? yes/no. (rows starting with "#" will be ignored, so do not count them as headers.
my $sep = " ";		#symbol used to separate the columns

my $tempfolder = "temp";		#name of the directory that will hold all the folders with the outputs

# Split by pop:
my $outfolder = "bypop";		#output folder for the genepop files separated by population
my $limpopsize = 3;  		#Number of samples per populations that you will not allow, if the number of samples in a population is not higher than this value, the population will be deleted

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

#join in the same file
#my $first_row = $inputname;
my $first_row = $inputname;		#add here whatever you want to appear in the first row of the final genepop input file as title
my $definitive = "_fixed";		#this will be added to the final file.

#output for the reference genotypes.
# Only used if $input_value ="global" and if there are loci missing for an entire population -> -p in Populations (Stacks) < number of populations
my $reffolder = "ref";
my $refout = "_ref";


#################################################################################################################
#################################################################################################################


######### COMMAND LINE ARGUMENTS


my $argumentnumber = scalar (@ARGV);

if($argumentnumber == 0) {print "\nNo arguments specified, will open \"$inputname\". Population names will be extracted from the first $poplenght characters of sample name\n";
}
elsif($argumentnumber == 1) {
	my $argument = $ARGV[0];
	if ( $argument =~ /^[0-9,.E]+$/ ) {
		$poplenght = $argument;
		print "\nOne numeric argument passed. The population name will be extracted from the first $poplenght characters of the sample names. Opening default file \"$inputname\"\n";
	}
	elsif ($argument eq "help" || $argument eq "-help" || $argument eq "--help" || $argument eq "-h" || $argument eq "--h") {
	die "\nUSAGE: This program will replace the missing values from a genepop file with the most common genotype of each population.\n\tBy default will read the file \"$inputname\" and assume that the population names can be extracted from the first two letters of the sample names. Type:  missing_replacer.pl\n\tYou can specify a different length for the population name in the sample name code, a different input file, or both population code length and file name. Examples:\n\t\tmissing_replacer.pl 4\n\t\tmissing_replacer.pl inputfile.txt\n\t\tmissing_replacer.pl subset.genepop 3\n\t\tmissing_replacer.pl 5 genepop_input\n\nIf some populations are missing some snps this will make the most common genotype of the population for that snp to be a missing value (usually \"0\")\nThis happens when the program \"populations\" (Stacks) is ran setting a value of -p smaller than the number of populations in the dataset\nIn this case \"missing_replacer.pl\" can proceed in different ways depending on the value of \"\$input_value\"\n a) Most conservative (but bad for some analysis) is to leave those missing values as missing (0):\t\t\t\$input_value = \"000000\"\n b) To get rid of all missing but also of the differences, replace them with the most common genotype of the entire dataset:\t\t\$input_value = \"global\"\n c) To evidenciate the differences, considering that the population must be missing a loci present in all other populations, replace it with a new unique allele (5):  \$input_value = \"005005\"\nBy default    \$input_value = $input_value   unless is changed by editting the script\n\n";
	}
	else {
		$inputname = $argument;
	print "\nOne argument passed (input file name), Opening file \"$inputname\". Population names extracted by default from the first $poplenght characters of sample name\n";
	}
}
elsif($argumentnumber == 2) {
	my $argument = $ARGV[0];
	if ( $argument =~ /^[0-9,.E]+$/ ) {
		$poplenght = $argument;
		$inputname = $ARGV[1];
		print "\nTwo arguments passed (length of population name and file name), population name will be extracted from the first $poplenght characters of the sample names in file \"$inputname\"\n";
	}
	else {
		$inputname = $argument;
		$poplenght = $ARGV[1];
		print "\nTwo arguments passed (file name and length of population name), population name will be extracted from the first $poplenght characters of the sample names in file \"$inputname\"\n";
	}
}
else {
	die "\n\tSomething is wrong. Did you specify more than two arguments?\n\ntype the name of the program + help to see the usage information:\n\tmissing_replacer help\n\tmissing_replacer --h\n\tmissing_replacer -help\n\tetc.";
}




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

if ($pathlength > 1) {
	my $firstdir = $directorypath[0]; #check
	my $lastdir = $directorypath[-2]; #temp
	$onlyfile = $directorypath[-1]; #populations.structure_neat_clean
	#print "Directory path: @directorypath\nFile name: $onlyfile\n";
	pop (@directorypath);
	$subdirpath = join ('/' , @directorypath);
	#print "Subdirpath: $subdirpath\n";
	$temp="$localdir" . "/" . "$subdirpath" . "/" ."$tempfolder";
}
else {
	$temp = "$localdir" . "/" . "$tempfolder";
	$onlyfile = $inputname;
}
#print "temp direct: $temp\n";
unless(-e $temp or mkdir $temp) {die "\nUnable to create \"$temp\" to hold the outputs\nMay be you don't have the rights: $!\n"; }

my $subdir = 0;
my $logout = 0;




my @namesplit = split ('_', $onlyfile);
my $length = scalar @namesplit;
#print "file name length: $length\n";
if ($length >= 2) { $keepname = $namesplit[0];}
else {$keepname = $onlyfile;}

#print "Filename to keep: $keepname\n";


my $filepath = "$localdir" . "/" . "$inputname";
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




if ($input_value eq "global") {

	
	
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
				if ($onegenotype eq "000000" | $onegenotype eq "0000" | $onegenotype eq "00" | $onegenotype eq "0") {
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


$filepath = "$localdir" . "/" . "$inputname";
my $newfolder = "$temp" . "/" . "$outfolder";
#print "newfolder: $newfolder\n";
$newfolder=~ s/temp\/temp\//temp\//;
#print "newfolder: $newfolder\n";
unless(-e $newfolder or mkdir $newfolder) {die "\nUnable to create \"$outfolder\" at\n$temp:\n$!\n"; }
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
	elsif($newline[0] ne "Pop" && $linenum >= 1) {
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
	elsif($newline[0] eq "Pop" && $linenum >= 3) {
		$popsize = scalar (@onepop);
		if ($popsize > $limpopsize) {
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
if ($popsize > $limpopsize) {
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
my @genepopfiles = readdir(DIR);					#extract filenames
closedir(DIR);

my $filenumber = 0;
print "\nReading files from $newfolder:\n" ;
foreach my $popfile (@genepopfiles) {					#process all the files one by one
	next if ($popfile =~ /^\.$/);				#don't use any hidden file
	next if ($popfile =~ /^\.\.$/);			
	next unless ($popfile =~ /.*$transfilter.*$/);		#read only genepop files
	transpose_table1($popfile, $sep);
	print "\tdone!\n";
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

print "\nNow looking for missing vales in the files saved in \"$resultspath\":\n\n" ;

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


	while (<$FILET>) {
		chomp;	#clean "end of line" symbols
		next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
		my $line = $_;
		$line =~ s/\s+$//;		#clean white tails in lines
		my @genotypes= split($sep, $line);	#split columns as different elements of an array
		$nsamples = scalar (@genotypes);
		
		if ($nloci == 0) {
			push (@nomissing, $line); 
			print "Procesing data of file $transfile:\t";
		}
		else {
			#loop through the array and save the genotypes, if it already appeared, add 1 to its value
			foreach (@genotypes) {
				my $onegenotype = $_;
				if ($onegenotype eq "000000" | $onegenotype eq "0000" | $onegenotype eq "00" | $onegenotype eq "0") {
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
			# if the entire population missess this SNP
			if ($moda == 0 && $input_value eq "global") {
				$moda = $refgenotyped{$nloci};
				print "\nFound genotypes for loci that are missing for an entire population: The most common global genotype will be input\n";
			}
			elsif ($moda == 0) {
				$moda = $input_value;
				print "\nFound genotypes for loci that are missing for an entire population: $input_value will be input in those missing genotypes\n";
			}
			#replace every missing ("0000") with the most frequent allele
			
			#print "\n-->  $moda\n";
			
			$column = 0;
			
			foreach (@genotypes) {
				my $onegenotype = $_;
				if ($onegenotype eq "000000" | $onegenotype eq "0000" | $onegenotype eq "00" | $onegenotype eq "0") {
					$genotypes[$column] = $moda;
					$missn++;
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
	print "$missn missing values replaced!\n";

	$filenumber++;
}


print "\n$filenumber Files processed and saved in directory \"$replaceout\".\n\n";









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
print "\nReading files from $newfolder:\n" ;
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
print "\nNow joining them together\n";

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

my $finalname = "$inputname" . "$definitive";
my $finalpath = "$localdir" . "/" . "$finalname";

open my $OUTF, '>', $finalpath or die "\nUnable to create or save \"$finalname\" at \"$localdir\": $!\n";
foreach (@finalfile) {print $OUTF "$_\n";} # Print each entry in our array to the file
close $OUTF;
print "All files joined in $finalname\n\nThe script finished with no errors (hopefully)\nDone!\n\n";








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
