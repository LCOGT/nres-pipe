pro log, msg, level, module, site, camera, filename, dayobs, dateobs, other_tags
; Print a log message in the standard LCO format so that it can ingested by logstash

; msg: Log message to print
; level: Logging level: DEBUG, INFO, WARNING, ERROR, or CRITICAL
; module: module that is calling the log message
; site: Site ID of the file being processed
; camera: Camera ID of the file being processed
; filename: Filename being processed
; dayobs: DAY-OBS from the header of the file being processed
; dateobs: DATE-OBS from the header of the file being processed
; other_tags: Dictionary of key value pairs that should be printed in the logs that can be used for metrics

    jul2greg, systime(/UTC, /JULIAN), month, day, year, hour, minute, second
    
    log_string = string(year, '(I4)') + '-' + string(month, format='(I02)') + '-' + string(day, format='(I02)')
    log_string = log_string + ' ' + string(hour, format='(I02)') + ':' + string(minute, format='(I02)' + ':' + string(second, format='(F0.3)') + ' '
    log_string = log_string + string(level, format='(A8)') + ': ' + string(module, format='(A15)') + ': ' + msg + ' | {'
    
    log_string = log_string + 'site: ' + string(site)
    log_string = log_string + ', camera: ' + string(camera)
    log_string = log_string + ', filename: ' + string(filename)
    log_string = log_string + ', DAY-OBS: ' + string(dayobs)
    log_string = log_string + ', DATE-OBS: ' + string(dateobs)
    
    foreach key, other_tags.keys() do begin
        log_string = logstring + ', ' + string(key) + ': ' + string(other_tags[key])
    endforeach
    log_string = log_string + '}'

    print, format='(I4),"-", (I2),"-"," ", (I02), ":", (I02), ":", (I02)', 2014 , 06, 17, 2,3 
end