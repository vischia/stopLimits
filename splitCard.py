import ROOT, os
from optparse import OptionParser

#Input things


#inDatacard = "/nfs/fanae/user/carlosec/Combine/CMSSW_8_1_0/src/datacards/Datacards_stop/jan16/datacard_MT2_21_T2tt_227p5_52p5_ElMu.txt"
#outDatacard = "/nfs/fanae/user/carlosec/Combine/CMSSW_8_1_0/src/datacards/Datacards_stop/jan16/testStat/splitsAll/datacard_MT2_21_T2tt_227p5_52p5_mod_ElMu_binName.txt" <=binName is needed because I'm lazy
#outRootFile = "/nfs/fanae/user/carlosec/Combine/CMSSW_8_1_0/src/datacards/Datacards_stop/jan16/testStat/splitsAll/MT2BIN_binName.root" <=binName is needed because I'm lazy

pr = OptionParser(usage="%prog inDataCard outDataCard outRootFile [options]")

pr.add_option("-n"  , "--nbins"         , dest="nbins"       , type="int"      , default=-1, help="Number of bins computed. -1 to let the code count")
pr.add_option("-v"  , "--verbose"         , dest="verbose"       , type="int"      , default=0, help="Verbosity on/off")

(options, args) = pr.parse_args()

inDatacard = args[0]
outDatacard = args[1]
outRootFile = args[2]
nbins = options.nbins


