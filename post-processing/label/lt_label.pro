;**************************************************************************** 
;Copyright © 2008-2011 Oregon State University                                
;All Rights Reserved.                                                         
;                                                                             
;                                                                             
;Permission to use, copy, modify, and distribute this software and its        
;documentation for educational, research and non-profit purposes, without     
;fee, and without a written agreement is hereby granted, provided that the    
;above copyright notice, this paragraph and the following three paragraphs    
;appear in all copies.                                                        
;                                                                             
;                                                                             
;Permission to incorporate this software into commercial products may be      
;obtained by contacting Oregon State University Office of Technology Transfer.
;                                                                             
;                                                                             
;This software program and documentation are copyrighted by Oregon State      
;University. The software program and documentation are supplied "as is",     
;without any accompanying services from Oregon State University. OSU does not 
;warrant that the operation of the program will be uninterrupted or           
;error-free. The end-user understands that the program was developed for      
;research purposes and is advised not to rely exclusively on the program for  
;any reason.                                                                  
;                                                                             
;                                                                             
;IN NO EVENT SHALL OREGON STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR DIRECT, 
;INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST      
;PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN 
;IF OREGON STATE UNIVERSITYHAS BEEN ADVISED OF THE POSSIBILITY OF SUCH        
;DAMAGE. OREGON STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,       
;INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
;FITNESS FOR A PARTICULAR PURPOSE AND ANY STATUTORY WARRANTY OF               
;NON-INFRINGEMENT. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS,    
;AND OREGON STATE UNIVERSITY HAS NO OBLIGATIONS TO PROVIDE MAINTENANCE,       
;SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.                            
;                                                                             
;**************************************************************************** 

;+
; NAME:
;  LT_LABEL
;
; PURPOSE:
;
;  This procedure labels landtrendr output using customer defined rules
;
; AUTHOR:
;
;
; CATEGORY:
;     Landtrendr, Post-Processing
;
; CALLING SEQUENCE:
;
;
; INPUTS:
;   * cover model
;       static_model_function = 'static_nbr_model_utah' ;percent cover model
;       change_model_function = 'none'  ;percent cover model
;
;   * disturbance rule: defines how to filter disturbance using a sliding scale based on duration.
;       pct_loss_threshold_at_one_year = 15
;       pct_loss_threshold_at_20_years = 3
;       pre_disturbance_cover_thresh = 5
;
;   * recovery rule: defines how to filter recovery a sliding scale based on duration.
;       pct_gain_threshold_for_recovery = 5
;
;   * label rule: defines a set of labels for disturbance
;
;       '3#moderate_fast_disturbance#GD0075XX0000L04'
;
;
; KEYWORD PARAMETERS:
;   * spectral bands: additional spectral band to retrieve values from
;   * output flag: whether to generate output file. [This might be put in the label rule definition]
;
; OUTPUTS:
;
;
; EXAMPLE:
;
;
; MODIFICATION HISTORY:
;   09.17.2010. Intial creation by Yang
;
;   10.08.2010. Add extracting fitted values
;
;   06.14.2011. Added END_YEAR option to constrain extraction
;               of change history for the period prior to END_YEAR (D. Pflugmacher)
;               params.end_year >  0 then end_year eq params.end_year
;               params.end_year =  0 (use file)
;               params.end_year = -1 (no predefined end year)
;               
;   07.12.2011  Added START_YEAR option (D. Pflugmacher)
;
;******************************************************************************************;


function lt_label, run_params, subset=subset, output_path=output_path, sspan=sspan

  run_name = run_params.run_name
  diag_file = run_params.diag_file
  class_codes = run_params.class_codes
  filter_params = run_params.filter_params
  merge_recovery = run_params.merge_recovery
  extract_tc_ftv = run_params.extract_tc_ftv
  end_year = run_params.end_year
  start_year = run_params.start_year
  
  param_variables = tag_names(run_params)
  theone = where(param_variables eq 'USE_RELATIVE_MAG', n_hits)
  if n_hits eq 0 then use_relative_mag = 1 else begin
    checkit = run_params.use_relative_mag
    if checkit eq 'yes' then use_relative_mag = 1
    if checkit eq 'no' then use_relative_mag = 0
    if checkit ne 'no' and checkit ne 'yes' then message, "within the label parameter file, the variable 'use_relative_mag' can only equal: yes or no"
  endelse
  
  
  
  ;first check to make sure all of the vertyr, etc. images are there
  len = strlen(diag_file)
  endpos = strpos(diag_file, '_diag.sav')
  
  simple_core_name =  strmid(diag_file, 0, endpos)
  vertval_file = simple_core_name + "_vertvals.bsq"
  vertyr_file = simple_core_name + "_vertyrs.bsq"
  endyear_file = simple_core_name + "_endyear.bsq"     ; NEW END_YEAR layer
  startyear_file = simple_core_name + "_startyear.bsq"     ; NEW START_YEAR layer  
