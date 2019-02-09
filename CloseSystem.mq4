
#property copyright "Copyright 2018, ballmdr@gmail.com"
#property version   "1.0"
#property strict

extern int Stop_Loss = 0;
extern int Take_Profit = 0;

const double sigma = 0.000001;

double bulletType = -1;
int bulletTicket = 0;
double bulletLot = 0;
double bulletSL = 0;
double bulletTP = 0;

int totalBuy, totalSell;

datetime currentTime;
int digits;
double pip;
double stopLevel;
bool isTrailingStop = false;
bool setProtectionSeparately = false;


double getPipValue() {

   if (digits == 4 || digits == 5) return (0.0001);
   if (digits == 2 || digits == 3) return (0.01);
   if (digits == 1) return (0.1);
   
   return (1);
}

int OnInit()
  {
   totalBuy = 0;
   totalSell = 0;
   currentTime = Time[0];
   digits = (int) MarketInfo(_Symbol, MODE_DIGITS);
   pip = getPipValue();
   stopLevel = MarketInfo(_Symbol, MODE_STOPLEVEL);
   isTrailingStop = isTrailingStop && Stop_Loss > 0;
   getTotalPosition();
   
   ObjectCreate("totalBuy",OBJ_LABEL,0,0,0);
   ObjectSet("totalBuy", OBJPROP_CORNER, 0);
   ObjectSet("totalBuy", OBJPROP_XDISTANCE, 10);
   ObjectSet("totalBuy", OBJPROP_YDISTANCE, 15);
   ObjectSet("totalBuy", OBJPROP_COLOR, Yellow);
   ObjectSetText("totalBuy", "Buy: " + totalBuy);
   
   ObjectCreate("totalSell", OBJ_LABEL,0,0,0);
   ObjectSet("totalSell", OBJPROP_CORNER, 0);
   ObjectSet("totalSell", OBJPROP_XDISTANCE, 10);
   ObjectSet("totalSell", OBJPROP_YDISTANCE, 30);
   ObjectSet("totalSell", OBJPROP_COLOR, Yellow);
   ObjectSetText("totalSell", "Sell: " + totalSell);
   
   Print("Buy: " + totalBuy);
   Print("Sell: " + totalSell);

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

   if (Time[0] > currentTime) {
      currentTime = Time[0];
      getTotalPosition();
   }
  }

void getTotalPosition() {
   int total = OrdersTotal();
   for (int i=0;i<total;i++) {
      if (OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == _Symbol) {
         switch(OrderType()) {
            case 0:
               totalBuy++;
               break;
            case 1:
               totalSell++;
               break;
         }
      }
   }

   
}