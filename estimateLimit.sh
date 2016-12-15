#!/bin/bash

DATACARD="baseCards/datacard_DeltaPhi_ElMu_0.txt"

combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.5
#combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.025
#combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.16
#combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.84
#combine -M HybridNew --frequentist --testStat LHC ${DATACARD} -H ProfileLikelihood --fork 4 --expectedFromGrid=0.975



