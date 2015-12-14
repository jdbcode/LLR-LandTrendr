;+
; NAME:
;       LT_HISTORY_METRICS
;
; PURPOSE:
;
;  This function create a standard set of historical variables from Landtrendr output.
;  For this routine, consecutive segment of the same type is merged together.
;
;  required input files are:
;       -   *_fitted.bsq
;       -   *_segmse.bsq
;       -   *_vertvals.bsq
;       -   *_vertyrs.bsq
;       -   *_brightness_ftv_fitted.bsq
;       -   *_greenness_ftv_fitted.bsq
;       -   *_wetness_ftv_fitted.bsq
;
;       potential input file:
;       -   *_brightness_ftv_source.bsq
;       -   *_greenness_ftv_source.bsq
;       -   *_wetness_ftv_source.bsq
;
;  calculated metrics variables are:
;       B, G, W at time t  (1-3)
;       Slope of B, G, W at time t (4-6)
;       B, G, W of recent vertex (7-9)
;       time since recent vertex (10)
;       B, G, W of prior vertex (11-13)
;       Duration of prior segment (14)
;
; AUTHOR:
;
; CATEGORY:
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;   each of the calculated metrics is written as a stack of images for the selected time intervals.
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;
;   TODO:
;     1. add subset defintion
;******************************************************************************************;
PRO lt_history_metrics, diagfile, end_year=end_year, start_year=start_year, run=run, suffix=suffix, subset=subset, output_corename=output_corename

  IF n_elements(diagfile) EQ 0 THEN return
  IF n_elements(suffix) EQ 0 THEN suffix = 'ltmetrix'
  IF n_elements(end_year) EQ 0 THEN end_year=-1
  IF n_elements(start_year) EQ 0 THEN start_year=-1
  IF n_elements(run) EQ 0 THEN run=''
  
  ;TODO: how to better handle the file search, currently assuming there is only one
  ; for each file type, but potentially there could be multiple.
  
  ;diag_file = file_search(lt_outputs_path+path_sep()+'*_'+run+'_diag.sav', count=n)
  ;IF n NE 1 THEN message, 'Diag file not found.'
  
  ;sv_file = file_search(lt_outputs_path+path_sep()+'*'+run+'_fitted.bsq', count=n)
  ;IF n NE 1 THEN message, 'Fitted file not found.'
  
  ;se_file = file_search(lt_outputs_path+path_sep()+'*'+run+'_segmse.bsq', count=n)
  ;IF n NE 1 THEN message, 'Segmse file not found.'
  
