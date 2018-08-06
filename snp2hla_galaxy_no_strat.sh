#!/bin/bash

# Basic parameters
max_memory=$1
window_size=$2

# provide a study name
STUDY_NAME=$3

#cd /home/mlibydt3/galaxy/tools/

# Set up directory paths - temp output to scratch  
TEMP_OUTPUT_DIR=$8
OUTPUT="$TEMP_OUTPUT_DIR"

# Subsetting .... 
DATA=$4
OUT=$4

# Reference panel path.
REF_PANEL=$5

# shortcuts to executables
PLINK=$6
snp2hla=$7

folder_name=`/usr/bin/date +"%Y-%b-%d_%H.%M.%S"`
folder_name=${folder_name}_$3
mkdir -p ${OUTPUT}/${folder_name}

# run the imputation  
$snp2hla ${OUT} ${REF_PANEL} ${OUTPUT}/${STUDY_NAME} $PLINK  $max_memory $window_size

# QC STEPS =======================================================================================================================================
SNP_MAF_THRESH=$9
R2=${10}
echo $SNP_MAF_THRESH > /home/mlibydt3/galaxy/tools/snp2hla/temp_output/R2-test.txt
echo ${R2} >> /home/mlibydt3/galaxy/tools/snp2hla/temp_output/R2-test.txt

#if [ "$SNP_MAF_THRESH" != -1 ] 
#then

# QC step: identify imputed markers with low r2 ( usually <0.5)
#grep -v \# ${OUTPUT}/${STUDY_NAME}.bgl.r2 | awk '{if($2< 0.5) print $1}' > ${OUTPUT}/${STUDY_NAME}.r2.list
grep -v \# ${OUTPUT}/${STUDY_NAME}.bgl.r2 | awk -v threshold0=${R2} '$2 < threshold0 {print $1}' > ${OUTPUT}/${STUDY_NAME}.r2.list

# QC step: exclude low allele frequency MAF, usually < 0.01
$PLINK \
	--bfile ${OUTPUT}/${STUDY_NAME} \
	--allow-no-sex \
	--freq \
	--out ${OUTPUT}/${STUDY_NAME}
 
sed '1 d' ${OUTPUT}/${STUDY_NAME}.frq | awk -v threshold=${SNP_MAF_THRESH} '$5 < threshold {print $2}' > ${OUTPUT}/${STUDY_NAME}_fail_snp_freq.list
cat ${OUTPUT}/${STUDY_NAME}.r2.list ${OUTPUT}/${STUDY_NAME}_fail_snp_freq.list | sort -u > ${OUTPUT}/${STUDY_NAME}.snp.exclusions

####
# QC step: Create QC'd dataset
####

$PLINK \
	--bfile ${OUTPUT}/${STUDY_NAME} \
	--exclude ${OUTPUT}/${STUDY_NAME}.snp.exclusions \
	--allow-no-sex \
	--make-bed \
	--out ${OUTPUT}/${STUDY_NAME}

# QC step: remove snps in  exclusion list from dosage file
while read -r line; do sed -i "/$line/d" ${OUTPUT}/${STUDY_NAME}.dosage; done < ${OUTPUT}/${STUDY_NAME}.snp.exclusions

# QC step: remove snps in  exclusion list from bgl.r2 file
while read -r line; do sed -i "/$line/d" ${OUTPUT}/${STUDY_NAME}.bgl.r2; done < ${OUTPUT}/${STUDY_NAME}.snp.exclusions

#fi

# END OF QC STEPS ================================================================================================================================

# transpose dosage file
Rscript $(dirname $0)/transpose_dosage.R ${OUTPUT}/${STUDY_NAME}.dosage ${OUTPUT}/${STUDY_NAME}.fam ${OUTPUT}/${STUDY_NAME}.out.dosage

#mv ${OUTPUT}/${STUDY_NAME}.dosage ${OUTPUT}/${STUDY_NAME}.out.dosage

# copy output to final directory
cp ${OUTPUT}/${STUDY_NAME}* ${OUTPUT}/${folder_name}