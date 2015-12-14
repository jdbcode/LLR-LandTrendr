pro run_label_class_filter, code_list, outputs_path
  
  index = where((code_list ne "") eq 1, n_index)
  if n_index ge 1 then code_list = code_list[index]
  
  codelist = strcompress(code_list, /rem)
  struct = {code:"",label:"",fast:0, slow:0, mmuf:11, mmus:11, durf:0, durs:4}
  struct = replicate(struct, n_elements(codelist))
  for i=0, n_elements(struct)-1 do begin
    split = strcompress(strsplit(codelist[i], ",", /extract), /rem)
    struct[i].code = split[0]
    codesplit = strcompress(strsplit(struct[i].code, "#", /extract), /rem)
    struct[i].label = codesplit[1]
    struct[i].fast = uint(split[1])
    struct[i].slow = uint(split[2])
    struct[i].mmuf = uint(split[3])
    struct[i].mmus = uint(split[4])
    struct[i].durf = uint(split[5])
    struct[i].durs = uint(split[6])
  endfor
    
  ;find the files that need to be filtered
  for i=0, n_elements(struct)-1 do begin
    ;do only the fast ones in this loop
    searchfor = strcompress("*"+struct[i].label+".bsq", /rem)
    file = file_search(outputs_path, searchfor, count=n_file)
    if n_file ge 1 then begin
      for k=0, n_file-1 do begin
        dir = file_dirname(file[k])
        dirtemp1 = dir+"\temp\"
        filebase = file_basename(file[k], ".bsq")
        searchfor = strcompress("*"+filebase+"*", /rem)
        filesorig = file_search(outputs_path, searchfor, count=n_files)
        index1 = where(strmatch(filesorig, "*mmu*") ne 1, n_index1)
        if n_index1 ge 1 then filesorig = filesorig[index1]
        filemove = strcompress(dirtemp1+file_basename(filesorig), /rem)
        file_mkdir, dirtemp1

        if struct[i].fast eq 1 then begin
          print, 'Filtering Fast Disturbance'
          file_move, filesorig, filemove
          dirtemp2 = dirtemp1+"temp\
          file_mkdir, dirtemp2
          lt_label_class_filter_fast, dirtemp1, dirtemp2, mmu=struct[i].mmuf, subset=subset, /all_neighbors, dur_thresh=struct[i].durf
          file_move, filemove, filesorig
          filteredfiles = file_search(dirtemp2, "*", count=n_filteredfiles)
          filteredfilesnew = strcompress(dir+"\"+file_basename(filteredfiles), /rem)
          if n_filteredfiles ge 1 then file_move, filteredfiles, filteredfilesnew
          print, 'Done Filtering Fast Disturbance'
        endif
        if struct[i].slow eq 1 then begin
          print, 'Filtering Slow Disturbance'
          file_move, filesorig, filemove
          dirtemp2 = dirtemp1+"temp\
          file_mkdir, dirtemp2
          lt_label_class_filter_slow, dirtemp1, dirtemp2, mmu=struct[i].mmus, subset=subset, /all_neighbors, dur_thresh=struct[i].durs
          file_move, filemove, filesorig
          filteredfiles = file_search(dirtemp2, "*", count=n_filteredfiles)
          filteredfilesnew = strcompress(dir+"\"+file_basename(filteredfiles), /rem)
          if n_filteredfiles ge 1 then file_move, filteredfiles, filteredfilesnew
          print, 'Done Filtering Slow Disturbance'
        endif
        file_delete, dirtemp1, /recursive
      endfor
    endif
  endfor
end