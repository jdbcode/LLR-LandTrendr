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

function run_ftv_single_chunk, vertex_image_file, apply_to_image_info,  $
		subset, apply_to_index, mask_image, output_image_group, $
		within_layer_offset, layersize, kernelsize, $
		background_val, $
		skipfactor, desawtooth_val, $
	;	pval, max_segments, normalize , $
		fix_doy_effect, divisor, interpolate=interpolate
		;, $
	;recovery_threshold, minneeded


	;6/20/08 the number of years is not the number of info items, because now we allow
	;  multiple images per year.  So check on the number of unique years in the
	;  year array
;print, 'original subset'
;print, subset

	years = fast_unique(apply_to_image_info.year)
	years = years[sort(years)]
	
	;change input year list if interpolation for missing years
	if keyword_set(interpolate) then years = indgen(range(years)+1)+min(years)
	
	n_yrs = n_elements(years)
	maxyear = max(years)			;keep this for later, when we sometimes need to fill in.
	n_images = n_elements(apply_to_image_info)	;because we need to go through each image, even if multiple per year

;	if n_yrs lt minimum_number_years_needed then begin
;		print, 'run_ftv_single_chunk:  there are fewer than the minimum
;		print, 'number of years available for disturbance/recovery extraction'
;		print, 'the minimum is: '+string(minimum_number_years_needed)
;		print, 'the number of files given to extract_disturbance_recovery4.pro: '+string(n_yrs)
;		print, 'confirm that the information from find_image_stack_files is correct'
;		return, {ok:0}
;	end
;


	;check on the mask image

	if file_exists(mask_image) eq 0 then begin
		print, 'run_ftv_single_chunk.pro needs to have a mask image.'
		print, 'the mask image should be 0s and 1s, with 1s indicating where
		print, ' to run the curve fitting.
		return, {ok:0}
	end


	;for the first year, just get the full subset, then use that
	;as the template.

	if n_elements(subset) eq 0 then begin
		print, 'run_ftv_single_chun k needs to have a "subset" keyword set'
		return, {ok:0}
	end



	;check on the mask image

tempsubset=subset
	zot_img, mask_image, mask_hdr, mask_img, subset=tempsubset



	if max(mask_img) gt 1 then begin
		print, 'The mask image must have a maximum value of 1, to indicate
		print, '  where to run the curve-fitting.  The mask image
		print, mask_image
		print, '   has a maximum of '+string(max(mask_img))
		return, {ok:0}
	end


	;  image_file:'', $
	;   			image_path:'', $
	;   			type:0, $				;1 mtbs 2 nonmtbs 3 reference year mtbs
	;   					nbr_file:'', $
	;   					tc_file:'', $
	;   					b6_file:'', $
	;   					year:0, $
	;   					julday:0, $
	;   					unique_year:0, $    ;flagged 1 if only 1 image in this year
	;   					n_in_year:0, $		;number of images in this year
	;   					image_priority:0, $	;priority of picking if more than one image per year
	;   					cloudyear:0, $
	;   					cloud_diff_file:'', $
	;   					shadow_diff_file:'', $
	;   					tc_cloud_diff_file:'', $
	;   					cloud_file:'none', $
	;   					subset:[ [0.d, 0.d],[0.d, 0.d]], $
	;   					useareafile: ''}


	;First, build an image to hold the different years, then read them in

	;use first year as a template
