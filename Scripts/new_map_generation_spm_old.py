#!/usr/bin/env python
# -*- coding: utf-8 -*-

import nibabel as nib
import os
import sys
import numpy as np

def main():

    recons_hdr = sys.argv[1]
    recons_img = recons_hdr[0:-3] + "img"
    original_pet_hdr = sys.argv[2]
    original_pet_img = original_pet_hdr[0:-3] + "img"
    matlab_rcommand = sys.argv[3] + " " + sys.argv[4] + " " + sys.argv[5]

    recons_dir = os.path.dirname(recons_hdr)
    data_dir = os.path.dirname(original_pet_hdr)

    mfile_name = os.path.join(recons_dir, "fusion.m")

    fused_recons = image_fusion(matlab_rcommand,mfile_name,original_pet_img,recons_img)
    fused_recons_hdr = fused_recons[0:-3] + "hdr"

    norm_factor = proportional_scaling(fused_recons_hdr, original_pet_hdr, original_pet_hdr)

    division_hdr = os.path.join(recons_dir, "division.hdr")

    os.system("opera_imagen_hdr -C %s %s %s fl multi" % (norm_factor, fused_recons_hdr, fused_recons_hdr))

    os.system("opera_imagen_hdr %s %s %s fl divid" % (original_pet_hdr,fused_recons_hdr, division_hdr))

    mask_hdr = os.path.join(data_dir, "Mask.hdr")
    vmax, vmean = compute_vmax_vmean(original_pet_hdr,original_pet_hdr)
    threshold = 0.1*vmax
    os.system("cambia_valores_de_un_intervalo %s %s 0 %s 0" % (original_pet_hdr, mask_hdr,threshold))
    os.system("cambia_valores_de_un_intervalo %s %s %s 10000000000 1" % (mask_hdr, mask_hdr,threshold))
    os.system("opera_imagen_hdr %s %s %s fl multi" % (division_hdr, mask_hdr, division_hdr))
    os.system("elimina_valores_nan_hdr %s %s >> /dev/null" % (division_hdr, division_hdr))
    os.system("elimina_valores_negativos_hdr %s %s >> /dev/null" % (division_hdr, division_hdr))
    os.system("cambia_valores_de_un_intervalo %s %s 5 1000000000 5" % (division_hdr, division_hdr))
    os.system("opera_imagen_hdr %s %s %s fl multi" % (division_hdr, mask_hdr, division_hdr))

def proportional_scaling(img,ref_img,mask_img):

    img_max, img_mean = compute_vmax_vmean(img, mask_img)
    ref_max, ref_mean = compute_vmax_vmean(ref_img, mask_img)

    if float(img_mean) != 0:
        fnorm = ref_mean / img_mean
        return fnorm
    else:
        message = 'Error! Image maean value is zero: ' + str(img)
        print message

def compute_vmax_vmean(img, mask_img):
    """
    Compute maximum and mean intensity values on input image counting 
    on voxels inside the reference image (brain mask)
    :param img: (string) input image path
    :param ref_img: (string) reference image path
    :return: 
    """

    img = nib.load(img)
    data = img.get_data()[:, :, :]
    data = np.nan_to_num(data)

    ref_img = nib.load(mask_img)
    data_ref = ref_img.get_data()[:, :, :]
    data_ref = np.nan_to_num(data_ref)

    i_max = np.amax(data_ref)

    super_threshold_indices = data_ref > 0.2*i_max
    data_ref[super_threshold_indices] = 0

    # Compute values restricted to voxels inside mask (ref image)
    indx = np.where((data>0) & (data_ref.reshape(data.shape)>0))

    # Maximum intensity value
    v_max = np.max(data[indx])
    # Mean intensity value
    v_mean = np.mean(data[indx])


    return [v_max, v_mean]

def image_fusion(matlab_rcommand, mfile_name, reference_image, source_image):
    
    design_type = "matlabbatch{1}.spm.spatial.coreg.estwrite."
    
    new_spm = open(mfile_name, "w")

    new_spm.write(design_type + "ref = {'" + reference_image + ",1'};" + "\n")
    new_spm.write(design_type + "source = {'" + source_image + ",1'};" + "\n")
    new_spm.write(design_type + "other = {''};" + "\n")
    new_spm.write(design_type + "eoptions.cost_fun = 'nmi';" + "\n")
    new_spm.write(design_type + "eoptions.sep = [4 2];" + "\n")
    new_spm.write(design_type + "eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];" + "\n")
    new_spm.write(design_type + "eoptions.fwhm = [7 7];" + "\n")
    new_spm.write(design_type + "roptions.interp = 4;")
    new_spm.write(design_type + "roptions.wrap = [0 0 0];")
    new_spm.write(design_type + "roptions.mask = 0;")
    new_spm.write(design_type + "roptions.prefix = 'r';")
    new_spm.close()

    print "%s %s" % (matlab_rcommand, mfile_name)
    os.system("%s %s" % (matlab_rcommand, mfile_name))

    components = os.path.split(source_image)
    output = os.path.join(components[0], "r" + components[1]) 

    return output

if __name__== "__main__":
    main()