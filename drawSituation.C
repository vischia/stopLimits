void drawSituation(TString who, TString card, TString location, TString theLabel, TString signalLabel)
{

  gSystem->Exec("mkdir -p " + location);

  TFile* f = TFile::Open(card, "READ");

  TString
    //signalLabel(who=="carlos" ? "h_Stop": "S_242_75" /*"Signal"*/ ),
    ttbarLabel( who=="carlos" ? "h_tt"  : "ttbar");
  

  TH1* s = (TH1*) f->Get(signalLabel);
  TH1* t = (TH1*) f->Get(ttbarLabel);

  s->SetLineColor(1);
  t->SetLineColor(2);

  s->SetFillStyle(0);
  t->SetFillStyle(0);

  s->SetLineWidth(3);
  t->SetLineWidth(3);
  
  t->SetTitle("");
  t->GetYaxis()->SetTitle("Expected yield");
  t->GetYaxis()->SetTitleOffset(1.4);
  t->GetXaxis()->SetTitle(theLabel);

  t->GetYaxis()->SetRangeUser(0., 8000.);
  
  TGraph* g = new TGraph(t->GetNbinsX() == 1 ? 1 : t->GetNbinsX());
  cout << "NBINS " << t->GetNbinsX() << ", " << s->GetNbinsX() << endl;
  cout << "INTEGRAL " << t->Integral() << ", " << s->Integral() << endl;
  if(t->GetNbinsX() == 1)
    {
      double ratio(t->GetBinContent(1) != 0 ?  s->GetBinContent(1) / sqrt(t->GetBinContent(1)) : 0. );
      cout << s->GetBinContent(1) << " / sqrt(" << t->GetBinContent(1) << ") = " << ratio << endl;
      g->SetPoint(0, s->GetXaxis()->GetBinCenter(1) , ratio);
    }
  else
    {
      for(int ibin=1; ibin<t->GetNbinsX()+1; ++ibin)
        {
          double ratio(t->GetBinContent(ibin) != 0 ?  s->GetBinContent(ibin) / sqrt(t->GetBinContent(ibin)) : 0. );
          cout << s->GetBinContent(ibin) << " / sqrt(" << t->GetBinContent(ibin) << ") = " << ratio << endl;
          g->SetPoint(ibin-1, s->GetXaxis()->GetBinCenter(ibin) , ratio);
          cout << "BIN " << ibin << ", CENTER: " << s->GetBinCenter(ibin) << endl;
        }
    }

  TLegend* leg = new TLegend(0.4,0.7,0.6,0.9);
  leg->AddEntry(s, "Signal", "l");
  leg->AddEntry(t, "ttbar", "l");

  vector<TString> systList; systList.clear();
  
  //systList.push_back("VV_ElMu_statbin1");
  //systList.push_back("ttV_ElMu_statbin1");
  //systList.push_back("DY_ElMu_statbin1");
  //systList.push_back("tW_ElMu_statbin1");
  //systList.push_back("ttbar_ElMu_statbin1");
  //systList.push_back("S_242_75_ElMu_statbin1");
  systList.push_back("ttbar_ElMu_statbin1");
  systList.push_back("ttbar_ElMu_statbin2");
  systList.push_back("ttbar_ElMu_statbin3");
  systList.push_back("ttbar_ElMu_statbin4");
  systList.push_back("ttbar_ElMu_statbin5");
  systList.push_back("ttbar_ElMu_statbin6");
  systList.push_back("ttbar_ElMu_statbin7");
  systList.push_back("SFS_250_50_ElMu_statbin1");
  systList.push_back("SFS_250_50_ElMu_statbin2");
  systList.push_back("SFS_250_50_ElMu_statbin3");
  systList.push_back("SFS_250_50_ElMu_statbin4");
  systList.push_back("SFS_250_50_ElMu_statbin5");
  systList.push_back("SFS_250_50_ElMu_statbin6");
  systList.push_back("SFS_250_50_ElMu_statbin7");
  systList.push_back("hdamp");
  systList.push_back("Scale");
  systList.push_back("ue");
  systList.push_back("isr");
  systList.push_back("nlo");
  systList.push_back("had");
  systList.push_back("JES");
  systList.push_back("Btag");
  systList.push_back("MisTag");
  systList.push_back("LepEff");
  systList.push_back("PU");
  systList.push_back("pdf");
  
  TCanvas* c = new TCanvas("c","c", 1000,1000);
  TH1* u = NULL;
  TH1* d = NULL;
  TLegend* legsyst = new TLegend(0.4,0.7,0.6,0.9);

  for(auto& syst : systList)
    {
      // Signal
      c->cd();
      c->SetTitle(Form("Syst %s",syst.Data()));
      u = (TH1*) f->Get(Form("%s_%sUp"  ,signalLabel.Data(),syst.Data()));
      d = (TH1*) f->Get(Form("%s_%sDown",signalLabel.Data(),syst.Data())); 
      if(u)
        {
          s->SetLineColor(1);
          s->SetFillStyle(0);
          s->SetLineWidth(3);
          u->SetLineColor(2);
          u->SetFillStyle(0);
          u->SetLineWidth(3);
          d->SetLineColor(3);
          d->SetFillStyle(0);
          d->SetLineWidth(3);
          legsyst->AddEntry(s, "Nominal", "l");
          legsyst->AddEntry(u, "Up variation", "l");
          legsyst->AddEntry(d, "Down variation", "l");
          //s->SetMaximum(10*s->GetMaximum());
          //gPad->SetLogy();
          //s->Draw();
          u->Divide(s);
          d->Divide(s);
          u->SetMaximum(2*u->GetMaximum());
          //gPad->SetLogy();
          u->Draw("hist");
          d->Draw("samehist");
          c->Print(Form("%s/signalShapes_%s.png",location.Data(),syst.Data()));
          c->Print(Form("%s/signalShapes_%s.pdf",location.Data(),syst.Data()));
          delete u;
          delete d;
        }
      c->Clear();
      
      // Dominant background
      c->cd();
      c->SetTitle(Form("Syst %s",syst.Data()));
      u = (TH1*) f->Get(Form("%s_%sUp"  ,ttbarLabel.Data(),syst.Data()));
      d = (TH1*) f->Get(Form("%s_%sDown",ttbarLabel.Data(),syst.Data())); 
      if(u)
        {
          t->SetLineColor(1);
          t->SetFillStyle(0);
          t->SetLineWidth(3);
          u->SetLineColor(2);
          u->SetFillStyle(0);
          u->SetLineWidth(3);
          d->SetLineColor(3);
          d->SetFillStyle(0);
          d->SetLineWidth(3);
          legsyst->AddEntry(t, "Nominal", "l");
          legsyst->AddEntry(u, "Up variation", "l");
          legsyst->AddEntry(d, "Down variation", "l");
          //u->SetMaximum(100*t->GetMaximum());
          //t->Draw();
          u->Divide(t);
          d->Divide(t);
          u->SetMaximum(10*u->GetMaximum());
          gPad->SetLogy();
          u->SetNdivisions(555, "Y");
          u->GetYaxis()->SetMoreLogLabels();
          u->Draw("hist");
          d->Draw("samehist");
          c->Print(Form("%s/ttbarShapes_%s.png",location.Data(),syst.Data()));
          c->Print(Form("%s/ttbarShapes_%s.pdf",location.Data(),syst.Data()));
          delete u;
          delete d;
        }
      c->Clear();
    }

  s->SetLineColor(1);
  t->SetLineColor(2);

  s->SetFillStyle(0);
  t->SetFillStyle(0);

  s->SetLineWidth(3);
  t->SetLineWidth(3);

  c = new TCanvas("c","c", 1000,1000);
  c->cd();
  t->Draw("hist");
  t->SetMaximum(1.5*t->GetMaximum());
  s->Draw("histsame");
  leg->Draw();
  c->Print(location+"/"+"shapes.png");
  c->Print(location+"/"+"shapes.pdf");

  TCanvas* c2 = new TCanvas("c2", "c2", 1000,1000);
  c2->cd();
  g->GetXaxis()->SetTitle(t->GetXaxis()->GetTitle());
  g->GetYaxis()->SetTitle("S/sqrt(B)");
  g->SetTitle("Elementary significance-like expression");
  g->SetLineWidth(3);
  g->SetMarkerStyle(21);
  g->Draw("APL");
  g->GetHistogram()->GetXaxis()->SetRangeUser(t->GetXaxis()->GetBinLowEdge(1), t->GetXaxis()->GetBinUpEdge(t->GetNbinsX()));
  c2->Print(location+"/"+"significance.png");
  c2->Print(location+"/"+"significance.pdf");


  TCanvas* c3 = new TCanvas("c3", "c3", 1000,1000);
  c2->cd();
  g->GetXaxis()->SetTitle(t->GetXaxis()->GetTitle());
  g->GetYaxis()->SetTitle("(signal-ttbar)/ttbar");
  s->SetTitle("Distributions normalized to 1 before subtraction/ratio");
  s->Scale(1./s->Integral());
  t->Scale(1./t->Integral());
  s->Add(t,-1);
  s->Divide(t);
  s->Draw();
  c2->Print(location+"/"+"shaperatio.png");
  c2->Print(location+"/"+"shaperatio.pdf");


  gApplication->Terminate();
  
}