tempsubset=subset

	zot_img, apply_to_image_info[0].image_file, hdr, img, subset=tempsubset, layer=[1], /hdronly



	;lcount = n_elements(layer)

	;if lcount eq 0 then layer = 1
	;zot_img, path+file_list[0], hdr, img, subset=subset, layer=layer, /hdronly
	;       if lcount eq 2 then begin
	;           layer2 = layer[1]
	;           layer1 = layer[0]
	;        end else layer1 = layer



	if hdr.pixeltype ne 6 and hdr.pixeltype ne 3 and hdr.pixeltype ne 5 then begin
		print, 'run_ftv_single_chunk expects the image to be of integer type'
		print, 'this one is type number '+string(hdr.pixeltype)

		return, {ok:0}
	end

	;make up a new image with the right dimensions.
	;the new image could potentially have multiple values for a given year,
	;which will be handled by the cloud mask.
	img = intarr(hdr.filesize[0], hdr.filesize[1], n_yrs)
	cld_img = bytarr(hdr.filesize[0], hdr.filesize[1], n_yrs)		;added v4
	usedmask = intarr(hdr.filesize[0], hdr.filesize[1]) ;valide values for years with multiple image

	;which image was used
	idx_img = bytarr(hdr.filesize[0], hdr.filesize[1], n_yrs)



	;now go through and build it.
	k = 0
	for i = 0, n_yrs-1 do begin
	;for i = 0, n_images-1 do begin
		; zot_img, info[i].image_file, hdr, img1, subset = subset, layer=layer1
		fileid = i + k
		this = where(apply_to_image_info.year eq years[i], n)

		;current year
		cur_mask = bytarr(hdr.filesize[0], hdr.filesize[1])
		cur_img = intarr(hdr.filesize[0], hdr.filesize[1])
		cur_idx = bytarr(hdr.filesize[0], hdr.filesize[1])

    ;this is a missing year, and interpolation requested
    if n eq 0 then begin
      cld_img[*,*,i] = 1
      k = k - 1
      continue
    endif 


		if n eq 1 then begin

			tempsubset=subset
			landtrendr_image_read, apply_to_image_info[fileid], hdr, img1, tempsubset, apply_to_index, modifier, background_val
			sz = size(img1, /dim)

			;now check vs. background. If so, then assign to the cloud
			;   image, since that's what I check before calling the
			;   fitting algorithm.
			bads = where(img1 eq background_val, n_bads)
			if n_bads ne 0 then cld_img[*,*,i] = (cld_img[*,*,i]+ (img1 eq background_val)) ne 0 	;ne 0 needed incase cloud image and background val!

			if n_elements(sz) gt 2 then begin
				print, 'run_ftv_single_chunks: each image layer must have a single layer'
				print, 'image '+file_list[fileid]+ 'has more than 1 layer'
				return, {ok:0}
			end	;x

			img[*,*,i] = img1/divisor	;added 2/7/08 this will scale to max of 1000

			idx_img[*,*,i] = replicate(fileid, size(img1, /dim))



			;now read the cloud mask
			; if there is no cloud mask, then just skip this
			if apply_to_image_info[fileid].cloud_file ne 'none' and apply_to_image_info[fileid].cloud_file ne '' then begin
				tempsubset=subset
				if apply_to_image_info[fileid].cloud_file eq 'band8' then $
					zot_img, apply_to_image_info[fileid].image_file, clhdr, mimg, layers=[8], subset=tempsubset else $
					zot_img, apply_to_image_info[fileid].cloud_file, clhdr, mimg, subset=tempsubset
				cld_img[*,*,i] = (cld_img[*,*,i] + (mimg eq 0)) ne 0
				;cld_img[*,*,i] = (cld_img[*,*,i] + (mimg gt 2300)) ne 0
			;  cld_img[*,*,i] = (cld_img[*,*,i] + (img1 ne 0)) ne 0 ;0 is no-cloud in cheng's cloudmasks
			end
		end	;if n eq 1

		;if multiple image exists for this year, select one and make the others masked out
		if n gt 1 then begin
			victims = apply_to_image_info[this]
			;sort by priority
			vicorder = sort(victims.image_priority)
			victims = victims[vicorder]
			;read in the cloud image
			for j = 0, n-1 do begin
			tempsubset=subset
				landtrendr_image_read, victims[j], hdr, img1, tempsubset, apply_to_index, modifier, background_val

				sz = size(img1, /dim)
				if n_elements(sz) gt 2 then begin
					print, 'run_ftv_single_chunks: each image layer must have a single layer'
					print, 'image '+file_list[fileid+j]+ 'has more than 1 layer'
					return, {ok:0}
				end

				;now read the cloud mask
				; if there is no cloud mask, then just skip this

				mimg = replicate(0, size(img1, /dim))
				if victims[j].cloud_file ne 'none' and victims[j].cloud_file ne '' then begin
					tempsubset=subset
					if victims[j].cloud_file eq 'band8' then $
						zot_img, victims[j].image_file, clhdr, mimg, layers=[8], subset=tempsubset else $
						zot_img, victims[j].cloud_file, clhdr, mimg, subset=tempsubset
						;cld_img[*,*,fileid+j] = (cld_img[*,*,fildid+j] + (mimg gt 2300)) ne 0
				end
        
        valid = where(img1 ne background_val and cur_mask eq 0 and mimg eq 1, n_valid)
				;valid = where(img1 ne background_val and cur_mask eq 0 and mimg le 2300, n_valid)
				if n_valid ne 0 then begin
					cur_img[valid] = img1[valid]
					cur_mask[valid] = 1
					cur_idx[valid] = replicate(this[vicorder[j]], n_valid)
				end
			endfor	;j

			k = k + n - 1
			img[*,*,i] = cur_img/divisor
			cld_img[*,*,i] = cur_mask ne 1
			idx_img[*,*,i] = cur_idx
		end    ;if ngt 1
	end

	img1 = 0 ;reset to save space
	cur_img = 0
	cur_mask = 0



	;***************************
	;then read the vertex image.  this is what we'll use to constrain the
	;   spectral image.

			tempsubset=subset
			zot_img, vertex_image_file, vhdr, vimg, subset=tempsubset

		;get the distrec image too, as this will tell if this is no-change pixel
			distrec_image = strmid(vertex_image_file, 0, strlen(vertex_image_file)-12)+'_distrec.bsq'
			tempsubset = subset
			zot_img, distrec_image, dhdr, distrec_img, subset=tempsubset, layers=[3]	;the flag -- if set to -1500, it's no change

	;observe year stuff

	sz = size(img, /dim)
	;      n_yrs = sz[2]
	;        x_axis = indgen(n_yrs)

				;v4 has the actual years, offset by the min

	min_year = min(apply_to_image_info.year)
	x_axis = years		;these were "uniqued" early on, so should be okay.


	;load in the stats image -- this will tell us where to run the
	;   fitting, as we want to match which pixels are actually fit and
	;   which ones are interpolated.
		tempsubset=subset
		vq = strlen(vertex_image_file)
		source_stats_image = strmid(vertex_image_file, 0, vq-12)+'_stats.bsq'
		zot_img, source_stats_image,i_hdr, interpolation_rules_image,  $
					subset=tempsubset, $
					layers = [5,9,10]
							;new layers of interpolation_rules_image:
							;1:  1 = directly run, 2 = interpolated
							;2:  xoffset to find the source pixel
							;3:  yoffset

	;set up the progress bar:

	progressBar = Obj_New("PROGRESSBAR", /fast_loop, title = 'Curve-fitting:  percent done')
	progressBar -> Start

