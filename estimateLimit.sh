#!/bin/bash

ALL=true
if   [ "$1" == "anal" ]; then
    ALL=false
fi

SITUATIONONLY=false
if [ "$2" == "situation" ]; then
    SITUATIONONLY=true
fi

# RUN [Asy|Ful]
# RUN="Asy"
# BANDS [bool]
BANDS=false

ALSOFULL=false 

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
    mkdir -p ${VARIED}
    cp ${BASELOCATION}/${SHAPE} ${VARIED}
    if [ "$WHAT" == "ttbar" ]; then
        for ttbarSys in 01 05 10 20 25 30 40 50 60 70 80 90 99; do
            cp ${BASELOCATION}/${BASE}.txt ${VARIED}/varied_${ttbarSys}_${BASE}.txt
            if [ "$BASELOCATION" == "carlos/" ]; then
                sed -i -- "s/tt  lnN     -    1.250000    -    -    -    -/tt  lnN     -    1.$ttbarSys    -    -    -    -/g" ${VARIED}/varied_${ttbarSys}_${BASE}.txt
            elif [ "$BASELOCATION" == "baseCards" ]; then
                sed -i -- "s/ttbar                 lnN     -       -       -       -        1.25      - /ttbar                 lnN     -       -       -       -        1.$ttbarSys      - /g" ${VARIED}/varied_${ttbarSys}_${BASE}.txt
            else
                sed -i -- "s/ttbar lnN  -  -  -  -  1.05  -/ttbar lnN - - - - 1.$ttbarSys - /g" ${VARIED}/varied_${ttbarSys}_${BASE}.txt
                                                                                                                                fi
            text2workspace.py ${VARIED}/varied_${ttbarSys}_${BASE}.txt -o ${VARIED}/varied_${ttbarSys}_${BASE}.root
        done
    elif [ "$WHAT" == "signal" ]; then
        for signalSys in 01 10 20 50 99; do
            cp ${BASELOCATION}/${BASE}.txt ${VARIED}/varied_${signalSys}_${BASE}.txt
            if [ "$BASELOCATION" == "carlos/" ]; then
                sed -i -- "s/Stop  lnN     1.200000    -    -    -    -    -/Stop  lnN    1.$signalSys    -    -    -    -    -/g" ${VARIED}/varied_${signalSys}_${BASE}.txt
            else
                sed -i -- "s/Signal lnN  -  -  -  -  -  -  1.15/Signal lnN - - - - - - 1.$signalSys /g" ${VARIED}/varied_${signalSys}_${BASE}.txt
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
        if [ "$ALSOFULL" == true ]; then
            runLimit ${CARD} Ful
        fi
    done
    cd -
}
######

### This function runs a ROOT macro that produces some plots about what happens when varying the overall ttbar syst uncertainty
function analyzeVariedSysts {
    WHAT=$1
    LOCATION=$2
    RUNFULL=$3
    WHO="juan"
    if [ "$BASELOCATION" == "carlos/" ]; then
        WHO="carlos"
    fi
    #if [ "$SITUATIONONLY" == false ]; then
    #    eval "root -l analyzeVariedSysts.C\\(\\\"${WHAT}\\\",\\\"${LOCATION}/\\\",\\\"${BASEDATACARD}\\\",\\\"${RUNFULL}\\\"\\)"
    #fi
    eval "root -l -b drawSituation.C\\(\\\"${WHO}\\\",\\\"${BASELOCATION}${BASESHAPESFILE}\\\",\\\"${LOCATION}\\\",\\\"${THELABEL}\\\",\\\"${SIGNALLABEL}\\\"\\)"

}
######

###### WRAP ######
function wrap {
    BASELOCATION=$1
    BASEDATACARD=$2
    THELABEL=$3
    BASESHAPESFILE=$4
    VARIEDLOCATION=$5
    SIGNALLABEL=$6

    #if [ "$ALL" == true ]; then
    #    # Create set of varied cards for base shape card
    #    createSetSysts ttbar  ${BASEDATACARD} ${BASESHAPESFILE} ${VARIEDLOCATION}
    #    createSetSysts signal ${BASEDATACARD} ${BASESHAPESFILE} ${VARIEDLOCATION}_signal
    #    
    #    # Run limits on the cards with varied systs
    #    runSetSysts ${VARIEDLOCATION}
    #    runSetSysts ${VARIEDLOCATION}_signal
    #fi
    
    # Analyze the outcome
    analyzeVariedSysts ttbar  ${VARIEDLOCATION} ${ALSOFULL}
    analyzeVariedSysts signal ${VARIEDLOCATION}_signal ${ALSOFULL}
    
}

