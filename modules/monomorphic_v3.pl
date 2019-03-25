#!/usr/bin/perl
use strict ; use warnings;

#monomorphic   			# by M'Óscar 
my $version = "monomorphic_v3.pl";

############################

# Use this script to delete all the columns (loci) from a file that have the same value in all the rows or more than two different values.
# This is optimised to work as a dataset_fixer module. Although it should run also as stand alone.

# For options, usage and other information check the help typing the name of the program version and "help" or "--h" or so...
# monomorphic_vX.pl -help



###########################################################################################################################
#######                                                                                                          ##########
#######         CHANGE LOG                                                                                       ##########
#######                                                                                                          ##########
#######    2019-03-14  -  Version 3                                                                              ##########
#######     Implemented flags to pass arguments from command line, to be able to set more options from it        ##########
#######     More customizable and with better help information                                                   ##########
#######                                                                                                          ##########
#######    2019-02-14  -  Version 2.1                                                                            ##########
#######     Fixed it to deal with files with "_" in their name tails added by dataset_fixer a part               ##########
#######     Added the option to consider "5" equivalent to missing and no another allele                         ##########
#######                                                                                                          ##########
#######    2018-12-13  -  Version 2                                                                              ##########
#######     Implemented to run it remotely: from a directory that is not the actual local working directory      ##########
#######                                                                                                          ##########
###########################################################################################################################


# THE COLUMN SEPARATOR DEFINITIONS MAY NEED TO BE CHANGED FROM "" TO ''; CHECK AND SEE. IN THE OTHER SCRIPTS IS '', BUT HERE IS "", DON'T REMEMBER WHY


########## Default parameters: all customizable from command line. Check Help Information 

my $inputfile = "populations.structure_neat_clean";   			#input file name

my $tail3 = "_better";		#this will be added at the end of the transposed output files
#my $tail3 = "_better";		#this will be added at the end of the transposed output files

my $sep1 = "\t";		#the column separator you have in your input file
#my $sep1 = " ";		#the column separator you have in your input file

my $changesep = "no";		#do you want to replace spaces with "tabs" (\t)? Recommended if you used PGDSpider.
#my $changesep = "no";		#do you want to replace spaces with "tabs" (\t)? Recommended if you used PGDSpider.
#my $changesep = "yes";		#do you want to replace spaces with "tabs" (\t)? Recommended if you used PGDSpider.

my $sep2 = "\t";		#the column separator you want for your input file ( only if $changesep = "yes")
#my $sep2 = "\t";		#the column separator you want for your input file ( only if $changesep = "yes")

my $tempdir = "temp";		#to hold the intermediate temprary files
#my $tempdir = "temp";		#to hold the intermediate temprary files

my $custommiss = "5";		#value that should be ignored if found. haven't had time to check if this actually works without errors.
#my $custommiss = "5";		#value that should be ignored if found
#my $custommiss = "n";		#value that should be ignored if found

#################################################################################################################
#################################################################################################################


my @helpfilename = split ("_", $inputfile);
my $tempname = $helpfilename[0];
my $helpinputname = "$tempname" . "$tail3";