;	vertyear_image = intarr(sz[0], sz[1], output_image_group[0].n_layers)
	vertvals_image = intarr(sz[0], sz[1], output_image_group[0].n_layers)
;	mag_image = intarr(sz[0], sz[1],output_image_group[2].n_layers)
;	dur_image = intarr(sz[0], sz[1], output_image_group[3].n_layers)
;	distrec_image = intarr(sz[0], sz[1], output_image_group[4].n_layers)




	fitted_image = intarr(sz[0], sz[1], output_image_group[1].n_layers)
	stats_image = intarr(sz[0], sz[1], output_image_group[2].n_layers)
	segmse_image = intarr(sz[0], sz[1], output_image_group[3].n_layers)
	source_image = intarr(sz[0], sz[1], output_image_group[4].n_layers)
	segmean_image = intarr(sz[0], sz[1], output_image_group[5].n_layers)

	totalcount = float(sz[0]*sz[1])





	ksq=kernelsize^2
	seed= randomseed()
	if n_elements(skipfactor) eq 0 then skipfactor = 3

	offset = (kernelsize-1)/2

;First, need to make sure that anything near the edge on the x-dim
;   is not set to 1 or 2, since those can't be used when the offset is
;   added in

   if offset ne 0 then begin
     interpolation_rules_image[0:offset-1,*] = 0
     interpolation_rules_image[sz[0]-1-offset+1:sz[0]-1, *] = 0
   end


