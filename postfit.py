#!env python
import os,sys
from subprocess import call,check_output
from optparse import OptionParser
import ROOT

parser=OptionParser()
parser.add_option("-d","--datacard",help="Datacard [%default]",default="WorkspaceM2000.root")
parser.add_option("-t","--txtdatacard",help="Txt Datacard [%default]",default="combine_datacard_hplushadronic_m2000.txt")
parser.add_option("-o","--output",help="Output [%default]",default="output.root")
parser.add_option("-v","--verbose",action='store_true',help="Verbose [%default]",default=False)
parser.add_option("-m","--mass",help="Mass [%default]",default="2000")
parser.add_option("-i","--input",help="input histogram file (data_obs should be there) [%default]",default="combine_histograms_hplushadronic_m2000.root")
parser.add_option("-x","--nofit",action='store_true',help="Don't run combine [%default]",default=False)
parser.add_option("-l","--light",action='store_true',help="Light mass options [%default]",default=False)
parser.add_option("","--rMax",type=float,help="rMax [%default]",default=1)
parser.add_option("","--rMin",type=float,help="rMin [%default]",default=0)
parser.add_option("","--bkg",action='store_true',help="Use bkg only shapes [%default]",default=False)
parser.add_option("","--prefit",action='store_true',help="Use prefit shapes [%default]",default=False)

opts,args=parser.parse_args()

if 'CMSSW_BASE' not in os.environ:
	print "-> DO CMSENV <-"
	exit(1)
#garbage un-collector
gc=[]

def printInfo(info,level=0):
	if info != "": 
		if level==0:
			print "-> ",info
		else:
			print "   *) ",info
	return 

def exe(cmd,info=""):
	printInfo(info)
	if opts.verbose:
		print " * calling cmd '"+cmd+"'"
	st=call(cmd,shell=True)
	if st !=0:
		print "-> Error during execution"
		raise ValueError

def write(fOut,h,hTarget):
	fOut.cd()
	if hTarget.GetNbinsX() !=h.GetNbinsX():
		print "-> WARNING DIFFERENT NUMBERS OF BINS"
	hTW=hTarget.Clone(h.GetName())
	hTW.Reset("ACE")
	for i in range(0,h.GetNbinsX()+2):
		hTW.SetBinContent(i,h.GetBinContent(i) ) 
		hTW.SetBinError(i,h.GetBinError(i) ) 
	hTW.Write()
	gc.append(hTW)

	#for i in range(0,h.GetNbinsX()+2):
	#	try:
	#		print "Bin",i,h.GetName() ,hTW.GetBinError(i)/hTW.GetBinContent(i),'==',h.GetBinError(i)/h.GetBinContent(i)
	#	except:
	#		pass


#### ---- 
info="Fitting workspace"
#cmd="combine -M MultiDimFit --saveWorkspace --setPhysicsModelParameters r=0 -n bkgonly  -m %s "%(opts.mass)  + opts.datacard
cmd="combine -M MultiDimFit --saveWorkspace --setPhysicsModelParameterRanges r=%s,%s -n bkgonly  -m %s "%("%.4f"%opts.rMin,"%.4f"%opts.rMax,opts.mass)  + opts.datacard
if opts.bkg:
	cmd="combine -M MultiDimFit --saveWorkspace --setPhysicsModelParameters r=0 -n bkgonly  -m %s "%(opts.mass)  + opts.datacard

if opts.light:
	cmd="combine -M MultiDimFit --saveWorkspace --setPhysicsModelParameterRanges BR=0,.1 -n bkgonly  -m %s "%(opts.mass)  + opts.datacard
if not opts.nofit:
	exe(cmd,info)
