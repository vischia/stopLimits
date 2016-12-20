void drawSituation(TString who, TString card, TString theLabel)
{
  TFile* f = TFile::Open(card, "READ");

  TString
    signalLabel(who=="carlos" ? "h_Stop": "Signal"),
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
  
  TGraph* g = new TGraph(t->GetNbinsX()-1);
  
  for(int ibin=1; ibin<t->GetNbinsX(); ++ibin)
    {
      double ratio( s->GetBinContent(ibin) / sqrt(t->GetBinContent(ibin)) );
      cout << ratio << endl;
      g->SetPoint(ibin-1, s->GetXaxis()->GetBinCenter(ibin) , ratio);
      
    }

  TLegend* leg = new TLegend(0.4,0.7,0.6,0.9);
  leg->AddEntry(s, "Signal", "l");
  leg->AddEntry(t, "ttbar", "l");

  TCanvas* c = new TCanvas("c","c", 1000,1000);
  c->cd();
  t->Draw("hist");
  s->Draw("histsame");
  leg->Draw();
  c->Print("shapes.png");
  c->Print("shapes.pdf");

  TCanvas* c2 = new TCanvas("c2", "c2", 1000,1000);
  c2->cd();
  g->GetXaxis()->SetTitle(t->GetXaxis()->GetTitle());
  g->GetYaxis()->SetTitle("S/sqrt(B)");
  g->SetTitle("Elementary significance-like expression");
  g->SetLineWidth(3);
  g->SetMarkerStyle(21);
  g->Draw("APL");
  c2->Print("significance.png");
  c2->Print("significance.pdf");


  gApplication->Terminate();
  
}
