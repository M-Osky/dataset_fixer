#!/bin/bash 

# dataset_fixer   			# by M'Óscar (M-Osky at GitHub)
VERSION="dataset_fixer_v3.sh"


############################

# Use this script to improve data files
# It will launch series of modules to replace the loci names, delete samples and loci of poor quality, and input genotypes when missing
# In addition it will transform the format to various other commonly used formats.
# For it to work you need to have the modules in your perl library, you need PGDSpider installed and also the parameter files that Spider uses to transform one format to another.
# It's been developed for the Structure input file created by "populations" (Stacks) and it seems to do fine.

# For options, usage and other information check the help typing the name of the program version and "help" or "--h" or so...
#	dataset_fixer_vX.sh -help


###########################################################################################################################
#######                                                                                                          ##########
#######         CHANGE LOG                                                                                       ##########
#######                                                                                                          ##########
#######    2019-03-21  -  Version 3                                                                              ##########
#######     Implemented flags to pass arguments from command line, to be able to set more options from it        ##########
#######     Now the options are customizable for all the modules and has better help information                 ##########
#######     Added a new module to change the loci names and options to skip some of the steps                    ##########
#######                                                                                                          ##########
#######    2019-01-11  -  Version 2.1                                                                            ##########
#######     Fixed an error in delete_bad_samples that messed up with heterozygosity                              ##########
#######     Now it calls delete_bad_samples_v3.1.pl (previously was v3.0)                                        ##########
#######                                                                                                          ##########
#######    2018-12-14  -  Version 2.0                                                                            ##########
#######     Implemented to run it remotely: from a directory that is not the actual local working directory      ##########
#######     Now it can be run automatically from the submission files after refmap + populations                 ##########
#######                                                                                                          ##########
###########################################################################################################################


#### NOTHING TO SEE BELOW THIS LINE


################################################################################################################
############################ DEFAULT PARAMETERS. ALL CUSTOMIZABLE FROM COMMAND LINE. ###########################
################################################################################################################

# Delete directory with temporary files on exit? yes/no
DELETE="yes"
#DELETE="yes"
#DELETE="no"

# Use new_locinames to replace the default names of of the loci with scaffold_position? yes/no
NEWLOCINAMES="yes"
#NEWLOCINAMES="no"

# Run delete_bad_samples a second time after delete_bad_loci with same settings than delete_bad_loci? yes/no
SECOND="yes"
#SECOND="yes"
#SECOND="no"

# After deleting samples and loci with high missing ratio, do you want to input the most common genotype on the rest of missing? yes/no
INPUTMISS="yes"
#INPUTMISS="no"
#INPUTMISS="yes"

# Path to your PGDSpider directory, or just the version name if it is sourced in your .bashrc
SPIDER="/shared/astambuk/software/spider/PGDSpider2-cli.jar"
#SPIDER="/shared/astambuk/software/spider/PGDSpider2-cli.jar"

# PGDSpider parameter file names/paths to transform formats
PARAM1="/shared/astambuk/software/spider/struct-to-genepop.spid"   			# Structure to Genepop
#PARAM1="/shared/astambuk/software/spider/struct-to-genepop.spid"   			# Structure to Genepop
PARAM2="/shared/astambuk/software/spider/genepopSNP-to-structure.spid"   			# Genepop to Structure
#PARAM2="/shared/astambuk/software/spider/genepopSNP-to-structure.spid"   			# Genepop to Structure
PARAM3="/shared/astambuk/software/spider/structure-arlequin.spid"   			# Structure to Arlequin
#PARAM3="/shared/astambuk/software/spider/structure-arlequin.spid"   			# Structure to Arlequin
PARAM4="/shared/astambuk/software/spider/structure-bayescan.spid"   			# Structure to Bayescan
#PARAM4="/shared/astambuk/software/spider/structure-bayescan.spid"   			# Structure to Bayescan


# Input file name
INPUT1="populations.structure"
#INPUT1="populations.structure"



NEW_LOCINAMES="new_locinames.pl"



# VCF file name
VCF="populations.snps.vcf"
#VCF="populations.snps.vcf"

# Input file backup tail or path
BKP=".bkp"
#BKP="_backup"



DELETE_BAD_SAMPLES="delete_bad_samples_v4.pl"



# The file has header (locus names)?
HEAD="yes"
#HEAD="no"
#HEAD="yes"