;  vv_file = file_search(lt_outputs_path+path_sep()+'*_'+run+'_vertvals.bsq', count=n)
;  IF n NE 1 THEN message, 'Vertvals file not found.'
;  
;  vy_file = file_search(lt_outputs_path+path_sep()+'*_'+run+'_vertyrs.bsq', count=n)
;  IF n NE 1 THEN message, 'Vertyrs file not found.'
;  
;  ftv_tcb_file = file_search(lt_outputs_path+path_sep()+'*'+run+'brightness_ftv_fitted.bsq', count=n)
;  IF n NE 1 THEN message, 'FTV brightness file not found.'
;  
;  ftv_tcg_file = file_search(lt_outputs_path+path_sep()+'*'+run+'greenness_ftv_fitted.bsq', count=n)
;  IF n NE 1 THEN message, 'FTV greenness file not found.'
;  
;  ftv_tcw_file = file_search(lt_outputs_path+path_sep()+'*'+run+'wetness_ftv_fitted.bsq', count=n)
;  IF n NE 1 THEN message, 'FTV wetness file not found.'
  diag_file = diagfile
  vv_file = stringswap(diagfile, "_diag.sav", "_vertvals.bsq")
  vy_file = stringswap(diagfile, "_diag.sav", "_vertyrs.bsq")
  ftv_tcb_file = stringswap(diagfile, "_diag.sav", "_brightness_ftv_fitted.bsq")
  ftv_tcg_file = stringswap(diagfile, "_diag.sav", "_greenness_ftv_fitted.bsq")
  ftv_tcw_file = stringswap(diagfile, "_diag.sav", "_wetness_ftv_fitted.bsq")

  
  ;retrieve image info
  restore, diag_file
  all_years = diag_info.image_info.year
  unique_years = fast_unique(all_years)
  all_years = unique_years[sort(unique_years)]
  modifier = get_modifier(diag_info.index)

  ;verify start_year and end_year
  tmp_years = [start_year, end_year]
  start_year = min(tmp_years)
  end_year = max(tmp_years)
  
  if start_year lt 0 or start_year lt min(all_years) then start_year = min(all_years)
  if end_year lt 0 or end_year gt max(all_years) then end_year = max(all_years)
  
  if start_year gt max(all_years) or end_year lt min(all_years) then message, "Improper start_year and/or end_year value"
  
  n_years = end_year - start_year + 1
  ;    src_tcb_file = file_search(lt_outputs_path+path_sep()+'*'+run+'brightness_ftv_source.bsq', count=n)
  ;    IF n NE 1 THEN message, 'FTV brightness file not found.'
  ;
  ;    src_tcg_file = file_search(lt_outputs_path+path_sep()+'*'+run+'greenness_ftv_source.bsq', count=n)
  ;    IF n NE 1 THEN message, 'FTV greenness file not found.'
  ;
  ;    src_tcw_file = file_search(lt_outputs_path+path_sep()+'*'+run+'wetness_ftv_source.bsq', count=n)
  ;    IF n NE 1 THEN message, 'FTV wetness file not found.'
  ;
  core_name = strmid(vv_file, 0, strlen(vv_file)-12)+suffix
  print, core_name
  
  ;if user specify output location and name
  if keyword_set(output_corename) then begin 
    core_name = output_corename
    file_mkdir, get_pathname(core_name)
  endif
  
  output_image_group = ["_b_t.bsq", "_g_t.bsq", "_w_t.bsq", $
    "_db_t.bsq", "_dg_t.bsq", "_dw_t.bsq", $
    "_rv_b.bsq", "_rv_g.bsq", "_rv_w.bsq", $
    "_ts_v.bsq", $
    "_pv_b.bsq", "_pv_g.bsq", "_pv_w.bsq", $
    "_pdur.bsq"]
    
  ;determine output image dimension
  if n_elements(subset) ne 0 then $
    zot_img, vv_file, hdr, vv_img,  subset=subset, /hdronly else $
    zot_img, vv_file, hdr, vv_img,  /hdronly
    
    
  ;now create the output file
  n_output_layers = n_years
  bytes_per_pixel = 2
  layersize = long(hdr.filesize[0]) * hdr.filesize[1] * bytes_per_pixel
  filesize = ulong64(layersize) * n_output_layers

  for i = 0, n_elements(output_image_group)-1 do begin
    this_file = core_name + output_image_group[i]
    
    openw, un, this_file, /get_lun
    point_lun, un, filesize - bytes_per_pixel
    ;a blank pixel
    writeu, un, 0
    free_lun, un         ;now the file exists on the drive.
    hdr1 = hdr
    hdr1.n_layers = n_output_layers
    hdr1.pixeltype = 6
    write_im_hdr, this_file, hdr1
  end   ;pre-create image
  
  ;now define the chunks to process
  ; now define the chunks
  max_pixels_per_chunk = 200000l
  pixsize = hdr.pixelsize
  subset = [[hdr.upperleftcenter], [hdr.lowerrightcenter]]
  kernelsize = 1
  
  ok = define_chunks3(subset, pixsize, max_pixels_per_chunk, kernelsize)
  
  if ok.ok eq 0 then message, 'error creating chunks'
  
  chunks = ok.subsets
  pixels_per_chunk = ok.pixels_per_chunk
  n_chunks = n_elements(chunks)
  current_chunk = 0
  
  
  for current_chunk = 0, n_chunks-1 do begin
    print, 'Processing chunk ' + string(current_chunk) + ' of ' + string(n_chunks) + ' chunks'
    
    this_subset =  chunks[current_chunk].coords
    within_layer_offset = chunks[current_chunk].within_layer_offset * 2
    ;read in segmse and fitted file
    ;zot_img, se_file, hdr, se_img, subset = this_subset
    ;zot_img, sv_file, hdr, sv_img, subset = this_subset
    
    ; read vertices
    zot_img, vy_file, hdr, vy_img, subset = this_subset
    zot_img, vv_file, hdr, vv_img, subset = this_subset
    
    ; read ftv images
    zot_img, ftv_tcb_file, hdr, ftv_tcb, subset = this_subset
    zot_img, ftv_tcg_file, hdr, ftv_tcg, subset = this_subset
    zot_img, ftv_tcw_file, hdr, ftv_tcw, subset = this_subset
    
    xsize = hdr.filesize[0]
    ysize = hdr.filesize[1]
    
    ;TODO: convert to 4 dimensional array to simplify output creation 
    ;B, G, W at t
    b_t = intarr(xsize, ysize, n_years)
    g_t = intarr(xsize, ysize, n_years)
    w_t = intarr(xsize, ysize, n_years)
    
    ;delta of B, G, W at t
    db_t = intarr(xsize, ysize, n_years)
    dg_t = intarr(xsize, ysize, n_years)
    dw_t = intarr(xsize, ysize, n_years)
    
    ;recent vertex B, G, W
    rv_b = intarr(xsize, ysize, n_years)
    rv_g = intarr(xsize, ysize, n_years)
    rv_w = intarr(xsize, ysize, n_years)
    
    ;time since recent vertex
    ts_v = intarr(xsize, ysize, n_years)
    
    ;previous vertex B, G, W
    pv_b = intarr(xsize, ysize, n_years)
    pv_g = intarr(xsize, ysize, n_years)
    pv_w = intarr(xsize, ysize, n_years)
    
    ;duration of previous segment
    p_dur = intarr(xsize, ysize, n_years)
    
    for x = 0, xsize-1 do begin
      for y = 0, ysize-1 do begin
        vertexes = vy_img[x, y, *]
        vertvals = vv_img[x, y, *]
        b_stack = ftv_tcb[x, y, *]
        g_stack = ftv_tcg[x, y, *]
        w_stack = ftv_tcw[x, y, *]
        
        this_metrics = calculate_history_metrics(all_years, vertexes, vertvals, modifier, b_stack, g_stack, w_stack, start_year, end_year)
        
        b_t[x, y, *] = this_metrics.b_t
        g_t[x, y, *] = this_metrics.g_t
        w_t[x, y, *] = this_metrics.w_t
        
        db_t[x, y, *] = this_metrics.db_t
        dg_t[x, y, *] = this_metrics.dg_t
        dw_t[x, y, *] = this_metrics.dw_t
        
        rv_b[x, y, *] = this_metrics.rv_b
        rv_g[x, y, *] = this_metrics.rv_g
        rv_w[x, y, *] = this_metrics.rv_w
        
        ts_v[x, y, *] = this_metrics.ts_v
        
        pv_b[x, y, *] = this_metrics.pv_b
        pv_g[x, y, *] = this_metrics.pv_g
        pv_w[x, y, *] = this_metrics.pv_w
        
        p_dur[x, y, *] = this_metrics.p_dur
      endfor ; y dimension
    endfor ; x dimension
  
    ;b_t
    this_file = core_name + output_image_group[0]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, b_t[*,*,layercount]
    end
    free_lun, un

    ;g_t
    this_file = core_name + output_image_group[1]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, g_t[*,*,layercount]
    end
    free_lun, un

    ;w_t
    this_file = core_name + output_image_group[2]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, w_t[*,*,layercount]
    end
    free_lun, un

    ;slb_t
    this_file = core_name + output_image_group[3]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, db_t[*,*,layercount]
    end
    free_lun, un

    ;slg_t
    this_file = core_name + output_image_group[4]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, dg_t[*,*,layercount]
    end
    free_lun, un

    ;slw_t
    this_file = core_name + output_image_group[5]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, dw_t[*,*,layercount]
    end
    free_lun, un

    ;rv_b
    this_file = core_name + output_image_group[6]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, rv_b[*,*,layercount]
    end
    free_lun, un

    ;rv_g
    this_file = core_name + output_image_group[7]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, rv_g[*,*,layercount]
    end
    free_lun, un

    ;rv_w
    this_file = core_name + output_image_group[8]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, rv_w[*,*,layercount]
    end
    free_lun, un

    ;ts_v
    this_file = core_name + output_image_group[9]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, ts_v[*,*,layercount]
    end
    free_lun, un

    ;pv_b
    this_file = core_name + output_image_group[10]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, pv_b[*,*,layercount]
    end
    free_lun, un

    ;pv_g
    this_file = core_name + output_image_group[11]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, pv_g[*,*,layercount]
    end
    free_lun, un

    ;pv_w
    this_file = core_name + output_image_group[12]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, pv_w[*,*,layercount]
    end
    free_lun, un

    ;p_dur
    this_file = core_name + output_image_group[13]
    openu, un, this_file, /get_lun
    for layercount = 0ull, n_years-1 do begin
      point_lun, un, layersize * layercount + within_layer_offset
      writeu, un, p_dur[*,*,layercount]
    end
    free_lun, un


  endfor ; process chunks
END