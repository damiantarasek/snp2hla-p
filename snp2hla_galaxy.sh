#!/bin/bash

# Basic parameters
max_memory=$1
window_size=$2

# provide a study name
STUDY_NAME=$3

##cd /home/mlibydt3/galaxy/tools/

# Set up directory paths - temp output to scratch 
#STUDY_INPUT="snp2hla/data/input/${STUDY_NAME}"
#STUDY_INPUT=$4 
TEMP_OUTPUT_DIR=$8
#FINAL_OUTPUT_DIR='snp2hla/imputation/output/raw/'
OUTPUT="$TEMP_OUTPUT_DIR"

#mkdir -p $FINAL_OUTPUT_DIR

# Subsetting .... 
DATA=$4
OUT=$4
SUBSETS=$9
SEED='2704'

# Reference panel path.
REF_PANEL=$5

# shortcuts to executables
PLINK=$6
snp2hla=$7

# find where the 'date' command is (might not be
# in /usr/bin)
date_exe=$(which date)
if [ -z "$date_exe" ] ; then
    echo "Can't find 'date' command" >&2
    exit 1
fi

folder_name=`$date_exe +"%Y-%b-%d_%H.%M.%S"`
folder_name=${folder_name}_$3
mkdir -p ${OUTPUT}/${folder_name}

# create subset keep lists.
Rscript $(dirname $0)/snp2hla_stratified_sampling.R ${DATA}.fam ${OUT} ${SUBSETS} ${SEED}

# split dataset into subsets.
for subset in $(seq 1 $SUBSETS)
do

	$PLINK --bfile ${DATA} --allow-no-sex --noweb --keep ${OUT}.keep${subset} --make-bed --out ${OUT}_${STUDY_NAME}-subset${subset} 

done
#########################

# run the imputation  
for subset in $(seq 1 $SUBSETS)
do

$snp2hla ${OUT}_${STUDY_NAME}-subset${subset} ${REF_PANEL} ${OUTPUT}/${STUDY_NAME}-subset${subset} $PLINK  $max_memory $window_size

done

# merge log files
  for subset in $(seq 1 $SUBSETS)
    do
    cat ${OUTPUT}/${STUDY_NAME}-subset${subset}.bgl.log >> ${OUTPUT}/${STUDY_NAME}.bgl.log
    done

# merge bgl.r2 files
cp ${OUTPUT}/${STUDY_NAME}-subset1.bgl.r2 ${OUTPUT}/${STUDY_NAME}.bgl.r2
  for subset in $(seq 2 $SUBSETS)
    do
    Rscript $(dirname $0)/left_join_iteration.R ${OUTPUT}/${STUDY_NAME}.bgl.r2 ${OUTPUT}/${STUDY_NAME}-subset${subset}.bgl.r2
    done
    
# merge bed files
> ${OUTPUT}/${STUDY_NAME}_bbf_files.txt

   for subset in $(seq 2 $SUBSETS)
   do 
      echo merge
      echo "${OUTPUT}/${STUDY_NAME}-subset${subset}.bed ${OUTPUT}/${STUDY_NAME}-subset${subset}.bim ${OUTPUT}/${STUDY_NAME}-subset${subset}.fam" >> ${OUTPUT}/${STUDY_NAME}_bbf_files.txt
   done

   $PLINK --noweb --allow-no-sex --bfile ${OUTPUT}/${STUDY_NAME}-subset1 --merge-list ${OUTPUT}/${STUDY_NAME}_bbf_files.txt --make-bed --out ${OUTPUT}/${STUDY_NAME} --silent

# dosage merge (without transposing)
> ${OUTPUT}/${STUDY_NAME}_dosage_files.txt

   for subset in $(seq 1 $SUBSETS)
   do 
      cut -d ' ' -f 1,2 ${OUTPUT}/${STUDY_NAME}-subset${subset}.fam > ${OUTPUT}/${STUDY_NAME}-c${subset}.lst
      echo "1 ${OUTPUT}/${STUDY_NAME}-subset${subset}.dosage ${OUTPUT}/${STUDY_NAME}-c${subset}.lst" >> ${OUTPUT}/${STUDY_NAME}_dosage_files.txt
   done

$PLINK --noweb --allow-no-sex --fam ${OUTPUT}/${STUDY_NAME}.fam --dosage ${OUTPUT}/${STUDY_NAME}_dosage_files.txt list format=1 sepheader --write-dosage --out ${OUTPUT}/${STUDY_NAME}
# transpose dosage file
Rscript $(dirname $0)/transpose_dosage.R ${OUTPUT}/${STUDY_NAME}.dosage ${OUTPUT}/${STUDY_NAME}.fam ${OUTPUT}/${STUDY_NAME}.out.dosage

# copy output to final directory
cp ${OUTPUT}/${STUDY_NAME}* ${OUTPUT}/${folder_name}
