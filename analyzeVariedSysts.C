


void analyzeVariedSysts(TString what, TString location, TString basename, TString SalsoFull)
{
  bool alsoFull(SalsoFull=="true" ? true : false );
  std::vector<TString> syst; syst.clear();
  std::vector<double>  perc; perc.clear();
  
  if(what=="ttbar")
    {
      syst.push_back("01"); perc.push_back(01);
      syst.push_back("05"); perc.push_back(05);
      syst.push_back("10"); perc.push_back(10);
      syst.push_back("20"); perc.push_back(20);
      syst.push_back("25"); perc.push_back(25);
      syst.push_back("30"); perc.push_back(30);
      syst.push_back("40"); perc.push_back(40);
      syst.push_back("50"); perc.push_back(50);
      syst.push_back("60"); perc.push_back(60);
      syst.push_back("70"); perc.push_back(70);
      syst.push_back("80"); perc.push_back(80);
      syst.push_back("90"); perc.push_back(90);
      syst.push_back("99"); perc.push_back(99);
    }
  else if(what=="signal")
    {
      syst.push_back("01"); perc.push_back(01);
      syst.push_back("10"); perc.push_back(10);
      syst.push_back("20"); perc.push_back(20);
      syst.push_back("50"); perc.push_back(50);
      syst.push_back("99"); perc.push_back(99);
    }
  
  TFile* fasy = NULL;
  TFile* fful = NULL;

  std::vector<double> asy; asy.clear();
  std::vector<double> ful; ful.clear();

  for( auto iSyst : syst){
    TString fnameAsy(location+"/higgsCombinevaried_"+iSyst+"_"+basename+".root.Asymptotic.mH120.root");
    TString fnameFul(location+"/higgsCombinevaried_"+iSyst+"_"+basename+".root.HybridNew.mH120.quant0.500.root");

    fasy = TFile::Open(fnameAsy);
    if(alsoFull)
      fful = TFile::Open(fnameFul);

    TTree* tasy = (TTree*) fasy->Get("limit");
    TTree* tful = NULL;
    if(alsoFull)
      tful = (TTree*) fful->Get("limit");

    double lasy(0.);
    double lful(0.);
    tasy->SetBranchAddress("limit", &lasy);
    if(alsoFull)tful->SetBranchAddress("limit", &lful);
    tasy->GetEntry(2);
    if(alsoFull)tful->GetEntry(0);
    asy.push_back(lasy);
    if(alsoFull)ful.push_back(lful);
    cout << "Limit: asy " << lasy << ", ful " << lful << " for syst " << iSyst << endl;
  }

  TGraph* asyG = new TGraph(syst.size());
  TGraph* fulG = new TGraph(syst.size());

  int iPoint(0);
  for( auto iPerc : perc)
    {
      asyG->SetPoint(iPoint, iPerc, asy[iPoint]);
      if(alsoFull)fulG->SetPoint(iPoint, iPerc, ful[iPoint]);
      iPoint++;
    }

  TLegend* leg = new TLegend(0.1,0.7,0.4,0.9);
  leg->AddEntry(asyG, "Asymptotic", "PL");
  if(alsoFull)leg->AddEntry(fulG, "Full CL_{s}", "PL");

  TCanvas* c = new TCanvas(what,what,1000,1000);
  c->cd();
  asyG->SetTitle("Varying the systematic uncertainty for "+what);
  asyG->GetXaxis()->SetTitle(what+" uncertainty [%]");
  asyG->GetYaxis()->SetTitle("Limit (#sigma/#sigma_{SM})");
  asyG->GetYaxis()->SetTitleOffset(1.4);
  asyG->SetLineWidth(3);
  asyG->SetMarkerStyle(21);
  if(alsoFull)fulG->SetLineWidth(3);
  if(alsoFull)fulG->SetMarkerStyle(21);
  if(alsoFull)fulG->SetLineColor(2);
  if(alsoFull)fulG->SetMarkerColor(2);
  asyG->GetYaxis()->SetRangeUser(0.01,2.5);
  asyG->Draw("APL");
  if(alsoFull)fulG->Draw("PLSAME");
  leg->Draw();
  c->Print(location+what+".png");
  c->Print(location+what+".pdf");

  gApplication->Terminate();

}
