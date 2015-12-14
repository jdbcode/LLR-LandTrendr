pro run_lt_llr

outdir = "\\forestry\share\Groups\Spacers-Annex\CommonData\MSS_images\045030\mss\bsq
segparamstxt = "\\forestry\share\Groups\Spacers-Annex\CommonData\MSS_images\045030\mss\bsq\outputs\segmentation_parameters.txt"
image_info_savefile = "\\forestry\share\Groups\Spacers-Annex\CommonData\MSS_images\045030\mss\bsq\composites\image_info.sav"
mask_image = "\\forestry\share\Groups\Spacers-Annex\CommonData\MSS_images\045030\mss\bsq\usearea\045030_usearea.bsq" 
eval = 0
resume = 0


;############################################################################################
file_mkdir, outdir
params = parse_seg_params(outdir, segparamstxt, image_info_savefile, mask_image=mask_image, subset=subset, eval=eval, resume=resume)
    
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
    
 end