;first, clean up the runats image.  There are places
;   where the interpolation rules image was  overwritten in tbcd
;   by the next chunk down in the case where the chunks are not
;   lined up exactly right.  So we need to repopulate those
;   places to do the directly run.  However, we also need to
;   make sure that none of the pixels directly on the edge of the
;   images are set, because the buffer of offset pixels for rounding
;   will be broken when we actually try to run those spots further
;   down.

	interpats = where(interpolation_rules_image[*,*,0] eq 2, n_interpats)
	szi = size(interpolation_rules_image, /dim)
	maxydim = szi[1]

	if n_interpats ne 0 then begin
    xy = getxy(interpats, sz[0], sz[1])
		;go through all of the pixels that needed to be interpolated
		for use_em = 0ul, n_interpats-1 do begin
	 	   x = xy[0, use_em]
	 	   y = xy[1, use_em]
			xoffset = interpolation_rules_image[x,y,1]
			yoffset = interpolation_rules_image[x,y,2]
			match_pos_x = x+xoffset
			match_pos_y = y+yoffset
			if match_pos_y le (maxydim-1-offset) and $
			   match_pos_y ge offset then interpolation_rules_image[match_pos_x, match_pos_y, 0] = 1


	   	end

	end

;now determine where we'll run things
	runats = where(interpolation_rules_image[*,*,0] eq 1, n_runats)
	if n_runats eq 0 then begin
		print, 'Error in run_ftv_single_chunk.pro :  the source stats image says no pixels were run'
		return, {ok:1}
		stop
	end
	;make lookup table
	   xy = getxy(runats, sz[0], sz[1])

	for use_em = 0ul, n_runats-1 do begin

 	   x = xy[0, use_em]
 	   y = xy[1, use_em]
;
;	for x = offset, sz[0]-(offset+1), skipfactor do begin
;		for y = offset, sz[1]-(offset+1), skipfactor do begin

			;check on the mask image to see if we should run this pixel
			if mask_img[x,y] eq 1 then begin
				;check for clouds

				chunk = img[x-offset:x+offset, y-offset:y+offset, *]
				usable = cld_img[x-offset:x+offset, y-offset:y+offset, *] eq 0

				slice = total(chunk*usable,1)
				slice_usable = total(usable, 1)

				vals = total(slice,1)/total(slice_usable,1)

				goods= where(cld_img[x,y,*] ne 1, ngds)
			;	if ngds gt minimum_number_years_needed then begin
				if ngds gt 0 then begin	;CHANGED IN TRANSTION FROM TBCD TO FTV 8/14/08 REK


				;get the vertices  ;CHANGED IN TRANSTION FROM TBCD TO FTV 8/14/08 REK

					all_vertices = vimg[x,y,*]
					real_verts = where(all_vertices ne 0, n_verts)

				  this_distrec = distrec_img[x,y]		;ony layer 3, which shows -1500 for no change

				  if n_verts gt 0 then begin 	;on the edge, there can be a few
				  								; pixels within the mask that have no
				  								; verts, so need to catch that here

				   if this_distrec eq -1500 then begin 	;if this is a no-change pixel.
						thismean=mean(vals[goods])
						thismse = mean((vals[goods] - thismean)^2)


						fitted_image[x,y,*] = thismean	;all yfit values should go in there, prior line was illogical.

						source_image[x,y,goods]=vals[goods]

						vertvals_image[x, y, 0:1] = thismean
						segmse_image[x,y,0] = thismse


;						vertvals_image[x,y,0:n_verts-1] = ok.model.vertvals		;in the units fed to fit_trajectory_v1

;						segmse_image[x,y,0:n_verts-2] = ok.model.segment_mse		;mse of each segment
						segmean_image[x,y,0] = thismean




						stats_image[x,y,4] = 1			;directly run?
						stats_image[x,y,5] = 1