# Input file columns are separated by
SEP=$'\t'
#SEP="\"\t\""
#SEP='\t'
#SEP=' '

# Missing values in Structure are coded as?
MISSING="0"
#MISSING="0"
#MISSING="-9"

# Delete samples with missing ratio equal and above 
DELETESAMPLES=0.85
#DELETESAMPLES=0.85

# Name of the directory that will hold the temporary files generated
TEMPDIR="temp"
#TEMPDIR="temp"

# Tail to add to the input filename after processing it with delete_bad_samples
SUFIX1="_clean"
#SUFIX1="_clean"



DELETE_BAD_LOCI="delete_bad_loci_v3.pl"



# Delete loci with missing value equal or above this rate,
#  also used for the second run of delete_bad_samples if SECOND=yes and DELETESAMPLES2="loci"
DELETELOCI=0.3		#If the ratio of missing is below  this value in despite of deleting loci, the most frequen genotype (per population) will be input #0.3

# Tail to replace the one in the input filename after processing it with delete_bad_loci
SUFIX2="_neat"
#SUFIX2="_neat"



MONOMORPHIC="monomorphic_v3.pl"



# Value (allele) to be ignored when checking monomorphic/non-biallelic loci
CUSTOMMISS="5"
#CUSTOMMISS="n"
#CUSTOMMISS="5"

# Replace column separator?
CHANGESEP="no"
#CHANGESEP="no"
#CHANGESEP="yes"

# Columns separator to replace (if CHANGESEP="yes")
SEP1=" "
#SEP1='\t'
#SEP1=" "



# New columns separator (if CHANGESEP="yes")
SEP2=$SEP1
#SEP2='\t'
#SEP2=" "

# Tail to replace the one in the input filename after processing it with monomorphic
SUFIX3="_better"


# When running delete_bad_samples again (if SECOND = "yes") you want a different miss ratio than DELETELOCI?
DELETESAMPLES2=$DELETELOCI
#DELETESAMPLES2=$DELETELOCI   			#Same than for loci
#DELETESAMPLES2="0.5"


# When transforming to Genepop and back (missing_replacer) the populations will be named acording to the first POPLENGTH characters of the sample names
POPLENGTH=2
#POPLENGTH=2
#POPLENGTH=3


SUFIX4=".genepop"


MISSING_REPLACER="missing_replacer_v3.pl"

#NUMBER OF CHARACTERS LONG THE POPULATION CODE FROM THE INDIVIDUAL TAGS IS
POPLENGHT=2

# Additional genotype to be considered as missing data 
EXTRAMISS="00000000"

# What to input when missing a genotype
MISSGRAL="pop"
#MISSGRAL="pop"
#MISSGRAL="global"
#MISSGRAL="000000"

# What to input when missing genotypes for a loci in most of the population
MISSPOP="005005"
#MISSPOP="005005"
#MISSPOP="global"
#MISSPOP="000000"

# Minimum number of samples per population to admit the population as valid?
MINPOP=5

# You want a customized title (first row) for your genepop file?
TITLE="\"File generated from $INPUT1 with $VERSION: $MISSGRAL mode input in missing, $MISSPOP if missing in most samples of the same population\""
#TITLE="File generated from $INPUT1 with $VERSION: $MISGRAL mode input in missing, $MISSPOP mode if missing in an entire population"
#TITLE="no"   			#If you want the default title generated by missing_replacer
#TITLE="Genepop file title used for debugging"

# Tail to replace the one in the input filename after processing it with monomorphic
SUFIX5="_fixed"

# Tail for the final output files
SUFIX6="_FINAL"

SUFIX7=".arp"
SUFIX8=".bayescan"
SUFIX9=".str"



#Help!
HELP="\n\n\t   $VERSION (OUTDATED)  Help Information\n\t-------------------------------------------------\n
\n\tThis script will launch a series of perl modules to check and fix a Structure SNP dataset.
\tThe modules need to be in your perl library and the location sourced so the system can use them.\n
\tYou need PGDSpider installed and functional, and four parameter files to transform formats:\n
		--spider          to specify a PGDSpider version or path
		--str_genepop     parameter file to transform: Structure -> Genepop
		--genepop_str     parameter file to transform: Genepop -> Structure
		--str_bayescan    parameter file to transform: Structure -> Bayescan
		--str_arlequin    parameter file to transform: Structure -> Arlequin
					(www.cmpg.unibe.ch/software/PGDSpider/)\n
	Defaults: $SPIDER
	          $PARAM1
	          $PARAM2
	          $PARAM3
	          $PARAM4\n
