//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2012, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "ball.mdr@gmail.com"
#property version   "1.00"
#property strict

#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4

int P=1;
int Order=SIGNAL_NONE;
int Total,Ticket,Ticket2;
double StopLossLevel,TakeProfitLevel,StopLevel;

extern int MagicNumber = 12345;
extern bool SignalMail = False;
double Lots=0.01;
int Slippage=3;
bool UseStopLoss=True;
int StopLoss=0;
bool UseTakeProfit=True;
int TakeProfit=0;
bool UseTrailingStop=False;
int TrailingStop=30;


double high;
double low;

double all_distance;
int contract=1000;
extern int cash = 3000;
extern int zone = 8;
extern int max_leverage = 10;
extern int max_bullet = 100;

int maxarr=zone+1;
int bullet;
double risk_per_zone;
double risk_per_trade;
double leverage;
double zone_distance;
double zone_mini_distance;
double zone_price[];
double zone_mini_price[];
double pipval=0.10;
double last_price;
double stoploss_distance = 0;
double std;
double priceBuffer[253];
int current_zone;
int current_zone_mini;
int total_order;
int last_zone;
int last_zone_mini;
bool can_open;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(Digits==5 || Digits==3 || Digits==1)P=10;else P=1;
   risk_per_zone=cash/zone;
   
   ArrayResize(zone_price, zone+1);

   setGrid();
   setMM();
   
   last_price = Close[0];
   current_zone = findCurrentlyZone(last_price);
   setGridMini();
   current_zone_mini = findCurrentlyZoneMini(last_price);
   last_zone = current_zone;
   last_zone_mini = current_zone_mini;
   printScreen();

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
   total_order = OrdersTotal();
   last_price = Close[0];
   current_zone = findCurrentlyZone(last_price);
   current_zone_mini = findCurrentlyZoneMini(last_price);
   if (newBar()) {
      setGrid();
      setMM();
      setGridMini();
   }
   
   if (last_zone_mini < current_zone_mini){
      //closeProfit();
      last_zone_mini = current_zone_mini;
   } else if (last_zone_mini != current_zone_mini) {
      Order = SIGNAL_BUY;
      last_zone_mini = current_zone_mini;
   }
   if(last_zone < current_zone) {
   
      closeProfit();
      last_zone = current_zone;
   } else if (last_zone > current_zone) {
      //modBreakeven();
      last_zone= current_zone;
   }

   printScreen();

   total_order = OrdersTotal();

   if(total_order == 0)
      can_open = True;
   else
      can_open = checkPositionMini();
   

// open position
   if(can_open) 
     {
      //Order = getSignal();
      if(Order != SIGNAL_NONE)
        {
         StopLoss = stoploss_distance;
         TakeProfit = zone_mini_distance*10000;
         if(Order == SIGNAL_BUY) 
           {
            //Check free margin
            if(AccountFreeMargin()<(1000*Lots)) 
              {
               Print("We have no money. Free Margin = ",AccountFreeMargin());
              }

            if(UseStopLoss) StopLossLevel=Ask-StopLoss*Point*P; else StopLossLevel=0.0;
            if(UseTakeProfit) TakeProfitLevel=Ask+TakeProfit*Point*P; else TakeProfitLevel=0.0;

            Ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,StopLossLevel,TakeProfitLevel,"Buy(#"+MagicNumber+")",MagicNumber,0,DodgerBlue);
            if(Ticket>0) 
              {
               if(OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES)) 
                 {
                  Print("BUY order opened : ",OrderOpenPrice());
                  if(SignalMail) SendMail("[Signal Alert]","["+Symbol()+"] "+DoubleToStr(Ask,Digits)+" Open Buy");
                    } else {
                  Print("Error opening BUY order : ",GetLastError());
                 }
                 } else if(Order==SIGNAL_SELL) {
               //Check free margin
               if(AccountFreeMargin()<(1000*Lots)) 
                 {
                  Print("We have no money. Free Margin = ",AccountFreeMargin());

                 }

               if(UseStopLoss) StopLossLevel=Bid+StopLoss*Point*P; else StopLossLevel=0.0;
               if(UseTakeProfit) TakeProfitLevel=Bid-TakeProfit*Point*P; else TakeProfitLevel=0.0;

               Ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,StopLossLevel,TakeProfitLevel,"Sell(#"+MagicNumber+")",MagicNumber,0,DeepPink);
               if(Ticket>0) 
                 {
                  if(OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES)) 
                    {
                     Print("SELL order opened : ",OrderOpenPrice());
                     if(SignalMail) SendMail("[Signal Alert]","["+Symbol()+"] "+DoubleToStr(Bid,Digits)+" Open Sell");
                       } else {
                     Print("Error opening SELL order : ",GetLastError());
                    }
                 }
              }
           }
         Order = SIGNAL_NONE;
        }

     }

  }
  
