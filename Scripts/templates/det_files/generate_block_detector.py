#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys

ndetectors_y = int(sys.argv[1])
ndetectors_z = int(sys.argv[2])
output = sys.argv[3]

new_file = open(output, "w")

index = 0

for i in range(2*ndetectors_z+1):

    if (i+1) % 2 != 0:
        
        for j in range(2*ndetectors_y+1):

            new_file.write(
            "            # Material element  (%s,%s) \n" % (i+1,j+1) +
            "            NUM_ELEMENTS_IN_LIST	block_material_info_list = 2 \n" + 
            "                INT	block_material_index = 0 \n" +
            "                BOOL	block_material_is_active = FALSE \n"
            )

            index += 1

    else:
        
        for j in range(2*ndetectors_y+1):

            if (j+1) % 2 != 0:

                new_file.write(
            "            # Material element  (%s,%s) \n" % (i+1,j+1) +
            "            NUM_ELEMENTS_IN_LIST	block_material_info_list = 2 \n" + 
            "                INT	block_material_index = 0 \n" +
            "                BOOL	block_material_is_active = FALSE \n"
                )

                index += 1

            else:

                new_file.write(
            "            # Material element  (%s,%s) \n" % (i+1,j+1) +
            "            NUM_ELEMENTS_IN_LIST	block_material_info_list = 2 \n" + 
            "                INT	block_material_index = 29 \n" +
            "                BOOL	block_material_is_active = TRUE \n"
                )

                index += 1

print "Number of elements is: " + str(index)

new_file.close()