\tBy default the input file name will be the Structure file as output by \"populations\" (Stacks).
\tTwo rows per sample, one row per locus. First row with marker names (headers).
\tFirst column with individual tags, second column with population tags.
\tDoes not matter if there is any extra rows commented out (starting with \"#\") they will be ignored
\tThe program should theoretically work with files with no headers (read below), but it is recommended to have them
\tIt is recommended that the individual tags include the population code at the beginning of the string.\n
		--headers         (yes/no) declare if your input file has/does not have headers/loci names (default: $HEAD)
		--input / --str   use this flag to specify a different input file name/path (default: $INPUT1)\n\n
	MODULE ORDER, SETTINGS AND SHORT DESCRIPTION:
\tThe intermediate output files (between modules) will be saved in a temporary directory that will be deleted on exit. Read below.\n
		1) $NEW_LOCINAMES         [optional] Will backup the original dataset and replace SNP names.
\t\t                            New SNP names will be the \"scaffold number\"_\"position of the SNP\" from the populations .vcf file.
		  --newnames                (yes/no) should this module be ran or should keep the original locus names? (Run by default?: $NEWLOCINAMES).
		  --vcf                     flag to specify a different vcf file to read the SNP position from (default: $VCF).
		  --bkp                     tail to add at the end of the Structure input file name to save the backup (default: $BKP).
\t\t                            - alternatively you can provide a whole path to save the backup in a different location -\n
\t\t2) $DELETE_BAD_SAMPLES Will filter out the samples that are almost empty (high rate of missing).
\t\t                            Output will be saved at $TEMPDIR/ with the same name + a \"tail\" added to the end.
		  --sep                     symbol used to separate columns, usually tab \'\\\t\', could be space \" \" (default: \'$SEP\')
		  --misscode                how are the missing data coded? Usually \"0\", \"-9\", or \"NA\" (default: $MISSING).
		  --miss_samples            (float) ratio of missing from which samples must be deleted (default: $DELETESAMPLES).
		  --tail_dbs                tail to add at the end of the input file name to generate the output name (default: $SUFIX1).\n
		3) $DELETE_BAD_LOCI    Will filter out the loci of poor quality (high rate of missing).
\t\t                            Output will be saved at $TEMPDIR/, a new \"tail\" will replace the previous one (anything after \"_\").
		  --miss_loci               (float) ratio of missing from which loci must be deleted (default: $DELETELOCI).
		  --tail_dbl                tail to replace the one in the input file name to generate the output file name (default: $SUFIX2).\n
		4) $DELETE_BAD_SAMPLES [optional] Will ran again to trim the rest of low quality samples.
\t\t                            By default will delete samples with missing ratio equal or above the one set with --miss_loci.
		  --delete_samples          (yes/no) should $VERSION run this program a second time or skip it? (Run by default?: $SECOND).
		  --miss_samples2           (float) ratio of missing from which samples must be deleted in this second run (default: $DELETELOCI).\n
\t\t5) $MONOMORPHIC        Will delete any monomorphic (mono-allelic) or non bi-allelic locus.
\t\t                            Some Structure files may mix different column separator, this can be fixed if prompted.
		  --replacesep              (yes/no) the program can replace the (or one of the) column separators (Replace by default?: $CHANGESEP).
		                            use this option only if not using $MISSING_REPLACER, PGDSpider will transform the whole data file for it
		  --sep1                    only if \"--replacesep yes\", column separator that should be replaced (default: sep1 = \"$SEP1\").
		  --sep2                    only if \"--replacesep yes\", new column separator that should replace --sep1.
		  --custommiss              value to be ignored when accounting number of alleles types, usually indicating missing (default: $CUSTOMMISS).
\t\t                            It will recognise as a missing value: 000; 00; 0; 0000; 000000; -9; ?; NA; N/A; #N/A
		  --tail_mnm                string to add/replace the end of the input file name to generate the output file name (default: $SUFIX3).\n
\t\t6) PGDSpider                Will change the format to genepop input file to assembly the genotypes per each locus/individual.
\t\t                            When transforming to Genepop populations tags are lost and replaced by the first sample name,
\t\t                            if your indibidual names include the population code, they will not be lost in the next steps.
		  --popcode                 (integer) if individual tags start with the population code, how many characters long is it? (default: $POPLENGHT).
		                            --popcode 3 <-- CRO_001;		--popcode 2 <-- ST042
		                            --popcode 0 <-- If you don't want or don't have population tags in your individual name tags.\n
