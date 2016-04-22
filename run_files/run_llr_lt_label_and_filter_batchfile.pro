;LLR-LandTrendr spectral-temporal change label and filtering batchfile

;#####################################################################################################################
;Inputs - these need to be defined by the user
diag_file = "T:\Commons\Braaten\LT_test\lt_output\tcangle\LT_v2.00_tcangle_paramset01_diag.sav"

static_model         = "no_cover_model_tcangle"
change_model         = "none"  ;leave as "none"
pct_tree_loss1       = 10
pct_tree_loss20      = 3
pre_dist_cover       = 20
pct_tree_gain        = 5
collapse_dist_angle  = 15
collapse_recv_angle  = 15
run_name             = "tcangle_lt_labels_adj_10000"
merge_recovery       = "yes" ; "yes" or "no"
extract_tc_ftv       = "yes"  ; "yes" or "no"
use_relative_mag     = "no"  ; "yes" or "no"
end_year             = -1
start_year           = -1

label_codes = [ $
  '3#greatest_disturbance#Y#GDXX0000X00X00#XXXX0000X00X00,              0, 0, 11, 11, 0, 4' $
  ] ;last entry should not have a comma, just a $    ;see example lineup below
  
;example label codes and filtering parameters - copy paste them into the above "label_codes" variable as needed  
  ;'3#greatest_disturbance#Y#GDXX0000X00X00#XXXX0000X00X00,              1, 1, 11, 11, 0, 4' ,$
  ;'4#most_recent_disturbance#Y#RDXX0000X00X00#XXXX0000X00X00,           1, 0, 11, 11, 0, 4' ,$
  ;'5#greatest_fast_disturbance#Y#GDXX0000L04X00#XXXX0000X00X00,         1, 0, 11, 11, 0, 4' ,$
  ;'6#second_greatest_fast_disturbance#Y#SDXX0000L04X00#XXXX0000X00X00,  1, 0, 11, 11, 0, 4' ,$
  ;'7#longest_disturbance#Y#LDXX0000G04X00#XXXX0000X00X00,               0, 1, 11, 11, 0, 4' ,$
  ;'8#longest_recovery#Y#LRXX0000G04X00#XXXX0000X00X00,                  0, 1, 11, 11, 0, 4'  $



;
;After inputs have been modified and the file saved, record the full path of this saved file and enter
;it in the IDL command prompt like the following and hit enter.
;
;   @"C:\mock\full_path_to_this_file.sav"
  
;#####################################################################################################################  
;#####################################################################################################################
;#####################################################################################################################
;run prep - don't change
;---pull out the label codes---
codelistsplit = [""]
for i=0, n_elements(label_codes)-1 do begin $
  pieces = strcompress(strsplit(label_codes[i], ",", /extract), /rem) &$
  codelistsplit = [codelistsplit, pieces[0]] &$
endfor
class_codes = codelistsplit[1:*]

;---set up run parameter structures---
filter_params = { $
  static_model: static_model ,$
  change_model: change_model ,$
  pct_tree_loss1: pct_tree_loss1 ,$
  pct_tree_loss20: pct_tree_loss20 ,$
  pre_dist_cover: pre_dist_cover ,$
  pct_tree_gain: pct_tree_gain ,$
  collapse_dist_angle: collapse_dist_angle ,$
  collapse_recv_angle: collapse_recv_angle}
  
run_params = { $
  run_name: run_name ,$
  diag_file: diag_file ,$
  class_codes: class_codes ,$
  filter_params: filter_params ,$
  merge_recovery: merge_recovery ,$
  extract_tc_ftv: extract_tc_ftv ,$
  use_relative_mag: use_relative_mag ,$
  end_year: end_year ,$
  start_year: start_year}
  
;---run the label function--- 
ok = lt_label(run_params)

;---get the path to the label files---
endpos = strpos(diag_file, '_diag.sav')
simple_core_name =  strmid(diag_file, 0, endpos)
path = file_dirname(simple_core_name, /mark_directory)
core_name_file_component = file_basename(simple_core_name)
outpath = path + run_name +"\"

;---run the label filter function---
run_label_class_filter, label_codes, outpath

;---convert headers---
diag_dir = file_dirname(diag_file)
search = diag_dir+'\*hdr'
templatehdr = file_search(search, count=n_files)
if n_files eq 0 then begin $
  print, ">>> error - could not find *.hdr file for use as a template in this directory:" &$
  print, diag_dir &$
  stop &$
endif
templatehdr = templatehdr[0]

convert_bsq_headers_to_envi2, outpath, templatehdr
