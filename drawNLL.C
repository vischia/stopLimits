//TGraph* GetIntersections(TGraph* g,  TCutG b)
//{
//  // Return a TGraph with the points of intersection
//  TGraph *interPoint = new TGraph();
//  Int_t i = 0;
//
//  cout << "Intersections" << endl;
//  // Loop over all points in this TGraph
//  for(size_t a_i = 0; a_i < g->GetN()-1; ++a_i)
//    {
//      cout << "a_i=" << a_i;
//      // Loop over all points in the TCutG region
//      for(size_t b_i = 0; b_i < b.GetN()-1; ++b_i)
//        {
//         
//          cout << "; b_i=" << b_i;
//          // Get the current point, and the next point for each of the objects
//          Double_t x1, y1, x2, y2 = 0;
//          Double_t ax1, ay1, ax2, ay2 = 0;
//          g->GetPoint(a_i, x1, y1);
//          g->GetPoint(a_i+1, x2, y2);
//          b.GetPoint(b_i, ax1, ay1);
//          b.GetPoint(b_i+1, ax2, ay2);
//
//          // Calculate the intersection between two straight lines, x axis
//          Double_t x = (ax1 *(ay2 *(x1-x2)+x2 * y1 - x1 * y2 )+ ax2 * (ay1 * (-x1+x2)- x2 * y1+x1 * y2)) 
//            / (-(ay1-ay2) * (x1-x2)+(ax1-ax2)* (y1-y2));
//                            
//          // Calculate the intersection between two straight lines, y axis
//          Double_t y = (ax1 * ay2 * (y1-y2)+ax2 * ay1 * (-y1+y2)+(ay1-ay2) * (x2 * y1-x1 * y2))/(-(ay1-ay2) * (x1-x2)+(ax1-ax2) * (y1-y2));
//
//          // Find the tightest interval along the x-axis defined by the four points
//          Double_t xrange_min = max(min(x1, x2), min(ax1, ax2));
//          Double_t xrange_max = min(max(x1, x2), max(ax1, ax2));
//
//          // If points from the two lines overlap, they are trivially intersecting
//          if ((x1 == ax1 and y1 == ay1) or (x2 == ax2 and y2 == ay2)){               
//            interPoint->SetPoint(i, (x1 == ax1 and y1 == ay1) ? x1 : x2, (x1 == ax1 and y1 == ay1) ? y1 : y2);
//            i++;
//            
//          } 
//          // If the intersection between the two lines is within the tight range, add it to the list of intersections.
//          else if(x > xrange_min && x < xrange_max)
//            {
//              interPoint->SetPoint(i,x, y);
//              i++;
//            
//            }
//        }
//      cout << endl;
//    }
//  return interPoint;
//}


void drawNLL(TString filename, TString nuis, int nb, double min, double max)
{

  TFile* f = TFile::Open(filename, "READ");

  TTree* t = (TTree*) f->Get("limit");

  TH2F* h = new TH2F("h", "h", nb, min, max, nb, 0., 1);

  //t->Draw("deltaNLL:"+nuis+">>h");
  cout << "this" << endl;
  t->Draw("deltaNLL:"+nuis, "deltaNLL < 0.52 && deltaNLL > 0.48");
  cout << "that" << endl;

  cout << gROOT->FindObject("Graph");
  TGraph* graphProf = (TGraph*) gROOT->FindObject("Graph")->Clone("likelihood"); graphProf->Sort();
  cout << "prof acquired" << endl;
  
//  // TCutG Region
//  
//  TCutG *cutg = new TCutG("elcorte",2);
//  cutg->SetVarX("");
//  cutg->SetVarY("");
//  cutg->SetTitle("elcorte");
//  Int_t ci;   // for color index setting
//  ci = TColor::GetColor("#00ff00");
//  cutg->SetFillColor(ci);
//  cutg->SetPoint(0,-5,0.5);
//  cutg->SetPoint(1, 5,0.5);
//   
//  cout << "cutg" << endl;
//  TGraph* chorro = GetIntersections(graphProf, *cutg);

  for(Int_t np =0; np<graphProf->GetN(); ++np)
    {
      Double_t x, y;
      graphProf->GetPoint(np, x, y);
      cout << "Intersection: " << x << " at deltaNLL " << y << endl;
    }
  
  TCanvas* c = new TCanvas("c", "c", 800, 800);
  c->cd();
  h->SetMarkerStyle(20);
  h->SetMarkerSize(1);
  h->Draw();
  c->Print(filename+TString(".pdf"));
  
  //  Int_t binsigmad, binsigmau;
  //  h->GetBinWithContent(0.5, binsigmad, 0, 0, 0);
  //  h->GetBinWithContent(0.5, binsigmau, 0, 0, 1);
  //  
  //  cout << "The bin content: " << h->GetBinCenter(binsigmad) << ", " << h->GetBinCenter(binsigmau) << endl;

  gApplication->Terminate();
}