\t\t7) $MISSING_REPLACER   [optional] Will locate positions with missing genotypes and input a genotype depending on the settings.
\t\t                            Different actions when a genotype is missing in few samples than when a locus is mostly absent in a population.
		  --input_miss              (yes/no) should run this module or skip it and keep missing values as they are (run by default?: $INPUTMISS).
		  --extra_gen               another genotype to be replaced, apart from \"000000\", \"0000\", \"00\", and \"0\". (default: $EXTRAMISS).
		  --miss_gral               what to input with general missing genotypes?: population mode: \"pop\" (more frequent genotype in the population);
		                            mode from all samples: \"global\"; leave it as missing: \"000000\"    (default: $MISSGRAL).
		  --miss_pop                what to input if a locus is missing in most of the population: input mode from all samples: \"global\";
		                            leave it as missing: \"000000\"; or input something to underline the difference (default: $MISSPOP).
		  --minpop                  (integer) populations with number of samples below this number will be deleted (default: $MINPOP).
		  --title                   print something as comment/title in the first row of the genepop file? Use quotation marks.
		                            if = \"no\" ( --title no ) or the flag is not used will use a default title. Check module help for more details.
		  --tail_mrp                string to add at the end of the input file name to generate the output file name (default: $SUFIX5).\n
\t\t8) FINAL RETOUCHES          $VERSION Will re-check the output file column separators and number of digits per allele.
\t\t                            PGDSpider will then produce versions of the final file in Structure, Bayescan, Arlequin and Genepop formats.
\t\t                            $VERSION will move all those files to the working directory and delete the intermediate files at $TEMPDIR/.
\t\t                            A log file from PGDSpider, $VERSION, and from each module will be saved at the working directory.
		  --dir                     use this flag to specify a different directory to save the intermediate files (default: $TEMPDIR).
		  --delete_temp             (yes/no) use this tell $VERSION if it should delete the temporary directory $TEMPDIR on exit (default: $DELETE).\n\n
		Each module has it own more detailed help information, type the name of the module and any help command to see it:\n
			$MISSING_REPLACER -h \n\t\t\t$MONOMORPHIC --help \n
		Some examples of how to use the command line flags and arguments:\n
			$VERSION --input home/populations.structure --popcode 3 --newnames no --missloci 0.15 --miss_samples2 0.3
			$VERSION --input home/populations.structure --headers no --misscode -9 --miss_gral global --miss_pop 000000
			$VERSION --input dataset.str -delete_temp no --sep \"\\\t\" --replacesep yes --sep1 \" \" --sep2 \'\\\t\' --title \"genepop file for debugging\"\n\n
			There is a new version of dataset_fixer available!\n\n\n"


#####################################################################
#####################################################################

#save arguments
#ARGUMENTS=( "$@" )
NUMBER=$#

#####################################################################
#####################################################################




