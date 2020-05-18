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
    
    os.system("cambia_formato_hdr %s %s 1B >> /dev/null " % (emiss_hdr,emiss_hdr))
    #os.system("cambia_formato_hdr %s %s fl >> /dev/null " % (emiss_hdr,emiss_hdr))
    
    status, header = commands.getstatusoutput("printf_header_hdr %s" % emiss_hdr)
    
    zpix = int(header.split()[13])
    xpix = int(header.split()[19])
    ypix = int(header.split()[25])
    
    os.system("estadistica %s %s %s %s  1b %s" % (str(xpix), str(ypix), str(zpix), emiss_img, aux_out))
    #os.system("estadistica %s %s %s %s  fl %s" % (str(xpix), str(ypix), str(zpix), emiss_img, aux_out))
     
    with open(aux_out) as f:
        lines = f.readlines()
      
    lines = [x.strip() for x in lines] 
         
    maxi = lines[2].split()[1]
    
    factor = 127/float(maxi)
    
    os.system("opera_imagen_hdr -C %s %s %s fl multi" % (str(factor), emiss_hdr, output_hdr))

    mask_hdr="mask.hdr"
    os.system("cambia_valores_de_un_intervalo %s %s 0 0.99 0" % (emiss_hdr, mask_hdr))
    os.system("cambia_valores_de_un_intervalo %s %s 0.99 10000000000 1" % (mask_hdr, mask_hdr))	
    #0.0001
    os.system("cambia_valores_de_un_intervalo %s %s 0 1 1" % (output_hdr, output_hdr))
    os.system("opera_imagen_hdr %s %s %s fl multi" % (output_hdr, mask_hdr, output_hdr))
    
    os.remove(aux_out)
    os.remove(mask_hdr)
    os.remove("mask.img")
    
    
      
if __name__== "__main__":
    main()