;  mag_file = simple_core_name + "_mags.bsq"           ; not needed anymore. mags and durs 
;  dur_file = simple_core_name + "_durs.bsq"           ; change for different END_YEARS. so
;  distrec_file = simple_core_name + "_distrec.bsq"    ; these images are no re-calculated here on the fly.

  
  
  ;make sure fitted images exist
  if extract_tc_ftv eq 'yes' then begin
    b_ftv_file = simple_core_name + "_brightness_ftv_fitted.bsq"
    g_ftv_file = simple_core_name + "_greenness_ftv_fitted.bsq"
    w_ftv_file = simple_core_name + "_wetness_ftv_fitted.bsq"
    print, b_ftv_file
    if file_exists(b_ftv_file) eq 0 then return, {ok:0, message: 'fitted brightness does not exists'}
    if file_exists(g_ftv_file) eq 0 then return, {ok:0, message: 'fitted greenness does not exists'}
    if file_exists(w_ftv_file) eq 0 then return, {ok:0, message: 'fitted wetness does not exists'}
  end
  
  
  if file_exists(vertval_file) eq 0 then return, {ok:0, message: 'Vertval image not found'}
  if file_exists(vertyr_file) eq 0 then return, {ok:0, message: 'Vertyr image not found'}

  ; Look only for END_YEAR image if parameter was set to 0
  if end_year eq 0 and file_exists(endyear_file) eq 0 then return, {ok:0, message: 'Endyear image not found'}
  if start_year eq 0 and file_exists(startyear_file) eq 0 then return, {ok:0, message: 'Startyear image not found'}

  ;next parse class rules
  ok = parse_class_codes(class_codes)
  
  if ok.ok eq 0 then begin
    print, 'Class codes could not be interpreted.  Bailing.'
    print, ok.message
    return, {ok:0}
  end
  
  interpd_class_codes = ok.class_structure
  
  ;determine the largest class number, so we can add class numbers for places
  ;that meet multiple criteria.
  n_classes = n_elements(interpd_class_codes)     ;number of classes
  next_class_num  = max(interpd_class_codes.class_num)+1
  next_class_posn = n_classes     ;because we're zero-based, the pointer to the next
  ;class in the class_descriptors is the number of classes
  
  if n_elements(interpd_class_codes) eq 1 then output_class_descriptors = interpd_class_codes.class_name else $
    output_class_descriptors = transpose(interpd_class_codes.class_name)
    
  ;is just a string with the original classes, but it may be expanded
  ;   if there are classes that must be created to capture combinations
  ;   of the original ones
  if n_elements(interpd_class_codes) eq 1 then  output_class_nums = interpd_class_codes.class_num else $
    output_class_nums = transpose(interpd_class_codes.class_num)
    
  ;now setup the output file
  ;there is a single label file, which corresponds to user rule, and
  ;there could be other individual files depends on the flag in the rule.
    
  path = file_dirname(simple_core_name, /mark_directory)
  core_name_file_component = file_basename(simple_core_name)
  outpath = path + run_name
  
  if keyword_set(output_path) then outpath = output_path
  
  file_mkdir,outpath
  core_name = outpath+path_sep()+core_name_file_component + "_"
  
  
  ;determine output image dimension
  if n_elements(subset) ne 0 then $
    zot_img, vertval_file, hdr, vv_img,  subset=subset, /hdronly else $
    zot_img, vertval_file, hdr, vv_img,  /hdronly
    
  ;create label image
  output_label_file = core_name + '_LTlabel.bsq'
  
  openw, un,  output_label_file, /get_lun
  n_output_layers = 1ul
  
  bytes_per_pixel = 2ul    ;allows lots of classes
  layersize = ulong(hdr.filesize[0]) * hdr.filesize[1] * bytes_per_pixel
  filesize = long(layersize) * n_output_layers
  point_lun, un, filesize - 2         ;-2 because we're going to write
  writeu, un, 0
  free_lun, un         ;now the file exists on the drive.
  hdr1 = hdr
  hdr1.n_layers = n_output_layers
  hdr1.pixeltype = 6
  write_im_hdr, output_label_file, hdr1
  
  
  ;create individual image file if needed
  output_files = strarr(n_classes)
  output_segs = intarr(n_classes)
  ftv_files = strarr(n_classes)
  
  write_details = interpd_class_codes.write_details
  for class = 0, n_classes-1 do begin
    types = *(interpd_class_codes[class].type)
    skips = where(types eq 'XX', n_skips)
    n_segs = n_elements(types);-n_skips
    n_output_layers = n_segs * 4 ;preval, year, magnitude, duration
    
    output_file = core_name + interpd_class_codes[class].class_name+'.bsq'
    output_segs[class] = n_segs
    output_files[class] = output_file
    
    ftv_file = core_name + interpd_class_codes[class].class_name+'_ftv_context.bsq'  ;"_ftv_predist.bsq" was replaced by _ftv_context.bsq - jb 4/16/12
    ftv_files[class] = ftv_file
    
    ;no output requested
    if write_details[class] eq 0 then continue
    
    ;create output class file
    openw, un,  output_file, /get_lun
    filesize = ulong(layersize) * n_output_layers
    point_lun, un, filesize - 2
    writeu, un, 0
    free_lun, un
    hdr1 = hdr
    hdr1.n_layers = n_output_layers
    hdr1.pixeltype = 6
    write_im_hdr,   output_file, hdr1
    
  
    ;create predisturbance tc file
    if extract_tc_ftv eq 'yes' then begin
      openw, fun, ftv_file, /get_lun
      filesize = ulong(layersize) * n_segs * 6  ;B, G, W, ▲B, ▲G, ▲W
      point_lun, fun, filesize - 2
      writeu, fun, 0
      free_lun, fun
      hdr2 = hdr
      hdr2.n_layers = n_segs * 6
      hdr2.pixeltype = 6
      write_im_hdr, ftv_file, hdr2
      
    endif
  endfor
  
  ;retrieve diagnosis information
  restore, diag_file
  image_info = diag_info.image_info
  every_year = image_info.year
  unique_years = fast_unique(every_year)
  all_years = unique_years[sort(unique_years)]
  n_years = n_elements(all_years)
  
  ; now define the chunks
  max_pixels_per_chunk = 200000l
  pixsize = hdr.pixelsize
  subset = [[hdr.upperleftcenter], [hdr.lowerrightcenter]]
  kernelsize = 1
  
  ok = define_chunks3(subset, pixsize, max_pixels_per_chunk, kernelsize)
  if ok.ok eq 0 then return, {ok:0}
  chunks = ok.subsets
  pixels_per_chunk = ok.pixels_per_chunk
  n_chunks = n_elements(chunks)
  current_chunk = 0          ;an index
  
  for current_chunk = 0, n_chunks-1 do begin
    print, 'Processing chunk ' + string(current_chunk) + ' of ' + string(n_chunks) + ' chunks'
    
    this_subset =  chunks[current_chunk].coords
    
    ;read in vertyr and vertval images
    zot_img, vertyr_file, hdr, vy_img, subset = this_subset
    zot_img, vertval_file, hdr, vv_img, subset = this_subset

    ; populate end of year EY_IMG variable. Look-up end_year parameter to decide whether
    ; to populate the variable from an image file or from the end_year parameter (if single year) 
    if end_year gt 0 then ey_img = end_year 
    if end_year eq 0 then zot_img, endyear_file, hdr, ey_img, subset=this_subset 

    if start_year gt 0 then sy_img = start_year   
    if start_year eq 0 then zot_img, startyear_file, hdr, sy_img, subset=this_subset
        
    ; modify vertex year and value array in place based on EY_IMG (if supplied)
    ; remember end_year parameter is 0 when ey_img comes from a file and -1 when we
    ; don't want to do any back-casting in which case ey_img or sy_img stays UNDEFINED
    if end_year ge 0 or start_year ge 0 then back_verts, vy_img, vv_img, end_year=ey_img, start_year=sy_img, /replace, sspan=sspan
    
    ; calculate other layers on-the-fly in stead of grabbing them from the files in case
    ; the vertices changed. Calculation is pretty fast.
    vert_mag_dur, vy_img, vv_img, mag=mag_img, dur=dur_img, distrec=distrec_img 
    
    ;just get the layer 3 that indicates the proportion of each type, with -1500 the no-change type
    distrec_img = distrec_img[*,*,2]
    
    xsize = hdr.filesize[0]
    ysize = hdr.filesize[1]
    
    label_image = intarr(xsize, ysize)
    
    ;put in the no-change pixels
    nochange = where(distrec_img eq -1500, n_nochange)
    if n_nochange ne 0 then label_image[nochange] = 1

     
    ;read in ftv_tc image if needed
    if extract_tc_ftv eq 'yes' then begin
      zot_img, b_ftv_file, hdr, b_ftv, subset=this_subset
      zot_img, g_ftv_file, hdr, g_ftv, subset=this_subset
      zot_img, w_ftv_file, hdr, w_ftv, subset=this_subset
    endif
    
    ;create year image
    yr_img = vy_img
    ;        for yr = 0, n_years-2 do begin   ;don't do the last year
    ;            these = where(vy_img eq all_years[yr], n)
    ;            if n ne 0 then yr_img[these] = all_years[yr+1]    ;just assign all cases to the next year
    ;        end
    
    for class = 0, n_classes-1 do begin
      print, "Processing class " + string(class+1) + " of " + string(n_classes)
      this_image = intarr(xsize, ysize, output_segs[class] * 4)
      if extract_tc_ftv eq 'yes' then ftv_image = intarr(xsize, ysize, output_segs[class] * 6)
      
      for x = 0, xsize-1 do begin
        for y = 0, ysize-1 do begin
          ;only for changed pixels
          if distrec_img[x,y] ne -1500 then begin
            if class eq 0 then label_image[x, y] = 2; by default it is nomatch
            ok = evaluate_classes_rule(interpd_class_codes[class], $
              yr_img[x,y,*], $
              vv_img[x,y,*], $
              mag_img[x,y,*], $
              filter_params, $
              merge_recovery ,$
              use_relative_mag=use_relative_mag)
              
            if ok.ok eq 0 then begin
              print, 'label landtrendr_images_v1 could not evaluate a class'
              print, ok.message
              return, {ok:0, message:'label landtrendr_images_v1 could not evaluate a class '+ok.message}
            end
            
            
            if ok.match then begin
              this_image[x,y,*] = vertex_to_disturbance_year(ok.outvals, all_years)
              label_image[x,y] = ok.class_num
              
              ;now extract ftv image and the corresponding magnitude.
              if extract_tc_ftv eq 'yes' then $
                ftv_image[x,y,*] = read_segment_spectral(b_ftv[x,y,*], g_ftv[x,y,*], w_ftv[x, y, *], ok.outvals, all_years)
            endif
          endif
        endfor
      endfor
      
      ;output requested for this class
      if write_details[class] gt 0 then begin
        openu, un, output_files[class], /get_lun
        n_segs = output_segs[class]
        
        for segs = 0, n_segs*4-1 do begin
          point_lun, un, segs*layersize + (chunks[current_chunk].within_layer_offset)*2
          writeu, un, this_image[*,*,segs]
        endfor
        
        free_lun, un
      endif
      
      if extract_tc_ftv eq 'yes' then begin
        openu, un, ftv_files[class], /get_lun
        n_segs = output_segs[class]
        
        for segs = 0, n_segs*6-1 do begin
          point_lun, un, segs*layersize + (chunks[current_chunk].within_layer_offset)*2
          writeu, un, ftv_image[*,*,segs]
        endfor
        free_lun, un
      endif
      
    endfor  ;endfor class
    
    ;now we've done everything in this chunk.  need to write out the label image
    openu, un,    output_label_file, /get_lun
    
    ;point to and write it.
    point_lun, un, (chunks[current_chunk].within_layer_offset)*2
    writeu, un, label_image
    free_lun, un
  endfor ;endfor current_chunk
  
  ;now that we've written everything out, we need to also capture the
  ;  class names
  output_descriptor_file = core_name + '_LTlabel_classnames.csv'
  
  base = {class_num: 0, class_descriptor:''}
  tcl = n_elements(output_class_nums)+2    ;add 2 -- one for no-change, one for no-match
  out_descriptor_structure = replicate(base, tcl)
  out_descriptor_structure[0:1].class_descriptor = ['No_change', 'No_match']
  out_descriptor_structure[0:1].class_num = [1,2]
  out_descriptor_structure[2:tcl-1].class_descriptor = reform(output_class_descriptors)
  out_descriptor_structure[2:tcl-1].class_num = reform(output_class_nums)
  
  export_structure_to_file, out_descriptor_structure, output_descriptor_file
  
  return, {ok:1, outpath:outpath, core_name:core_name}
  
end
