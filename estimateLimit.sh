#!/bin/bash

ALL=true
if   [ "$1" == "anal" ]; then
    ALL=false
fi

#BASELOCATION="baseCards/"
BASELOCATION="carlos/"
#BASEDATACARD="datacard_DeltaPhi_ElMu_0"
BASEDATACARD="datacard_Stop_Stats_250_75_lumi35000"
#BASESHAPESFILE="DeltaPhi_ElMu_0.root"
BASESHAPESFILE="BDT_testAlllum35000250_75.root"
#VARIEDLOCATION="variedTtbar"
VARIEDLOCATION="variedTtbarCarlos"

# RUN [Asy|Ful]
# RUN="Asy"
# BANDS [bool]
BANDS=false

### This function runs limits for a single datacard
function runLimit {
    DATACARD=$1
    RUN=$2
    if   [ "$RUN" == "Asy" ]; then
        combine -M Asymptotic ${DATACARD} -n ${DATACARD}
    elif [ "$RUN" == "Ful" ]; then
        combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.5 -n ${DATACARD}
        if [ "$BANDS" = true ]; then
            combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.025 -n ${DATACARD}
            combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.16 -n ${DATACARD}
            combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.84 -n ${DATACARD}
            combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.975 -n ${DATACARD}
        fi
    fi
}
######

### This function creates syst cards with varied systematics ###
function createSetSysts {
    WHAT=$1
    BASE=$2
    SHAPE=$3
    VARIED=$4
    mkdir ${VARIED}
    cp ${BASELOCATION}/${SHAPE} ${VARIED}
    if [ "$WHAT" == "ttbar" ]; then
        for ttbarSys in 01 05 10 20 25 30 40 50 60 70 80 90 99; do
            cp ${BASELOCATION}/${BASE}.txt ${VARIED}/varied_${ttbarSys}_${BASE}.txt
            if [ "$BASELOCATION" == "carlos" ]; then
                sed -i -- "s/tt  lnN     -    1.250000    -    -    -    -/tt  lnN     -    1.$ttbarSys    -    -    -    -/g" ${VARIED}/varied_${ttbarSys}_${BASE}.txt
            else
                sed -i -- "s/ttbar                 lnN     -       -       -       -        1.25      - /ttbar                 lnN     -       -       -       -        1.$ttbarSys      - /g" ${VARIED}/varied_${ttbarSys}_${BASE}.txt
            fi
            text2workspace.py ${VARIED}/varied_${ttbarSys}_${BASE}.txt -o ${VARIED}/varied_${ttbarSys}_${BASE}.root
        done
    elif [ "$WHAT" == "signal" ]; then
        for signalSys in 01 10 20 50 99; do
            cp ${BASELOCATION}/${BASE}.txt ${VARIED}/varied_${signalSys}_${BASE}.txt
            if [ "$BASELOCATION" == "carlos" ]; then
                sed -i -- "s/Stop  lnN     1.200000    -    -    -    -    -/Stop  lnN    1.$signalSys    -    -    -    -    -/g" ${VARIED}/varied_${signalSys}_${BASE}.txt
            else
                sed -i -- "s/Signal                lnN     -       -       -       -        -         1.20 /Signal                lnN     -       -       -       -        -         1.$signalSys /g" ${VARIED}/varied_${signalSys}_${BASE}.txt
            fi
            text2workspace.py ${VARIED}/varied_${signalSys}_${BASE}.txt -o ${VARIED}/varied_${signalSys}_${BASE}.root
        done
    fi

}
######



### This function runs limits for the cards created via the createSetSysts function ###
function runSetSysts {
    LOCATION=$1
    cd ${LOCATION}
    for CARD in `ls varied*root `; do
        runLimit ${CARD} Asy
        #runLimit ${CARD} Ful
    done
    cd -
}
######

### This function runs a ROOT macro that produces some plots about what happens when varying the overall ttbar syst uncertainty
function analyzeVariedSysts {
    WHAT=$1
    LOCATION=$2
    eval "root -l analyzeVariedSysts.C\\(\\\"${WHAT}\\\",\\\"${LOCATION}\\\"\\)"
}
######

###### MAIN ######

if [ "$ALL" == true ]; then
    # Create set of varied cards for base shape card
    createSetSysts ttbar  ${BASEDATACARD} ${BASESHAPESFILE} ${VARIEDLOCATION}
    createSetSysts signal ${BASEDATACARD} ${BASESHAPESFILE} ${VARIEDLOCATION}_signal

    # Run limits on the cards with varied systs
    runSetSysts ${VARIEDLOCATION}
    runSetSysts ${VARIEDLOCATION}_signal
fi

# Analyze the outcome
analyzeVariedSysts ttbar  ${VARIEDLOCATION}
analyzeVariedSysts signal ${VARIEDLOCATION}_signal


