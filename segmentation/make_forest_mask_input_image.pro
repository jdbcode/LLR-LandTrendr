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

;**************************************************
;Name:  make_forest_mask_input_image
;
;Purpose:  Take outputs from LandTrendr and from FTV fitting
;   to create a multilayer image that can be used to
;   train a supervised classifier to separate forest from
;   non-forest
;General strategy:  Identify the darkest segment and use it
;    for all of the output.  However, because the interpolation
;    of the FTV images can lead to there being fewer segments
;    in the Greenness and wetness layers, we have to limit
;    the brightness segments to the ones that overlap with
;    greenness and wetness segments.  Eventually, we should
;    constrain the FTV to use the same pixels for interpolation
;    as the original landtrendr run, as this will make all of the
;    outputs more consistent.  But for now, this workaround will work

function make_forest_mask_input_image, diag_info_sav_file

  ;access the diag_info file
  ;restore, diag_info_sav_file

  ;find the fitted image to create an output name
  ;fitted_image = diag_info.output_image_group[5].filename

  filecomponent = file_basename(diag_info_sav_file)
  pathcomponent = file_dirname(diag_info_sav_file)+'\'
  
  ;get the core filename without "_fitted.bsq"
  core = strmid(filecomponent, 0, strpos(filecomponent, "_", /reverse_search))
  
  ;make the output image
  output_filename = pathcomponent + core + '_darkseg.bsq'
  
  ;find the tc vertvals and segmse files
  counts = bytarr(6)
  segmse_brightness_image = file_search(pathcomponent, '*'+core+'*'+'brightness_ftv_segmse.bsq', count=counts1)
  segmse_greenness_image = file_search(pathcomponent, '*'+core+'*'+'greenness_ftv_segmse.bsq', count=counts2)
  segmse_wetness_image = file_search(pathcomponent, '*'+core+'*'+'wetness_ftv_segmse.bsq', count=counts3)
  vertval_brightness_image = file_search(pathcomponent, '*'+core+'*'+'brightness_ftv_vertvals.bsq', count=counts4)
  vertval_greenness_image = file_search(pathcomponent, '*'+core+'*'+'greenness_ftv_vertvals.bsq', count=counts5)
  vertval_wetness_image = file_search(pathcomponent, '*'+core+'*'+'wetness_ftv_vertvals.bsq', count=counts6)
  
  ;check for existence of the dependent files
  if counts1 eq 0 then print, ">>> warning the file 'brightness_ftv_segmse.bsq' does not seem to exist for this run: ",core
  if counts2 eq 0 then print, ">>> warning the file 'greenness_ftv_segmse.bsq' does not seem to exist for this run: ",core
  if counts3 eq 0 then print, ">>> warning the file 'wetness_ftv_segmse.bsq' does not seem to exist for this run: ",core
  if counts4 eq 0 then print, ">>> warning the file 'brightness_ftv_vertvals.bsq' does not seem to exist for this run: ",core
  if counts5 eq 0 then print, ">>> warning the file 'greenness_ftv_vertvals.bsq' does not seem to exist for this run: ",core
  if counts6 eq 0 then print, ">>> warning the file 'wetness_ftv_vertvals.bsq' does not seem to exist for this run: ",core
  
  if (counts1+counts2+counts3+counts4+counts5+counts6) ne 6 then stop
  
  ;set up
  background_val = 0
  
  ;track image will keep track of the tcangle
  zot_img, vertval_brightness_image, hdr, vertval_brt_img, layers=[1]
  trackimg = vertval_brt_img
  zot_img, vertval_greenness_image, hdr, vertval_grn_img, layers=[1]
  vertval_grn_img = vertval_grn_img * (-1)
  
  goods = where(vertval_brt_img ne 0, n_goods)
  if n_goods gt 0 then $
    trackimg[goods] = atan(float(vertval_grn_img[goods])/vertval_brt_img[goods])*!radeg*10
  notgoods = where(vertval_brt_img eq 0, n_bads)
  if n_bads ne 0 then trackimg[NOTGOODS] = 0
  use_seg = 	bytarr(hdr.filesize[0], hdr.filesize[1])
  if n_goods gt 0 then use_seg[goods]=1
  
  
  ;------------------
  ;set up the output file
  n_segs = hdr.n_layers
  
  bytes_per_pixel = 2
  n_output_layers = 6		;3/9/09 changed to hardwired 6 now that 3 of mean 3 of mse
  
  openw, un, output_filename, /get_lun
  layersize = ulong(hdr.filesize[0]) * $          ;we'll use this for writing later
    hdr.filesize[1] *  $
    bytes_per_pixel
  filesize = ulong64(layersize) * n_output_layers
  point_lun, un, filesize - bytes_per_pixel
  writeu, un, 0
  free_lun, un
  hdr1 = hdr
  hdr1.n_layers = n_output_layers
  hdr1.pixeltype = 6
  write_im_hdr, 	output_filename, hdr1
  
  ; now create the metadata file
  this_meta = stringswap(output_filename, ".bsq", "_meta.txt")
  infiles = [vertval_brightness_image, vertval_greenness_image, vertval_wetness_image, $
    segmse_brightness_image, segmse_greenness_image, segmse_wetness_image]
  files = file_basename(infiles+[replicate(','+string(10b), n_elements(infiles)-1), ''])
  files = string(files, format='('+string(n_elements(files))+'A)')
  meta = create_struct("DATA", "Dark Segment Image", "FILENAME", file_basename(output_filename), "PARENT_FILE", files)
  
  concatenate_metadata, infiles, this_meta, params=meta
  
  
  ;-------------------------
  
  ;set up counter variables
  use_seg = 	bytarr(hdr.filesize[0], hdr.filesize[1])
  
  ;now go through and find the most forested segments based on angle
  ;   we already have the first layer calc'd, so start at 2
  zot_img, segmse_brightness_image, hdr, segmse_brt_img, layers=[1]
  for i = 2, n_segs do begin
    ;we're looking for segments that have non-zero mean and non-zero
  
    zot_img, vertval_brightness_image, hdr, vertval_brt_img, layers=[i]
    ;for the first and second vertex, we associate withthe first segment,
    ;  thereafter we always refer to the segment leading up to the current vertex
    ;  thus, if i = 2, we just hold on to the prior segmse image.
    
    if i gt 2 then zot_img, segmse_brightness_image, hdr, segmse_brt_img, layers=[i-1]
    
    zot_img, vertval_greenness_image, hdr, vertval_grn_img, layers=[i]
    vertval_grn_img = vertval_grn_img * (-1)	;need to convert because the vertvals images are modifier by modifier
    
    ;see if this angle is better than the existing one
    goods = where(vertval_brt_img ne 0 and segmse_brt_img gt 0, n_goods)
    if n_goods gt 0 then begin
      angle = (atan(float(vertval_grn_img[goods])/vertval_brt_img[goods])*!radeg*10)
      better_thans  = where(angle gt trackimg[goods], nbts)
      
      if nbts gt 0 then begin
        trackimg[goods[better_thans]] = angle[better_thans]
        use_seg[goods[better_thans]] = i
      end
    end		;n_goods gt 0
  end	;i
  
  ;then use the use_seg to assign all of the values
  names = [vertval_brightness_image, vertval_greenness_image, vertval_wetness_image, $
    segmse_brightness_image, segmse_greenness_image, segmse_wetness_image]
  modifier = [1,-1,-1,1,1,1]
  
  ;now write it out
  layer = 0
  for nm = 0, 5 do begin
    zot_img, names[nm], hdr2, img, layers = [1]
    img = img * modifier[nm]		;need to swap the greenness and wetness images
    
    track_img = img
    for i = 2, n_segs do begin
      if nm le 2 then $		;if usingthe vertex images, okay to use segs
        zot_img, names[nm], hdr2, img, layers = [i] else $  otherwise if using the mse image (with one fewer layers)
      if i gt 2 then zot_img, names[nm], hdr2, img, layers = [i-1]	;if i eq 2, it won't read anew and will use prior layer
      img = img * modifier[nm]		;need to flip the greenness and wetness images
      
      test = (use_seg eq i)
      these = where(test gt 0, n_matches)
      if n_matches ne 0 then track_img[these] = img[these]
    end
    
    ;now write it out
    openu, un, output_filename, /get_lun
    point_lun, un, (layersize * layer)
    writeu, un, track_img
    
    free_lun, un
    layer = layer+1
  end
  
  print, 'done with forest mask input layer image'
  return, {ok:1}
end