function main {
    BASELOCATION=$1
    BASEDATACARD=$2
    THELABEL=$3
    BASESHAPESFILE=$4
    VARIEDLOCATION=$5
    SIGNALLABEL=$6

    wrap "$BASELOCATION" "$BASEDATACARD" "$THELABEL" "$BASESHAPESFILE" "$VARIEDLOCATION" "$SIGNALLABEL"
 
    rm -r ~/www/stop/${VARIEDLOCATION}
    cp -r ${VARIEDLOCATION}       ~/www/stop/
    cp ~/www/stop/index.php ~/www/stop/${VARIEDLOCATION}/      
    
}

main "2017-10-30_mt2g0_xuan/" "datacard_CutAndCount_MT2g0_SFS_200_50_ElMu.txt" "Counts" "CutAndCount_MT2g0.root" "out2017-10-30_cnc_mt2g0_200_50" "SFS_200_50"
main "2017-10-30_mt2g0ls_xuan/" "datacard_MT2_MT2g0_SFS_200_50_ElMu.txt" "M_{T2}" "MT2_MT2g0.root" "out2017-10-30_mt2_mt2g0_200_50" "SFS_200_50"

main "2017-10-30_mt2g0_xuan/" "datacard_CutAndCount_MT2g0_SFS_225_50_ElMu.txt" "Counts" "CutAndCount_MT2g0.root" "out2017-10-03_cnc_mt2g0_225_50" "SFS_225_50"
main "2017-10-30_mt2g0_xuan/" "datacard_MT2_MT2g0_SFS_225_50_ElMu.txt" "M_{T2}" "MT2_MT2g0.root" "out2017-10-30_mt2_mt2g0_225_50" "SFS_225_50"

main "2017-10-30_mt2g0_xuan/" "datacard_CutAndCount_MT2g0_SFS_250_50_ElMu.txt" "Counts" "CutAndCount_MT2g0.root" "out2017-10-30_cnc_mt2g0_250_50" "SFS_250_50"
main "2017-10-30_mt2g0_xuan/" "datacard_MT2_MT2g0_SFS_250_50_ElMu.txt" "M_{T2}" "MT2_MT2g0.root" "out2017-10-30_mt2_mt2g0_250_50" "SFS_250_50"

#main "2017-10-03_xuan/" "datacard_CutAndCount_SFS_200_50_ElMu.txt" "Counts" "CutAndCount.root" "out2017-10-03_cnc_200_50" "SFS_200_50"
#main "2017-10-03_xuan/" "datacard_MT2_SFS_200_50_ElMu.txt" "M_{T2}" "MT2.root" "out2017-10-03_mt2_200_50" "SFS_200_50"
#
#main "2017-10-03_xuan/" "datacard_CutAndCount_SFS_225_50_ElMu.txt" "Counts" "CutAndCount.root" "out2017-10-03_cnc_225_50" "SFS_225_50"
#main "2017-10-03_xuan/" "datacard_MT2_SFS_225_50_ElMu.txt" "M_{T2}" "MT2.root" "out2017-10-03_mt2_225_50" "SFS_225_50"
#
#main "2017-10-03_xuan/" "datacard_CutAndCount_SFS_250_50_ElMu.txt" "Counts" "CutAndCount.root" "out2017-10-03_cnc_250_50" "SFS_250_50"
#main "2017-10-03_xuan/" "datacard_MT2_SFS_250_50_ElMu.txt" "M_{T2}" "MT2.root" "out2017-10-03_mt2_250_50" "SFS_250_50"
#

#main "2017-06-28_NoMetCut/" "datacard_CutAndCount_SFS_250_50_ElMu.txt" "Counts" "CutAndCount.root" "out2017-06-28_cnc" "SFS_250_50"
#main "2017-06-28_NoMetCut/" "datacard_MT2_SFS_250_50_ElMu.txt" "M_{T2}" "MT2.root" "out2017-06-28_mt2" "SFS_250_50"

#main "2017-06-26_newpdf/" "datacard_MT26bins_SFS_250_50_ElMu.txt" "M_{T2}" "MT26bins.root"  "out2017-06-26_newpdf" "SFS_250_50"
#main "2017-06-26_newpdf_7bins/" "datacard_MT27bins_SFS_250_50_ElMu.txt" "M_{T2}" "MT27bins.root"  "out2017-06-26_newpdf_7bins" "SFS_250_50"

