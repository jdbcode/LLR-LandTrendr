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

PRO lt_label_class_filter_fast, label_image_directory, output_image_directory,$
        mmu=mmu, subset=subset, all_neighbors=all_neighbors, dur_thresh=dur_thresh
        
    COMPILE_OPT idl2
    
    file_mkdir, output_image_directory
    
    ;default use 11 pixels as minimum mapping unit
    IF n_elements(mmu) EQ 0 THEN mmu = 11
    IF n_elements(dur_thresh) EQ 0 THEN dur_thresh = 0
    
    ;output patch image
    label_imgs = file_search(label_image_directory, "*.bsq", count=imgcounts)
    
    IF imgcounts EQ 0 THEN return
    
    ;ignore __LTlabel.bsq
    apos = strpos(label_imgs, "__LTlabel.bsq")
    valid = where(apos EQ -1, nv)
    IF nv GT 0 THEN label_imgs = label_imgs[valid]
    
    ;ignore _ftv_predist.bsq
    apos = strpos(label_imgs, "_ftv_predist.bsq")   ;old naming convention - kept in for compatibility
    valid = where(apos EQ -1, nv)
    IF nv GT 0 THEN label_imgs = label_imgs[valid]
    
    ;ignore _ftv_context.bsq
    apos = strpos(label_imgs, "_ftv_context.bsq")   ;new naming convention 
    valid = where(apos EQ -1, nv)
    IF nv GT 0 THEN label_imgs = label_imgs[valid]
    
    
    filelabel = strcompress("_mmu" + string(mmu), /re)
    
    FOR i = 0, nv-1 DO BEGIN
    
        print, "Processing " + label_imgs[i]
        
        filtered_image = output_image_directory + file_basename(label_imgs[i], ".bsq") + filelabel +"_tight.bsq
        out_patch_file = output_image_directory+ file_basename(label_imgs[i], ".bsq") + filelabel + "_tight_patchid.bsq" 
        
        ;check if these exist
        test1= stringswap(filtered_image, "temp\temp\", "")
        test2= stringswap(out_patch_file, "temp\temp\", "")
        if (file_exists(test1[0])+file_exists(test2[0])) ge 1 then begin
          print, ">>> !!!warning!!! this filtered labled image set: "
          print, ">>> ", test1
          print, ">>> ", test2
          print, ">>> already exits, skipping."
          continue
        endif
        
        ;read image
        IF n_elements(subset) EQ 0 THEN BEGIN
            zot_img, label_imgs[i], hdr, imgdat ;, /hdronly
            subset = [[hdr.upperleftcenter], [hdr.lowerrightcenter]]
        ENDIF ELSE BEGIN
            zot_img, label_imgs[i], hdr, imgdat, subset=subset ;, /hdronly
        ENDELSE
        
        ;ignore file not in duration, magnitude, uration, predisturbance format
        IF hdr.n_layers MOD 4 NE 0 THEN BEGIN
            print, "Ignoring file " + label_imgs[i]
            CONTINUE
        ENDIF
        
        fs = hdr.filesize
        layersize = ulong64(fs[0]) * fs[1]
        byte_per_pixel = 2

        infiles = [label_imgs[i]]
        files = file_basename(infiles)
        files = string(files, format='('+string(n_elements(files))+'A)')      
        run_params = {mmu:mmu, subset:subset, all_neighbors:keyword_set(all_neighbors), dur_thresh:dur_thresh}

        IF file_exists(filtered_image) EQ 0 THEN BEGIN
            openw, un, filtered_image, /get_lun
            point_lun, un, layersize*byte_per_pixel*hdr.n_layers-byte_per_pixel
            writeu, un, 0s
            free_lun, un
            this_hdr = hdr
            write_im_hdr, filtered_image, this_hdr
         
        END
        
        IF file_exists(out_patch_file) EQ 0 THEN BEGIN
            openw, un, out_patch_file, /get_lun
            point_lun, un, layersize*4-4
            writeu, un, 0u
            free_lun, un
            this_hdr = hdr
            this_hdr.n_layers = 1
            this_hdr.pixeltype = 7 ; u32
            write_im_hdr, out_patch_file, this_hdr
                                   
        END
        
        pid = ulonarr(fs[0], fs[1])
        
        ;go through each label and patch filter it.
        FOR layer = 0, hdr.n_layers-1 DO BEGIN
            current_layer = imgdat[*,*,layer]
            filtered_layer = current_layer ;first pass of image
            
            IF max(current_layer) LE 0 THEN CONTINUE
            
            mag = imgdat[*,*,layer+1]
            dur = imgdat[*,*,layer+2]
            pre = imgdat[*,*,layer+3]
            
            ;first get all the years for this layer
            allyears = fast_unique(current_layer)
            allyears = allyears[sort(allyears)]
            allyears = allyears[where(allyears GT 0)]
            
            ;first pass geting mean response
            tpid = intarr(fs[0], fs[1])
            
            ;first pass get the no offset mean
            FOR yidx = 0, n_elements(allyears)-1 DO BEGIN
                wdat = current_layer EQ allyears[yidx]
                dana = obj_new("BLOB_ANALYZER", wdat)
                    
                FOR j = 0, dana->NumberOfBlobs()-1 DO BEGIN
                    victims = dana->GetIndices(j)
                    IF n_elements(victims) gt (1.5 * mmu) THEN tpid[victims] = 1
                ENDFOR
                obj_destroy, dana
            ENDFOR
            
            ;second pass to allow offset and get group mean
            FOR yidx = 0, n_elements(allyears)-1 DO BEGIN
                wdat = current_layer GT 0 AND current_layer LT (allyears[yidx] + dur_thresh) and current_layer GT (allyears[yidx]-dur_thresh) and tpid eq 0
                
                IF max(wdat) EQ 0 THEN CONTINUE
                ;IF keyword_set(all_neighbors) THEN $
                    dana = obj_new("BLOB_ANALYZER", wdat, /all_neighbors) ;$
                ;ELSE $
                    ;dana = obj_new("BLOB_ANALYZER", wdat)
                    
                FOR j = 0, dana->NumberOfBlobs()-1 DO BEGIN
                    victims = dana->GetIndices(j)
                    these_mean = fix(mean(current_layer[victims]))
                    ;IF abs(these_mean - allyears[yidx]) LE dur_thresh/2.0 THEN BEGIN
                        ;tpid[victims] = 2
                        filtered_layer[victims] = these_mean
                    ;ENDIF
                ENDFOR
                obj_destroy, dana
            ENDFOR
            
            ;third pass do the spatial filtering
            allyears = fast_unique(filtered_layer)
            allyears = allyears[sort(allyears)]
            allyears = allyears[where(allyears GT 0)]
            
            FOR yidx=0, n_elements(allyears)-1 DO BEGIN
                print, string(9b) + " processing year " + string(allyears[yidx])
            
                wdat = filtered_layer eq allyears[yidx]
                
                IF max(wdat) EQ 0 THEN CONTINUE
                
                IF keyword_set(all_neighbors) THEN $
                    dana = obj_new("BLOB_ANALYZER", wdat, /all_neighbors) $
                ELSE $
                    dana = obj_new("BLOB_ANALYZER", wdat)
                    
                FOR j = 0, dana->NumberOfBlobs()-1 DO BEGIN
                    victims = dana->GetIndices(j)
                    ;if patch is too small
                    patch_size = n_elements(victims)
                    
                    ;print, patch_size
                    
                    IF (patch_size LT mmu) THEN BEGIN
                        wdat[victims] = 0
                        filtered_layer[victims] = 0
                        current_layer[victims] = 0
                        mag[victims] = 0
                        dur[victims] = 0
                        pre[victims] = 0
                    ENDIF

                ENDFOR ;end for all patches
                obj_destroy, dana
                
                mean_yr = median(current_layer, 3) ; should current_layer be used here?
                mean_mag = median(mag, 3)
                mean_dur = median(dur, 3)
                mean_pre = median(pre, 3)
                
                holes = obj_new("BLOB_ANALYZER", wdat EQ 0) ;check this
                FOR j = 0, holes->NumberOfBlobs()-1 DO BEGIN
                    victims = holes->GetIndices(j)
                    ;if patch is too small than defined threshold
                    patch_size = n_elements(victims)
                    IF (patch_size LT mmu) THEN BEGIN
                        wdat[victims] = 1 ;fill holes
                        filtered_layer[victims] = max(mean_yr[victims])
                        current_layer[victims] = max(mean_yr[victims])
                        mag[victims] = max(mean_mag[victims])
                        dur[victims] = max(mean_dur[victims])
                        pre[victims] = fix(mean(mean_pre[victims]))
                    ENDIF
                ENDFOR
                obj_destroy, holes
                
                IF layer EQ 0 THEN BEGIN
                    ;wdat = current_layer GT 0 AND current_layer LT (allyears[yidx] + dur_thresh) AND pid EQ 0
                    IF max(wdat) GT 0 THEN BEGIN
                        IF keyword_set(all_neighbors) THEN $
                            dana = obj_new("BLOB_ANALYZER", wdat, /all_neighbors) $
                        ELSE $
                            dana = obj_new("BLOB_ANALYZER", wdat)
                            
                        this_pid = *(dana->PatchImage())
                        pid = temporary(pid) + (this_pid * 100 + allyears[yidx] - 1980) * (this_pid GT 0)
                        ;mpid = max(pid)
                        ;pid = temporary(pid) + this_pid+mpid*(this_pid GT 0)
                        obj_destroy, dana
                    ENDIF
                ENDIF
                
            ENDFOR
            
            
            ;write out filtered data
            openu, un, filtered_image, /get_lun
            point_lun, un, layersize*byte_per_pixel*layer
            writeu, un, current_layer
            writeu, un, mag
            writeu, un, dur
            writeu, un, pre
            free_lun, un
            
            ;write out patch file
            IF layer EQ 0 THEN BEGIN
                openu, un, out_patch_file, /get_lun
                writeu, un, pid
                free_lun, un
            ENDIF
            
            current_layer = 0
            filtered_layer = 0
            mag = 0
            dur = 0
            pid = 0
            
            ;move to the next disturbance year layer
            layer = layer+3
        ENDFOR
    ENDFOR
    
    print, "LT_LABEL_CLASS_FILTER done!"
END