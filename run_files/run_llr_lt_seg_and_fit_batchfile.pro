;LLR-LandTrendr spectral-temporal segmentation and fitting batchfile

;######################################################################################################
;Inputs - these need to be defined by the user

llr_composite_dir = "K:\test\composite\tca\"
lt_output_dir = "K:\test\composite\landtrendr\"
seg_params_txt = "K:\test\composite\landtrendr\tca_segmentation_parameters.txt"
mask_image = "K:\test\composite\useareafile.bsq"
eval = 0
resume = 0


;After inputs have been modified and the file saved, record the full path of this saved file and enter
;it in the IDL command prompt like the following and hit enter.
;
;   @"C:\mock\full_path_to_this_file.sav"



;######################################################################################################
run_llr_lt_seg_and_fit, llr_composite_dir, lt_output_dir, seg_params_txt, mask_image, eval, resume