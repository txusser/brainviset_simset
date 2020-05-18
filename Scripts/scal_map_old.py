#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import commands
import sys

def main():
    
    emiss_hdr = sys.argv[1]
    emiss_img = emiss_hdr[0:-3]+ "img"
    output_hdr = sys.argv[2]
    
    aux_out = "aux.txt"
    
    os.system("cambia_formato_hdr %s %s fl >> /dev/null " % (emiss_hdr,emiss_hdr))
    
    status, header = commands.getstatusoutput("printf_header_hdr %s" % emiss_hdr)
    
    zpix = int(header.split()[13])
    xpix = int(header.split()[19])
    ypix = int(header.split()[25])
    
    os.system("estadistica %s %s %s %s  fl %s" % (str(xpix), str(ypix), str(zpix), emiss_img, aux_out))
     
    with open(aux_out) as f:
        lines = f.readlines()
      
    lines = [x.strip() for x in lines] 
         
    maxi = lines[2].split()[1]
    
    factor = 127/float(maxi)
    
    os.system("opera_imagen_hdr -C %s %s %s fl multi" % (str(factor), emiss_hdr, output_hdr))
    ### NEW ####
    #os.system("cambia_valores_de_un_intervalo %s %s 0.001 1 1" % (output_hdr, output_hdr))
    #os.system("cambia_valores_de_un_intervalo %s %s 0.1 1 1" % (output_hdr, output_hdr))
    ####  ####
    os.remove(aux_out)
    
    
      
if __name__== "__main__":
    main()
