#!/bin/tcsh -f

setenv STAR_DIR ${PWD}
setenv CORE ${PWD:h:h:h:h:h:h:t}
setenv DATE ${PWD:h:h:t}
setenv CORNER ${PWD:t}
set corner = ($CORNER:as/-/ /)

setenv SPEF_FILE HCPU_plover_cpu_noram0-${corner[2]}-${corner[3]}.spef.gz

rm -rf star star.log *star_sum


#star_sub -v 2018.06-SP4-1 -lic 27020@soc.postech.ac.kr -Is -64 -cpu 8 -nopop star_cmd |tee -i star.log
starXtract -Is -64 -cpu 8 -nopop starRC.cmd |tee -i star.log

sleep 60

if((-e "../../30_outputs/${SPEF_FILE}")) then
    touch ../../30_outputs/${SPEF_FILE}.done
endif
