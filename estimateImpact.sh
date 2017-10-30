#!/bin/bash

# Prerequisite: installing the combineTool.py tool.
#       Method 1 (install only the script):
#                  bash <(curl -s https://raw.githubusercontent.com/cms-analysis/CombineHarvester/master/CombineTools/scripts/sparse-checkout-ssh.sh)
#       Method 2 (install the whole CombineHarvester):
#                  cd $CMSSW_BASE/src
#                  git clone https://github.com/cms-analysis/CombineHarvester.git CombineHarvester
#                  scram b -j 6

function main {
DATACARD=$1
LABEL=$2
MASS="1"
TABLES=$3

if [ "$1" != "" ]; then
    DATACARD=${1}
fi

echo "Preliminary: convert to rootspace"
echo "---------------------------------"

rm ${DATACARD}.root
text2workspace.py ${DATACARD}.txt -m 1
DATACARD="${DATACARD}.root"

if [ "$TABLES" = "yes" ]; then
    echo "Pre-stage: get pulls from ML fit"
    echo "---------------------------------"
    
    combine -M MaxLikelihoodFit -d ${DATACARD} -m ${MASS} -t -1 --expectSignal EXPECTED
    diffNuisances.py -a -f latex -g pullPlots_${LABEL}.root  > pullTable_${LABEL}.log
    return
fi

echo "First Stage: fit for each POI"
echo "-----------------------------"

combineTool.py -M Impacts -d ${DATACARD} -m ${MASS} -t -1 --doInitialFit --robustFit 1


echo "Second Stage: fit scan for each nuisance parameter"
echo "--------------------------------------------------"

combineTool.py -M Impacts -d ${DATACARD} -m ${MASS} -t -1 --robustFit 1 --doFits --parallel 8

echo "Third Stage: collect outputs"
echo "----------------------------"

combineTool.py -M Impacts -d ${DATACARD} -m ${MASS} -t -1 -o impacts.json

echo "Fourth Stage: plot pulls and impacts"
echo "------------------------------------"

plotImpacts.py -i impacts.json -o impacts

mv impacts.pdf ~/www/stop/impacts_${LABEL}.pdf


}
# end MAIN

TABLES=$1

main 2017-06-28_NoMetCut/datacard_MT2_SFS_250_50_ElMu_nostat         2017-06_28_SFS_250_50_ElMu_mt2_nostat ${TABLES} 


#main 2017-06-28_NoMetCut/datacard_CutAndCount_SFS_200_50_ElMu 2017-06_28_SFS_200_50_ElMu_cnc ${TABLES}
#main 2017-06-28_NoMetCut/datacard_MT2_SFS_200_50_ElMu         2017-06_28_SFS_200_50_ElMu_mt2 ${TABLES}
#
#main 2017-06-28_NoMetCut/datacard_CutAndCount_SFS_225_50_ElMu 2017-06_28_SFS_225_50_ElMu_cnc ${TABLES}
#main 2017-06-28_NoMetCut/datacard_MT2_SFS_225_50_ElMu         2017-06_28_SFS_225_50_ElMu_mt2 ${TABLES}
#
#main 2017-06-28_NoMetCut/datacard_CutAndCount_SFS_250_50_ElMu 2017-06_28_SFS_250_50_ElMu_cnc ${TABLES}
#main 2017-06-28_NoMetCut/datacard_MT2_SFS_250_50_ElMu         2017-06_28_SFS_250_50_ElMu_mt2 ${TABLES} 


#main 2017-06-22_juanWithFakes/datacard_CutAndCount_SFS_200_50_ElMu 2017-06-22_SFS_200_50_ElMu_cnc
#main 2017-06-22_juanWithFakes/datacard_CutAndCount_SFS_225_50_ElMu 2017-06-22_SFS_225_50_ElMu_cnc
#main 2017-06-22_juanWithFakes/datacard_CutAndCount_SFS_250_50_ElMu 2017-06-22_SFS_250_50_ElMu_cnc
#main 2017-06-22_juanWithFakes/datacard_MT2_SFS_200_50_ElMu 2017-06-22_SFS_200_50_ElMu_mt2
#main 2017-06-22_juanWithFakes/datacard_MT2_SFS_225_50_ElMu 2017-06-22_SFS_225_50_ElMu_mt2
#main 2017-06-22_juanWithFakes/datacard_MT2_SFS_250_50_ElMu 2017-06-22_SFS_500_50_ElMu_mt2


exit 0