#### ---- 
### info="StatOnly"
### cmd="combine -M MaxLikelihoodFit --rMin=0 --rMax=.1  --saveNormalizations --saveShapes --saveWithUncertainties --saveWorkspace --plots -m %s -n statdata -S 0 --snapshotName=MultiDimFit higgsCombinebkgonly.MultiDimFit.mH%s.root"%(opts.mass,opts.mass)
### if not opts.nofit:
### 	exe(cmd,info)
### #### ---- 
info="BkgStat"
#cmd = "combine -M MaxLikelihoodFit --rMin=0 --rMax=1 --saveNormalizations --saveShapes --saveWithUncertainties --saveWorkspace  --plots -m %(mass)s -n statbkg --floatNuisances $(cat %(txt)s | grep stat | cut -d' ' -f1  | tr '\n' ',') --snapshotName=MultiDimFit higgsCombinebkgonly.MultiDimFit.mH%(mass)s.root"%{"mass":opts.mass,"txt":opts.txtdatacard}
cmd = "combine -M MaxLikelihoodFit --rMin=%(rMin)s --rMax=%(rMax)s --saveNormalizations --saveShapes --saveWithUncertainties --saveWorkspace  --plots -m %(mass)s -n statbkg --freezeNuisances $( cat %(txt)s  | cut -d' ' -f1  | grep -v stat | grep -v -- '----------------' | grep -v '^rate' | grep -v '^bin' | grep -v 'shapes' | grep -v 'observation' | grep -v '^.max'   | grep -v '^#' | grep -v '^process' | grep -v '^Date' | grep -v '^Description'  | tr '\n' ',') --snapshotName=MultiDimFit higgsCombinebkgonly.MultiDimFit.mH%(mass)s.root"%{"mass":opts.mass,"txt":opts.txtdatacard,"rMax":"%.4f"%opts.rMax,"rMin":"%.4f"%opts.rMin}
if opts.light:
	cmd = "combine -M MaxLikelihoodFit --setPhysicsModelParameterRanges BR=0,.1 --saveNormalizations --saveShapes --saveWithUncertainties --saveWorkspace  --plots -m %(mass)s -n statbkg --freezeNuisances $( cat %(txt)s  | cut -d' ' -f1  | grep -v stat | grep -v -- '----------------' | grep -v '^rate' | grep -v '^bin' | grep -v 'shapes' | grep -v 'observation' | grep -v '^.max'   | grep -v '^#' | grep -v '^process' | grep -v '^Date' | grep -v '^Description'  | tr '\n' ',') --snapshotName=MultiDimFit higgsCombinebkgonly.MultiDimFit.mH%(mass)s.root"%{"mass":opts.mass,"txt":opts.txtdatacard}
if not opts.nofit:
	exe(cmd,info)
#### ---- 
info="Full Fit p2"
cmd="combine -M MaxLikelihoodFit --rMin=%s --rMax=%s --robustFit=1  --saveNormalizations --saveShapes --saveWithUncertainties --saveWorkspace --plots -m %s %s"%("%.4f"%opts.rMin,"%.4f"%opts.rMax,opts.mass,opts.datacard)
if opts.light:
	cmd="combine -M MaxLikelihoodFit --setPhysicsModelParameterRanges BR=0,.1 --robustFit=1  --saveNormalizations --saveShapes --saveWithUncertainties --saveWorkspace --plots -m %s %s"%(opts.mass,opts.datacard)
if not opts.nofit:
	exe(cmd,info)
#### ---- 
printInfo("Collecting results")

fTot=ROOT.TFile.Open("mlfit.root")
fBkg=ROOT.TFile.Open("mlfitstatbkg.root")
#fStat=ROOT.TFile.Open("mlfitstatdata.root")
fData=ROOT.TFile.Open(opts.input)

fOut=ROOT.TFile.Open(opts.output,"RECREATE")
fOut.cd()

printInfo("data",1)
data=fData.Get("data_obs").Clone()
data.Write()

cat="taunuhadr"
prefix="CMS_Hptntj_"

if opts.light:
	prefix=""

fitdir="shapes_fit_s"
if opts.bkg:
	fitdir="shapes_fit_b"
if opts.prefit:
	fitdir="shapes_prefit"

printInfo("splitted backgrounds",1)
for proc in ["DY_t_genuine","W_t_genuine","ttbar_t_genuine","QCDandFakeTau","singleTop_t_genuine","VV_t_genuine"]:
	if opts.verbose:
		print "-> trying to get '"+fitdir+"/"+cat+"/"+prefix +proc +"'"
	h=fTot.Get(fitdir+"/"+cat+"/"+prefix +proc).Clone()
	write(fOut,h,data)

printInfo("total background",1)
if opts.verbose:
	print "-> trying to get '"+fitdir+"/"+cat+"/"+"total_background" +"'"
h=fTot.Get(fitdir+"/"+cat+"/" + "total_background").Clone("total_background")
write(fOut,h,data)

## printInfo("statonly",1)
## if opts.verbose:
## 	print "-> trying to get '"+"shapes_fit_s/"+cat+"/"+"total_background" +"'"
## h=fStat.Get("shapes_fit_s/"+cat+"/" + "total_background").Clone("total_background_statonly")
## write(fOut,h,data)
## 
printInfo("statall",1)
if opts.verbose:
	print "-> trying to get '"+"shapes_fit_s/"+cat+"/"+"total_background" +"'"
h=fBkg.Get("shapes_fit_s/"+cat+"/" + "total_background").Clone("total_background_statall")
write(fOut,h,data)

fOut.Close()

