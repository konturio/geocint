# geocint

###geocint processing pipeline

Directory structure:
 - Makefile - maps dependencies between generation stages
 - data/ - file-based input and output data
 - tables/ - SQL that generates a table named after the script
 - scripts/ - scripts that perform transformation on top of table without creating new one
 - functions / - service SQL functions used in more than a single other file