
#property copyright "ball.mdr@gmail.com"
#property version   "1.00"
#property strict

#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4

int P = 1;
int Order = SIGNAL_NONE;
int Total, Ticket, Ticket2;
double StopLossLevel, TakeProfitLevel, StopLevel;

extern int MagicNumber = 12345;
extern bool SignalMail = False;
double Lots = 0.01;
extern int Slippage = 3;
extern bool UseStopLoss = True;
extern int StopLoss = 20;
extern bool UseTakeProfit = True;
extern int TakeProfit = 40;
extern bool UseTrailingStop = False;
extern int TrailingStop = 30;
extern float fisher_params = 0.25;

double high;
double low;

double all_distance;
int contract;
int cash;
int zone;
int bullet;
double risk_per_zone;
double risk_per_trade;
double leverage;
double zone_distance;
double zone_price[9];
double pipval;
double last_price;
double stoploss_distance;
double std;
double priceBuffer[253];



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(Digits == 5 || Digits == 3 || Digits == 1)P = 10;else P = 1;
   contract = 1000;
   cash = 3000;
   zone = 8;
   bullet = 9;
   pipval = 0.10;
   
   for (int i=252;i>=0;i--) priceBuffer[i]=iClose(NULL,PERIOD_D1,i);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   
   setVar();
   printScreen();
   
   findCurrentlyZone();
   
  
  // open position
   if (Total == 0) {
      if (Order == SIGNAL_BUY) {
         //Check free margin
         if (AccountFreeMargin() < (1000 * Lots)) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
         }

         if (UseStopLoss) StopLossLevel = Ask - StopLoss * Point * P; else StopLossLevel = 0.0;
         if (UseTakeProfit) TakeProfitLevel = Ask + TakeProfit * Point * P; else TakeProfitLevel = 0.0;

         Ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, StopLossLevel, TakeProfitLevel, "Buy(#" + MagicNumber + ")", MagicNumber, 0, DodgerBlue);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("BUY order opened : ", OrderOpenPrice());
                if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Open Buy");
			} else {
				Print("Error opening BUY order : ", GetLastError());
			}
      }
   }

 
   if (Order == SIGNAL_SELL) {
         //Check free margin
         if (AccountFreeMargin() < (1000 * Lots)) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());

         }

         if (UseStopLoss) StopLossLevel = Bid + StopLoss * Point * P; else StopLossLevel = 0.0;
         if (UseTakeProfit) TakeProfitLevel = Bid - TakeProfit * Point * P; else TakeProfitLevel = 0.0;

         Ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, StopLossLevel, TakeProfitLevel, "Sell(#" + MagicNumber + ")", MagicNumber, 0, DeepPink);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("SELL order opened : ", OrderOpenPrice());
                if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Open Sell");
			} else {
				Print("Error opening SELL order : ", GetLastError());
			}
         }
   }
   }

}

void setVar(){
   
   high = iHighest(NULL, PERIOD_MN1, MODE_HIGH, 1, 12);
   high = iHigh(NULL, PERIOD_MN1, high);
   
   low = iLowest(NULL, PERIOD_MN1, MODE_HIGH, 12, 1);
   low = iLow(NULL, PERIOD_MN1, low);
   
   
   all_distance = high - low;

   risk_per_zone = cash/zone;
   risk_per_trade = risk_per_zone/bullet;
   leverage = contract/risk_per_trade;
   zone_distance = all_distance/zone;
   stoploss_distance = risk_per_trade/pipval;
   std = iStdDevOnArray(priceBuffer,100,10,0,MODE_EMA,0);
   
   
   last_price = Ask;
   
   for (int i=0;i<=zone;i++){
      if (i==0){
         zone_price[0] = low;
      } else {
         zone_price[i] = zone_price[i-1] + zone_distance;
      }
   }
   

}

void printScreen(){

   ObjectCreate("High", OBJ_HLINE, 0, Time[0],high,0,0);
   ObjectCreate("Low", OBJ_HLINE, 0, Time[0],low,0,0);
   
   ObjectCreate("RPZ", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("RPZ", "Risk per Zone: " + risk_per_zone,16, "Verdana", White);
   ObjectSet("RPZ", OBJPROP_CORNER, 0);
   ObjectSet("RPZ", OBJPROP_XDISTANCE, 20);
   ObjectSet("RPZ", OBJPROP_YDISTANCE, 20);
   
   ObjectCreate("RPT", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("RPT", "Risk per Trade: " + risk_per_trade,16,"Verdana",White);
   ObjectSet("RPT", OBJPROP_CORNER, 0);
   ObjectSet("RPT", OBJPROP_XDISTANCE, 20);
   ObjectSet("RPT", OBJPROP_YDISTANCE, 60);
   
   ObjectCreate("ZD", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("ZD", "Zone Distance(pips): " + zone_distance*10000,16,"Verdana",White);
   ObjectSet("ZD", OBJPROP_CORNER, 0);
   ObjectSet("ZD", OBJPROP_XDISTANCE, 20);
   ObjectSet("ZD", OBJPROP_YDISTANCE, 100);
   
   ObjectCreate("cash", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("cash", "Cash: " + cash + ", Zone: " + zone + ", Bullet per Zone: " + bullet,16,"Verdana",White);
   ObjectSet("cash", OBJPROP_CORNER, 0);
   ObjectSet("cash", OBJPROP_XDISTANCE, 20);
   ObjectSet("cash", OBJPROP_YDISTANCE, 140);
   
   ObjectCreate("lv", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("lv", "Leverage: " + leverage,16,"Verdana",White);
   ObjectSet("lv", OBJPROP_CORNER, 0);
   ObjectSet("lv", OBJPROP_XDISTANCE, 20);
   ObjectSet("lv", OBJPROP_YDISTANCE, 180);
   
   ObjectCreate("sld", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("sld", "Stoploss Distance: " + stoploss_distance,16,"Verdana",White);
   ObjectSet("sld", OBJPROP_CORNER, 0);
   ObjectSet("sld", OBJPROP_XDISTANCE, 20);
   ObjectSet("sld", OBJPROP_YDISTANCE, 220);
   
   ObjectCreate("3sd", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("3sd", "3 SD: " + (std*3) * 10000,16,"Verdana",White);
   ObjectSet("3sd", OBJPROP_CORNER, 0);
   ObjectSet("3sd", OBJPROP_XDISTANCE, 20);
   ObjectSet("3sd", OBJPROP_YDISTANCE, 260);
   
   for(int i=0;i<=zone;i++){
      ObjectCreate("zone"+i, OBJ_HLINE, 0, Time[0],zone_price[i],0,0);
   }

}

void findCurrentlyZone(){

   for (int i=0;i<=zone;i++){
      if (zone_price[i] <= last_price && last_price <= zone_price[i+1]){
         
      }
   }

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
   if (Fish1 > fisher_params) { up = true; }
   else if (Fish1 < fisher_params) { up = false; }
   
   return(up);
}
