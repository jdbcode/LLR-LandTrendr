;+
; NAME:
;   CALCULATE_HISTORY_METRICS
;
; PURPOSE:
;   calculate historical metrics for a single pixel for [start_year, end_year]
;
; AUTHOR:
;
; CATEGORY:
;   Post processing
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
;-

function get_modifier, index
  modifier = 1
  
  tempindex = strupcase(index)
  
  case 1 of
    (tempindex eq 'UDIST'): begin
      modifier = 1
    end
    
    (tempindex eq 'BAND1'): begin
      modifier = 1
    end
    
    (tempindex eq 'BAND2'): begin
      modifier = 1
    end
    
    (tempindex eq 'BAND3'): begin
      modifier = 1
    end
    
    (tempindex eq 'BAND4'): begin
      modifier = -1
    end
    
    (tempindex eq 'BAND5'): begin
      modifier = 1
    end
    
    (tempindex eq 'BAND7'): begin
      modifier = 1
    end
    
    (tempindex eq 'NBR'): begin
      modifier = -1
    end
    
    (tempindex eq 'WETNESS'): begin
      modifier = -1
    end
    
    (tempindex eq 'BRIGHTNESS'): begin
      modifier = 1
    end
    (tempindex eq 'GREENNESS'): begin
      modifier = -1
    end
    
    (tempindex eq 'TCANGLE'): begin
      modifier = -1
    end
    
    (tempindex eq 'NDVI'): begin
      modifier = -1
    end
    
    (tempindex eq 'BIOMASS'): begin
      modifier = -1
    end
    
    (tempindex eq 'PROBFOR'): begin
      modifier = -1
    end
    
    else: modifier = 1;
    endcase
    return, modifier
  end
