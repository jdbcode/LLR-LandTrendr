pro run_lt_llr

  llr_composite_dir = "K:\test\composite\tca\"
  lt_output_dir = "K:\test\composite\landtrendr\"
  seg_params_txt = "K:\test\composite\landtrendr\tca_segmentation_parameters.txt"
  mask_image = "K:\test\composite\useareafile.bsq"
  eval = 0
  resume = 0
  
  
  ;############################################################################################
  create_image_info_llr, llr_composite_dir
  search = llr_composite_dir+'*image_info.sav'
  image_info_savefile = file_search(search, count=n_files)
  if n_files ne 1 then begin
    print, ">>> error - could not find the file *image_info.sav in this directory:"
    print, llr_composite_dir
    stop
  endif
  
  file_mkdir, lt_output_dir
  params = parse_seg_params(lt_output_dir, seg_params_txt, image_info_savefile, mask_image=mask_image, subset=subset, eval=eval, resume=resume)
  
  ;if this is the non-eval run - find the eval files and delete them
  if keyword_set(eval) ne 1 then begin
    eval_files = file_search(file_dirname(params[0].output_base), "*eval*", count=n_eval_files)
    if n_eval_files ge 1 then file_delete, eval_files
  endif
  
  if keyword_set(eval) eq 1 then n_runs = 1 else n_runs = n_elements(params)
  
  for i=0, n_runs-1 do begin
    print, ">>> Starting Segmentation", i+1
    t1 = systime(1)
    ok= process_tbcd_chunks(params[i])
    end_time = systime()
    print, '>>> Done With Segmentation', i+1
    t2 = systime(1)
    time = float((t2-t1)/60)
    print, ">>> segmentation ", i+1, " took: ", time," minutes"
    
  endfor
  
  search = llr_composite_dir+'*.hdr'
  templatehdr = file_search(search, count=n_files)
  templatehdr = templatehdr[0]
  outdirpath = file_dirname(params[0].output_base)
  convert_bsq_headers_to_envi2, outdirpath, templatehdr
  
end