;						stats_image[x,y,6] = x_axis[goods[0]]	;set to minimum usable year
						stats_image[x,y,7] = n_elements(goods)



				   end else begin 		;for most pixels -- since most have changed. this is the main routine

					vertices = all_vertices[real_verts]




					;first check to see if fix the doy effect
					if n_elements(fixdoyeffect) ne 0 then begin

						idxs = idx_img[x,y,*]

						uniques = fast_unique(apply_to_image_info[idxs[goods]].julday)
						if n_elements(uniques) gt 4 then begin
							r = poly_fit(apply_to_image_info[idxs[goods]].julday, vals[goods],2, chisq=chisq,yfit = yfit)
							m = mean(yfit)
							zzz = calc_fitting_stats3(vals[goods], yfit, 3, resid=resid)
							if zzz.p_of_f lt pval then outvals = m+resid else $
								outvals = vals[goods]
						end else outvals = vals[goods]
					end else outvals = vals[goods]  ;n_elements(fixdoyeffect)

					;OCCASIONAL ISSUE WITH THE VERTICES BEING THE SAME FOR
					;   V1 AND V2, SO NEED TO DEAL WITH HERE. ULTIMATELY FIX IN
					;   TBCD.

					IF vertices[0] eq vertices[1] then vertices[1] = maxyear;set to the maximum in case we have a glitch





					;*****************************************************
if n_elements(outvals) eq 1 then begin
  print, "wrong"
endif
						ok=apply_fitted_trajectory_v1(x_axis,goods, outvals, $
										 vertices, desawtooth_val)

					;*****************************************************



;
;					ok=fit_trajectory_v1(x_axis,goods, outvals, $
;						minneeded, background_val, $
;						modifier, seed, $
;						desawtooth_val, pval, $
;						max_segments, recovery_threshold)

;					if ok.ok eq 1 then begin
;						;take out the bad year


						;fitted_image[x,y,*] = round(ok.model.yfit[uniq(apply_to_image_info.year)])	;all years, including masked out, will get fittedvals
						fitted_image[x,y,*] = round(ok.model.yfit)	;all yfit values should go in there, prior line was illogical.

						source_image[x,y,goods]=outvals

						;below changed from run_tbcd -- need to specify the
						;  number of verts, since the fitting algorithm just
						;  calcs for the segments defined by the vertices, whereas
						;  the original tbcd version always has the max.

						;YANG
						;n_verts may not be the right number to use in here, as the apply_fitted_trajectory_v1
						; could potentially add one or two vertex in the output.

						vertvals_image[x, y, 0:ok.model.n_segments] = ok.model.vertvals[0:ok.model.n_segments]
						segmse_image[x,y,0:ok.model.n_segments-1] = ok.model.segment_mse[0:ok.model.n_segments-1]


;						vertvals_image[x,y,0:n_verts-1] = ok.model.vertvals		;in the units fed to fit_trajectory_v1

;						segmse_image[x,y,0:n_verts-2] = ok.model.segment_mse		;mse of each segment
						for ss = 0, ok.model.n_segments-1 do $			;mean of each segment
								segmean_image[x,y,ss] = (vertvals_image[x,y,ss]+vertvals_image[x,y,ss+1])/2.



					;	vertyear_image[x,y,*] = ok.model.vertices		;these are true years

;						;get the magnitudes and the proportions
;						temp = shift(ok.best_model.vertvals, -1) - ok.best_model.vertvals
;						mag_image[x,y,0:ok.best_model.n_segments-1] = temp[0:ok.best_model.n_segments-1]
;
;						maxdist = max(mag_image[x,y,0:ok.best_model.n_segments-1], min=maxrec)
;						distrec_image[x,y, 0]=max([maxdist,0])
;						distrec_image[x,y, 1]=min([maxrec, 0])
;
;
;
;						totalmag = total(abs(mag_image[x,y, *]))	;the total distance traversed, up or down
;						summag = float(total(mag_image[x,y, *]))			;the actual value with pluses and minuses
;						if totalmag eq 0 then distrec_image[x,y, 2] = (-1500) else $
;							distrec_image[x,y, 2] = (summag/totalmag)*1000	;will be -1000 if all rec, + 1000 if all dist
;
;						;get the durations
;						temp = shift(ok.best_model.vertices, -1) - ok.best_model.vertices
;
;						dur_image[x,y,0:ok.best_model.n_segments-1] = temp[0:ok.best_model.n_segments-1]
;
;
;						;					mag_image[x,y,*] =
;						;					 = intarr(sz[0], sz[1], max_segments)
;						;			distrec_image = intarr(sz[0], sz[1], max_segments)
;
;


