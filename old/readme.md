# dataset_fixer outdated version

- Summary

Those are some old versions. I don't recommend them, but it's true that they are less complex and easier to use.

Main dataset_fixer has no help information, the first lines of the script briefly explain its use.
Only two arguments can be passed from command line:
  - input file path/name (string).
  - number of characters of the population name code in the individual tag (integer)
  
Everything about the input file format and most of the pipeline is the same than in the main updated version (see readme)
Most of the modules have their own Help information, I specially recommend to check missing_replacer help to understand the parameters

To see the help information of the modules you can use any help flag: -h --h help -help --help

  - refmap_maker.pl is not a module of dataset_fixer
  It is a script to make multiple ref_map submission files with different parameters
  


# Whole info
Unix script that will call different perl modules to check and clean your Structure datasets from missing values and other errors
Will delete samples with high percentage of missing (85% by deffault), then loci with high percentage of missing (30% and above), and then again the samples left with 30% or more.
Then will look if there is any loci monomorphic or no biallelic and delete it
Then (optional) will input the missing values left with average or another value
Then will transform the input file to various formats and output a log file with the list of samples and loci deleted.

The script allows to quickly change some parameter, also accepts some command line arguments.

This has been bash directly in the working directory and in another path with no problems. All the output files will be generated in the path where your input file is at.
It has also been called from a submission file and submited as a job (qsub) with no errors
It uses PGDSpider for some format transformations, that doesn't depend on me and I can't help with that. Also PGDSpider outputs the log file at the working directory by default

My input files are always in Structure format as Populations (from Stacks pipeline) produces them: tab-separated, one row commented out, one row with marker names (with two empty positions at the left), two rows per individual. One first column with individual tags, one second column with population codes and then the columns with SNPs coded from 0-4 (0=missing)
It may fail if the sample names don't include the population names in their codename: POPa001, POPa002, POPb003

Some options can be also changed in the script or through command line arguments if it doesn't fit your inputfile

Check the help from the script for more details

Example

            902100_004 090210_008 460150_015 046015_016 906090_023  090609_042
    SKA001  SKA 1 2 1 2 3 3 4 2
    SKA001  SKA 1 3 1 4 2 3 2 2
    SKA002  SKA 2 2 1 2 3 3 4 1
    SKA002  SKA 1 2 1 4 3 3 4 1
    UWU002  UWU 2 2 1 4 2 3 4 2
    UWU002  UWU 2 2 4 2 3 1 4 2

- M'Ósky
