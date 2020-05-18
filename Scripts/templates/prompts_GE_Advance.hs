!INTERFILE  :=
name of data file := PROJECTIONS_SIMSET
Originating System := SimSet
!GENERAL DATA :=
!GENERAL IMAGE DATA :=
!type of data := PET
;applied corrections:={arc correction}
;ASCII list, Static|Dynamic|Gated|Tomographic|Curve|ROI|PET|Other
imagedata byte order := LITTLEENDIAN
!PET STUDY (General) :=
!PET data type := Emission
;ASCII list que puede ser Emission|Transmission|Blank|AttenuationCorrection|Normalisation|Image
!number format := float
!number of bytes per pixel := 4

;Sinograms 3D
number of dimensions := 4
matrix axis label [4] := segment
!matrix size [4] := 23
matrix axis label [2] := view
!matrix size [2] := 336
matrix axis label [3] := axial coordinate
!matrix size [3] := { 7,8,9,10,11,12,13,14,15,16,17,18,17,16,15,14,13,12,11,10,9,8,7 }
matrix axis label [1] := tangential coordinate
!matrix size [1] := 281
minimum ring difference per segment := { -11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11 }
maximum ring difference per segment := { -11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11 }

Scanner parameters:=
Scanner type := SimSet
number of rings := 18
number of detectors per ring := 672
Inner ring diameter (cm) := 92.4
Average depth of interaction (cm) := 0.84
distance between rings (cm) := 0.844444444
Default bin size (cm) := 0.4
;Number of blocks per bucket in transaxial direction         := 1
;Number of blocks per bucket in axial direction              := 4
;Number of crystals per block in transaxial direction        := 8
;Number of crystals per block in axial direction             := 8
;Number of detector layers                                   := 1
;Number of crystals per singles unit in axial direction      := 32
;Number of crystals per singles unit in transaxial direction := 8
;end scanner parameters:=

effective central bin size (cm) := 0.4
data offset in bytes[1] := 0
number of time frames := 1
!END OF INTERFILE :=
