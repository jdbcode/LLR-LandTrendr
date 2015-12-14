pro create_image_info_llr, path

  ;path = "K:\test\045030\composites\"
  
  imgfiles = file_search(path, '*composite.bsq', count=n_imgfiles)
  
  
  base = { image_file:'none', $
    image_path:'none', $
    type:0, $       ;1 mtbs 2 nonmtbs 3 reference year mtbs
    nbr_file:'none', $
    tc_file:'none', $
    b6_file:'none', $
    year:0, $
    julday:0, $
    unique_year:1, $    ;flagged 1 if only 1 image in this year
    n_in_year:1, $    ;number of images in this year
    image_priority:0, $ ;priority of picking if more than one image per year
    cloudyear:0, $
    madcal_mask_file:'none',$
    cloud_diff_file:'none', $
    shadow_diff_file:'none', $
    tc_cloud_diff_file:'none', $
    cloud_file:'none', $
    subset:[ [0.d, 0.d],[0.d, 0.d]], $
    useareafile: 'none'}
    
  image_info = replicate(base, n_imgfiles)
  
  for i=0, n_imgfiles-1 do begin
    base = file_basename(imgfiles[i])
    year = strmid(base,0,4)
    image_info[i].year = fix(year)
    image_info[i].image_file = imgfiles[i]
  endfor
  
  order = sort(image_info.year)
  image_info = image_info[order]
  filename = path+"\image_info.sav"
  save, image_info, filename = filename
  
end
  