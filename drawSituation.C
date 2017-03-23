void drawSituation(TString who, TString card, TString location, TString theLabel)
{

  gSystem->Exec("mkdir -p " + location);

  TFile* f = TFile::Open(card, "READ");

  TString
    signalLabel(who=="carlos" ? "h_Stop": "S_242_75" /*"Signal"*/ ),
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
  
  TGraph* g = new TGraph(t->GetNbinsX() == 1 ? 1 : t->GetNbinsX()-1);
  cout << "NBINS " << t->GetNbinsX() << endl;
  cout << "INTEGRAL " << t->Integral() << endl;
  if(t->GetNbinsX() == 1)
    {
      double ratio(t->GetBinContent(1) != 0 ?  s->GetBinContent(1) / sqrt(t->GetBinContent(1)) : 0. );
      cout << s->GetBinContent(1) << " / sqrt(" << t->GetBinContent(1) << ") = " << ratio << endl;
      g->SetPoint(0, s->GetXaxis()->GetBinCenter(1) , ratio);
    }
  else
    {
      for(int ibin=1; ibin<t->GetNbinsX(); ++ibin)
        {
          double ratio(t->GetBinContent(ibin) != 0 ?  s->GetBinContent(ibin) / sqrt(t->GetBinContent(ibin)) : 0. );
          cout << s->GetBinContent(ibin) << " / sqrt(" << t->GetBinContent(ibin) << ") = " << ratio << endl;
          g->SetPoint(ibin-1, s->GetXaxis()->GetBinCenter(ibin) , ratio);
        }
    }

  TLegend* leg = new TLegend(0.4,0.7,0.6,0.9);
  leg->AddEntry(s, "Signal", "l");
  leg->AddEntry(t, "ttbar", "l");

  vector<TString> systList; systList.clear();
  
  systList.push_back("VV_ElMu_statbin1");
  systList.push_back("ttV_ElMu_statbin1");
  systList.push_back("DY_ElMu_statbin1");
  systList.push_back("tW_ElMu_statbin1");
  systList.push_back("ttbar_ElMu_statbin1");
  systList.push_back("S_242_75_ElMu_statbin1");
  systList.push_back("ue");
  systList.push_back("isr");
  systList.push_back("nlo");
  systList.push_back("had");
  systList.push_back("JES");
  systList.push_back("Btag");
  systList.push_back("MisTag");
  systList.push_back("LepEff");
  systList.push_back("PU");
  
  TCanvas* c = new TCanvas("c","c", 1000,1000);
  TH1* u = NULL;
  TH1* d = NULL;
  TLegend* legsyst = new TLegend(0.4,0.7,0.6,0.9);

  for(auto& syst : systList)
    {
      // Signal
      c->cd();
      u = (TH1*) f->Get(Form("%s_%sUp"  ,signalLabel,syst));
      d = (TH1*) f->Get(Form("%s_%sDown",signalLabel,syst)); 
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
      s->Draw();
      u->Draw("samehist");
      d->Draw("samehist");
      c->Print(Form("%s/signalShapes_%s.png",location,syst));
      c->Print(Form("%s/signalShapes_%s.pdf",location,syst));
      
      delete u;
      delete d;
      
      c->Clear();
      
      // Dominant background
      c->cd();
      u = (TH1*) f->Get(Form("%s_%sUp"  ,ttbarLabel,syst));
      d = (TH1*) f->Get(Form("%s_%sDown",ttbarLabel,syst)); 
      t->SetLineColor(1);
      t->SetFillStyle(0);
      t->SetLineWidth(3);
      u->SetLineColor(2);
      u->SetFillStyle(0);
      u->SetLineWidth(3);
      d->SetLineColor(3);
      d->SetFillStyle(0);
      d->SetLineWidth(3);
      t->Draw();
      u->Draw("samehist");
      d->Draw("samehist");
      c->Print(Form("%s/ttbarShapes_%s.png",location,syst));
      c->Print(Form("%s/ttbarShapes_%s.pdf",location,syst));
      delete u;
      delete d;
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
  c2->Print(location+"/"+"significance.png");
  c2->Print(location+"/"+"significance.pdf");


  gApplication->Terminate();
  
}
