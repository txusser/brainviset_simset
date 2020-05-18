
############  ANALYZE Output format module ####################

if [ $scatter_param -eq 3 -a $min_s -eq 0 -a $max_s -eq 3 ]; then
CMAX=4
FMAX=4
fi

if [ $scatter_param -eq 1 -a $min_s -eq 0 -a $max_s -eq 9 ]; then
CMAX=2
FMAX=1
fi
echo $Z
NIMA=$[$[$Z * $Z]]


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
				conv_SimSET_output_2_img $DIR_OUTPUT/rec.weight $BINS $ANG $NIMA $BSIZE $DBR $scatt_bin scatt_bin_f"$F"_c"$C".hdr 
				echo "conv_SimSET_output_2_img $DIR_OUTPUT/rec.weight $BINS $ANG $NIMA $BSIZE $DBR $scatt_bin scatt_bin_f"$F"_c"$C".hdr "

				if [ $F -eq 0 -a $C -eq 0 ]; then 
					mv  scatt_bin_f"$F"_c"$C".img trues.img
					mv  scatt_bin_f"$F"_c"$C".hdr trues.hdr
					else if [ $F -eq 0 -a $C -eq 1 ]; then 
						mv  scatt_bin_f"$F"_c"$C".img scatter.img 
						mv  scatt_bin_f"$F"_c"$C".hdr scatter.hdr 
#						NAME_IMAGE=singles11
#					else
#						NAME_IMAGE=scatt_bin_f"$F"_c"$C"
					fi
				fi
				C=$[$C + 1]
			done
C=0
F=$[$F + 1]
done

if [ $CMAX -eq 4 -a $FMAX -eq 4 ]; then
# proccessing output
opera_imagen_hdr scatt_bin_f0_c1.hdr scatt_bin_f1_c0.hdr singles.hdr fl sumar
opera_imagen_hdr scatt_bin_f0_c2.hdr scatt_bin_f2_c0.hdr doubles.hdr fl sumar
opera_imagen_hdr scatt_bin_f0_c3.hdr scatt_bin_f3_c0.hdr pmultiples1.hdr fl sumar
opera_imagen_hdr scatt_bin_f1_c3.hdr scatt_bin_f3_c1.hdr pmultiples2.hdr fl sumar
opera_imagen_hdr scatt_bin_f1_c2.hdr scatt_bin_f2_c1.hdr pmultiples3.hdr fl sumar
opera_imagen_hdr scatt_bin_f3_c2.hdr scatt_bin_f2_c3.hdr pmultiples4.hdr fl sumar
opera_imagen_hdr scatt_bin_f2_c2.hdr scatt_bin_f3_c3.hdr pmultiples5.hdr fl sumar

opera_imagen_hdr pmultiples1.hdr pmultiples2.hdr pmultiples12.hdr fl sumar
opera_imagen_hdr pmultiples3.hdr pmultiples4.hdr pmultiples34.hdr fl sumar
opera_imagen_hdr pmultiples12.hdr pmultiples34.hdr pmultiples1234.hdr fl sumar
opera_imagen_hdr pmultiples5.hdr pmultiples1234.hdr multiples.hdr fl sumar

fi
#rm -f ${DIR_OUTPUT}/scatt_bin* ${DIR_OUTPUT}/pmultiples*


 
