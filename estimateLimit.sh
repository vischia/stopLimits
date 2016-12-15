#!/bin/bash

DATACARD="baseCards/datacard_DeltaPhi_ElMu_0.txt"

# RUN [Asy|Ful]
RUN="Asy"
# BANDS [bool]
BANDS=false

if   [ "$RUN" == "Asy" ]; then
    combine -M Asymptotic ${DATACARD}
elif [ "$RUN" == "Ful" ]; then
    combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.5
    if [ "$BANDS" = true ]; then
        combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.025
        combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.16
        combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.84
        combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.975
    fi
fi


