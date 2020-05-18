
############  IF Output format module ####################

if [ $scatter_param -eq 3 -a $min_s -eq 0 -a $max_s -eq 3 ]; then
CMAX=4
FMAX=4
fi

if [ $scatter_param -eq 1 -a $min_s -eq 0 -a $max_s -eq 9 ]; then
CMAX=2
FMAX=1
fi

#por defecto saca todos los segments (3d-3d)
segment=$[$Z - 1]

# Generating $AXIALS and $MRD for interfile headers
SG=$[$[2 * $segment] + 1]
MRD=0
I_MRD=0
AXIALS=$Z
I_AXIALS=$Z

i=1
while
        [ $i -le $segment ]
        do
		I_MRD=$[$I_MRD + 1]
		MRD="-""$I_MRD"",""$MRD"",""$I_MRD"
		I_AXIALS=$[$I_AXIALS - 1]
		AXIALS="$I_AXIALS"",""$AXIALS"",""$I_AXIALS"
		i=$[$i + 1]
	   done

# Convert to STIR format and split in scatter bins
F=0
C=0
while
        [ $F -lt $FMAX ]
        do
		while
			[ $C -lt $CMAX ]
			do
				scatt_bin=$[ 4*${F} + ${C} ]
				conv_SimSET_STIR ${DIR_OUTPUT}/rec.weight 32768 fl $ANG $BINS $Z $segment $scatt_bin scatt_bin_f"$F"_c"$C".s 

				if [ $F -eq 0 -a $C -eq 0 ]; then 
					mv  scatt_bin_f"$F"_c"$C".s trues.s
					NAME_IMAGE=trues
					else if [ $F -eq 1 -a $C -eq 1 ]; then 
						mv  scatt_bin_f"$F"_c"$C".s singles11.s # 1blue + 1pink
						NAME_IMAGE=singles11
					else
						NAME_IMAGE=scatt_bin_f"$F"_c"$C"
					fi
				fi
				sed -e s%NAME_IMAGE%"${NAME_IMAGE}".s% \
				-e s%SEGMENT%"${SG}"% \
				-e s%VIEWS%"${ANG}"% \
				-e s%AXIALS%"${AXIALS}"% \
				-e s%TANGENTIALS%"${BINS}"% \
				-e s%MRD%"${MRD}"% \
				-e s%RINGS%"${Z}"% \
				-e s%DBR%"${DBR}"% \
				-e s%BSIZE%"${BSIZE}"% \
				< ${DIR_INPUT}/template_stir_projdata_hdr.hs > ${DIR_OUTPUT}/${NAME_IMAGE}.hs
				C=$[$C + 1]
			done
C=0
F=$[$F + 1]
done

if [ $CMAX -eq 4 -a $FMAX -eq 4 ]; then
# proccessing output
stir_math -s --add singles scatt_bin_f0_c1.hs scatt_bin_f1_c0.hs 2> ${DIR_OUTPUT}/kk.err
stir_math -s --add doubles scatt_bin_f0_c2.hs scatt_bin_f2_c0.hs 2> ${DIR_OUTPUT}/kk.err
stir_math -s --add multiples scatt_bin_f0_c3.hs scatt_bin_f1_c2.hs scatt_bin_f1_c3.hs scatt_bin_f2_c1.hs scatt_bin_f2_c2.hs scatt_bin_f2_c3.hs scatt_bin_f3_c0.hs scatt_bin_f3_c1.hs scatt_bin_f3_c2.hs scatt_bin_f3_c3.hs  2> ${DIR_OUTPUT}/kk.err
rm -f ${DIR_OUTPUT}/scatt_bin_f*_c*.* ${DIR_OUTPUT}/scatt_bin_f*_c*.*
fi

rm -f ${DIR_OUTPUT}/kk.err
 
