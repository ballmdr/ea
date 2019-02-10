
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
int StopLoss = 0;
extern bool UseTakeProfit = True;
extern int TakeProfit = 0;
extern bool UseTrailingStop = False;
extern int TrailingStop = 30;
extern float fisher_params = 0.25;

double high;
double low;

double all_distance;
int contract = 1000;
int cash = 3000;
int zone = 8;
int maxarr = zone + 1;
int bullet;
double risk_per_zone;
double risk_per_trade;
double leverage;
double zone_distance;
double zone_price[10];
double pipval = 0.10;
double last_price;
double stoploss_distance;
double std;
double priceBuffer[253];
int current_zone;
int total_order;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(Digits == 5 || Digits == 3 || Digits == 1)P = 10;else P = 1;
   risk_per_zone = cash/zone;
   
   setGrid();

   setMM();
   
   
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
   
   
   if (last_price > zone_price[9] || last_price < zone_price[0]){
      for (int i=252;i>=0;i--) priceBuffer[i]=iClose(NULL,PERIOD_D1,i);
      setGrid();
      setMM();
   }
   
   last_price = Close[0];
   
   current_zone = findCurrentlyZone(last_price);
   printScreen();
   
   bool can_open;
   
   total_order = OrdersTotal();
   
   if (total_order == 0){
      can_open = True;
   } else {
      can_open = checkPosition();
   }
   
   ObjectCreate("rsi", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("rsi", "rsi2: " + last_price,14, "Verdana", White);
   ObjectSet("rsi", OBJPROP_CORNER, 0);
   ObjectSet("rsi", OBJPROP_XDISTANCE, 20);
   ObjectSet("rsi", OBJPROP_YDISTANCE, 350);
   
  
  // open position
   if (can_open) {
      int signal = SIGNAL_NONE;
      signal = getSignal();
      if (signal != SIGNAL_NONE){
         StopLoss = stoploss_distance;
         TakeProfit = zone_distance*10000;
         if (signal == SIGNAL_BUY) {
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
         } else if (signal == SIGNAL_SELL) {
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

 

   }

}

int getSignal(){

   double rsi = iRSI(NULL, 0, 2, PRICE_CLOSE, 0);
   
   
   if (rsi < 10){
      return SIGNAL_BUY;
   } else if (rsi > 90){
      return SIGNAL_SELL;
   }
   return SIGNAL_NONE;

}

bool checkPosition(){

   int num_pos_in_zone = 0;
   
   
   for (int i=0;i<total_order;i++){
      
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         if (current_zone == findCurrentlyZone(OrderOpenPrice())){
            num_pos_in_zone++;
         }
      }
   
   }
   Comment("position in zone: " + num_pos_in_zone);
   if (num_pos_in_zone < bullet){
      return True; 
   } else {
      return False;
   }

}

void setMM(){
   
   
   std = iStdDevOnArray(priceBuffer,252,252,0,MODE_SMA,0); 
  
   bool find_bullet = False;
   while(!find_bullet){
      for (int i=10;i>=1;i--){
         risk_per_trade = risk_per_zone/i;
         stoploss_distance = risk_per_trade/pipval;
         
         if (stoploss_distance > ((std*3)*10000)){
            find_bullet = True;
            bullet = i;
            break;
         }
      }   
   }
   
   leverage = contract/risk_per_trade;
   

}

void setGrid(){

   high = iHighest(NULL, PERIOD_D1, MODE_HIGH, 252, 0);
   high = iHigh(NULL, PERIOD_D1, high);
   
   low = iLowest(NULL, PERIOD_D1, MODE_LOW, 252, 0);
   low = iLow(NULL, PERIOD_D1, low);
   all_distance = high - low;
   zone_distance = all_distance/zone;
   
   for (int i=0;i<=zone+1;i++){
      if (i==0){
         zone_price[0] = low;
      } else {
         zone_price[i] = zone_price[i-1] + zone_distance;
      }
   }
   
}

void printScreen(){

   ObjectsDeleteAll();
   
   int font_size = 12;
   int line_spacing = 20;
   int line_start = 20;

   ObjectCreate("High", OBJ_HLINE, 0, Time[0],high);
   ObjectCreate("Low", OBJ_HLINE, 0, Time[0],low);
   
   ObjectCreate("RPZ", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("RPZ", "Risk per Zone: " + risk_per_zone,font_size, "Verdana", White);
   ObjectSet("RPZ", OBJPROP_CORNER, 0);
   ObjectSet("RPZ", OBJPROP_XDISTANCE, 20);
   ObjectSet("RPZ", OBJPROP_YDISTANCE, line_start);
   
   ObjectCreate("RPT", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("RPT", "Risk per Trade: " + risk_per_trade,font_size,"Verdana",White);
   ObjectSet("RPT", OBJPROP_CORNER, 0);
   ObjectSet("RPT", OBJPROP_XDISTANCE, 20);
   ObjectSet("RPT", OBJPROP_YDISTANCE, line_start+=line_spacing);
   
   ObjectCreate("ZD", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("ZD", "Zone Distance(pips): " + zone_distance*10000,font_size,"Verdana",White);
   ObjectSet("ZD", OBJPROP_CORNER, 0);
   ObjectSet("ZD", OBJPROP_XDISTANCE, 20);
   ObjectSet("ZD", OBJPROP_YDISTANCE, line_start+=line_spacing);
   
   ObjectCreate("cash", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("cash", "Cash: " + cash + ", Zone: " + zone + ", Bullet per Zone: " + bullet,font_size,"Verdana",White);
   ObjectSet("cash", OBJPROP_CORNER, 0);
   ObjectSet("cash", OBJPROP_XDISTANCE, 20);
   ObjectSet("cash", OBJPROP_YDISTANCE, line_start+=line_spacing);
   
   ObjectCreate("lv", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("lv", "Leverage: " + leverage,font_size,"Verdana",White);
   ObjectSet("lv", OBJPROP_CORNER, 0);
   ObjectSet("lv", OBJPROP_XDISTANCE, 20);
   ObjectSet("lv", OBJPROP_YDISTANCE, line_start+=line_spacing);
   
   ObjectCreate("sld", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("sld", "Stoploss Distance: " + stoploss_distance,font_size,"Verdana",White);
   ObjectSet("sld", OBJPROP_CORNER, 0);
   ObjectSet("sld", OBJPROP_XDISTANCE, 20);
   ObjectSet("sld", OBJPROP_YDISTANCE, line_start+=line_spacing);
   
   ObjectCreate("3sd", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("3sd", "3 SD: " + (std*3) * 10000,font_size,"Verdana",White);
   ObjectSet("3sd", OBJPROP_CORNER, 0);
   ObjectSet("3sd", OBJPROP_XDISTANCE, 20);
   ObjectSet("3sd", OBJPROP_YDISTANCE, line_start+=line_spacing);
   
   ObjectCreate("hl", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("hl", "High - Low: " + high + " - " + low,font_size,"Verdana",White);
   ObjectSet("hl", OBJPROP_CORNER, 0);
   ObjectSet("hl", OBJPROP_XDISTANCE, 20);
   ObjectSet("hl", OBJPROP_YDISTANCE, line_start+=line_spacing);
   
   for(int i=0;i<=zone;i++){
      ObjectCreate("zone"+i, OBJ_HLINE, 0, Time[0],zone_price[i]);
      ObjectSet("zone"+i, OBJPROP_STYLE, STYLE_DOT);
   }
   
   ObjectCreate("currentzone", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("currentzone", "Current Zone: " + current_zone,font_size,"Verdana",White);
   ObjectSet("currentzone", OBJPROP_CORNER, 0);
   ObjectSet("currentzone", OBJPROP_XDISTANCE, 20);
   ObjectSet("currentzone", OBJPROP_YDISTANCE, line_start+=line_spacing); 

}

int findCurrentlyZone(double price){

   for (int i=0;i<=zone;i++){
      if (zone_price[i] <= price && price <= zone_price[i+1]){
         return i+1;
      }
   }
   return 0;

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
