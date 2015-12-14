function make_metadata_for_preprocessing, inputfile, modisimgsrc=modisimgsrc, madcal_summary=madcal_summary, cost=cost,$
    darkobjval=darkobjval, tcsrcimg=tcsrcimg, cldmaskthresh=cldmaskthresh, maskedclasses=maskedclasses, tcmultiplier=tcmultiplier,$
    tccoeffs=tccoeffs, norm_method=norm_method, ledaps_ref=ledaps_ref, modis_ref=modis_ref, cldmskversion=cldmskversion,$
    generic_ref=generic_ref
    
  ;find some paths
  if keyword_set(modisimgsrc) eq 1 then begin
    imgdirpos = strpos(inputfile,"madcal")+7
    maddir = strmid(inputfile, 0, imgdirpos)
    rootdir = strmid(inputfile, 0, imgdirpos-8)
    imgdir = rootdir+"\images\"
  endif else begin
    imgdirpos = strpos(inputfile,"images")+7
    imgdir = strmid(inputfile, 0, imgdirpos)
    rootdir = strmid(inputfile, 0, imgdirpos-8)
    maddir = rootdir+"\madcal\"
  endelse
  
  ;find the file_mgmt and image_info savefile
  file_mgmt_file = file_search(imgdir, "*landtrendr_file_mgmt*", count=n_file_mgmt_file)
  if n_file_mgmt_file eq 1 then restore, file_mgmt_file
  image_info_file = file_search(imgdir, "*landtrendr_image_info*", count=n_image_info_file)
  if n_image_info_file eq 1 then restore, image_info_file
  
  ;figure out the subset value for the passed image in file_mgmt
  searchthis = "*"+strmid(file_basename(inputfile),0,18)+"*"
  thisdate = where(strmatch(file_mgmt.ltimgbase, searchthis) eq 1)
  
  ;make/find some info from file_mgt - namely the archive filename
  archvfile = replicate(create_struct("archvfilename",""), n_elements(file_mgmt))
  for i=0, n_elements(file_mgmt)-1 do archvfile[i].archvfilename = file_search(imgdir, file_mgmt[i].ltimgbase+"*archv.bsq")
  
  ;figure out what data was passed (the subset is i)
  searchfor = ["*archv.bsq", "*cloudmask.bsq", "*radref.bsq", "*_to_*.bsq",$
    "*modis_reference.bsq", "*b6.bsq", "*ltc.bsq"]
  for i=0, n_elements(searchfor)-1 do begin
    theone = strmatch(inputfile, searchfor[i])
    if theone eq 1 then break
  endfor
  
  ;output different structures depending on what data was passed
  case i of
  
    ;---archv---
    0: begin
      metadata = {data: "archive image",$
        filename: file_basename(inputfile),$
        parent_filename: file_basename(file_mgmt[thisdate].glovisimg),$
        native_projection: file_mgmt[thisdate].nativeproj,$
        final_projection: file_mgmt[thisdate].reproj,$
        reprojection_method: "gdalwarp using nearest neighbor",$
        glovis_process_code_version: glovis_process_version()}
    end
    
    ;---cloudmask---
    1: begin
    
      if file_mgmt[thisdate].unpackedin eq "lt" then begin
        vct_source_filename = "na"
        lt_source_filename = file_basename(archvfile[i].archvfilename)
      endif
      
      if file_mgmt[thisdate].unpackedin eq "vct" and file_mgmt[thisdate].cmaskfixed eq "no" then begin
        vct_source_filename = file_basename(file_mgmt[thisdate].vctmaskfile)
        lt_source_filename = "na"
      endif
      
      if file_mgmt[thisdate].unpackedin eq "vct" and file_mgmt[thisdate].cmaskfixed eq "yes" then begin
        vct_source_filename = file_basename(file_mgmt[thisdate].vctmaskfile)
        lt_source_filename = file_basename(archvfile[i].archvfilename)
      endif
      
      
      if keyword_set(cldmaskthresh) eq 1 then begin
        ;lt_source_filename = stringswap(file_basename(inputfile), "cloudmask", "archv")
        lt_source_filename = file_basename(file_search(maddir, "*cloud_shadow_reference_image.bsq"))
        
        if keyword_set(cldmskversion) eq 1 then begin
        
          if cldmskversion eq 1 then begin
          
            if cldmaskthresh[0] eq 1 then begin ;thermal was used if eq 1
              if cldmaskthresh[1] eq -9999 then band6_thresh = "na" else band6_thresh = cldmaskthresh[1]
              band1_thresh = "na"
              if cldmaskthresh[2] eq -9999 then band4_thresh = "na" else band4_thresh = cldmaskthresh[2]
              band5_thresh = "na"
            endif else begin
              if cldmaskthresh[1] eq 9999 then band1_thresh = "na" else band1_thresh = cldmaskthresh[1]
              band6_thresh = "na"
              if cldmaskthresh[2] eq -9999 then band4_thresh = "na" else band4_thresh = cldmaskthresh[2]
              band5_thresh = "na"
            endelse
            
            if cldmaskthresh[2] eq -9999 then band4_thresh = "na" else band4_thresh = cldmaskthresh[2]
            if cldmaskthresh[3] eq -9999 then band1_thresh = "na" else band1_thresh = cldmaskthresh[3]
            band5_thresh = "na"
          endif
          
          if cldmskversion eq 2 then begin
            if cldmaskthresh[0] eq -99999 then band6_thresh = "na" else band6_thresh = cldmaskthresh[0]
            if cldmaskthresh[1] eq 99999 then band1_thresh = "na" else band1_thresh = cldmaskthresh[1]
            if cldmaskthresh[2] eq -99999 then band4_thresh = "na" else band4_thresh = cldmaskthresh[2]
            if cldmaskthresh[3] eq -99999 then band5_thresh = "na" else band5_thresh = cldmaskthresh[3]
          endif
          
        endif else begin ;;if keyword_set(cldmskversion) eq 1 then begin
          print, ">>> warning! cloud mask thresholds were passed..."
          print, ">>> but the masking version was not specified..."
          print, ">>> make sure that the version is passed as the keyword: cldmskversion..."
          print, ">>> where non-gui versions are value: 1 and the gui version is value: 2"
          print, ""
          print, ">>> ending program
          print, ""
          stop
        endelse ;if keyword_set(cldmskversion) eq 1 then begin
        
      endif else begin
        band1_thresh = "na"
        band4_thresh = "na"
        band5_thresh = "na"
        band6_thresh = "na"
      endelse
      
      if keyword_set(maskedclasses) eq 1 then masked_classes = maskedclasses else masked_classes = "na"
      
      metadata = {data: "cloudmask",$
        filename: file_basename(inputfile),$
        vct_source_filename: vct_source_filename,$
        lt_source_filename: lt_source_filename,$
        masked_classes: masked_classes,$
        band1_threshold: band1_thresh,$
        band4_threshold: band4_thresh,$
        band5_threshold: band5_thresh,$
        band6_cloudthresh: band6_thresh,$
        glovis_process_code_version: glovis_process_version(),$
        cloudmask_code_version: cloudmask_version()}
    end
    
    ;---radref---
    2: begin
      if keyword_set(cost) eq 1 then begin
        parent_filename = file_basename(archvfile[thisdate].archvfilename)
        correction_method = "cost"
        modis_reference_image = "na"
        cloudmask_file = "na"
        darkobjvalb1 = darkobjval[0]
        darkobjvalb2 = darkobjval[1]
        darkobjvalb3 = darkobjval[2]
        darkobjvalb4 = darkobjval[3]
        darkobjvalb5 = darkobjval[4]
        darkobjvalb7 = darkobjval[5]
        band1_offset = "na"
        band2_offset = "na"
        band3_offset = "na"
        band4_offset = "na"
        band5_offset = "na"
        band7_offset = "na"
        band1_slope = "na"
        band2_slope = "na"
        band3_slope = "na"
        band4_slope = "na"
        band5_slope = "na"
        band7_slope = "na"
        band1_correlation = "na"
        band2_correlation = "na"
        band3_correlation = "na"
        band4_correlation = "na"
        band5_correlation = "na"
        band7_correlation = "na"
      endif
      
      if keyword_set(modis_ref) eq 1 then begin
        parent_filename = file_basename(archvfile[thisdate].archvfilename)
        correction_method = "relative normalization to modis reference image"
        modis_reference_image = file_basename(file_search(maddir, "*modis_reference.bsq", count=n_modis_reference_image))
        cloudmask_file = file_basename(file_search(imgdir, searchthis+"cloudmask.bsq", count=n_cloudmask_file))
        darkobjvalb1 = "na"
        darkobjvalb2 = "na"
        darkobjvalb3 = "na"
        darkobjvalb4 = "na"
        darkobjvalb5 = "na"
        darkobjvalb7 = "na"
        band1_offset = madcal_summary.b1_int
        band2_offset = madcal_summary.b2_int
        band3_offset = madcal_summary.b3_int
        band4_offset = madcal_summary.b4_int
        band5_offset = madcal_summary.b5_int
        band7_offset = madcal_summary.b6_int
        band1_slope = madcal_summary.b1_slope
        band2_slope = madcal_summary.b2_slope
        band3_slope = madcal_summary.b3_slope
        band4_slope = madcal_summary.b4_slope
        band5_slope = madcal_summary.b5_slope
        band7_slope = madcal_summary.b6_slope
        band1_correlation = madcal_summary.b1_corr
        band2_correlation = madcal_summary.b2_corr
        band3_correlation = madcal_summary.b3_corr
        band4_correlation = madcal_summary.b4_corr
        band5_correlation = madcal_summary.b5_corr
        band7_correlation = madcal_summary.b6_corr
      endif
      
      if keyword_set(ledaps_ref) eq 1 then begin
        parent_filename = file_search(maddir, "*ledaps*.bsq")
        goods = where(strmatch(parent_filename, "*temp*") ne 1, n_goods)
        if n_goods eq 1 then parent_filename = parent_filename[goods]
        correction_method = "ledaps atmospheric correction"
        modis_reference_image = "na"
        cloudmask_file = "na"
        darkobjvalb1 = "na"
        darkobjvalb2 = "na"
        darkobjvalb3 = "na"
        darkobjvalb4 = "na"
        darkobjvalb5 = "na"
        darkobjvalb7 = "na"
        band1_offset = "na"
        band2_offset = "na"
        band3_offset = "na"
        band4_offset = "na"
        band5_offset = "na"
        band7_offset = "na"
        band1_slope = "na"
        band2_slope = "na"
        band3_slope = "na"
        band4_slope = "na"
        band5_slope = "na"
        band7_slope = "na"
        band1_correlation = "na"
        band2_correlation = "na"
        band3_correlation = "na"
        band4_correlation = "na"
        band5_correlation = "na"
        band7_correlation = "na"
      endif
      
      if keyword_set(generic_ref) eq 1 then begin
        parent_filename = file_basename(archvfile[thisdate].archvfilename)
        correction_method = "image to image relative normalization"
        modis_reference_image = "na"
        cloudmask_file = "na"
        darkobjvalb1 = "na"
        darkobjvalb2 = "na"
        darkobjvalb3 = "na"
        darkobjvalb4 = "na"
        darkobjvalb5 = "na"
        darkobjvalb7 = "na"
        band1_offset = madcal_summary.b1_int
        band2_offset = madcal_summary.b2_int
        band3_offset = madcal_summary.b3_int
        band4_offset = madcal_summary.b4_int
        band5_offset = madcal_summary.b5_int
        band7_offset = madcal_summary.b6_int
        band1_slope = madcal_summary.b1_slope
        band2_slope = madcal_summary.b2_slope
        band3_slope = madcal_summary.b3_slope
        band4_slope = madcal_summary.b4_slope
        band5_slope = madcal_summary.b5_slope
        band7_slope = madcal_summary.b6_slope
        band1_correlation = madcal_summary.b1_corr
        band2_correlation = madcal_summary.b2_corr
        band3_correlation = madcal_summary.b3_corr
        band4_correlation = madcal_summary.b4_corr
        band5_correlation = madcal_summary.b5_corr
        band7_correlation = madcal_summary.b6_corr
      endif
      
      metadata = {data: "radiometric reference image",$
        filename: file_basename(inputfile),$
        parent_filename: parent_filename,$
        correction_method: correction_method,$
        modis_reference_image: file_basename(modis_reference_image),$
        cloudmask_file: file_basename(cloudmask_file),$
        darkobjvalb1: darkobjvalb1,$
        darkobjvalb2: darkobjvalb2,$
        darkobjvalb3: darkobjvalb3,$
        darkobjvalb4: darkobjvalb4,$
        darkobjvalb5: darkobjvalb5,$
        darkobjvalb7: darkobjvalb7,$
        band1_offset: band1_offset,$
        band2_offset: band2_offset,$
        band3_offset: band3_offset,$
        band4_offset: band4_offset,$
        band5_offset: band5_offset,$
        band7_offset: band7_offset,$
        band1_slope: band1_slope,$
        band2_slope: band2_slope,$
        band3_slope: band3_slope,$
        band4_slope: band4_slope,$
        band5_slope: band5_slope,$
        band7_slope: band7_slope,$
        band1_correlation: band1_correlation,$
        band2_correlation: band2_correlation,$
        band3_correlation: band3_correlation,$
        band4_correlation: band4_correlation,$
        band5_correlation: band5_correlation,$
        band7_correlation: band7_correlation,$
        glovis_process_code_version: glovis_process_version(),$
        madcal_code_version: madcal_version()}
    end
    
    ;---_to_---
    3: begin
      if norm_method eq 1 then begin
        radiometric_reference_image = file_search(maddir, "*modis_reference.bsq", count=n_radiometric_reference_image)
        radiometric_reference_cloudmask_file = "na"
      endif
      if norm_method eq 2 then begin
        radiometric_reference_image = file_search(imgdir, "*radref.bsq", count=n_radiometric_reference_image)
        search = "*"+strmid(file_basename(radiometric_reference_image),0,18)+"*cloudmask.bsq"
        radiometric_reference_cloudmask_file = file_search(imgdir, search, count=n_radiometric_reference_cloudmask_file)
      endif
      if norm_method eq 3 then begin
        radiometric_reference_image = file_search(maddir, "*radref.bsq", count=n_radiometric_reference_image)
        search = "*"+strmid(file_basename(radiometric_reference_image),0,18)+"*cloudmask.bsq"
        radiometric_reference_cloudmask_file = file_search(maddir, search, count=n_radiometric_reference_cloudmask_file)
      endif
      
      metadata = {data: "radiometrically normalized image",$
        filename: file_basename(inputfile),$
        parent_filename:file_basename(archvfile[thisdate].archvfilename),$
        radiometric_reference_image: file_basename(radiometric_reference_image),$
        radiometric_reference_cloudmask_file:file_basename(radiometric_reference_cloudmask_file),$
        archive_cloudmask_file: file_basename(file_search(imgdir, searchthis+"cloudmask.bsq")),$
        band1_offset: madcal_summary.b1_int,$
        band2_offset: madcal_summary.b2_int,$
        band3_offset: madcal_summary.b3_int,$
        band4_offset: madcal_summary.b4_int,$
        band5_offset: madcal_summary.b5_int,$
        band7_offset: madcal_summary.b6_int,$
        band1_slope: madcal_summary.b1_slope,$
        band2_slope: madcal_summary.b2_slope,$
        band3_slope: madcal_summary.b3_slope,$
        band4_slope: madcal_summary.b4_slope,$
        band5_slope: madcal_summary.b5_slope,$
        band7_slope: madcal_summary.b6_slope,$
        band1_correlation: madcal_summary.b1_corr,$
        band2_correlation: madcal_summary.b2_corr,$
        band3_correlation: madcal_summary.b3_corr,$
        band4_correlation: madcal_summary.b4_corr,$
        band5_correlation: madcal_summary.b5_corr,$
        band7_correlation: madcal_summary.b6_corr,$
        glovis_process_code_version: glovis_process_version(),$
        madcal_code_version: madcal_version()}
    end
    
    ;---modis reference---
    4: begin
      metadata = {data: "modis reference image",$
        filename: file_basename(inputfile),$
        parent_filename: file_basename(modisimgsrc),$
        glovis_process_code_version: glovis_process_version(),$
        madcal_code_version: madcal_version()}
        
    end
    
    ;---b6---
    5: begin
      parent_filename = file_basename(file_mgmt[thisdate].glovisimg)
      
      metadata = {data: "thermal band",$
        filename: file_basename(inputfile),$
        parent_filename: parent_filename ,$
        native_projection: file_basename(file_mgmt[thisdate].nativeproj),$
        final_projection: file_basename(file_mgmt[thisdate].reproj),$
        reprojection_method: "gdalwarp using nearest neighbor",$
        glovis_process_code_version: glovis_process_version()}
    end
    
    ;---ltc---
    6: begin
      coeff = string(tccoeffs)
      metadata = {data: "tassled cap transformation",$
        filename: file_basename(inputfile),$
        parent_filename: file_basename(tcsrcimg),$
        tc_brt_coeffs: strjoin(coeff[*,0], ","),$
        tc_grn_coeffs: strjoin(coeff[*,1], ","),$
        tc_wet_coeffs: strjoin(coeff[*,2], ","),$
        tc_scale_factor: tcmultiplier,$
        glovis_process_code_version: glovis_process_version()}
    end
    
  endcase
  
  ;write out the metadata file
  output_metadata_file = stringswap(inputfile, ".bsq", "_meta.txt")
  openw, fun, output_metadata_file, /get_lun
  printf, fun, convert_struct_to_string(metadata)
  free_lun, fun
  
  return, metadata
  
end



