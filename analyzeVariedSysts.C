void analyzeVariedSysts(TString location){
  
  std::vector<TString> syst; syst.clear();
  syst.push_back("01");
  syst.push_back("05");
  syst.push_back("10");
  syst.push_back("20");
  syst.push_back("25");
  syst.push_back("30");
  syst.push_back("40");
  syst.push_back("50");
  syst.push_back("60");
  syst.push_back("70");
  syst.push_back("80");
  syst.push_back("90");
  syst.push_back("99");
  
  TFile* f = NULL;

  for( auto iSyst : syst){
    TString fname(location+"/higgsCombinevaried_"+iSyst+"_datacard_DeltaPhi_ElMu_0.txt.Asymptotic.mH120.root");
    f = TFile::Open(fname);
    TTree* t = (TTree*) f->Get("limit");
    double l(0.);
    t->SetBranchAddress("limit", &l);
    t->GetEntry(2);
    cout << "Limit: " << l << " for file " << fname << endl;
  }
  gApplication->Terminate();

}