## -----------------------------
#  KEY: TH1F     data_obs;1      data_obs
#  KEY: TH1F     CMS_Hptntj_DY_t_genuine;1       data_obs
#  KEY: TH1F     CMS_Hptntj_W_t_genuine;1        data_obs
#  KEY: TH1F     CMS_Hptntj_ttbar_t_genuine;1    data_obs
#  KEY: TH1F     CMS_Hptntj_QCDandFakeTau;1      data_obs
#  KEY: TH1F     total_background;1      data_obs
#  KEY: TH1F     total_background_statall;1      data_obs
#
#index 4, Name taunuhadr/CMS_Hptntj_W_t_genuine, val 1152.35
#index 5, Name taunuhadr/CMS_Hptntj_singleTop_t_genuine, val 255.428
#index 6, Name taunuhadr/CMS_Hptntj_ttbar_t_genuine, val 136

doPlot=True
if doPlot:
	c=ROOT.TCanvas("c","c",800,800)
	fOut=ROOT.TFile.Open(opts.output)
	data=fOut.Get("data_obs").Clone()
	b   = fOut.Get("total_background").Clone()
	bs  = fOut.Get("total_background_statall")
	#bsd  = fOut.Get("total_background_statonly")

	if opts.light:
		dy = fOut.Get("DY_t_genuine").Clone()
		w  = fOut.Get("W_t_genuine").Clone()
		tt = fOut.Get("ttbar_t_genuine").Clone()
		qcd= fOut.Get("QCDandFakeTau").Clone()
		st = fOut.Get("singleTop_t_genuine").Clone()
		vv = fOut.Get("VV_t_genuine").Clone()
	else:
		dy = fOut.Get("CMS_Hptntj_DY_t_genuine").Clone()
		w  = fOut.Get("CMS_Hptntj_W_t_genuine").Clone()
		tt = fOut.Get("CMS_Hptntj_ttbar_t_genuine").Clone()
		qcd= fOut.Get("CMS_Hptntj_QCDandFakeTau").Clone()
		st = fOut.Get("CMS_Hptntj_singleTop_t_genuine").Clone()
		vv = fOut.Get("CMS_Hptntj_VV_t_genuine").Clone()
	
	if dy==None:print "NONE DY"
	
	dy.SetLineColor(ROOT.kBlack)
	w.SetLineColor(ROOT.kBlack)
	tt.SetLineColor(ROOT.kBlack)
	st.SetLineColor(ROOT.kBlack)
	vv.SetLineColor(ROOT.kBlack)
	qcd.SetLineColor(ROOT.kBlack)

	qcd.SetFillColor(ROOT.kOrange)
	w.SetFillColor(ROOT.kGreen-4)
	dy.SetFillColor(ROOT.kCyan)
	tt.SetFillColor(ROOT.kMagenta+2)
	st.SetFillColor(ROOT.kRed)
	vv.SetFillColor(ROOT.kBlue)

	ts=ROOT.THStack()
	ts.SetName("ts")
	ts.Add(dy)
	ts.Add(vv)
	ts.Add(w)
	ts.Add(tt)
	ts.Add(st)
	ts.Add(qcd)

	gc.extend([dy,w,tt,qcd,ts])

	data.SetLineColor(ROOT.kBlack)
	data.SetMarkerColor(ROOT.kBlack)
	data.SetMarkerStyle(20)
	data.SetLineWidth(2)

	b0=b.Clone("b0")
	b0.SetLineColor(ROOT.kBlue)
	b0.SetLineWidth(2)
	b0.SetFillStyle(0)

	b.SetLineColor(ROOT.kBlue)
	b.SetLineWidth(2)
	b.SetFillColor(ROOT.kBlue)
	b.SetFillStyle(3004)

	bs.SetFillColor(ROOT.kRed)
	bs.SetFillStyle(3005)

	## bsd.SetFillColor(ROOT.kGreen)
	## bsd.SetFillStyle(3001)

	ts.Draw("HIST")
	b.Draw("E2 SAME")

	bs.Draw("E2 SAME")
	## bsd.Draw("PE2 SAME")

	b0.Draw("HIST SAME")
	data.Draw("AXIS SAME")	
	data.Draw("AXIS X+ Y+ SAME")	
	data.Draw("PE SAME")	

	c.SetLogy()
	ts.GetXaxis().SetRangeUser(0,500)
	ts.GetYaxis().SetRangeUser(.1,3e3)

	c.Modified()
	c.Update()

	## RATIO
	c2=ROOT.TCanvas("c2","c2",800,800)
	rD = data.Clone("rData")
	rB = b.Clone("rB")
	rS = bs.Clone("rS")
	for i in range(0,b0.GetNbinsX() +2):
		b0.SetBinError(i,0)
	rD.Divide(b0)
	rB.Divide(b0)
	rS.Divide(b0)

	rD.Draw("PE")
	rB.Draw("E2 SAME")
	rS.Draw("E2 SAME")

	rD.GetYaxis().SetRangeUser(0,2)
	rD.GetXaxis().SetRangeUser(0,500)
	
	raw_input("ok?")