#main "2017-06-22_juanWithFakes/" "datacard_MT2_SFS_200_50_ElMu.txt" "M_{T2}" "MT2.root"  "systs_2017-06-22_juan_mt2" "SFS_200_50"
#main "2017-06-22_juanWithFakes/" "datacard_MT2_SFS_225_50_ElMu.txt" "M_{T2}" "MT2.root"  "systs_2017-06-22_juan_mt2" "SFS_225_50"
#main "2017-06-22_juanWithFakes/" "datacard_MT2_SFS_250_50_ElMu.txt" "M_{T2}" "MT2.root"  "systs_2017-06-22_juan_mt2" "SFS_250_50"
#
#main "2017-06-22_juanWithFakes/" "datacard_CutAndCount_SFS_200_50_ElMu.txt" "Counts" "CutAndCount.root"  "systs_2017-06-22_juan_cnc" "SFS_200_50"
#main "2017-06-22_juanWithFakes/" "datacard_CutAndCount_SFS_225_50_ElMu.txt" "Counts" "CutAndCount.root"  "systs_2017-06-22_juan_cnc" "SFS_225_50"
#main "2017-06-22_juanWithFakes/" "datacard_CutAndCount_SFS_250_50_ElMu.txt" "Counts" "CutAndCount.root"  "systs_2017-06-22_juan_cnc" "SFS_250_50"

# main "baseCards/" "datacard_DeltaPhi_ElMu_0"  "#Delta#phi(#it{l}, #mu)" "DeltaPhi_ElMu_0.root" "variedTtbar"

# main "carlos/" "datacard_Stop_Stats_250_75_lumi35000" "BDT\\ discriminator""BDT_testAlllum35000250_75.root" "variedTtbarCarlos"

# main "2017-01-10_juan/" "datacard_DeltaEta_ElMu_250_75" "#Delta#eta\ #it{l}\,\ #mu"  "DeltaEta_ElMu_250_75.root" "varied_2017-01-10_juan_DeltaEta"
# main "2017-01-10_juan/" "datacard_HT_ElMu_250_75" "H_{T}"  "HT_ElMu_250_75.root" "varied_2017-01-10_juan_HT"
# main "2017-01-10_juan/" "datacard_DeltaPhiLepMet_ElMu_250_75" "#Delta#Phi\ #it{l}\,\ MET"  "DeltaPhiLepMet_ElMu_250_75.root" "varied_2017-01-10_juan_DeltaPhiLepMet"
# main "2017-01-10_juan/" "datacard_MET_ElMu_250_75" "MET"  "MET_ElMu_250_75.root" "varied_2017-01-10_juan_MET"
# main "2017-01-10_juan/" "datacard_DeltaPhi_ElMu_250_75" "#Delta#phi\ #it{l}\,\ #mu"  "DeltaPhi_ElMu_250_75.root" "varied_2017-01-10_juan_DeltaPhi"
# main "2017-01-10_juan/" "datacard_MT2_ElMu_250_75" "M_{T2}"  "MT2_ElMu_250_75.root" "varied_2017-01-10_juan_MT2"

#main "2017-03-15_juan/" "datacard_CutAndCount_ElMu_S-200-50" "CutNCount" "CutAndCount_ElMu.root" "varied_2017-03-15_juan_CnC"
#main "2017-03-15_juan/" "datacard_TMT2_ElMu_S-200-50" "M_{T2}" "TMT2_ElMu.root" "varied_2017-03-15_juan_MT2"


#main "2017-03-22_juan/" "datacard_CutAndCount_ElMu_S_242_75" "CutNCount" "CutAndCount_ElMu.root" "varied_2017-03-22_juan_CnC"
#main "2017-03-22_juan/" "datacard_TMT2_ElMu_S_242_75" "M_{T2}" "TMT2_ElMu.root" "varied_2017-03-22_juan_MT2"

