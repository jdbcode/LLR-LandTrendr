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

pro landtrendr_image_read, image_info_for_this_year, hdr, img, subset, index, modifier, background_val

	;image_info_for_this_year if the image info structure for the year of
	;   interest only, based on the structure set up
	;  in set_up_files_landtrendr....

	;hdr and img will be filled with header and image, respectively, as with
	;  zot_img

	;subset is the geographic subset, as would be passed to zot_img

	;index is a string that defines any of a number of
	;  combinations of bands, etc. used by landtrendr
	;  New ones can be made within this function
	;  Pass back a pointer to the image
	;  Band5
	;  wetness
	;  NBR
	;  TCangle
	;  NDVI

mastersubset = subset
image_info = image_info_for_this_year

if n_elements(image_info) gt 1 then begin
   message, "landtrend_image_read:  image info should already be subsetted to single year"
   return
end


tempindex = strlowcase(index)

case 1 of

(tempindex eq 'band1'):   begin
						if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
					   zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = 1
					  end
(tempindex eq 'band2'):   begin
						if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
					   zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = 1
					  end
(tempindex eq 'band3'):   begin
						if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
					   zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = 1
					  end
(tempindex eq 'band4'):   begin
						if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
					   zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = -1
					  end
(tempindex eq 'band5'):   begin
						if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
					   zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = 1
					  end
(tempindex eq 'band7'):   begin
						if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
					   zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = 1
					  end
(tempindex eq 'nbr'):   begin
            if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
             zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
            modifier = -1
            end
(tempindex eq 'wetness'):   begin
            if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
             zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = -1
					  end
(tempindex eq 'brightness'):   begin
            if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
             zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = 1
					  end
(tempindex eq 'greenness'):   begin
            if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
             zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = -1
					  end
(tempindex eq 'tcangle'):   begin
            if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
             zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = -1
					  end
(tempindex eq 'ndvi'):   begin
            if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + ' does not exist'
             zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
						modifier = -1
					  end

; (tempindex eq 'BIOMASS'):  begin
; 						if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + 'does not exist'
;						zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
;						modifier = -1
;						end

; (tempindex eq 'PROBFOR'):  begin
; 						if (file_exists(image_info.image_file) eq 0) then message, image_info.image_file + 'does not exist'
;						zot_img, image_info.image_file, hdr, img, subset=subset, layer = [1]
;						modifier = -1
;						end

else: message, 'Index not recognized. Options are NDVI, tcangle, wetness, band5, nbr'
endcase

return

end

