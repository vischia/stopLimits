#!/bin/bash

DATACARD="datacard_DeltaPhi_ElMu_0"
MASS="1"

if [ "$1" != "" ]; then
    DATACARD=${1}
fi

echo "Preliminary: convert to rootspace"
echo "---------------------------------"

rm ${DATACARD}.root
text2workspace.py ${DATACARD}.txt -m 1
DATACARD="${DATACARD}.root"

echo "First Stage: fit for each POI"
echo "-----------------------------"

combineTool.py -M Impacts -d ${DATACARD} -m ${MASS} --doInitialFit --robustFit 1


echo "Second Stage: fit scan for each nuisance parameter"
echo "--------------------------------------------------"

combineTool.py -M Impacts -d ${DATACARD} -m ${MASS} --robustFit 1 --doFits --parallel 8

echo "Third Stage: collect outputs"
echo "----------------------------"

combineTool.py -M Impacts -d ${DATACARD} -m ${MASS} -o impacts.json

echo "Fourth Stage: plot pulls and impacts"
echo "------------------------------------"

plotImpacts.py -i impacts.json -o impacts

exit 0