#mkdir -p ~/www/stop/old/
#rm -r  ~/www/stop/old/varied_2017-03-22_juan_CnC/
#rm -r  ~/www/stop/old/varied_2017-03-22_juan_CnC_signal/
#rm -r  ~/www/stop/old/varied_2017-03-22_juan_MT2/
#rm -r  ~/www/stop/old/varied_2017-03-22_juan_MT2_signal/
#
#mv ~/www/stop/varied_2017-03-22_juan_CnC/        ~/www/stop/old/  
#mv ~/www/stop/varied_2017-03-22_juan_CnC_signal/ ~/www/stop/old/
#mv ~/www/stop/varied_2017-03-22_juan_MT2/        ~/www/stop/old/
#mv ~/www/stop/varied_2017-03-22_juan_MT2_signal/ ~/www/stop/old/ 
#
#cp -r varied_2017-03-22_juan_CnC/        ~/www/stop/
#cp -r varied_2017-03-22_juan_CnC_signal/ ~/www/stop/
#cp -r varied_2017-03-22_juan_MT2/        ~/www/stop/
#cp -r varied_2017-03-22_juan_MT2_signal/ ~/www/stop/
#
#cp ~/www/stop/index.php ~/www/stop/varied_2017-03-22_juan_CnC/
#cp ~/www/stop/index.php ~/www/stop/varied_2017-03-22_juan_CnC_signal/
#cp ~/www/stop/index.php ~/www/stop/varied_2017-03-22_juan_MT2/
#cp ~/www/stop/index.php ~/www/stop/varied_2017-03-22_juan_MT2_signal/
#

#main "MT2g100_2017-06-20/" "datacard_CutAndCount_MT2g100_SFS_250_50_ElMu.txt" "M_{T2}" "CutAndCount_MT2g100_ElMu.root"  "mt2g100" "SFS_250_50"


#main "MT2tails_2017-06-20/" "datacard_MT2_SFS_250_50_ElMu.txt" "M_{T2}" "MT2_ElMu.root"               "mt2tails_nocut" "SFS_250_50"
#main "MT2tails_2017-06-20/" "datacard_MT2_leq120_SFS_250_50_ElMu.txt" "M_{T2}" "MT2_leq120_ElMu.root" "mt2tails_nocut_leq120" "SFS_250_50"
#main "MT2tails_2017-06-20/" "datacard_MT2_leq140_SFS_250_50_ElMu.txt" "M_{T2}" "MT2_leq140_ElMu.root" "mt2tails_nocut_leq140" "SFS_250_50"
#

###main "nbins/2bins/"  "datacard_MT2_no0_0_SFS_250_50_ElMu" "M_{T2}" "MT2_no0_0_ElMu.root" "varied_2bins"  "SFS_250_50"
###main "nbins/3bins/"  "datacard_MT2_no0_1_SFS_250_50_ElMu" "M_{T2}" "MT2_no0_1_ElMu.root" "varied_3bins"  "SFS_250_50"
###main "nbins/6bins/"  "datacard_MT2_no0_2_SFS_250_50_ElMu" "M_{T2}" "MT2_no0_2_ElMu.root" "varied_6bins"  "SFS_250_50"
###main "nbins/7bins/"  "datacard_MT2_no0_3_SFS_250_50_ElMu" "M_{T2}" "MT2_no0_3_ElMu.root" "varied_7bins"  "SFS_250_50"
###main "nbins/9bins/"  "datacard_MT2_no0_4_SFS_250_50_ElMu" "M_{T2}" "MT2_no0_4_ElMu.root" "varied_9bins"  "SFS_250_50"
###main "nbins/10bins/" "datacard_MT2_no0_5_SFS_250_50_ElMu" "M_{T2}" "MT2_no0_5_ElMu.root" "varied_10bins" "SFS_250_50"
###main "nbins/12bins/" "datacard_MT2_no0_6_SFS_250_50_ElMu" "M_{T2}" "MT2_no0_6_ElMu.root" "varied_12bins" "SFS_250_50"


#main "2017-06-13_juan/" "datacard_MT2_ElMu_SFS_200_50" "M_{T2}" "MT2.root" "varied_2017-06-13_juan_MT2_200" "SFS_200_50"
#main "2017-06-13_juan/" "datacard_MT2_ElMu_SFS_225_50" "M_{T2}" "MT2.root" "varied_2017-06-13_juan_MT2_225" "SFS_225_50"
#main "2017-06-13_juan/" "datacard_MT2_ElMu_SFS_250_50" "M_{T2}" "MT2.root" "varied_2017-06-13_juan_MT2_250" "SFS_250_50"
#
#main "2017-06-13_juan/" "datacard_CutAndCount_ElMu_SFS_200_50" "Yield" "CutAndCount.root" "varied_2017-06-13_juan_CutAndCount_200" "SFS_200_50"
#main "2017-06-13_juan/" "datacard_CutAndCount_ElMu_SFS_225_50" "Yield" "CutAndCount.root" "varied_2017-06-13_juan_CutAndCount_225" "SFS_225_50"
#main "2017-06-13_juan/" "datacard_CutAndCount_ElMu_SFS_250_50" "Yield" "CutAndCount.root" "varied_2017-06-13_juan_CutAndCount_250" "SFS_250_50"
#
#