bool newBar(){
   static datetime new_time = 0;
   bool new_bar = False;
   if (new_time != Time[0]) {
      new_time = Time[0];
      new_bar = True;
   }
   return new_bar;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeProfit()
  {
   
   
   for (int i=0;i<total_order;i++) {
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if (OrderProfit() > 0.0) {
            OrderClose(OrderTicket(), Lots, Bid, Slippage, Red);
         }
      }
   }

  }
  
void modBreakeven(){

   for (int i=0;i<total_order;i++){
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), OrderOpenPrice(),0);
      }
   }
   
}
  
void modSL(double newSL){
   
   for (int i=0;i<total_order;i++){
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         StopLossLevel = Ask - newSL * Point * P;
         OrderModify(OrderTicket(), OrderOpenPrice(), StopLossLevel, OrderTakeProfit(),0);
      }
   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkPositionMini(){
   
   for (int i=0;i<total_order;i++){
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(current_zone_mini == findCurrentlyZoneMini(OrderOpenPrice()))
            return False;
      }
   }
   return True;

}

bool checkPosition()
  {

   int num_pos_in_zone=0;

   for(int i=0;i<total_order;i++)
     {

      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(current_zone==findCurrentlyZone(OrderOpenPrice()))
           {
            num_pos_in_zone++;
           }
        }

     }
   if(num_pos_in_zone<bullet)
     {
      return True;
        } else {
      return False;
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setGridMini(){

   double zone_mini_high = zone_price[current_zone];
   double zone_mini_low = zone_price[current_zone-1];
   zone_mini_distance = (zone_mini_high - zone_mini_low)/bullet;
   
   ArrayResize(zone_mini_price, bullet+1);
   
   for(int i=0;i<=bullet;i++)
     {
      if(i==0)
        {
         zone_mini_price[0] = zone_mini_low;
           } else {
         zone_mini_price[i] = zone_mini_price[i-1] + zone_mini_distance;
        }
     }

}
void setMM()
  {

   for(int i=252;i>=0;i--) priceBuffer[i]=iClose(NULL,PERIOD_D1,i);
   std=iStdDevOnArray(priceBuffer,252,252,0,MODE_SMA,0);

   bool find_bullet=False;
   double new_sl;
   
   
   while(!find_bullet) {
      for(int i=max_bullet;i>=1;i--){
         risk_per_trade=risk_per_zone/i;
         new_sl = risk_per_trade/pipval;
         leverage=contract/risk_per_trade;
         if (leverage < max_leverage){
            if(new_sl>((std*3)*10000)) {
               find_bullet=True;
               bullet=i;
               break;
            }
         }
      }
   }
     
   if (stoploss_distance > 0 && stoploss_distance != new_sl) {
      modSL(new_sl);
   }
   
   
   
   stoploss_distance = new_sl;

   

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setGrid()
  {

   high = iHighest(NULL, PERIOD_D1, MODE_HIGH, 252, 1);
   high = iHigh(NULL, PERIOD_D1, high);

   low = iLowest(NULL, PERIOD_D1, MODE_LOW, 252, 1);
   low = iLow(NULL, PERIOD_D1, low);
   all_distance=high-low;
   zone_distance=all_distance/zone;

   for(int i=0;i<=zone;i++)
     {
      if(i==0)
        {
         zone_price[0]=low;
           } else {
         zone_price[i]=zone_price[i-1]+zone_distance;
        }
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printScreen()
  {

   ObjectsDeleteAll();

   int font_size=12;
   int line_spacing=20;
   int line_start=20;
   
   for(int i=0;i<=zone;i++)
     {
      ObjectCreate("zone"+i,OBJ_HLINE,0,Time[0],zone_price[i]);
      ObjectSet("zone"+i,OBJPROP_STYLE,STYLE_SOLID);
     }
     
   for(int i=0;i<=bullet;i++)
     {
      ObjectCreate("zone_mini"+i,OBJ_HLINE,0,Time[0],zone_mini_price[i]);
      ObjectSet("zone_mini"+i,OBJPROP_STYLE,STYLE_DOT);
      ObjectSet("zone_mini"+i, OBJPROP_COLOR, clrDeepSkyBlue);
     }

   ObjectCreate("RPZ",OBJ_LABEL,0,0,0);
   ObjectSetText("RPZ","Risk per Zone: "+risk_per_zone,font_size,"Verdana",White);
   ObjectSet("RPZ",OBJPROP_CORNER,0);
   ObjectSet("RPZ",OBJPROP_XDISTANCE,20);
   ObjectSet("RPZ",OBJPROP_YDISTANCE,line_start);

   ObjectCreate("RPT",OBJ_LABEL,0,0,0);
   ObjectSetText("RPT","Risk per Trade: "+risk_per_trade,font_size,"Verdana",White);
   ObjectSet("RPT",OBJPROP_CORNER,0);
   ObjectSet("RPT",OBJPROP_XDISTANCE,20);
   ObjectSet("RPT",OBJPROP_YDISTANCE,line_start+=line_spacing);

   ObjectCreate("ZD",OBJ_LABEL,0,0,0);
   ObjectSetText("ZD","Zone Distance(pips): "+zone_distance*10000,font_size,"Verdana",White);
   ObjectSet("ZD",OBJPROP_CORNER,0);
   ObjectSet("ZD",OBJPROP_XDISTANCE,20);
   ObjectSet("ZD",OBJPROP_YDISTANCE,line_start+=line_spacing);

   ObjectCreate("cash",OBJ_LABEL,0,0,0);
   ObjectSetText("cash","Cash: "+cash+", Zone: "+zone+", Bullet per Zone: "+bullet,font_size,"Verdana",White);
   ObjectSet("cash",OBJPROP_CORNER,0);
   ObjectSet("cash",OBJPROP_XDISTANCE,20);
   ObjectSet("cash",OBJPROP_YDISTANCE,line_start+=line_spacing);

   ObjectCreate("lv",OBJ_LABEL,0,0,0);
   ObjectSetText("lv","Leverage: "+leverage,font_size,"Verdana",White);
   ObjectSet("lv",OBJPROP_CORNER,0);
   ObjectSet("lv",OBJPROP_XDISTANCE,20);
   ObjectSet("lv",OBJPROP_YDISTANCE,line_start+=line_spacing);

   ObjectCreate("sld",OBJ_LABEL,0,0,0);
   ObjectSetText("sld","Stoploss Distance: "+stoploss_distance,font_size,"Verdana",White);
   ObjectSet("sld",OBJPROP_CORNER,0);
   ObjectSet("sld",OBJPROP_XDISTANCE,20);
   ObjectSet("sld",OBJPROP_YDISTANCE,line_start+=line_spacing);

   ObjectCreate("sd",OBJ_LABEL,0,0,0);
   ObjectSetText("sd","3 SD: "+(std*3)*10000,font_size,"Verdana",White);
   ObjectSet("sd",OBJPROP_CORNER,0);
   ObjectSet("sd",OBJPROP_XDISTANCE,20);
   ObjectSet("sd",OBJPROP_YDISTANCE,line_start+=line_spacing);

   ObjectCreate("hl",OBJ_LABEL,0,0,0);
   ObjectSetText("hl","High - Low: "+high+" - "+low,font_size,"Verdana",White);
   ObjectSet("hl",OBJPROP_CORNER,0);
   ObjectSet("hl",OBJPROP_XDISTANCE,20);
   ObjectSet("hl",OBJPROP_YDISTANCE,line_start+=line_spacing);

   ObjectCreate("currentzone",OBJ_LABEL,0,0,0);
   ObjectSetText("currentzone","Current Zone: "+current_zone,font_size,"Verdana",White);
   ObjectSet("currentzone",OBJPROP_CORNER,0);
   ObjectSet("currentzone",OBJPROP_XDISTANCE,20);
   ObjectSet("currentzone",OBJPROP_YDISTANCE,line_start+=line_spacing);
   
   ObjectCreate("currentzonemini",OBJ_LABEL,0,0,0);
   ObjectSetText("currentzonemini","Current Zone Mini: "+current_zone_mini,font_size,"Verdana",White);
   ObjectSet("currentzonemini",OBJPROP_CORNER,0);
   ObjectSet("currentzonemini",OBJPROP_XDISTANCE,20);
   ObjectSet("currentzonemini",OBJPROP_YDISTANCE,line_start+=line_spacing);
   
   ObjectCreate("canopen",OBJ_LABEL,0,0,0);
   ObjectSetText("canopen","Can Open: "+can_open,font_size,"Verdana",White);
   ObjectSet("canopen",OBJPROP_CORNER,0);
   ObjectSet("canopen",OBJPROP_XDISTANCE,20);
   ObjectSet("canopen",OBJPROP_YDISTANCE,line_start+=line_spacing);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int findCurrentlyZoneMini(double price){

   for (int i=0;i<=bullet;i++) {
   
      if (i == bullet){
         return i;
      }
      if (zone_mini_price[i] <= price && price <= zone_mini_price[i+1])
      {
         return i+1;
      }
   
   }
   return 0;

}
int findCurrentlyZone(double price)
  {

   for(int i=0;i<=zone;i++)
     {
      if(i==zone)
        {
         return i;
        }
      if(zone_price[i]<=price && price<=zone_price[i+1])
        {
         return i+1;
        }
     }
   return 0;

  }
//+------------------------------------------------------------------+