#Help!
my %arguments = map { $_ => 1 } @ARGV;
if(exists($arguments{"help"}) || exists($arguments{"--help"}) || exists($arguments{"-help"}) || exists($arguments{"-h"}) || exists($arguments{"--h"})) {
	die "\n\n\t   $version   Help Information\n\t-------------------------------------------------\n
	This program will delete any column with the same value in all its rows or with more than two different values.
	Its designed to delete monomorphic or non-biallelic loci from a Structure input file.
	
	To acccount for the number of different alleles it will not consider as alleles the missing values
	It will recognise as a missing value: 000; 00; 0; 0000; 000000; -9; ?; NA; N/A; #N/A
	In addition it will ignore one additional user defined value. By default: $custommiss
	Every other value will be accounted for and if there is more or less than two allele variants, the locus will be deleted
	
	It has been tested with the Structure file generated by the program populations (Stacks),
	that is: Structure file format: tab separated, with a row with locus names (headers), two rows per individual,
	         and two initial columns on the left with individual and population tags.
	Any row commented out (starting with: #) will be ignored.
	
	Some Structure files generated by PGDSpider mix spaces and tabs as column separators
	You can change the column separator to homogeneize the separator with:  \"changesep\"
	
	Some temporary translocated files will be saved in a subdirectory called \"$tempdir\"
	
	The output file name will be the input file name - any tail (anything at the right of a \"_\") + a tail,
	 output file name by default: $helpinputname;
	In addition will output a log file with the deleted loci and a list of the loci kept.
	
	To run the default just call the program:
	
		$version
	
	Parameters to use if need to change defaults:
	--input            set a different file name or path to the input file (default: $inputfile)
	--sep              symbol used to separate columns, usually tab \"\\t\" but can be space \" \", comma \",\", or semmicolon \";\" 
	-changesep         add this to tell the program that you want to replace the columns separator
	--sep2             only if \"changesep\" column separator that should replace the one in the file.
	--custommiss       a value to be ignored when accounting number of different alleles, usually indicating missing (default: $custommiss)
	--dir              subdirectory to save the temporary files (default: $tempdir)
	--tail             string to add/replace the end of the input file name to generate the output file name (default: $tail3)
	
	Example:
	
		$version --input /home/refmap/out/temp/trial.str --custommiss n changesep --sep \" \" --sep2 \"\\t\"
	
	This program is optimized to run as part of \"dataset_fixer.sh\" although it should also work as stand alone.
	Because of the dataset_fixer pipeline there were some redundancies with the output $tempdir/ subdirectory:
	 If the input file was already in $tempdir/ subdirectory it was duplicated for the output: $tempdir/$tempdir/$helpinputname
	 To solve this, if needed, the program will change   $tempdir/$tempdir/  to   $tempdir/
	This program has not been tested with other file formats but it may probably work if the data is sorted by columns.
	This program will output a log file with the loci deleted and a list of the loci kept.
	This program has not been tested on animals, but our dog seems ok with it.
	\n\n";
}



use Getopt::Long;

GetOptions( "input=s" => \$inputfile,              #   --input
            "custommiss=s" => \$custommiss,        #   --custommiss
            "dir=s" => \$tempdir,                  #   --dir
            "tail=s" => \$tail3,                  #   --tail3
            "sep=s" => \$sep1,                     #   --sep
            "sep2=s" => \$sep2 );                  #   --sep2


if(exists($arguments{"--changesep"})) { $changesep = "yes";}
if(exists($arguments{"-changesep"})) { $changesep = "yes";}
if(exists($arguments{"changesep"})) { $changesep = "yes";}

#debug
#die "\nParameters:\n  Input file name:  $inputfile\n  Old column separators:  \"$sep1\"\n  Replace separator?    $changesep\n  New columns separator:  \"$sep2\"\n  Value to ignore:  $custommiss\n  Tail added to the file name:  $tail3\n  Output file stored at:  $tempdir\n\n";

my $argumentnumber = keys %arguments;
if($argumentnumber == 0) {print "\n\nNo arguments specified, using defaults:\n";}
else { print "\n\n";}
print "$version will delete the loci from $inputfile if they are monomorphic or non-biallelic.\n\n";

#################################################################################################################
###################################################################



#PATH
use Cwd qw(cwd);
my $localdir = cwd;



my @filename = 0;
my $keepname = 0;
my $finalfile = 0;




#DEALING WITH LONG WEIRD PATHS FROM dataset_fixer
my @directorypath = split('/' , $inputfile);
my $pathlength = scalar @directorypath;
my $onlyfile = 0;
my $firstdir = $directorypath[0]; #temp
my $lastdir = $directorypath[-2]; #check
my $subdir = 0;
my $logout = 0;
my $subdirpath = 0;
my $pathtemp = 0;



if ($pathlength >= 3 && $firstdir eq $tempdir && $lastdir ne $tempdir) {
	$onlyfile = $directorypath[-1]; #populations.structure_neat_clean
	@filename = split("_", $onlyfile);
	# this lines are added to deal with file names that have "_" in their name, but i could make the pipeline fail
	my @filename_keep = @filename;   		#backup
	pop(@filename_keep);   		#delete the tails
	pop(@filename_keep);
	my $lengthname = scalar (@filename_keep);
	
	if ($lengthname > 1) { $keepname = join ('_' , @filename_keep); }
	else { $keepname = $filename[0]; }
	
	$finalfile = "$keepname"."$tail3";

	my @pathonly = @directorypath;
	pop (@pathonly);
	$onlyfile = "$tempdir" . "/" . "$onlyfile";
	shift (@pathonly);
	$subdir = join('/', @pathonly);
	$subdirpath = $subdir;
	$pathtemp = "$subdirpath" . "/" . "$tempdir" . "/";
	$logout = "$subdirpath" . "/" . "monomorphic.log";
}
elsif ($pathlength > 1) {
	@filename = split("_", $inputfile);
	$onlyfile = $directorypath[-1]; #populations.structure_neat_clean
	@filename = split("_", $onlyfile);
	$keepname = $filename[0];
	$finalfile = "$keepname"."$tail3";
	my @pathonly = @directorypath;
	pop (@pathonly); 
	$subdir = join('/', @pathonly);
	$subdirpath = $subdir;
	
	if (-e "monomorphic.log" && $subdir eq $tempdir) { $logout = "monomorphic.log"; }
	else { $logout = "$subdirpath" . "/" . "monomorphic.log"; }
	$pathtemp = "$subdirpath" . "/" . "$tempdir" . "/";
}
else {
	@filename = split("_", $inputfile);
	$keepname = $filename[0];
	$finalfile = "$keepname"."$tail3";
	$onlyfile = $inputfile;
	
	$logout = "$localdir" . "/" . "monomorphic.log";
	$subdirpath = $localdir;
	$pathtemp = "$localdir" . "/" . "$tempdir" . "/";
	@directorypath = $localdir;
	$pathlength = 0;
}

#print "\n\n$pathlength elements at the input file passed, (@directorypath). Subdirectory is \"$subdir\", and file is \"$onlyfile\", temp should be at \"$pathtemp\".\n$firstdir eq $tempdir ?  $lastdir ne $tempdir ?\n\n";






###############################

my $replacedsep = "monotemp/replacedsep.tmp";
my $transloc = "monotemp/transloc.tmp";
my $nomonomorf = "monotemp/nomonomorf.tmp";


######## THIS HAS BEEN CHANGED RECENTLY AND NO DEBUGGED, MAY NEED SOME FIXING
$pathtemp =~ s/$tempdir\/$tempdir\//$tempdir\//;

my $pathin = "$pathtemp" . "$onlyfile";
$pathin=~ s/$tempdir\/$tempdir\//$tempdir\//;
my $pathout = "$pathtemp" . "$finalfile";
$pathout=~ s/$tempdir\/$tempdir\//$tempdir\//;
#$pathout=~ s/$tempdir\///g;
my $temp1 = "$pathtemp" . "$replacedsep";
$temp1=~ s/$tempdir\/$tempdir\//$tempdir\//;		#this line will fix the possible duplication of a temp folder to hold the results.

my $temp2 = "$pathtemp" . "$transloc";
$temp2=~ s/$tempdir\/$tempdir\//$tempdir\//;		#this line will fix the possible duplication of a temp folder to hold the results.

my $temp3 = "$pathtemp" . "$nomonomorf";
$temp3=~ s/$tempdir\/$tempdir\//$tempdir\//;		#this line will fix the possible duplication of a temp folder to hold the results.

my $backstage = "$pathtemp" . "monotemp";

unless(-e $pathtemp or mkdir $pathtemp) {die "\nUnable to create \"$pathtemp\": $!\n"; }
unless(-e $backstage or mkdir $backstage) {die "\nUnable to create \"$backstage\": $!\n"; }

my @definitive =();

################


# replace space as column separator with tab (\t) -or whatever separator with another-
if ($changesep eq "yes") { 
	open my $OFILE, '<', $pathin or die "\nUnable to find or open $onlyfile at $subdirpath: $!\n";
	while (<$OFILE>) {
		chomp;	#clean "end of line" symbols
		next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
		my $line = $_;
		$line =~ s/\s+$//;		#clean white tails in lines
		$line =~ s/$sep1/$sep2/g; 
		push (@definitive, $line);
	} 

	close $OFILE;

	open my $ROUT, '>', $temp1 or die "\nUnable to create or save \"$replacedsep\" at $pathtemp: $!\n";
	# Loop over the array
	foreach (@definitive) {print $ROUT "$_\n";} # Print each entry in our array to the file
	close $ROUT; 
	print "\nColumns separator at $onlyfile converted to tab (\\t). Temporary file generated\n";
}

	


my $popfile = 0;
my $sep = 0;

#select input file to transpose
if ($changesep eq "yes") { 
	$popfile = $replacedsep;
	$sep = $sep2;
}
else {
	$popfile = $onlyfile;
	$sep = $sep1;
}

print "\nReading rows and columns. " ;
transpose_table1($popfile, $sep);
print "Done.    Temporary file generated.\nNow looking for monomorphic loci...";





# now Delete monomorphic loci


open my $TFILE, '<', $temp2 or die "\nUnable to find or open $transloc at $pathtemp: $!\n";

my $row = 0;
my $count = 0;
my @nomon=();
my $locusname = 0;
my $weird = 0;
my $mononum = 0;
my @monoreport = ("#List of excluded (non-biallelic) loci from $onlyfile", "", "Locus name   \tallele\/s");
my $deleted = 0;
my $alleles = 0;

while (<$TFILE>) {
	chomp;	#clean "end of line" symbols
	next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
	
	my $line = $_;
	$line =~ s/\s+$//;		#clean white tails in lines
	
	if ($row < 2) {
		push (@nomon, $line);		#save sample names and populations (first two rows)
		$row++;
	}
	else {
		my @newline= split($sep, $line);	#split columns as different elements of an array
		my $samplenum = scalar (@newline);
		my %unique = ();
		$locusname = $newline[0];
		foreach (@newline) {
			my $allele = $_;
			next if $allele eq "000";
			next if $allele eq "00";
			next if $allele eq "0";
			next if $allele eq "0000";
			next if $allele eq "000000";
			next if $allele eq "-9";
			next if $allele eq $custommiss;   		#This line is added to be able to deal with the files after using replace_missing. SHOULD WORK, BUT MAY NEED DEBUGGING
			next if $allele eq "?";
			next if $allele eq "NA";
			next if $allele eq "N/A";
			next if $allele eq "#N/A";
			$unique{$allele} = 42;		#save each allele as a key of the hash, to have only unique values
		}
		
		delete $unique{$locusname};
		my @keys = keys %unique;
		my $hashsize = scalar keys %unique;
		
		if ($hashsize == 1) { 
			#print "$locusname is monomorphic (allele = @keys) and will be excluded.\n";
			$alleles = $keys[0];
			$deleted = "$locusname   \t$alleles";
			push (@monoreport, $deleted);
			$mononum++;
			}
		elsif ($hashsize == 2) {
			push (@nomon, $line);
			$row++;
		}
		else {
			#print "Something wrong with $locusname; alleles found: @keys .\n";
			$alleles = join (" ", @keys);
			$deleted = "$locusname   \t$alleles";
			push (@monoreport, $deleted);
			$weird++;
		}
	}
	$count++;
}

print "\tDone.\n\n";
close $TFILE;
my $savedloci = $row - 2;
my $locinum = $count - 2;
my $excluded = $mononum + $weird;


print "From a total of $locinum loci, $excluded were deleted: $mononum monomorphic and $weird non biallelic, list saved in log file.\nSaving $savedloci biallelic loci in $finalfile ...   ";

open my $MOUT, '>', $temp3 or die "\nUnable to create or save $temp3: $!\n";
# Loop over the array
foreach (@nomon) {print $MOUT "$_\n";} # Print each entry in our array to the file
close $MOUT; 

my $logout2 = "$subdirpath" . "/" . "monomorphic.log";

$logout2 =~ s/$tempdir\///;

open my $OUT3, '>>', $logout2 or die "\nUnable to create or save $logout2: $!\n";

if ($excluded > 0) {
	# Loop over the array
	push (@monoreport, "\n");
	push (@monoreport, "\n");
	foreach (@monoreport) {print $OUT3 "$_\n";} # Print each entry in our array to the file
}
else {
	print $OUT3 "All loci in $onlyfile are biallelic!\nThat's cool!\n";
	print "All loci were biallelic! Nice.\n\n\n";
}
close $OUT3; 


# Transpose back

transpose_table2($nomonomorf, $sep);
print "Done!\n\n";



# NEW PAT NOT DEBUGGED FINAL LIST OF LOCI

my $locifile = "final_loci_list";

print "Saving final name list of \"good\" loci kept (\"$locifile\")...\t";
open my $NEWFILE, '<', $pathout or die "\nProblem finding, opening or reading the final file $pathout: $!\n";

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
print "Done!\n\n\t$version finished!\n\n";


































#######################
###   SUBROUTINES   ###
#######################







sub transpose_table1 {
  my $popfile = shift ;
  my $sep = shift ;

  my $file = $popfile;
  $file = "$pathtemp/$popfile";
  my $error = "$tempdir/$tempdir/";
  $file =~ s/$error/$tempdir\//;
  
  my $transposed_file = $temp2 ;
  my @data ;
  my $size ;
  my @size ;
  my $size_temp ;
  my @tmp ;
  my $line ;
  
  open F, '<', $file or die "Couldn't read from $file: $!";

  open T, '>', $transposed_file or die "Couldn't write to $transposed_file file at $pathtemp: $!";

	# test if the first 3 lines are identical, die if not
	for  my $i (1 .. 3 ){
		$line = (<F>);
		chomp $line;
		@tmp  = $line =~ /$sep/g;
		$size[$i-1] =  @tmp +1 ; # table size, nb of columns in the non transposed table -> nb of lines after transposition
	}
	close(F) ;
	($size[0]  == $size[1]  and $size[0] == $size[2]) ? print "Transposing" : die "Legth of the lines are different\n" ;

	open F, '<', $file or die "Couldn't read from $file file: $!";
  #my $l = 1; # line #
  my $c = 1 ; # column #
  while ($line = <F>)
    {
		chomp $line;
		#next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
		$line =~ s/\s+$//;		#clean white tails in lines
		
	    @tmp  = split "$sep", $line;
	    $data[$c] = [ @tmp ];
        my @count  = $line =~ /$sep/g; # count the nb of separators
	    $size = @count +1 ; # table size, nb of columns in the non transposed table -> nb of lines after transposition
	    $size  ==  $size[1] ? 1 : die "Error the size of the table is not constant at line $c : $size  instead of  $size[1]\n" ;
	    ++$c ;
    } 
  print "...   " ;

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





#######################



sub transpose_table2 {
  my $nomonomorf = shift ;
  my $sep = shift ;

  my $file = "$pathtemp/$nomonomorf";
  my $error = "$tempdir/$tempdir/";
  $file =~ s/$error/$tempdir\//;
  
  
  
  
  my $transposed_file = $pathout ;
  my @data ;
  my $size ;
  my @size ;
  my $size_temp ;
  my @tmp ;
  my $line ;
  

  open F, '<', $file or die "Couldn't read from $file file at $pathtemp: $!";


  open T, '>', $transposed_file or die "Couldn't write to $finalfile at $pathtemp file: $!";

	# test if the first 3 lines are identical, die if not
	for  my $i (1 .. 3 ){
		$line = (<F>);
		chomp $line;
		@tmp  = $line =~ /$sep/g;
		$size[$i-1] =  @tmp +1 ; # table size, nb of columns in the non transposed table -> nb of lines after transposition
	}
	close(F) ;
	($size[0]  == $size[1]  and $size[0] == $size[2]) ? print "Transposing" : die "Legth of the lines are different\n" ;

	
	open F, '<', $file or die "Couldn't read from $file file: $!";
  #my $l = 1; # line #
  my $c = 1 ; # column #
  while ($line = <F>)
    {
		chomp $line;
		#next if /^(\s*(#.*)?)?$/;   # skip blank lines and comments
		$line =~ s/\s+$//;		#clean white tails in lines
		
	    @tmp  = split "$sep", $line;
	    $data[$c] = [ @tmp ];
        my @count  = $line =~ /$sep/g; # count the nb of separators
	    $size = @count +1 ; # table size, nb of columns in the non transposed table -> nb of lines after transposition
	    $size  ==  $size[1] ? 1 : die "Error the size of the table is not constant at line $c : $size  instead of  $size[1]\n" ;
	    ++$c ;
    } 
  print "...   " ;


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