;						if ok.best_model.f_stat gt 300 then ok.best_model.f_stat = 300
;						stats_image[x,y,0] = round(ok.best_model.p_of_f*100)
;						stats_image[x,y,1] = round(ok.best_model.f_stat*100)
;						stats_image[x,y,2] = round(ok.best_model.ms_regr/10.)
;						stats_image[x,y,3] = round(ok.best_model.ms_resid/10.)
						stats_image[x,y,4] = 1			;directly run?
						stats_image[x,y,5] = ok.model.n_segments
;						stats_image[x,y,6] = x_axis[goods[0]]	;set to minimum usable year
						stats_image[x,y,7] = n_elements(goods)	;number of usable years
;

					end
				  end	;distrec ne -1500
				end



			end


			if progressBar -> CheckCancel() then begin
				;progressBar -> destroy
				print, 'x and y', string(x)+string(y)
				stop
			;    return, {ok:0}

			end

;		end ;y


		percent_done = (float(x)*y)/ totalcount
		if (percent_done*100) eq round(percent_done*100) then progressBar -> Update, percent_done*100

;	end		;x


end ;use_em


	progressBar -> Destroy


	;under the new way of doing things (1/23/09), we only want to
	;  interpolate from the same pixel that the
	;  original landtrendr run interpolated.  this keeps all
	;  indices on the same vertex line


	runats = where(interpolation_rules_image[*,*,0] eq 2, n_runats)
	if n_runats eq 0 then goto, no_interp



	;make lookup table
	   xy = getxy(runats, sz[0], sz[1])


	progressBar = Obj_New("PROGRESSBAR", /fast_loop, title = 'Interpolating:  percent done')
	progressBar -> Start


	;go through all of the pixels that needed to be interpolated

	for use_em = 0ul, n_runats-1 do begin

 	   x = xy[0, use_em]
 	   y = xy[1, use_em]

		xoffset = interpolation_rules_image[x,y,1]
		yoffset = interpolation_rules_image[x,y,2]
		match_pos_x = x+xoffset
		match_pos_y = y+yoffset

		if match_pos_y le (hdr.filesize[1]-1) and match_pos_y ge 0 $
		  and match_pos_x le (hdr.filesize[0]-1) and match_pos_x ge 0		then begin ; as long as we're not over the edge into the next one.
		;vertyear_image[x,y,*] = vertyear_image[match_pos_x,match_pos_y, *]
			vertvals_image[x,y,*] = vertvals_image[match_pos_x,match_pos_y, *]
			segmse_image[x,y,*] = segmse_image[match_pos_x,match_pos_y, *]
			segmean_image[x,y,*] = segmean_image[match_pos_x,match_pos_y, *]
	;
	;		mag_image[x,y,*] = mag_image[match_pos_x,match_pos_y, *]
	;		distrec_image[x,y,*] = distrec_image[match_pos_x,match_pos_y, *]
	;		dur_image[x,y,*] = dur_image[match_pos_x,match_pos_y, *]

			fitted_image[x,y,*] = fitted_image[match_pos_x,match_pos_y, *]
			;if total(fitted_image[x,y,*]) eq 0 then stop

			;stats_image[x,y,0:3] = stats_image[match_pos_x,match_pos_y,0:3]
			stats_image[x,y,4] = 2	;interpolated
			;stats_image[x,y,5] = stats_image[match_pos_x,match_pos_y, 5]
			stats_image[x,y,6] = stats_image[match_pos_x,match_pos_y, 6]
			stats_image[x,y,7] = stats_image[match_pos_x,match_pos_y, 7]
			stats_image[x,y,8] = xoffset
			stats_image[x,y,9] = yoffset
		end

		percent_done = (float(x)*y)/ totalcount
		if (percent_done*100) eq round(percent_done*100) then progressBar -> Update, percent_done*100

	end	;use_em




	progressBar->Destroy


