#!/usr/bin/perl
#monomorphic_v2.pl
use strict ; use warnings;
#by M'Ósky 2018

#This will translocate structure input file, delete monomorphic loci and save it back.
#input file name can be specified from the command line as a first argument after calling the program: monomorphic.pl inputfilename.txt
#an end tail for the output file name can be specified from the command line as a second argument after calling the program: monomorphic.pl inputfilename.txt -onlybi_allelic
#This reads from and writes to a "temp" subdirectory to fit in dataset_fixer.sh, if you want to run it by itself,



########## Default parameter 
my $inputfile = "populations.structure_neat_clean";

#The output file will be automatically generated adding $endtail to input file name
# If there is any other "tail" at the right end of the inputfile name, after an underscore "_", it will be deleted and replaced by $endtail.
my $endtail = "_better";		#this will be added at the end of the transposed output files
	my @filename = split("_", $inputfile);
	my $keepname = $filename[0];
my $finalfile = "$keepname"."$endtail";





my $sep1 = "\t";		#the column separator you have in your input file
my $changesep = "no";		#do you want to replace spaces with "tabs" (\t)? Recommended if you used PGDSpider.
	my $sep2 = "\t";		#the column separator you want for your input file ( only if $changesep = "yes")
my $tempdir = "temp";		#to hold the intermediate temprary files





###########################################################################################################################
#######                                                                                                          ##########
#######         CHANGE LOG                                                                                       ##########
#######    2018-12-14  -  Version 2                                                                              ##########
#######     Implemented to run it remotely: from a directory that is not the actual local working directory      ##########
#######                                                                                                          ##########
###########################################################################################################################





#PATH
use Cwd qw(cwd);
my $localdir = cwd;

my $pathtemp = "$localdir" . "/" . "$tempdir";


my @directorypath = $localdir;
my $pathlength = 0;
my $onlyfile = $inputfile; #populations.structure_neat_clean



# command line argument

my $argumentnumber = scalar (@ARGV);

if($argumentnumber == 0) {
	print "\nNo arguments specified, will delete monomorphic loci from \"$inputfile\", results will be saved as \"$finalfile\"\n";
}
elsif($argumentnumber == 1) {
	$inputfile = $ARGV[0];
	@directorypath = split('/' , $inputfile);
	$pathlength = scalar @directorypath;
	$onlyfile = $directorypath[-1]; #populations.structure_neat_clean
	
	@filename = split("_", $onlyfile);
	$keepname = $filename[0];
	$finalfile = "$keepname"."$endtail";
	
	print "\nOne argument passed (input file name), will delete monomorphic loci from \"$inputfile\", results will be saved as \"$finalfile\"\n";
	}
elsif($argumentnumber == 2) {
	$inputfile = $ARGV[0];
	$endtail = $ARGV[1];
	
	@directorypath = split('/' , $inputfile);
	$pathlength = scalar @directorypath;
	$onlyfile = $directorypath[-1]; #populations.structure_neat_clean
	
	@filename = split("_", $onlyfile);
	$keepname = $filename[0];
	$finalfile = "$keepname"."$endtail";
	
	print "\nTwo arguments passed (input and output file end-tail), will delete monomorphic loci from \"$inputfile\", results will be saved adding \"$finalfile\" to the file name\n";
}




#DEALING WITH LONG WEIRD PATHS FROM dataset_fixer

my $firstdir = $directorypath[0]; #temp
my $lastdir = $directorypath[-2]; #check
my $subdir = 0;
my $logout = 0;
my $subdirpath = 0;



if ($pathlength >= 3 && $firstdir eq $tempdir && $lastdir ne $tempdir) {
	my @pathonly = @directorypath;
	pop (@pathonly);
	$onlyfile = "$tempdir" . "/" . "$onlyfile";
	shift (@pathonly);
	$subdir = join('/', @pathonly);
	$subdirpath = "$localdir" . "/" . "$subdir";
	$pathtemp = "$subdirpath" . "/" . "$tempdir";
	$logout = "$subdirpath" . "/" . "monomorphic.log";
}
elsif ($pathlength > 1) {
	my @pathonly = @directorypath;
	pop (@pathonly); 
	$subdir = join('/', @pathonly);
	$subdirpath = "$localdir" . "/" . "$subdir";
	
	if (-e "monomorphic.log" && $subdir eq $tempdir) { $logout = "$localdir" . "/" . "monomorphic.log"; }
	else { $logout = "$subdirpath" . "/" . "monomorphic.log"; }
	$pathtemp = "$subdirpath" . "/" . "$tempdir";
}
else {
	$onlyfile = $inputfile;
	$logout = "$localdir" . "/" . "monomorphic.log";
	$subdirpath = $localdir;
}

#print "\n\n$pathlength elements at the input file passed, (@directorypath). Subdirectory is \"$subdir\", and file is \"$onlyfile\", temp should be at \"$pathtemp\".\n$firstdir eq $tempdir ?  $lastdir ne $tempdir ?\n\n";








###############################

my $replacedsep = "replacedsep.tmp";
my $transloc = "transloc.tmp";
my $nomonomorf = "nomonomorf.tmp";



my $pathin = "$pathtemp" . "/" . "$onlyfile";
$pathin=~ s/temp\/temp\//temp\//;
my $pathout = "$pathtemp" . "/" . "$finalfile";
$pathout=~ s/temp\/temp\//temp\//;
my $temp1 = "$pathtemp"  ."/" . "$replacedsep";
$temp1=~ s/temp\/temp\//temp\//;		#this line will fix the possible duplication of a temp folder to hold the results.

my $temp2 = "$pathtemp" . "/" . "$transloc";
$temp2=~ s/temp\/temp\//temp\//;		#this line will fix the possible duplication of a temp folder to hold the results.

my $temp3 = "$pathtemp" . "/" . "$nomonomorf";
$temp3=~ s/temp\/temp\//temp\//;		#this line will fix the possible duplication of a temp folder to hold the results.



unless(-e $pathtemp or mkdir $pathtemp) {die "\nUnable to create \"$tempdir\" at\n$subdirpath\nMay be you don't have the rights: $!\n"; }

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
print "Done.    Temporary file generated.\n\nNow looking for monomorphic loci...";





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

print "\tDone.\n";
close $TFILE;
my $savedloci = $row - 2;
my $locinum = $count - 2;
my $excluded = $mononum + $weird;


print "From a total of $locinum loci, $excluded were deleted: $mononum monomorphic and $weird non biallelic, list saved in log file.\nSaving $savedloci biallelic loci in $finalfile ...   ";

open my $MOUT, '>', $temp3 or die "\nUnable to create or save \"$nomonomorf\" at $pathtemp: $!\n";
# Loop over the array
foreach (@nomon) {print $MOUT "$_\n";} # Print each entry in our array to the file
close $MOUT; 

my $logout2 = "$subdirpath" . "/" . "monomorphic.log";
open my $OUT3, '>>', $logout2 or die "\nUnable to create or save \"monomorphic.log\" at $subdirpath: $!\n";

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
