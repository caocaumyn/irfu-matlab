#!/bin/sh
#
# This software was developed as part of the MAARBLE (Monitoring,
# Analyzing and Assessing Radiation Belt Energization and Loss)
# collaborative research project which has received funding from the
# European Community's Seventh Framework Programme (FP7-SPACE-2011-1)
# under grant agreement n. 284520.

flist="CX_CH_AUX_MAARBLE_ULF_PC12.ceh \
CX_CH_AUX_MAARBLE_ULF_PC35.ceh \
CX_CH_AUX_MAARBLE_ULF_PC1.ceh \
CX_CH_AUX_MAARBLE_ULF_FACMATR.ceh \
CX_CH_AUX_MAARBLE_SA_VLF.ceh"


for f in $flist
do
   CLI=1
   while test $CLI -le 4
   do
      fout=`echo $f| sed -e "s=X=${CLI}="`
      echo "Writing $fout"
      cat $f|sed -e "s=XXX=${CLI}=" > $fout
      CLI=$(($CLI+1))
   done
done