while test $# -gt 0; do
	case "$1" in
		-h|h|--help|--h|-help|help)
			printf "$HELP"
			exit 0
			;;
		--newnames)
			shift
			NEWLOCINAMES=$1
			shift
			;;
		--delete_temp)
			shift
			DELETE=$1
			shift
			;;
		--delete_samples)
			shift
			SECOND=$1
			shift
			;;
		--input_miss)
			shift
			INPUTMISS=$1
			shift
			;;
		--spider)
			shift
			SPIDER=$1
			shift
			;;
		--str_genepop)
			shift
			PARAM1=$1
			shift
			;;
		--genepop_str)
			shift
			PARAM2=$1
			shift
			;;
		--str_arlequin)
			shift
			PARAM3=$1
			shift
			;;
		--str_bayescan)
			shift
			PARAM4=$1
			shift
			;;
		--input|--str)
			shift
			INPUT1=$1
			shift
			;;
		--vcf)
			shift
			VCF=$1
			shift
			;;
		--bkp)
			shift
			BKP=$1
			shift
			;;
		--headers)
			shift
			HEAD=$1
			shift
			;;
		--sep)
			shift
			SEP=$1
			shift
			;;
		--misscode)
			shift
			MISSING=$1
			shift
			;;
		--miss_samples)
			shift
			DELETESAMPLES=$1
			shift
			;;
		--dir)
			shift
			TEMPDIR=$1
			shift
			;;
		--tail_dbs)
			shift
			SUFIX1=$1
			shift
			;;
		--miss_loci)
			shift
			DELETELOCI=$1
			shift
			;;
		--tail_dbl)
			shift
			SUFIX2=$1
			shift
			;;
			
		--miss_samples2)
			shift
			DELETESAMPLES2=$1
			shift
			;;
		--custommiss)
			shift
			CUSTOMMISS=$1
			shift
			;;
		--replacesep)
			shift
			CHANGESEP=$1
			shift
			;;
		--sep1)
			shift
			SEP1=$1
			shift
			;;
		--sep2)
			shift
			SEP2=$1
			shift
			;;
		--tail_mnm)
			shift
			SUFIX3=$1
			shift
			;;
		--popcode)
			shift
			POPLENGHT=$1
			shift
			;;
		--extra_gen)
			shift
			EXTRAMISS=$1
			shift
			;;
		--miss_gral)
			shift
			MISSGRAL=$1
			shift
			;;
		--miss_pop)
			shift
			MISSPOP=$1
			shift
			;;
		--minpop)
			shift
			MINPOP=$1
			shift
			;;
		--title)
			shift
			TITLE=$1
			shift
			;;
		--tail_mrp)
			shift
			SUFIX5=$1
			shift
			;;
		--endtail)
			shift
			SUFIX6=$1
			shift
			;;
		*)
			printf "\nError: $1 is not a recognized flag!\n\nCall the program using any \"help\" flag to see the usage:\n\t$VERSION --h\n\t$VERSION -help\n\t$VERSION help\n\tetc..."
			exit 0;
		;;
	esac
done










#### DIRECTORIES AND FILE NAMES

MYDIR=$(dirname $INPUT1)
FILENAME=$(basename $INPUT1)
INPUT2="$MYDIR/$TEMPDIR/$FILENAME$SUFIX1"
INPUT3="$MYDIR/$TEMPDIR/$FILENAME$SUFIX2"
INPUT4="$INPUT3$SUFIX1"
INPUT5="$MYDIR/$TEMPDIR/$FILENAME$SUFIX3"
INPUT6="$MYDIR/$TEMPDIR/$FILENAME$SUFIX4"
INPUT7="$INPUT6$SUFIX5"
INPUT8="$MYDIR/$TEMPDIR/$FILENAME$SUFIX5"
SUFIX6="_FINAL"
OUTPUT="$MYDIR/$FILENAME$SUFIX6"
OUTPUTARP="$OUTPUT$SUFIX7"
OUTPUTBAY="$OUTPUT$SUFIX8"
OUTPUTGEN="$OUTPUT$SUFIX4"
OUTPUTSTR="$OUTPUT$SUFIX9"




########## NOW START THE PIPELINE
LOGPATH="$MYDIR/dataset_fixer.log"



if [[ ( $CHANGESEP == "yes" ) ]] && [[ ( $SEP1 == $SEP2 ) ]]
then
	printf "\nError: Found \"--replacesep yes\", but does not make much sense to replace column separator if a new different column separator \"--sep2\" is not defined.\n\nCall the program using any \"help\" flag to see usage:\n\t$VERSION --h\n\t$VERSION -help\n\t$VERSION help\n\tetc..."
	exit 0
fi


#exit 0





