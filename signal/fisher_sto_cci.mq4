int getSignal() {
   bool fish = FisherCheck();
   bool sto = StoCheck();
   string cci = CciCheck();
   
   if (fish && sto && (cci == "buy")) {
      return SIGNAL_BUY;
   } else if (!fish && !sto && (cci == "sell")) {
      return SIGNAL_SELL;
   } else { return SIGNAL_NONE; }
}
//+------------------------------------------------------------------+
string CciCheck() {
   
   double temp = iCCI(NULL, 0, 20, PRICE_TYPICAL, 0);

   string cciSignal;
   if (temp < -75) { cciSignal = "buy"; }
   else if (temp > 75) { cciSignal = "sell"; }
   else { cciSignal = "no"; }
   return cciSignal;
}

bool StoCheck () {
   double temp = iStochastic(NULL, 0, 6, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   bool stoSignal = true;
   if (temp < 50) { stoSignal = true; }
   else if (temp > 50) { stoSignal =  false; }
   
   return stoSignal;
}

bool FisherCheck () {

   int    period=10;
   double Value=0,Value1=0,Value2=0,Fish=0,Fish1=0,Fish2=0;
   double price;
   double MinL=0;
   double MaxH=0;  
   
   MaxH = High[iHighest(NULL,0,MODE_HIGH,period,0)];
   MinL = Low[iLowest(NULL,0,MODE_LOW,period,0)];
   price = (High[0]+Low[0])/2;
   Value = 0.33*2*((price-MinL)/(MaxH-MinL)-0.5);     
   Value=MathMin(MathMax(Value,-0.999),0.999); 
   Fish1 = 0.5*MathLog((1+Value)/(1-Value));

   bool up=true;
   if (Fish1 > 0) { up = true; }
   else if (Fish1 < 0) { up = false; }
   
   return(up);
}