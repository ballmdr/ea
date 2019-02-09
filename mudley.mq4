
#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4

int MagicNumber = 12345;
bool SignalMail = False;
double Lots = 0.10;
int Slippage = 3;
bool UseStopLoss = False;
extern int maxTotal = 6;
extern double maBiasSetting = 690;
extern double emaFastSetting= 31;
extern double emaSlowSetting = 15;
double emaBias;

bool UseTakeProfit = True;

bool UseTrailingStop = True;
int TrailingStop = 10;

int P = 1;
int Order = SIGNAL_NONE;
int Total, Ticket, Ticket2;
double StopLossLevel, TakeProfitLevel, StopLevel;



double emaFast_1, emaFast_2, emaSlow_1, emaSlow_2;


int init() {
   
   if(Digits == 5 || Digits == 3 || Digits == 1)P = 10;else P = 1;

   return(0);
}

int deinit() {
   return(0);
}




int start() {

   Total = OrdersTotal();
   Order = SIGNAL_NONE;

   emaFast_1 = iMA(NULL, PERIOD_M5, emaFastSetting, 0, MODE_EMA, PRICE_CLOSE, 1);
   emaFast_2 = iMA(NULL, PERIOD_M5, emaFastSetting, 0, MODE_EMA, PRICE_CLOSE, 2);
   emaSlow_1 = iMA(NULL, PERIOD_M5, emaSlowSetting, 0, MODE_EMA, PRICE_CLOSE, 1);
   emaSlow_2 = iMA(NULL, PERIOD_M5, emaSlowSetting, 0, MODE_EMA, PRICE_CLOSE, 2);
   
   emaBias = iMA(NULL, PERIOD_M5, maBiasSetting, 0, MODE_SMA, PRICE_CLOSE, 1);
   
   double atr = iATR(NULL, PERIOD_D1, 14, 0);
   int StopLoss = (2.5 * atr) * 1000;
   int TakeProfit = (atr) * 1000;

   StopLevel = (MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD)) / P; 

   if (StopLoss < StopLevel) StopLoss = StopLevel;
   if (TakeProfit < StopLevel) TakeProfit = StopLevel;

   int lastTicket = LastOrderTicket();
   lastTicket = OrderSelect(lastTicket, SELECT_BY_TICKET);
   double lastPrice = OrderOpenPrice();
   int orderType = OrderType();
   datetime lastClose =  OrderCloseTime();
   
   if (Total > maxTotal) {
      int firstTicket = OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
      double closePrice;
      if (OrderType() == 0) {
         closePrice = Bid;
      } else {
         closePrice = Ask;
      }
      firstTicket = OrderClose(OrderTicket(), OrderLots(), closePrice, Slippage, Red);
   }
   
   if (Close[0] > emaBias && emaSlow_2 > emaFast_2 && emaFast_1 >= emaSlow_1) Order = SIGNAL_BUY;

   if (Close[0] < emaBias && emaFast_2 > emaSlow_2 && emaSlow_1 >= emaFast_1) Order = SIGNAL_SELL; 
   
   Print("total: " + Total);
   Print("orderType: " + orderType);
   Print("last close: " + lastClose);
   

   if (Order == SIGNAL_BUY) {
         
      if (Total < 1 || (orderType != 0)) {
         if (AccountFreeMargin() < (1000 * Lots)) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return(0);
         }

         if (UseStopLoss) StopLossLevel = Ask - StopLoss * Point * P; else StopLossLevel = 0.0;
         if (UseTakeProfit) TakeProfitLevel = Ask + TakeProfit * Point * P; else TakeProfitLevel = 0.0;

         Ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, StopLossLevel, TakeProfitLevel, "EA Mudley HomeWork", MagicNumber, 0, DodgerBlue);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("BUY order opened : ", OrderOpenPrice());
			} else {
				Print("Error opening BUY order : ", GetLastError());
			}
         }
         return(0);
      }
   }

 
   if (Order == SIGNAL_SELL) {
      if (Total < 1 || orderType != 1) {
         if (AccountFreeMargin() < (1000 * Lots)) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return(0);
         }

         if (UseStopLoss) StopLossLevel = Bid + StopLoss * Point * P; else StopLossLevel = 0.0;
         if (UseTakeProfit) TakeProfitLevel = Bid - TakeProfit * Point * P; else TakeProfitLevel = 0.0;

         Ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, StopLossLevel, TakeProfitLevel, "Sell(#" + MagicNumber + ")", MagicNumber, 0, DeepPink);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("SELL order opened : ", OrderOpenPrice());
			} else {
				Print("Error opening SELL order : ", GetLastError());
			}
         }
         return(0);
      }
   }

   return(0);
}