class splitter():
  def __init__(self, cardPath, binNumber, outCard, outRootFile):
    self.inCard = cardPath
    self.nBins  = binNumber
    self.oCard = outCard
    self.oFile = outRootFile
    self.collectThings()
    for i in range(1,self.nBins+1):
      print "-------------------"
      print "- Splitting bin %s -"%i
      print "-------------------"
      self.printCard(i)

  def collectThings(self):
    """ Get Text info from the original datacard """
    self.systs = [] #Systematics, ordered by appearance
    self.systsLines = [] #The - - - number1 - - systematic lines
    self.shapeFiles = [] #The input shape rootfiles
    self.shapeBins  = [] #The input bins (in datacard line bins)
    self.proctoFile = {} #To pass from process to the file with the shapes
    processGet = False
    tempFile = open(self.inCard,"r")
    for line in tempFile.readlines():
      if line[0] == "#": continue
      tempLine = line.split()
      if tempLine[0] in ["jmax","kmax","observation","rate"]: continue
      if tempLine[0] == "bin":
        if len(tempLine) == (len(self.shapeBins) + 1):
          continue
        else:
          self.shapebinsforProcesses = tempLine[1:]
          continue
      if tempLine[0] == "imax":
        self.imax = line
        continue
      if tempLine[0] == "shapes":
        self.shapeBins.append(tempLine[2])
        for word in tempLine:
          if ".root" in word:
            self.shapeFiles.append(word)
        self.proctoFile[tempLine[2]] = self.shapeFiles[-1]
        continue

      if tempLine[0]=="process":
        if not processGet: 
          self.processes = tempLine[1:]
          processGet = True
        else:
          self.processesNums = tempLine[1:]
          processGet = False
        continue      
      if "stat" in tempLine[0]: continue
      self.systs.append(tempLine[0])
      self.systsLines.append(line)
    if self.nBins == -1: #This breaks if more than one shapes file is being used
      temp = ROOT.TFile("/".join(self.inCard.split("/")[:-1]) + "/" + self.shapeFiles[0], "READ")
      self.nBins = temp.Get("data_obs").GetNbinsX()
      temp.Close()

  def getYieldsAndWrite(self, rootFile, what, inumber, oFile, write = True, whatOut = False):
    if not whatOut: whatOut = what
    #print write, what, whatOut

    opRoot = ROOT.TFile("/".join(self.inCard.split("/")[:-1]) + "/" + rootFile, "READ")
    oldOne = opRoot.Get(what)
    theOriginalYield  = float(oldOne.GetBinContent(inumber))
    theYield  = theOriginalYield
    theCenter = oldOne.GetBinCenter(inumber)
    theWidth  = oldOne.GetBinWidth(inumber)
    oldOne.Delete()
    if theYield <= 0:
      theYield = 0.0000001
    newOne = ROOT.TH1F(whatOut, whatOut, 1, theCenter- theWidth/2., theCenter+ theWidth/2.)
    newOne.SetBinContent(1, theYield)
    oFile.cd()
    if write: newOne.Write()
    newOne.Delete()
    return theOriginalYield

  def printCard(self,inumber):
    outputRootFile = ROOT.TFile(self.oFile.replace("binName",str(inumber)), "UPDATE")
    outCard        = open(self.oCard.replace("binName",str(inumber)),"w")
    outCard.write(self.imax)
    outCard.write("jmax *\n")
    outCard.write("kmax *\n")
    outCard.write("##-----------\n")
    for i in range(len(self.shapeBins)):
      outCard.write("shapes * ")
      outCard.write(self.shapeBins[i])
      outCard.write(" " + self.oFile.replace("binName",str(inumber)) + " $PROCESS $PROCESS_$SYSTEMATIC")
    outCard.write("\n##-----------\n")
    outCard.write("bin ")
    for i in range(len(self.shapeBins)):
        outCard.write( self.shapeBins[i] + " ")
    outCard.write("\n")
    outCard.write("observation ")
    for i in range(len(self.shapeBins)):
      outCard.write( "%i "%self.getYieldsAndWrite(self.shapeFiles[i], "data_obs", inumber,outputRootFile))

    self.procToExclude = []
    for k in range(len(self.processes)):
        y = self.getYieldsAndWrite(self.proctoFile[self.shapebinsforProcesses[k]], self.processes[k], inumber,outputRootFile, False)
        if float(y) < 0.0001:
          self.procToExclude.append(k)

    outCard.write("\n##-----------\n")
    outCard.write("bin ")
    for k, bin in enumerate(self.shapebinsforProcesses):
      if not (k in self.procToExclude):
        outCard.write(bin + " ")
    outCard.write("\n")
    outCard.write("process ")
    for k, proc in enumerate(self.processes):
      if not (k in self.procToExclude):
        outCard.write(proc + " ")    
    outCard.write("\n")
    outCard.write("process ")
    for k, proc in enumerate(self.processesNums):
      if not (k in self.procToExclude):
        outCard.write(proc + " ")
    outCard.write("\n")
    outCard.write("rate ")    
    self.signalYields = 0
    for k in range(len(self.processes)):
        if not (k in self.procToExclude):
          tmpYields = self.getYieldsAndWrite(self.proctoFile[self.shapebinsforProcesses[k]], self.processes[k], inumber,outputRootFile, True)
          outCard.write("%.4f "%tmpYields)
          if int(self.processesNums[k]) <= 0:
            self.signalYields += tmpYields

    outCard.write("\n##-----------\n")
    for line in self.systsLines:
      if not ("shape" in line.split()): 
        newLine = []
        m = 0        
        for word in line.split():
          if word in self.systs + ["lnN"]:
            newLine.append(word)
          else:
            if m in self.procToExclude:
              m +=1
              continue
            else:
              m +=1
              newLine.append(word)  
        outCard.write(" ".join(newLine)+"\n")
        continue
      n = 0
      writeIt = False
      linetemp = []
      for word in line.split():
        if word in self.systs + ["shape"]: 
          linetemp.append(word)
          continue
        if "-" in word:
          if n in self.procToExclude: 
            n += 1            
            continue
          linetemp.append("-")
          if options.verbose > 0: print "appended", self.processes[n], n, self.procToExclude
          n += 1
          continue
        if n in self.procToExclude:
          n += 1
          continue

        y1 = self.getYieldsAndWrite(self.proctoFile[self.shapebinsforProcesses[n]], self.processes[n] + "_" + line.split()[0] +"Up", inumber,outputRootFile,True)
        y2 = self.getYieldsAndWrite(self.proctoFile[self.shapebinsforProcesses[n]], self.processes[n] + "_" + line.split()[0] +"Down", inumber,outputRootFile,True)
        n +=1
        if float(y1) > 0 or float(y2) > 0:
          if options.verbose > 0: print "floating", self.processes[n-1]
          writeIt = True
          linetemp.append(word)
        else:
          linetemp.append("-")
      if writeIt == True:
        outCard.write(" ".join(linetemp)+"\n")

    tempimpLine = ("-  k"*len(self.shapeBins)*(len(self.processes)-len(self.procToExclude))).split("k")[:-1]
    tempimpLine[0] = "1  "
    for bin in self.shapeBins:
      for k, proc in enumerate(self.processes):
        impactLine = "".join(tempimpLine)
        if k in self.procToExclude: continue
        tempimpLine = [tempimpLine[-1]] + tempimpLine[:-1]
        yup = self.getYieldsAndWrite(self.proctoFile[self.shapebinsforProcesses[k]], proc + "_" + proc+"_"+bin+"_statbin%1sUp"%inumber, inumber,outputRootFile, True, proc+"_" +proc+"_"+bin+"_statbin1Up")
        ydn = self.getYieldsAndWrite(self.proctoFile[self.shapebinsforProcesses[k]], proc + "_" + proc+"_"+bin+"_statbin%1sDown"%inumber, inumber,outputRootFile, True, proc+"_" +proc+"_"+bin+"_statbin1Down")  
        """if float(yup) > 0  or float(ydn) > 0:    
          outCard.write(proc+"_"+bin+"_statbin1 shape " + impactLine + "\n")"""

    if self.signalYields == 0:
      os.remove(self.oCard.replace("binName",str(inumber)))
      return 0
"""    if self.signalYields > 0:
      outCard.close()
      print "-----------------"
      print "- back only fit -"
      print "-----------------"
      os.system("combine -M MaxLikelihoodFit -t -1 --expectSignal 0 %s --minos=all >> ./splitCards/fitb%s.txt"%(self.oCard.replace("binName",str(inumber)),inumber))
      os.system("python  /mnt_pool/ciencias_users/user/carlosec/CMSSW_7_4_7/src/HiggsAnalysis/CombinedLimit/test/diffNuisances.py -a mlfit.root -g ./splitCards/plotsb%s.root >> ./splitCards/fitb%s.txt "%(str(inumber),str(inumber)))

      print "-----------------"
      print "- b+s only fit  -"
      print "-----------------"
      os.system("combine -M MaxLikelihoodFit -t -1 --expectSignal 1 %s --minos=all >> ./splitCards/fits%s.txt"%(self.oCard.replace("binName",str(inumber)),inumber))
      os.system("python  /mnt_pool/ciencias_users/user/carlosec/CMSSW_7_4_7/src/HiggsAnalysis/CombinedLimit/test/diffNuisances.py -a mlfit.root -g ./splitCards/plotssb%s.root >> ./splitCards/fits%s.txt"%(str(inumber),str(inumber)))"""

spl = splitter(inDatacard,nbins, outDatacard ,outRootFile )