;	;now interpolate
;	desired_kernel_size = 15
;	ks = min([desired_kernel_size, sz[0], sz[1]])		;make sure that the kernel size is not
;	;bigger than the size of the chunk
;
;
;	dmat = fltarr(ks,ks)
;	halfval = (ks-1)/2
;	for x = 0, sz[0]-1 do begin			;start and end one pixel in,
;		for y = 0, sz[1]-1 do begin
;			checkval = (stats_image[x,y,4] ne 1) + $
;				(mask_img[x,y] eq 1)
;
;
;			if checkval eq 2 then begin
;
;				;first, get cloud info for the desired pixel
;				goods_pix = cld_img[x,y,*] ne 1
;
;				;then calc the range of neighborhood pixels
;
;				start_x = max([x-halfval, 0])		;first set up starting point, make sure in image
;				start_y = max([y-halfval, 0])
;				end_x = min([start_x+ks-1, sz[0]-1])  ;if we're near the other side, bump
;				end_y = min([start_y+ks-1, sz[1]-1])
;				start_x = end_x-ks+1								 ;jiggle start if we had to bump
;				start_y = end_y-ks+1							 ;won't affect anything if we're not near the end
;
;
;				;set the source image to img[x,y,combined_goods].
;				;  this is not interpolated.
;
;				wh_goods_pix = where(goods_pix eq 1, n_goods_pix)
;				if n_goods_pix ne 0 then source_image[x,y,wh_goods_pix] = img[x,y,wh_goods_pix]
;
;				;then go through and get distance in spectral/temporal space
;
;				for i = start_x, end_x do begin
;					for j= start_y, end_y do begin
;
;						;if this is a real curve-fitted pixel, then see
;						;  how far away
;
;						if stats_image[i,j,4] eq 1 then begin
;							goods_test = cld_img[i,j,*] ne 1
;							combined_goods = where(goods_test*goods_pix eq 1, ngds)
;							if ngds ne 0 then $
;								;						  	      dmat[i-start_x, j-start_y] = $
;								;						  					sqrt(total(img[i,j,combined_goods] - $
;								;						  					img[x,y,combined_goods])^2) else dmat[i-start_x, j-start_y] = 2e32
;								dmat[i-start_x, j-start_y] = $
;								total(abs(img[i,j,combined_goods] - $
;								img[x,y,combined_goods])) else dmat[i-start_x, j-start_y] = 2e32
;
;
;
;						end else dmat[i-start_x, j-start_y] = 2e32		;just set to an absurdly high number
;
;					end
;				end
;
;
;
;				;then pick closest one
;
;				closest = where(dmat eq min(dmat))
;				closest = closest[0]
;				pos = getxy(closest, ks, ks)
;
;				if min(dmat) ne 2e32 then begin
;					;vertyear_image[x,y,*] = vertyear_image[pos[0]+start_x, pos[1]+start_y, *]
;					vertvals_image[x,y,*] = vertvals_image[pos[0]+start_x, pos[1]+start_y, *]
;					segmse_image[x,y,*] = segmse_image[pos[0]+start_x, pos[1]+start_y, *]
;					segmean_image[x,y,*] = segmean_image[pos[0]+start_x, pos[1]+start_y, *]
;
;
;;					mag_image[x,y,*] = mag_image[pos[0]+start_x, pos[1]+start_y, *]
;;					distrec_image[x,y,*] = distrec_image[pos[0]+start_x, pos[1]+start_y, *]
;;					dur_image[x,y,*] = dur_image[pos[0]+start_x, pos[1]+start_y, *]
;
;					fitted_image[x,y,*] = fitted_image[pos[0]+start_x, pos[1]+start_y, *]
;				;	stats_image[x,y,0:3] = stats_image[pos[0]+start_x,pos[1]+start_y,0:3]
;					stats_image[x,y,4] = 2	;interpolated
;				;	stats_image[x,y,5] = stats_image[pos[0]+start_x, pos[1]+start_y, 5]
;					stats_image[x,y,6] = stats_image[pos[0]+start_x, pos[1]+start_y, 6]
;   					stats_image[x,y,7] = stats_image[pos[0]+start_x, pos[1]+start_y, 7]
;
;
;				end else begin 			;if no good vals
;					;vertyear_image[x,y,*] = -1
;					vertvals_image[x,y,*] = -1
;					segmse_image[x,y,*] = -1
;;					mag_image[x,y,*] = -1
;;					distrec_image[x,y,*] = -1
;;					dur_image[x,y,*] = -1
;					segmean_image[x,y,*] = -1
;
;					fitted_image[x,y,*] = -1
;					stats_image[x,y,*] = [1.0, 0, 0, 0, 2, -1, 0, 0]	;set p to 1.0, and set to interpolated
;				end
;
;			end	;checkval okay
;		end	;y


	;write 'em out

	;vertices


