#!/bin/bash

BASELOCATION="baseCards/"
BASEDATACARD="datacard_DeltaPhi_ElMu_0.txt"

VARIEDLOCATION="variedTtbar"

# RUN [Asy|Ful]
RUN="Asy"
# BANDS [bool]
BANDS=false

### This function runs limits for a single datacard
function runLimit {
    CARD=$1
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
}
######

### This function creates syst cards with varied systematics ###
function createSetSysts {
    BASE=${BASELOCATION}$1
    VARIED=$2
    mkdir ${VARIED}
    for ttbarSys in 01 05 10 20 25 30 40 50 60 70 80 90 99; do
        cp ${BASE} ${VARIED}/varied_${ttbarSys}_${BASE}
        sed -i -- 's/ttbar                 lnN     -       -       -       -        1.25      - /ttbar                 lnN     -       -       -       -        1.${ttbarSys}      - /g' variedSysts/varied_${ttbarSys}_${BASE}
    done

}
######

### This function runs limits for the cards created via the createSetSysts function ###
function runSetSysts {
    LOCATION=$1
    cd ${LOCATION}
    for CARD in `ls ./`; do
        runLimit ${CARD}
    done
}
######

### This function runs a ROOT macro that produces some plots about what happens when varying the overall ttbar syst uncertainty
function analyzeVariedSysts {
    LOCATION=$1
    eval "root -l analyzeVariedSysts.C\\(\\\"${LOCATION}\\\"\\)"
}
######

###### MAIN ######

# Create set of varied cards for base shape card
createSetSysts ${BASEDATACARD} ${VARIEDLOCATION}

# Run limits on the cards with varied systs
runSetSysts ${VARIEDLOCATION}

# Analyze the outcome
analyzeVariedSysts ${VARIEDLOCATION}



