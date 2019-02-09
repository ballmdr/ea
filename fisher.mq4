
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
int Total, Ticket;
double StopLossLevel, TakeProfitLevel, StopLevel;

extern int MagicNumber = 12345;
extern bool SignalMail = False;
extern double Lots = 0.10;
extern int Slippage = 3;
extern bool UseStopLoss = False;
extern int StopLoss = 20;
extern bool UseTakeProfit = True;
extern int TakeProfit = 40;
extern bool UseTrailingStop = False;
extern int TrailingStop = 30;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (Digits == 5 || Digits == 3 || Digits == 1) P = 10; else P = 1;

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
   Total = OrdersTotal();
   
   if (Total > 1 ) { checkPosition(); }
   
   bool canOpen;

   if (Total == 0) { canOpen = true; }
   else if (Total == 4) { canOpen = false; }
   else { canOpen = getMM(); }

  // open position
   if (canOpen) {
      Order = getSignal();
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
      } //end buy

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
      } //end sell
   } //end check canOpen
}

void checkPosition() {
   double open1, open2, sl1, sl2;
   int ticket1, ticket2;
   if (OrderSelect(Total - 1, SELECT_BY_POS, MODE_TRADES)) {
      sl2 = OrderStopLoss();
      ticket2 = OrderTicket();
      open2 = OrderOpenPrice();
   }
   if (OrderSelect(Total - 2, SELECT_BY_POS, MODE_TRADES)) {
      sl1 = OrderStopLoss();
      ticket1 = OrderTicket();
      open1 = OrderOpenPrice();
   }
   double diff = open1 - open2;
   double tpMod = diff/2;
   
   if (!OrderModify(ticket1, open1, sl1, tpMod, 0, Blue)) Print (GetLastError());
   if (!OrderModify(ticket2, open2, sl2, tpMod, 0, Blue)) Print (GetLastError());
}

bool getMM() {

   return blockTrade();

}
// -----------
/* Money Management Zone */
bool blockTrade() {

   if (OrderSelect(Total - 1, SELECT_BY_POS, MODE_TRADES)) { //select last order
      if (loss()) { return true; } else { return false; } //check last order loss or not
   }
   
   return true;
   
}

bool loss() {
   double open = OrderOpenPrice();
   double diff;
   if (OrderType() == OP_BUY) {
      diff = open - Close[0];
   } else {
      diff = Close[0] - open;
   }

   if (diff > (StopLoss * Point * P)) { return true; } else { return false; }

}
//---------------
/* signal zone */
int testSignal(){
   double emaFast_1 = iMA(NULL, 0, 5, 0, MODE_EMA, PRICE_CLOSE, 1);
   double emaFast_2 = iMA(NULL, 0, 5, 0, MODE_EMA, PRICE_CLOSE, 2);
   double emaSlow_1 = iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, 1);
   double emaSlow_2 = iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, 2);
   //double emaBias = iMA(NULL, PERIOD_D1, 35, 0, MODE_SMA, PRICE_CLOSE, 1);
   
   if (emaSlow_2 > emaFast_2 && emaFast_1 >= emaSlow_1) return SIGNAL_BUY;

   if (emaFast_2 > emaSlow_2 && emaSlow_1 >= emaFast_1) return SIGNAL_SELL; 
   
   return SIGNAL_NONE;
}

int getSignal() {

   return testSignal();
   /*
   bool fish = FisherCheck();
   bool sto = StoCheck();
   string cci = CciCheck();
   
   if (fish && sto && (cci == "buy")) {
      return SIGNAL_BUY;
   } else if (!fish && !sto && (cci == "sell")) {
      return SIGNAL_SELL;
   } else { return SIGNAL_NONE; } */
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