{


printf "\n\tRunning $VERSION. ATTENTION: A NEW VERSION IS AVAILABLE\n\n"

if [[ $NUMBER == "0" ]]
then
	printf '%s\n' "--------------------------------" "No arguments, using defaults:"
else
	printf '%s\n' "--------------------------------"
fi

printf "Input file name: $INPUT1\nPopulation names will be extracted from the first $POPLENGHT characters of each sample name\nOption to input when genotype missing for few individuals = $MISSGRAL\nOption to input when genotype are missing for most of the individuals of a population = $MISSPOP\n--------------------------------\n\n\n"



#exit 0

if [[ ( $NEWLOCINAMES == "yes" ) ]] || [[ ( $HEAD == "yes" ) ]]
then
	if [ $HEAD == "yes" ]
	then
		if [ $NEWLOCINAMES == "yes" ]
		then
			printf "Replacing locus names:\n"
			printf "$NEW_LOCINAMES --str $INPUT1 --vcf $VCF --bkp $BKP\n\n"
			$NEW_LOCINAMES --str $INPUT1 --vcf $VCF --bkp $BKP
		elif [ $NEWLOCINAMES == "no" ]
		then
			printf "Keeping original locus names.\n"
		fi
	elif [ $HEAD == "no" ]
	then
		printf "Inputing new locus names:\n"
		printf "$NEW_LOCINAMES --str $INPUT1 --vcf $VCF --bkp $BKP nohead\n\n"
		$NEW_LOCINAMES --str $INPUT1 nohead --vcf $VCF --bkp $BKP nohead
	fi
	
	
	
	printf "\n\n\n##########\n\n\nDeleting \"empty\" samples:\n"
	printf "$DELETE_BAD_SAMPLES --input $INPUT1 --sep \"$SEP\" --misscode $MISSING --miss_samples $DELETESAMPLES --dir $TEMPDIR --tail $SUFIX1\n\n"
	$DELETE_BAD_SAMPLES --input $INPUT1 --sep "$SEP" --misscode $MISSING --miss_samples $DELETESAMPLES --dir $TEMPDIR --tail $SUFIX1
	
	
	
	printf "\n\n\n##########\n\n\nDeleting \"bad\" loci:\n"
	printf "$DELETE_BAD_LOCI --input $INPUT2 --sep \"$SEP\" --misscode $MISSING --miss_loci $DELETELOCI --dir $TEMPDIR --tail $SUFIX2\n\n"
	$DELETE_BAD_LOCI --input $INPUT2 --sep "$SEP" --misscode $MISSING --miss_loci $DELETELOCI --dir $TEMPDIR --tail $SUFIX2
	
	
	
	if [ $SECOND == "yes" ]
	then
		printf "\n\n\n##########\n\n\nDeleting the rest of \"bad\" samples:\n"
		printf "$DELETE_BAD_SAMPLES --input $INPUT3 --sep \"$SEP\" --misscode $MISSING --miss_samples $DELETESAMPLES2 --dir $TEMPDIR --tail $SUFIX1\n\n"
		$DELETE_BAD_SAMPLES --input $INPUT3 --sep "$SEP" --misscode $MISSING --miss_samples $DELETESAMPLES2 --dir $TEMPDIR --tail $SUFIX1
	elif [ $SECOND == "no" ]
	then
		printf "\tKeeping all samples with missing rate below $DELETESAMPLES.\n"
		mv $INPUT3 $INPUT4
	fi
	
	
	
	if [ $CHANGESEP == "no" ]
	then
		printf "\n\n\n##########\n\n\nDeleting non-biallelic loci:\n"
		printf "$MONOMORPHIC --input $INPUT4 --sep \"$SEP\" --custommiss $CUSTOMMISS --dir $TEMPDIR --tail $SUFIX3"
		$MONOMORPHIC --input $INPUT4 --sep "$SEP" --custommiss $CUSTOMMISS --dir $TEMPDIR --tail $SUFIX3
	elif [ $CHANGESEP == "yes" ]
	then
		printf "\n\n\n##########\n\n\nReplacing column separator and deleting non-biallelic loci:\n"
		printf "$MONOMORPHIC --input $INPUT4 --sep \"$SEP1\" --custommiss $CUSTOMMISS changesep --sep2 \"$SEP2\" --dir $TEMPDIR --tail $SUFIX3"
		$MONOMORPHIC --input $INPUT4 --sep "$SEP1" --custommiss $CUSTOMMISS changesep --sep2 "$SEP2"--dir $TEMPDIR --tail $SUFIX3
	fi
	
	
	
	if [ $INPUTMISS == "yes" ]
	then
		printf "\n\n\n##########\n\n\nTransforming to genepop with PGDSpider to build genotypes\n\n"
		printf "java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT5 -inputformat STRUCTURE -outputfile $INPUT6 -outputformat GENEPOP -spid $PARAM1"
		java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT5 -inputformat STRUCTURE -outputfile $INPUT6 -outputformat GENEPOP -spid $PARAM1
		printf "\nSpider is done.\n\n\n##########\n\n\nInputing most common genotype in missing:\n"
		printf "$MISSING_REPLACER --input $INPUT6 --sep \"$SEP2\" --popcode $POPLENGHT --extra_gen $EXTRAMISS --miss_gral $MISSGRAL --miss_pop $MISSPOP --minpop $MINPOP --dir $TEMPDIR --tail $SUFIX5 --title $TITLE\n\n"
		$MISSING_REPLACER --input $INPUT6 --sep "$SEP2" --popcode $POPLENGHT --extra_gen $EXTRAMISS --miss_gral $MISSGRAL --miss_pop $MISSPOP --minpop $MINPOP --dir $TEMPDIR --tail $SUFIX5 --title $TITLE
		
		printf "\n\n\n##########\n\n\nTransforming back to Structure with PGDSpider\n\n"
		printf "java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT7 -inputformat GENEPOP -outputfile $INPUT8 -outputformat STRUCTURE -spid $PARAM2"
		java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT7 -inputformat GENEPOP -outputfile $INPUT8 -outputformat STRUCTURE -spid $PARAM2
		printf "\nSpider is done.\n\n"
	
	elif [ $INPUTMISS == "no" ] 
	then
		printf "\n\n###########\n\n\nMissing values will not be replaced.\nTransforming to genepop with PGDSpider\n\n"
		printf "java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT5 -inputformat STRUCTURE -outputfile $INPUT6 -outputformat GENEPOP -spid $PARAM1"
		java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT5 -inputformat STRUCTURE -outputfile $INPUT6 -outputformat GENEPOP -spid $PARAM1
		mv $INPUT5 $INPUT8
		mv $INPUT6 $INPUT7
	fi
	
	
	################ IF NO HEADERS (LOCI NAMES) THIS HAS NOT BEEN TESTED
	
	
	
elif [[ ( $HEAD == "no" ) && ( $NEWLOCINAMES == "no" ) ]]
then
	printf "\tNo locus names will be written.\n"
	
	printf "\n\n\n##########\n\n\nDeleting \"empty\" samples:\n"
	printf "$DELETE_BAD_SAMPLES --input $INPUT1 --sep \"$SEP\" nohead --misscode $MISSING --miss_samples $DELETESAMPLES --dir $TEMPDIR --tail $SUFIX1\n\n"
	$DELETE_BAD_SAMPLES --input $INPUT1 --sep "$SEP" nohead --misscode $MISSING --miss_samples $DELETESAMPLES --dir $TEMPDIR --tail $SUFIX1
	
	
	
	printf "\n\n\n##########\n\n\nDeleting \"bad\" loci:\n"
	printf "$DELETE_BAD_LOCI --input $INPUT2 nohead --sep \"$SEP\" --misscode $MISSING --miss_loci $DELETELOCI --dir $TEMPDIR --tail $SUFIX2\n\n"
	$DELETE_BAD_LOCI --input $INPUT2 nohead --sep "$SEP" --misscode $MISSING --miss_loci $DELETELOCI --dir $TEMPDIR --tail $SUFIX2
	
	
	
	if [ $SECOND == "yes" ]
	then
		printf "\n\n\n##########\n\n\nDeleting the rest of \"bad\" samples:\n"
		printf "$DELETE_BAD_SAMPLES --input $INPUT3 nohead --sep \"$SEP\" --misscode $MISSING --miss_samples $DELETESAMPLES2 --dir $TEMPDIR --tail $SUFIX1\n\n"
		$DELETE_BAD_SAMPLES --input $INPUT3 nohead --sep "$SEP" --misscode $MISSING --miss_samples $DELETESAMPLES2 --dir $TEMPDIR --tail $SUFIX1
	elif [ $SECOND == "no" ]
	then
		printf "\tKeeping all samples with missing rate below $DELETESAMPLES.\n"
		mv $INPUT3 $INPUT4
	fi
	
	
	
	if [ $CHANGESEP == "no" ]
	then
		printf "\n\n\n##########\n\n\nDeleting non-biallelic loci:\n"
		printf "$MONOMORPHIC --input $INPUT4 nohead --sep \"$SEP\" --custommiss $CUSTOMMISS --dir $TEMPDIR --tail $SUFIX3"
		$MONOMORPHIC --input $INPUT4 nohead --sep "$SEP" --custommiss $CUSTOMMISS --dir $TEMPDIR --tail $SUFIX3
	elif [ $CHANGESEP == "yes" ]
	then
		printf "\n\n\n##########\n\n\nReplacing column separator and deleting non-biallelic loci:\n"
		printf "$MONOMORPHIC --input $INPUT4 nohead --sep \"$SEP1\" --custommiss $CUSTOMMISS changesep --sep2 \"$SEP2\" --dir $TEMPDIR --tail $SUFIX3"
		$MONOMORPHIC --input $INPUT4 nohead --sep "$SEP1" --custommiss $CUSTOMMISS changesep --sep2 "$SEP2" --dir $TEMPDIR --tail $SUFIX3
	fi
	
	
	
	if [ $INPUTMISS == "yes" ]
	then
		printf "\n\n\n##########\n\n\nTransforming to genepop with PGDSpider to build genotypes\n\n"
		printf "java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT5 -inputformat STRUCTURE -outputfile $INPUT6 -outputformat GENEPOP -spid $PARAM1"
		java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT5 -inputformat STRUCTURE -outputfile $INPUT6 -outputformat GENEPOP -spid $PARAM1
		printf "\nSpider is done.\n\n\n##########\n\n\nInputing most common genotype in missing:\n"
		printf "$MISSING_REPLACER --input $INPUT6 nohead --sep \"$SEP2\" --popcode $POPLENGHT --extra_gen $EXTRAMISS --miss_gral $MISSGRAL --miss_pop $MISSPOP --minpop $MINPOP --dir $TEMPDIR --tail $SUFIX5 --title $TITLE\n\n"
		$MISSING_REPLACER --input $INPUT6 nohead --sep "$SEP2" --popcode $POPLENGHT --extra_gen $EXTRAMISS --miss_gral $MISSGRAL --miss_pop $MISSPOP --minpop $MINPOP --dir $TEMPDIR --tail $SUFIX5 --title $TITLE
		
		printf "\n\n\n##########\n\n\nTransforming back to Structure with PGDSpider\n\n"
		printf "java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT7 -inputformat GENEPOP -outputfile $INPUT8 -outputformat STRUCTURE -spid $PARAM2"
		java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT7 -inputformat GENEPOP -outputfile $INPUT8 -outputformat STRUCTURE -spid $PARAM2
		printf "\nSpider is done.\n\n"
	
	elif [ $INPUT == "no" ] 
	then
		printf "\n\n###########\n\n\nMissing values will not be replaced.\nTransforming to genepop with PGDSpider\n\n"
		printf "java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT5 -inputformat STRUCTURE -outputfile $INPUT6 -outputformat GENEPOP -spid $PARAM1"
		java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $INPUT5 -inputformat STRUCTURE -outputfile $INPUT6 -outputformat GENEPOP -spid $PARAM1
		mv $INPUT5 $INPUT8
		mv $INPUT6 $INPUT7
	fi
	
fi




##################### FINAL STEPS

printf '%s\n' "--------------------------------"


printf "\n\nSaving final Structure file $OUTPUTSTR...\n\n"
cp $INPUT8 $OUTPUTSTR
sed -i 's/ /\t/g' $OUTPUTSTR
sed -i 's/\t00/\t/g' $OUTPUTSTR
printf "\nSaving final Genepop file $OUTPUTGEN...\n\n"
mv $INPUT7 $OUTPUTGEN
printf "\nTransforming to Arlequin...\n\n"
printf "java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $OUTPUTSTR -inputformat STRUCTURE -outputfile $OUTPUTARP -outputformat ARLEQUIN -spid $PARAM3"
java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $OUTPUTSTR -inputformat STRUCTURE -outputfile $OUTPUTARP -outputformat ARLEQUIN -spid $PARAM3
printf "\n\nTransforming to Bayescan...\n\n"
printf "java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $OUTPUTSTR -inputformat STRUCTURE -outputfile $OUTPUTBAY -outputformat GESTE_BAYE_SCAN -spid $PARAM4"
java -Xmx10240m -Xms512m -jar $SPIDER -inputfile $OUTPUTSTR -inputformat STRUCTURE -outputfile $OUTPUTBAY -outputformat GESTE_BAYE_SCAN -spid $PARAM4

printf '%s\n' "--------------------------------"

if [ $DELETE == "yes" ]
then
	printf "\n\nDeleting temporary files\n\n"
	rm -r $TEMPDIR
elif [ $DELETE == "no" ]
then
	printf "\n\nKeeping temporary files (for debugging purposes) at $TEMPFOLDER/\n\n"
fi
printf "\n$VERSION finished successfully (fingers crossed) the log files for each module were saved at \"$MYDIR\"\nSaving $VERSION log file as $LOGPATH\n\n\tALL DONE! REMEMBER TO CHECK THE NEW dataset_fixer VERSION!\n\n"




} | tee "$LOGPATH"
