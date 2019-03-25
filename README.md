# Dataset fixer version 3.0

Unix script that will call different perl modules to check and clean your Structure datasets from missing values and other errors.

It works smoothly with Structure files generated by populations (Stacks): populations.structure

When I say smoothly I mean in my system, always back up your files when trying for the first time, althought this program should do the backup for you you are never too safe.

The program has many option and flags that can be used to change its behaviour or to adapt it to your file format. There is no need to edit the script unless you want to change also the defaults.
To see the full information, usage, arguments, and settings just use any of the usual help flags (-h --h help -help --help).

    dataset_fixer_v3.sh -help

By default it will call five different modules: new_locinames, delete_bad_samples, delete_bad_loci, monomorphic, and missing_replacer
They need to be at your perl library.
Process:

1)  [optional] Will rename the loci names using Scaffold number + SNP position from a vcf file.
2)  Will delete low quality samples (with percentage of missing 85% and above by default).
3)  Will delete low quality loci (with percentage of missing 30% and above by default).
4)  [optional] Will delete the samples left with 30% or more missing.
5)  Will look if there is any loci monomorphic or non bi-allelic and delete it.
6)  [optional] Will input the most frequent genotype (by default) in any missing values left.
7)  Will call PGDSpider to transform the file to various formats (Bayescan, Genepop, Arlequin).
8)  Will output a log file, a popmap, and lists of samples loci deleted and kept


Some of the modules have more functionalities not activated by default, like replace column separator.
It can input/replace missing genotypes in different ways:
- SNP is missing in few samples: global mode (most frequent genotype), population mode, customized value (including "0" to keep it as missing).
- SNP is missing in most of the samples of the population: global mode, customized value (including "5" to differentiate it as a deletion or "0" to keep it as missing).

This has been bash directly in the working directory and in another path with no problems. All the output files will be generated in the path where your input file is at.

It has also been called from a submission file and submitted as a job (qsub) with no errors


# YOU NEED PGDSPIDER
It uses PGDSpider for some format transformations, I do not own neither am related with that program. It doesn't depend on me and I can't help with that. But is an easy enough to use program to trasform formats.

http://www.cmpg.unibe.ch/software/PGDSpider/

By default PGDSpider outputs the log file in the working directory, not in the directory where the input file is.
I saved the parameter files I use in a subdirectory called "spider".
Probably the only think you need to edit in dataset_fixer script is the location of PGDSpider and its parameter files, it can be set from command line options, but I could turn out quite annoying to do it everytime.



# input files are always in Structure format as Populations (from Stacks pipeline) produces them
Tab-separated. It may have one first row commented out, doesn't matter, will be ignored.

One row with marker names (with two empty positions at the left), two rows per individual.

One first column with individual tags, one second column with population codes and then one column per SNP, coded from 0-4 (0=missing).

It may fail if the sample names don't include the population names in their codename:
POP1_001; or popA002; or CoolPlace042; etc

Some command line arguments can be used to adjust this if it doesn't fit your inputfile format.

Check the help from the dataset_fixer script and/or from the perl modules for more details.

Example

                                    1_4         1_8         1_15        2_16        3_23        2_42
            Le001       Lemuria     3           2           3           4           1           1
            Le001       Lemuria     3           2           1           1           1           4
            Le002       Lemuria     3           2           1           1           2           4
            Le002       Lemuria     2           2           1           1           2           4
            La003       LaPuta      2           2           3           4           1           4
            La003       LaPuta      3           1           3           4           1           1
            La004       LaPuta      2           2           3           1           1           4
            La004       LaPuta      2           1           3           4           1           4
            La005       LaPuta      2           1           3           4           1           4
            La005       LaPuta      3           1           3           4           1           4
            At006       Atlantis    3           2           1           4           2           4
            At006       Atlantis    3           2           3           4           2           1
