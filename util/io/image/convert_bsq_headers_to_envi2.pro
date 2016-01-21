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

pro convert_bsq_headers_to_envi2, path, template_bsq_file, overwrite=overwrite, pattern=pattern
  ;template_bsq_file = "C:\temp\composite\034032_2013_composite.hdr"
  ;path = "C:\temp\composite\header_work2"
  
  
  ;take all of the .bsq files in the directory and
  ;  convert to envi style
  ;   Coordinates are adjusted to ENVI style (upper left corner of pixel)
  ;   and a copy of the old hdr is made first.


  ;get the projection string stuff from the template header


  ;if file_test(template_bsq_file) eq 0 then begin
  ; print, 'the template file cannot be found'
  ;  print, template_bsq_file
  ;  print, 'check path and name and re-run'
  ;  return
  ;end
  
  ;potential_header = [template_bsq_file+'.hdr', strmid(template_bsq_file, 0, strlen(template_bsq_file)-4)+'.hdr']
  ;checker = [file_test(potential_header[0]), file_test(potential_header[1])]
  ;headerfile = potential_header[where(checker eq 1, many)]
  ;if many ne 1 then headerfile = headerfile[0]	;just take the zeroth one
  openr, un, template_bsq_file, /get_lun  
  query_file2, un, 'map info', mapinfo, separator='=', /norestart
  query_file2, un, 'projection info', projinfo, separator = '=', /norestart
  query_file2, un, 'coordinate system string', coordsysstr, separator = '=', /norestart
  free_lun, un
  ;if mapinfo eq 'no_match' then begin
  ;  print, 'The header for the template file appears to have no map information'
  ;  print, headerfile
  ;  return
  ;end
  
  ;parse the mapinfo so the upper left and pixel size can be overwritten
  
  ;pieces = strsplit(mapinfo, ',', /extract)
  ;projname = pieces[0]
  ;if strupcase(strcompress(projname, /rem)) ne '{UTM' then begin
  ;  startx = pieces[1]
  ;  starty = pieces[2]
  ;  uplxy = pieces[3:4]   ;will be overwritten
  ;  pixsizex = pieces[5]
  ;  pixsizey = pieces[6]
  ;  datum = pieces[7]
  ;  units = pieces[8]
  ;  query_file2, un, 'projection info', projinfo, separator = '=', /norestart
  ;  free_lun, un
  ;  if mapinfo eq 'no_match' then begin
  ;    print, 'The header for the template file appears to have no proj information'
  ;    print, headerfile
  ;    return
  ;  end
    
    
    
  ;end else begin 	;if it's UTM
  ;  startx = pieces[1]
  ;  starty = pieces[2]
  ;  uplxy = pieces[3:4]   ;will be overwritten
  ;  pixsizex = pieces[5]
  ;  pixsizey = pieces[6]
  ;  zone = pieces[7]
  ;  northsouth = pieces[8]
  ;  datum = pieces[9]
  ;  units = pieces[10]
  ;end
  
  
  
  ;now go through each bsq file and make the headers
  
  bsq_files = file_search(path, '*.bsq') 
  n = n_elements(bsq_files)
  ;if n eq 1 and bsq_files[0] eq '' then begin
  ;  print, 'No BSQ files in the directory.  Returning. '
  ;  return
  ;end
  
  for i = 0, n-1 do begin
    i=0
    file = bsq_files[i]
    
    ;if keyword_set(pattern) then begin
    ;  if strpos(file, pattern) lt 0 then continue
    ;endif
    
    potential_header = strmid(file, 0, strlen(file)-4)+'.hdr'
    checker = file_test(potential_header[0])
    if total(checker) eq 0 then	begin 	;this is promising, check it out
      print, 'The bsq file '+file
      print, 'appears to have no "hdr" file'
      goto, skipto
    end
    
    hdrfile = potential_header
    openr, hdrun, hdrfile, /get_lun
    qqq = ''
    readf,hdrun, qqq
    free_lun, hdrun
    
    
    ;test cases
    first = matchstr([qqq], 'ENVI') eq -1
    second = (file_test(hdrfile+'.flat'))*2
    third = keyword_set(overwrite)*4    ;third = (n_elements(overwrite) eq 1)*4 -old jdb 9/27/11
    t = first+second+third
    
    
    case 1 of
     (t eq 1 or t eq 4 or t eq 5 or t eq 6 or t eq 7):  begin ;if it not an envi file already, and overwrite is selected even if it exists
           
        file_copy, hdrfile, hdrfile+'.flat', overwrite=overwrite
      
        zot_img, file, bsqhdr, img, /hdronly	;get the non-proj header info
        file_delete, hdrfile		;get rid of the prior version
        
        ;now write itout      
        openw, hdrun, hdrfile, /get_lun
        printf, hdrun, 'ENVI'
        printf, hdrun, 'description = {'
        printf, hdrun, '   File imported into ENVI.}
        printf, hdrun, 'samples = '+strcompress(string(bsqhdr.filesize[0]),/rem)
        printf, hdrun, 'lines = '+strcompress(string(bsqhdr.filesize[1]), /rem)
        printf, hdrun, 'bands = '+strcompress(string(bsqhdr.n_layers), /rem)
        printf, hdrun, 'header offset = 0'
        printf, hdrun, 'file type = ENVI Standard'
        
        imagine_type = fix(strtrim (bsqhdr.pixeltype, 2))
        case imagine_type of
          (3): envitype = 1	;unsigned 8-bit
          (5): envitype = 12 ;unsigned 16-bit
          (6): envitype = 2	;signed 16-bit
          (9): envitype = 4	;float
          (7): envitype = 13 	;unsigned 32
                   
          else:  begin
            print, 'convert_bsq_headers_to_envi does not recognize byte type of '+string(imagine_type)
            print, 'Read failed. Skipping '+hdrfile
            goto, skipto
          end
        endcase
              
        printf, hdrun, 'data type = '+strcompress(string(envitype), /rem)
        printf, hdrun, 'interleave = bsq'
        printf, hdrun, 'sensor type = Unknown'
        printf, hdrun, 'byte order = 0'
        
        printf, hdrun, 'map info ='+mapinfo
        printf, hdrun, 'projection info ='+projinfo
        printf, hdrun, 'coordinate system string ='+coordsysstr
        
        printf, hdrun, 'wavelength units = Unknown'
        free_lun, hdrun
        
        
        ;map stuff
        ;if strupcase(strcompress(projname, /rem)) ne '{UTM' then begin
        ;  printf, hdrun, 'map info = '+projname+','+startx+','+starty+','+ $
        ;    strcompress(string(bsqhdr.upperleftcenter[0]),/rem)+','+$   ;okay to use center because use the 1.5 for the startx and starty
        ;    strcompress(string(bsqhdr.upperleftcenter[1]),/rem)+','+$
        ;    strcompress(string(bsqhdr.pixelsize[0]),/rem)+','+$
        ;    strcompress(string(bsqhdr.pixelsize[1]),/rem)+','+$
        ;    datum + ','+units
        ;  printf, hdrun, 'projection info = '+ projinfo
        ;end else begin ;if UTM
        ;  printf, hdrun, 'map info = '+strcompress(projname, /rem)+','+startx+','+starty+','+ $
        ;    strcompress(string(bsqhdr.upperleftcenter[0]),/rem)+','+$   ;okay to use center because use the 1.5 for the startx and starty
        ;    strcompress(string(bsqhdr.upperleftcenter[1]),/rem)+','+$
        ;    strcompress(string(bsqhdr.pixelsize[0]),/rem)+','+$
        ;    strcompress(string(bsqhdr.pixelsize[1]),/rem)+','+$
        ;    strcompress(string(zone),/rem)+','+$
        ;    northsouth+',' + $
        ;    datum + ','+units
        ;end

        ;printf, hdrun, 'wavelength units = Unknown'
        ;free_lun, hdrun
        ;skip:
        
      end;  this file
      (t eq 3 or t eq 2): ;print, 'Could not overwrite '+hdrfile+'.flat.  Consider using /overwrite'
      else:		;t = 4  -- don't do anything, because it is already an envi file
      
    endcase
    
    skipto:
    
    
  end ;all files
  
  
  return
end