;	openu, un, output_image_group[0].filename, /get_lun
;	for layercount = 0, output_image_group[0].n_layers-1 do begin
;		point_lun, un, (output_image_group[0].layersize * $
;			layercount)+within_layer_offset
;		writeu, un, vertyear_image[*,*,layercount]
;	end
;	free_lun, un


;jump here if no interpolation
	no_interp:

	;vertvals

	openu, un, output_image_group[0].filename, /get_lun
	for layercount = 0ull, output_image_group[0].n_layers-1 do begin
		point_lun, un, (output_image_group[0].layersize * $
			layercount)+within_layer_offset
		writeu, un, vertvals_image[*,*,layercount]*modifier		;added modifier july 9 2008 so values make sense
	end
	free_lun, un


;	;mag image
;
;	openu, un, output_image_group[2].filename, /get_lun
;	for layercount = 0, output_image_group[2].n_layers-1 do begin
;		point_lun, un, (output_image_group[2].layersize * $
;			layercount)+within_layer_offset
;		writeu, un, mag_image[*,*,layercount]
;	end
;	free_lun, un
;
;	;duration image
;
;
;	openu, un, output_image_group[3].filename, /get_lun
;	for layercount = 0, output_image_group[3].n_layers-1 do begin
;		point_lun, un, (output_image_group[3].layersize * $
;			layercount)+within_layer_offset
;		writeu, un, dur_image[*,*,layercount]
;	end
;	free_lun, un
;
;	;distrec image
;
;
;	openu, un, output_image_group[4].filename, /get_lun
;	for layercount = 0, output_image_group[4].n_layers-1 do begin
;		point_lun, un, (output_image_group[4].layersize * $
;			layercount)+within_layer_offset
;		writeu, un, distrec_image[*,*,layercount]
;	end
;	free_lun, un
	;fitted

	openu, un, output_image_group[1].filename, /get_lun
	for layercount = 0ull, output_image_group[1].n_layers-1 do begin
		point_lun, un, ulong64(output_image_group[1].layersize) * $
			layercount+within_layer_offset
		writeu, un, fitted_image[*,*,layercount]
	end
	free_lun, un

	;stats

	openu, un, output_image_group[2].filename, /get_lun
	for layercount = 0ull, output_image_group[2].n_layers-1 do begin
		point_lun, un, (output_image_group[2].layersize * $
			layercount)+within_layer_offset
		writeu, un, stats_image[*,*,layercount]
	end
	free_lun, un

	;segmse

	openu, un, output_image_group[3].filename, /get_lun
	for layercount = 0ull, output_image_group[3].n_layers-1 do begin
		point_lun, un, (output_image_group[3].layersize * $
			layercount)+within_layer_offset
		writeu, un, segmse_image[*,*,layercount]
	end
	free_lun, un

	;source image

	openu, un, output_image_group[4].filename, /get_lun
	for layercount = 0ull, output_image_group[4].n_layers-1 do begin
		point_lun, un, (output_image_group[4].layersize * $
			layercount)+within_layer_offset
		writeu, un, source_image[*,*,layercount]
	end
	free_lun, un


	;segmean image

	openu, un, output_image_group[5].filename, /get_lun
	for layercount = 0ull, output_image_group[5].n_layers-1 do begin
		point_lun, un, (output_image_group[5].layersize * $
			layercount)+within_layer_offset
		writeu, un, segmean_image[*,*,layercount]
	end
	free_lun, un




	return, {ok:1}

end

