#####################################################################
#####################################################################
# script: scratch.sh
# author: Lincoln Harris
# date: 7.16.18
#
#####################################################################
#####################################################################
#!/bin/bash

for dir in *; do
	echo $dir
	#mv ./${dir}/*R1_all.fastq ./${dir}/*R1_001.fastq
	#mv ./${dir}/*R2_all.fastq ./${dir}/*R2_001.fastq

	mv ./${dir}/*R1_001.fastq ./${dir}/${dir}_R1_001.fastq
	mv ./${dir}/*R2_001.fastq ./${dir}/${dir}_R2_001.fastq
done

#####################################################################
#####################################################################
