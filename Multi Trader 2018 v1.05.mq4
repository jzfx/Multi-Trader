//+------------------------------------------------------------------+
//|                                      Multi Trader 2018 v1.05.mq4 |
//|                                Copyright 2018, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+

// 1.05 Avaiable modules:  Deinit reason,Apply/remove theme, Dashboard UI
// ,Price/PIP mode selection, Input Validation,Account_info,buy/Sell function
// ,magic_number,slippage, pull dashboard data, buy button pressed, sell button pressed
// ,update global variables, trade monitor, clear global variables, IsConnected Controls
// Expiry control,Check auto trading is enabled

#property copyright "Copyright 2018, Chamal Abayaratne"
#property link      "cabayaratne@gmail.com"
#property version   "1.05"
#property strict

// -- Processed values
double stop_loss_pips_p,tp_1_pips_p,tp_2_pips_p,tp_3_pips_p;  // -- Used for default lot sizes and pip values
string acc_name,acc_server; // save account name and account servers
int acc_number; //Account number
bool trading_allowed; // True: Trading enabled False: Disabled
double inf_array[2][5]; // Grab DashBoard data
double sorted_array[4];    // Grab Price data to sort
// -- Magic number
int magic_number = 999;
//-- Slippage
int slippage = 20;



//-- Default levels of pips
extern string Default_PIP_level_Settings="==============";
extern double stop_loss_pips = 50.0;
extern double tp_1_pips = 20.0;
extern double tp_1_lots = 0.02;
extern double tp_2_pips = 50.0;
extern double tp_2_lots = 0.01;
extern double tp_3_pips = 100.0;
extern double tp_3_lots = 0.01;

//-- Trade Management
extern string Trade_Management_Settings="==============";
extern bool enable_trade_management = True;
extern int trade_manage_pip_offset = +5.0;
extern int refresh_rate = 5;


extern string Other_Settings="==============";
//-- Default mode
extern bool start_with_pip_mode = True;
//-- Panel Anchor location
extern int panel_x = 10;   // X offset
extern int panel_y = 30;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Check if AutoTrading Is enabled
   if(!IsExpertEnabled()){Alert("Please enable Auto Trading");return INIT_FAILED;}
   // Check if expired
   if(is_expired()){Alert("Product Evaluation Period expired.");return INIT_FAILED;}

   // Check Account info and enable/disable trading
   get_account_info();
   // Apply Template and elements
   remove_elements();
   set_chart();
   draw_panel();
   // Adjust pip values based on broker
   adjust_pip_values();
   set_default_lots();
   // Check Default trading mode Pips or Price
   if(start_with_pip_mode){pips_button_pressed();}
   else{price_button_pressed();}
   // Set Event timer in seconds
   EventSetTimer(refresh_rate);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  //-- Remove Global Variables // sleep for 1 second(s) // Only when connected
  if(IsConnected()){Sleep(1000);clear_global_variables();}
  
  // Remove Template
  reset_chart();
  remove_elements();
  // Print Uninit reason
  Print(__FUNCTION__,"_Uninitalization reason code = ",getUninitReasonText(reason));
  }
  
//+------------------------------------------------------------------+
//| Chart event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Event ID
                  const long& lparam,   // Parameter of type long event
                  const double& dparam, // Parameter of type double event
                  const string& sparam  // Parameter of type string events
                  )
  {
  //-- For development
  //if(id==CHARTEVENT_OBJECT_CLICK){Comment("OBJ: ",sparam,"\nX: ",lparam,"\nY :",dparam);}
  
  if(id==CHARTEVENT_OBJECT_CLICK && sparam=="MLT_price_button"){price_button_pressed();}
  if(id==CHARTEVENT_OBJECT_CLICK && sparam=="MLT_pips_button"){pips_button_pressed();}
  
  if(id==CHARTEVENT_OBJECT_CLICK && sparam=="MLT_buy_button"){buy_button_pressed();}
  if(id==CHARTEVENT_OBJECT_CLICK && sparam=="MLT_sell_button"){sell_button_pressed();}
  }
  
  
//+------------------------------------------------------------------+
//| On timer function                                             |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
  if(enable_trade_management){trade_monitor();}
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| SET Template for MULTI TRADER                                    |
//+------------------------------------------------------------------+
void set_chart()
{  
   if(!ChartSetString(0,CHART_COMMENT,"  Multi Trader 2018 | Chamal Abayaratne")){Print(__FUNCTION__,": Chart Comment Set Fail");}
   if(!ChartSetInteger(0,CHART_MODE,0,CHART_CANDLES)){Print(__FUNCTION__,": Chart MODE Set to Japanese Candles Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_BACKGROUND,0,clrWhite)){Print(__FUNCTION__,": Chart COLOR_Background Set Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrBlack)){Print(__FUNCTION__,": Chart COLOR_FOREGROUND Set Fail");}
   if(!ChartSetInteger(0,CHART_SHOW_GRID,True)){Print(__FUNCTION__,": Chart GRID_SHOW Failed");}
   if(!ChartSetInteger(0,CHART_SHIFT,True)){Print(__FUNCTION__,": Chart set SHIFT Failed");}
   if(!ChartSetInteger(0,CHART_AUTOSCROLL,True)){Print(__FUNCTION__,": Chart set AUTOSCROLL Failed");}
   if(!ChartSetInteger(0,CHART_SHOW_VOLUMES,CHART_VOLUME_HIDE)){Print(__FUNCTION__,": Chart VOLUME_HIDE Failed");}
   if(!ChartSetInteger(0,CHART_COLOR_GRID,clrSilver)){Print(__FUNCTION__,": Chart COLOR_GRID Set Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_CHART_UP,clrGreen)){Print(__FUNCTION__,": Chart COLOR_CHART_UP Set Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrLime)){Print(__FUNCTION__,": Chart COLOR_CANDLE_BULL Set Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_CHART_DOWN,clrRed)){Print(__FUNCTION__,": Chart COLOR_CHART_DOWN Set Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrTomato)){Print(__FUNCTION__,": Chart COLOR_CANDLE_BULL Set Fail");}
   
   //Refresh
   ChartRedraw(0);
   
}

//+------------------------------------------------------------------+
//| SET Template for MULTI TRADER                                    |
//+------------------------------------------------------------------+
void reset_chart()
{  
   if(!ChartSetString(0,CHART_COMMENT,"Multi Trader Removed")){Print(__FUNCTION__,": Chart Comment Set Fail");}
   if(!ChartSetInteger(0,CHART_MODE,0,CHART_CANDLES)){Print(__FUNCTION__,": Chart MODE Set to Japanese Candles Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_BACKGROUND,0,clrBlack)){Print(__FUNCTION__,": Chart COLOR_Background Set Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrWhite)){Print(__FUNCTION__,": Chart COLOR_FOREGROUND Set Fail");}
   if(!ChartSetInteger(0,CHART_SHOW_GRID,True)){Print(__FUNCTION__,": Chart GRID_SHOW Failed");}
   if(!ChartSetInteger(0,CHART_SHIFT,False)){Print(__FUNCTION__,": Chart set SHIFT Failed");}
   if(!ChartSetInteger(0,CHART_AUTOSCROLL,True)){Print(__FUNCTION__,": Chart set AUTOSCROLL Failed");}
   if(!ChartSetInteger(0,CHART_SHOW_VOLUMES,CHART_VOLUME_HIDE)){Print(__FUNCTION__,": Chart VOLUME_HIDE Failed");}
   if(!ChartSetInteger(0,CHART_COLOR_GRID,clrLightSlateGray)){Print(__FUNCTION__,": Chart COLOR_GRID Set Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_CHART_UP,clrLime)){Print(__FUNCTION__,": Chart COLOR_CHART_UP Set Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrBlack)){Print(__FUNCTION__,": Chart COLOR_CANDLE_BULL Set Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_CHART_DOWN,clrLime)){Print(__FUNCTION__,": Chart COLOR_CHART_DOWN Set Fail");}
   if(!ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrWhite)){Print(__FUNCTION__,": Chart COLOR_CANDLE_BULL Set Fail");}
   
   //Refresh
   ChartRedraw(0);
}

  
//+------------------------------------------------------------------+
//| get text description- of Uninit                                  |
//+------------------------------------------------------------------+
string getUninitReasonText(int reasonCode)
  {
   string text="";
//---
   switch(reasonCode)
     {
      case REASON_ACCOUNT://
         text="Account was changed";break;
      case REASON_PROGRAM://
         text="ExpertRemove() function called";break;
      case REASON_CHARTCHANGE://
         text="Symbol or timeframe was changed";break;
      case REASON_TEMPLATE:
         text="A new template has been applied";break;
      case REASON_CHARTCLOSE://
         text="Chart was closed";break;
      case REASON_PARAMETERS://
         text="Input-parameter was changed";break;
      case REASON_RECOMPILE://
         text="Program "+__FILE__+" was recompiled";break;
      case REASON_REMOVE://
         text="Program "+__FILE__+" was removed from chart";break;
      case REASON_INITFAILED://
         text="init failure:OnInit() handler has returned a nonzero value";break;
      case REASON_CLOSE://
         text="Terminal has been closed";break;
      default:text="Unknown reason";
     }
//---
   return text;
  }
  
//+------------------------------------------------------------------+
//| Create Trading panel                                             |
//+------------------------------------------------------------------+
void draw_panel()
  {
//------------------ Create Back Panel ------------------------------+
  ObjectCreate(0,"MLT_panel_background",OBJ_RECTANGLE_LABEL,0,0,0);
  ObjectSetInteger(0,"MLT_panel_background",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_panel_background",OBJPROP_XDISTANCE,panel_x);
  ObjectSetInteger(0,"MLT_panel_background",OBJPROP_YDISTANCE,panel_y);
  ObjectSetInteger(0,"MLT_panel_background",OBJPROP_XSIZE,150);
  ObjectSetInteger(0,"MLT_panel_background",OBJPROP_YSIZE,300);
  ObjectSetInteger(0,"MLT_panel_background",OBJPROP_BGCOLOR,clrDimGray);
  ObjectSetInteger(0,"MLT_panel_background",OBJPROP_BORDER_TYPE,BORDER_FLAT);
//--- set flat border color (in Flat mode)
   ObjectSetInteger(0,"MLT_panel_background",OBJPROP_COLOR,clrAqua);
//--- set flat border line style
   ObjectSetInteger(0,"MLT_panel_background",OBJPROP_STYLE,STYLE_SOLID);
//--- set flat border width
   ObjectSetInteger(0,"MLT_panel_background",OBJPROP_WIDTH,2);
   set_common_properties("MLT_panel_background");

//------------------ Text Label: NAME ------------------------------+
  ObjectCreate(0,"MLT_TRADE_LABEL",OBJ_LABEL,0,0,0);
  ObjectSetInteger(0,"MLT_TRADE_LABEL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TRADE_LABEL",OBJPROP_XDISTANCE,panel_x+25);
  ObjectSetInteger(0,"MLT_TRADE_LABEL",OBJPROP_YDISTANCE,panel_y+8);
  ObjectSetInteger(0,"MLT_TRADE_LABEL",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_TRADE_LABEL",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TRADE_LABEL",OBJPROP_TEXT,"Multi Trader Panel");
  ObjectSetInteger(0,"MLT_TRADE_LABEL",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_TRADE_LABEL");

//------------------ Buy Button ------------------------------+
  ObjectCreate(0,"MLT_buy_button",OBJ_BUTTON,0,0,0);
  ObjectSetInteger(0,"MLT_buy_button",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_buy_button",OBJPROP_XDISTANCE,panel_x+10);
  ObjectSetInteger(0,"MLT_buy_button",OBJPROP_YDISTANCE,panel_y+30);
  ObjectSetInteger(0,"MLT_buy_button",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_buy_button",OBJPROP_YSIZE,20);
  ObjectSetInteger(0,"MLT_buy_button",OBJPROP_BGCOLOR,clrBlue);
  ObjectSetString(0,"MLT_buy_button",OBJPROP_TEXT,"BUY");
  ObjectSetInteger(0,"MLT_buy_button",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_buy_button");

//------------------ Sell Button ------------------------------+
  ObjectCreate(0,"MLT_sell_button",OBJ_BUTTON,0,0,0);
  ObjectSetInteger(0,"MLT_sell_button",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_sell_button",OBJPROP_XDISTANCE,panel_x+80);
  ObjectSetInteger(0,"MLT_sell_button",OBJPROP_YDISTANCE,panel_y+30);
  ObjectSetInteger(0,"MLT_sell_button",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_sell_button",OBJPROP_YSIZE,20);
  ObjectSetInteger(0,"MLT_sell_button",OBJPROP_BGCOLOR,clrRed);
  ObjectSetString(0,"MLT_sell_button",OBJPROP_TEXT,"SELL");
  ObjectSetInteger(0,"MLT_sell_button",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_sell_button");

//------------------ Price Button ------------------------------+
  ObjectCreate(0,"MLT_price_button",OBJ_BUTTON,0,0,0);
  ObjectSetInteger(0,"MLT_price_button",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_price_button",OBJPROP_XDISTANCE,panel_x+10);
  ObjectSetInteger(0,"MLT_price_button",OBJPROP_YDISTANCE,panel_y+60);
  ObjectSetInteger(0,"MLT_price_button",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_price_button",OBJPROP_YSIZE,20);
  ObjectSetInteger(0,"MLT_price_button",OBJPROP_BGCOLOR,clrGoldenrod);
  ObjectSetString(0,"MLT_price_button",OBJPROP_TEXT,"PRICE");
  ObjectSetInteger(0,"MLT_price_button",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_price_button");
  
//------------------ Pips Button ------------------------------+
  ObjectCreate(0,"MLT_pips_button",OBJ_BUTTON,0,0,0);
  ObjectSetInteger(0,"MLT_pips_button",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_pips_button",OBJPROP_XDISTANCE,panel_x+80);
  ObjectSetInteger(0,"MLT_pips_button",OBJPROP_YDISTANCE,panel_y+60);
  ObjectSetInteger(0,"MLT_pips_button",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_pips_button",OBJPROP_YSIZE,20);
  ObjectSetInteger(0,"MLT_pips_button",OBJPROP_BGCOLOR,clrGoldenrod);
  ObjectSetString(0,"MLT_pips_button",OBJPROP_TEXT,"PIPS");
  ObjectSetInteger(0,"MLT_pips_button",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_pips_button");
  
//------------------ Text Label: Stop Loss ------------------------------+
  ObjectCreate(0,"MLT_SL_LABEL",OBJ_LABEL,0,0,0);
  ObjectSetInteger(0,"MLT_SL_LABEL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_SL_LABEL",OBJPROP_XDISTANCE,panel_x+10);
  ObjectSetInteger(0,"MLT_SL_LABEL",OBJPROP_YDISTANCE,panel_y+90);
  ObjectSetInteger(0,"MLT_SL_LABEL",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_SL_LABEL",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_SL_LABEL",OBJPROP_TEXT,"Set Stop Loss:");
  ObjectSetInteger(0,"MLT_SL_LABEL",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_SL_LABEL");
  
//------------------ Text Label: SL input ------------------------------+
  ObjectCreate(0,"MLT_SL_INPUT",OBJ_EDIT,0,0,0);
  ObjectSetInteger(0,"MLT_SL_INPUT",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_SL_INPUT",OBJPROP_XDISTANCE,panel_x+10);
  ObjectSetInteger(0,"MLT_SL_INPUT",OBJPROP_YDISTANCE,panel_y+110);
  ObjectSetInteger(0,"MLT_SL_INPUT",OBJPROP_XSIZE,70);
  ObjectSetInteger(0,"MLT_SL_INPUT",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_SL_INPUT",OBJPROP_TEXT,"Enter SL");
  ObjectSetInteger(0,"MLT_SL_INPUT",OBJPROP_COLOR,clrBlack);
  set_common_properties("MLT_SL_INPUT");
  
//------------------ Text Label: TP1 ------------------------------+
  ObjectCreate(0,"MLT_TP1_LABEL",OBJ_LABEL,0,0,0);
  ObjectSetInteger(0,"MLT_TP1_LABEL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP1_LABEL",OBJPROP_XDISTANCE,panel_x+10);
  ObjectSetInteger(0,"MLT_TP1_LABEL",OBJPROP_YDISTANCE,panel_y+140);
  ObjectSetInteger(0,"MLT_TP1_LABEL",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_TP1_LABEL",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP1_LABEL",OBJPROP_TEXT,"TP 1:");
  ObjectSetInteger(0,"MLT_TP1_LABEL",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_TP1_LABEL");
  
//------------------ Text Label: TP1 input ------------------------------+
  ObjectCreate(0,"MLT_TP1_INPUT",OBJ_EDIT,0,0,0);
  ObjectSetInteger(0,"MLT_TP1_INPUT",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP1_INPUT",OBJPROP_XDISTANCE,panel_x+10);
  ObjectSetInteger(0,"MLT_TP1_INPUT",OBJPROP_YDISTANCE,panel_y+160);
  ObjectSetInteger(0,"MLT_TP1_INPUT",OBJPROP_XSIZE,70);
  ObjectSetInteger(0,"MLT_TP1_INPUT",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP1_INPUT",OBJPROP_TEXT,"Enter TP1");
  ObjectSetInteger(0,"MLT_TP1_INPUT",OBJPROP_COLOR,clrBlack);
  set_common_properties("MLT_TP1_INPUT");
  
//------------------ Text Label: TP1 LOT ------------------------------+
  ObjectCreate(0,"MLT_TP1_LOT_LABEL",OBJ_LABEL,0,0,0);
  ObjectSetInteger(0,"MLT_TP1_LOT_LABEL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP1_LOT_LABEL",OBJPROP_XDISTANCE,panel_x+90);
  ObjectSetInteger(0,"MLT_TP1_LOT_LABEL",OBJPROP_YDISTANCE,panel_y+140);
  ObjectSetInteger(0,"MLT_TP1_LOT_LABEL",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_TP1_LOT_LABEL",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP1_LOT_LABEL",OBJPROP_TEXT,"Lots:");
  ObjectSetInteger(0,"MLT_TP1_LOT_LABEL",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_TP1_LOT_LABEL");
  
//------------------ Text Label: TP1 LOT input ------------------------------+
  ObjectCreate(0,"MLT_TP1_LOT_INPUT",OBJ_EDIT,0,0,0);
  ObjectSetInteger(0,"MLT_TP1_LOT_INPUT",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP1_LOT_INPUT",OBJPROP_XDISTANCE,panel_x+90);
  ObjectSetInteger(0,"MLT_TP1_LOT_INPUT",OBJPROP_YDISTANCE,panel_y+160);
  ObjectSetInteger(0,"MLT_TP1_LOT_INPUT",OBJPROP_XSIZE,50);
  ObjectSetInteger(0,"MLT_TP1_LOT_INPUT",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP1_LOT_INPUT",OBJPROP_TEXT,"0.01");
  ObjectSetInteger(0,"MLT_TP1_LOT_INPUT",OBJPROP_COLOR,clrBlack);
  set_common_properties("MLT_TP1_LOT_INPUT");
  
//------------------ Text Label: TP2 ------------------------------+
  ObjectCreate(0,"MLT_TP2_LABEL",OBJ_LABEL,0,0,0);
  ObjectSetInteger(0,"MLT_TP2_LABEL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP2_LABEL",OBJPROP_XDISTANCE,panel_x+10);
  ObjectSetInteger(0,"MLT_TP2_LABEL",OBJPROP_YDISTANCE,panel_y+190);
  ObjectSetInteger(0,"MLT_TP2_LABEL",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_TP2_LABEL",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP2_LABEL",OBJPROP_TEXT,"TP 2:");
  ObjectSetInteger(0,"MLT_TP2_LABEL",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_TP2_LABEL");
  
//------------------ Text Label: TP2 input ------------------------------+
  ObjectCreate(0,"MLT_TP2_INPUT",OBJ_EDIT,0,0,0);
  ObjectSetInteger(0,"MLT_TP2_INPUT",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP2_INPUT",OBJPROP_XDISTANCE,panel_x+10);
  ObjectSetInteger(0,"MLT_TP2_INPUT",OBJPROP_YDISTANCE,panel_y+210);
  ObjectSetInteger(0,"MLT_TP2_INPUT",OBJPROP_XSIZE,70);
  ObjectSetInteger(0,"MLT_TP2_INPUT",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP2_INPUT",OBJPROP_TEXT,"Enter TP2");
  ObjectSetInteger(0,"MLT_TP2_INPUT",OBJPROP_COLOR,clrBlack);
  set_common_properties("MLT_TP2_INPUT");
  
//------------------ Text Label: TP2 LOT ------------------------------+
  ObjectCreate(0,"MLT_TP2_LOT_LABEL",OBJ_LABEL,0,0,0);
  ObjectSetInteger(0,"MLT_TP2_LOT_LABEL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP2_LOT_LABEL",OBJPROP_XDISTANCE,panel_x+90);
  ObjectSetInteger(0,"MLT_TP2_LOT_LABEL",OBJPROP_YDISTANCE,panel_y+190);
  ObjectSetInteger(0,"MLT_TP2_LOT_LABEL",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_TP2_LOT_LABEL",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP2_LOT_LABEL",OBJPROP_TEXT,"Lots:");
  ObjectSetInteger(0,"MLT_TP2_LOT_LABEL",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_TP2_LOT_LABEL");
  
//------------------ Text Label: TP2 LOT input ------------------------------+
  ObjectCreate(0,"MLT_TP2_LOT_INPUT",OBJ_EDIT,0,0,0);
  ObjectSetInteger(0,"MLT_TP2_LOT_INPUT",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP2_LOT_INPUT",OBJPROP_XDISTANCE,panel_x+90);
  ObjectSetInteger(0,"MLT_TP2_LOT_INPUT",OBJPROP_YDISTANCE,panel_y+210);
  ObjectSetInteger(0,"MLT_TP2_LOT_INPUT",OBJPROP_XSIZE,50);
  ObjectSetInteger(0,"MLT_TP2_LOT_INPUT",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP2_LOT_INPUT",OBJPROP_TEXT,"0.01");
  ObjectSetInteger(0,"MLT_TP2_LOT_INPUT",OBJPROP_COLOR,clrBlack);
  set_common_properties("MLT_TP2_LOT_INPUT");

//------------------ Text Label: TP3 ------------------------------+
  ObjectCreate(0,"MLT_TP3_LABEL",OBJ_LABEL,0,0,0);
  ObjectSetInteger(0,"MLT_TP3_LABEL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP3_LABEL",OBJPROP_XDISTANCE,panel_x+10);
  ObjectSetInteger(0,"MLT_TP3_LABEL",OBJPROP_YDISTANCE,panel_y+240);
  ObjectSetInteger(0,"MLT_TP3_LABEL",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_TP3_LABEL",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP3_LABEL",OBJPROP_TEXT,"TP 3:");
  ObjectSetInteger(0,"MLT_TP3_LABEL",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_TP3_LABEL");
  
//------------------ Text Label: TP3 input ------------------------------+
  ObjectCreate(0,"MLT_TP3_INPUT",OBJ_EDIT,0,0,0);
  ObjectSetInteger(0,"MLT_TP3_INPUT",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP3_INPUT",OBJPROP_XDISTANCE,panel_x+10);
  ObjectSetInteger(0,"MLT_TP3_INPUT",OBJPROP_YDISTANCE,panel_y+260);
  ObjectSetInteger(0,"MLT_TP3_INPUT",OBJPROP_XSIZE,70);
  ObjectSetInteger(0,"MLT_TP3_INPUT",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP3_INPUT",OBJPROP_TEXT,"Enter TP3");
  ObjectSetInteger(0,"MLT_TP3_INPUT",OBJPROP_COLOR,clrBlack);
  set_common_properties("MLT_TP3_INPUT");
  
//------------------ Text Label: TP3 LOT ------------------------------+
  ObjectCreate(0,"MLT_TP3_LOT_LABEL",OBJ_LABEL,0,0,0);
  ObjectSetInteger(0,"MLT_TP3_LOT_LABEL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP3_LOT_LABEL",OBJPROP_XDISTANCE,panel_x+90);
  ObjectSetInteger(0,"MLT_TP3_LOT_LABEL",OBJPROP_YDISTANCE,panel_y+240);
  ObjectSetInteger(0,"MLT_TP3_LOT_LABEL",OBJPROP_XSIZE,60);
  ObjectSetInteger(0,"MLT_TP3_LOT_LABEL",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP3_LOT_LABEL",OBJPROP_TEXT,"Lots:");
  ObjectSetInteger(0,"MLT_TP3_LOT_LABEL",OBJPROP_COLOR,clrWhite);
  set_common_properties("MLT_TP3_LOT_LABEL");
  
//------------------ Text Label: TP3 LOT input ------------------------------+
  ObjectCreate(0,"MLT_TP3_LOT_INPUT",OBJ_EDIT,0,0,0);
  ObjectSetInteger(0,"MLT_TP3_LOT_INPUT",OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSetInteger(0,"MLT_TP3_LOT_INPUT",OBJPROP_XDISTANCE,panel_x+90);
  ObjectSetInteger(0,"MLT_TP3_LOT_INPUT",OBJPROP_YDISTANCE,panel_y+260);
  ObjectSetInteger(0,"MLT_TP3_LOT_INPUT",OBJPROP_XSIZE,50);
  ObjectSetInteger(0,"MLT_TP3_LOT_INPUT",OBJPROP_YSIZE,20);
  ObjectSetString(0,"MLT_TP3_LOT_INPUT",OBJPROP_TEXT,"0.01");
  ObjectSetInteger(0,"MLT_TP3_LOT_INPUT",OBJPROP_COLOR,clrBlack);
  set_common_properties("MLT_TP3_LOT_INPUT");

  ChartRedraw();
  }
  
//+------------------------------------------------------------------+
//| Set common Obj properties                                        |
//+------------------------------------------------------------------+
void set_common_properties(string obj_name)
{
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(0,obj_name,OBJPROP_BACK,False);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(0,obj_name,OBJPROP_SELECTABLE,False);
   ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,False);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,True);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(0,obj_name,OBJPROP_ZORDER,0);
}

//+------------------------------------------------------------------+
//| Remove Trading panel                                             |
//+------------------------------------------------------------------+
void remove_elements()
  {
  ObjectsDeleteAll(0,"MLT_");
  ChartRedraw();
  }
  
//+------------------------------------------------------------------+
//| Price Button pressed                                             |
//+------------------------------------------------------------------+
void price_button_pressed()
  {
  ObjectSetInteger(0,"MLT_price_button",OBJPROP_STATE,True);
  ObjectSetInteger(0,"MLT_pips_button",OBJPROP_STATE,False);
  
  ObjectSetString(0,"MLT_SL_INPUT",OBJPROP_TEXT,DoubleToString(Ask-stop_loss_pips_p*Point,Digits));
  ObjectSetString(0,"MLT_TP1_INPUT",OBJPROP_TEXT,DoubleToString(Ask+tp_1_pips_p*Point,Digits));
  ObjectSetString(0,"MLT_TP2_INPUT",OBJPROP_TEXT,DoubleToString(Ask+tp_2_pips_p*Point,Digits));
  ObjectSetString(0,"MLT_TP3_INPUT",OBJPROP_TEXT,DoubleToString(Ask+tp_3_pips_p*Point,Digits));
  
  ChartRedraw();
  }
  
//+------------------------------------------------------------------+
//| Pips Button pressed                                              |
//+------------------------------------------------------------------+
void pips_button_pressed()
  {
  ObjectSetInteger(0,"MLT_price_button",OBJPROP_STATE,False);
  ObjectSetInteger(0,"MLT_pips_button",OBJPROP_STATE,True);
   
  if(Digits==3 || Digits==5)
     {
     ObjectSetString(0,"MLT_SL_INPUT",OBJPROP_TEXT,DoubleToString(stop_loss_pips_p/10,1));
     ObjectSetString(0,"MLT_TP1_INPUT",OBJPROP_TEXT,DoubleToString(tp_1_pips_p/10,1));
     ObjectSetString(0,"MLT_TP2_INPUT",OBJPROP_TEXT,DoubleToString(tp_2_pips_p/10,1));
     ObjectSetString(0,"MLT_TP3_INPUT",OBJPROP_TEXT,DoubleToString(tp_3_pips_p/10,1));
     }
  if(Digits==2 || Digits==4)
     {
     ObjectSetString(0,"MLT_SL_INPUT",OBJPROP_TEXT,DoubleToString(stop_loss_pips_p,1));
     ObjectSetString(0,"MLT_TP1_INPUT",OBJPROP_TEXT,DoubleToString(tp_1_pips_p,1));
     ObjectSetString(0,"MLT_TP2_INPUT",OBJPROP_TEXT,DoubleToString(tp_2_pips_p,1));
     ObjectSetString(0,"MLT_TP3_INPUT",OBJPROP_TEXT,DoubleToString(tp_3_pips_p,1));
     }
  ChartRedraw();
  }
  
//+------------------------------------------------------------------+
//| Adjust pip values                                                |
//+------------------------------------------------------------------+
void adjust_pip_values()
   {
   if(Digits==3 || Digits==5)
      {
      stop_loss_pips_p = int(stop_loss_pips*10);
      tp_1_pips_p = int(tp_1_pips*10);
      tp_2_pips_p = int(tp_2_pips*10);
      tp_3_pips_p = int(tp_3_pips*10);
      }
   if(Digits==2 || Digits==4)
      {
      stop_loss_pips_p = int(stop_loss_pips);
      tp_1_pips_p = int(tp_1_pips);
      tp_2_pips_p = int(tp_2_pips);
      tp_3_pips_p = int(tp_3_pips);
      }
   }
   
//+------------------------------------------------------------------+
//| Set default lot values                                           |
//+------------------------------------------------------------------+
void set_default_lots()
  {
  ResetLastError();
  ObjectSetString(0,"MLT_TP1_LOT_INPUT",OBJPROP_TEXT,DoubleToString(tp_1_lots,2));
  ObjectSetString(0,"MLT_TP2_LOT_INPUT",OBJPROP_TEXT,DoubleToString(tp_2_lots,2));
  ObjectSetString(0,"MLT_TP3_LOT_INPUT",OBJPROP_TEXT,DoubleToString(tp_3_lots,2));
  }
  
//+------------------------------------------------------------------+
//| Input double validatior                                          |
//+------------------------------------------------------------------+
bool input_double_validator()
  {
   string sl_input_txt= ObjectGetString(0,"MLT_SL_INPUT",OBJPROP_TEXT);
   string tp1_input_txt= ObjectGetString(0,"MLT_TP1_INPUT",OBJPROP_TEXT);
   string tp2_input_txt= ObjectGetString(0,"MLT_TP2_INPUT",OBJPROP_TEXT);
   string tp3_input_txt= ObjectGetString(0,"MLT_TP3_INPUT",OBJPROP_TEXT);
   
   string tp1_lot_txt= ObjectGetString(0,"MLT_TP1_LOT_INPUT",OBJPROP_TEXT);
   string tp2_lot_txt= ObjectGetString(0,"MLT_TP2_LOT_INPUT",OBJPROP_TEXT);
   string tp3_lot_txt= ObjectGetString(0,"MLT_TP3_LOT_INPUT",OBJPROP_TEXT);  

   if(ObjectGetInteger(0,"MLT_pips_button",OBJPROP_STATE)) // If Pips is selected
      {
      // Any type of numerical input is accepted.
      //if(sl_input_txt!=DoubleToString(StringToDouble(sl_input_txt),1)){return False;}
      //if(tp1_input_txt!=DoubleToString(StringToDouble(tp1_input_txt),1)){return False;}
      //if(tp2_input_txt!=DoubleToString(StringToDouble(tp2_input_txt),1)){return False;}
      //if(tp3_input_txt!=DoubleToString(StringToDouble(tp3_input_txt),1)){return False;}  
      }
  else // if Price is selected
      {
      if(sl_input_txt!=DoubleToString(StringToDouble(sl_input_txt),Digits)){Alert("Error: Exact price required");return False;}
      if(tp1_input_txt!=DoubleToString(StringToDouble(tp1_input_txt),Digits)){Alert("Error: Exact price required");return False;}
      if(tp2_input_txt!=DoubleToString(StringToDouble(tp2_input_txt),Digits)){Alert("Error: Exact price required");return False;}
      if(tp3_input_txt!=DoubleToString(StringToDouble(tp3_input_txt),Digits)){Alert("Error: Exact price required");return False;}     
      }
      
   if(tp1_lot_txt!=DoubleToString(StringToDouble(tp1_lot_txt),2)){Alert("Error: Enter lots in 00.00 format.");return False;}
   if(tp2_lot_txt!=DoubleToString(StringToDouble(tp2_lot_txt),2)){Alert("Error: Enter lots in 00.00 format.");return False;}
   if(tp3_lot_txt!=DoubleToString(StringToDouble(tp3_lot_txt),2)){Alert("Error: Enter lots in 00.00 format.");return False;} 
   
   // Check for minus values
   if(StringToDouble(sl_input_txt)<0){Alert("Negative values can't be entered.");return False;}
   if(StringToDouble(tp1_input_txt)<0){Alert("Negative values can't be entered.");return False;}
   if(StringToDouble(tp2_input_txt)<0){Alert("Negative values can't be entered.");return False;}
   if(StringToDouble(tp3_input_txt)<0){Alert("Negative values can't be entered.");return False;}
   
   if(StringToDouble(tp1_lot_txt)<0){Alert("Negative values can't be entered.");return False;}
   if(StringToDouble(tp2_lot_txt)<0){Alert("Negative values can't be entered.");return False;}
   if(StringToDouble(tp3_lot_txt)<0){Alert("Negative values can't be entered.");return False;}
   
  return True;
  }
  
//+------------------------------------------------------------------+
//| Get Account Info                                                 |
//+------------------------------------------------------------------+
void get_account_info()
   {
   acc_name=AccountName();
   acc_number=AccountNumber();
   acc_server=AccountServer();
   if(IsDemo()){trading_allowed=True;}
   else{trading_allowed=False;}
   Print("Name: ",acc_name,",Number: ",acc_number,",Server: ",acc_server);
   }
   
//+------------------------------------------------------------------+
//| Check expiry                                                     |
//+------------------------------------------------------------------+

bool is_expired()
{
   datetime date=D'2019.01.01 00:00:01';
   if(date<Time[0]){return True;}
   else{return False;}
}
   
//+------------------------------------------------------------------+
//| Buy Sell Order                                                   |
//+------------------------------------------------------------------+
int order_open(string symbol,double lot_size,int trade_type,double stop_loss,double take_profit)
   {
   int boolean_val;
   int order_ticket=-1;
   double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
   lot_size = NormalizeDouble(lot_size,2);
   stop_loss = NormalizeDouble(stop_loss,Digits);
   take_profit = NormalizeDouble(take_profit,Digits);
   
   if(trade_type==OP_BUY)
      {
      if((Ask+minstoplevel*Point)>take_profit){Alert("Broker: Invalid Take Profit");return -1;}
      if((Ask-minstoplevel*Point)<stop_loss){Alert("Broker: Invalid Stop Loss");return -1;}
      order_ticket = OrderSend(symbol,trade_type,lot_size,Ask,slippage,0,0,"MLT",magic_number);
      if(order_ticket==-1){Alert("Order Not opened! Check journal");return -1;}
      boolean_val=OrderSelect(order_ticket,SELECT_BY_TICKET,MODE_TRADES);
      if(OrderModify(OrderTicket(),OrderOpenPrice(),stop_loss,take_profit,0)==False)
         {
         Alert("Server: SL or TP cannot be set: ",OrderTicket(),".Check with broker/journal. Unmanagable order will close immediately");
         boolean_val=OrderClose(OrderTicket(),OrderLots(),Bid,slippage);
         return -1;
         }
      }
   if(trade_type==OP_SELL)
      {
      if((Bid-minstoplevel*Point)<take_profit){Alert("Broker: Invalid Take Profit");return -1;}
      if((Bid+minstoplevel*Point)>stop_loss){Alert("Broker: Invalid Stop Loss");return -1;}
      order_ticket = OrderSend(symbol,trade_type,lot_size,Bid,slippage,0,0,"MLT",magic_number);
      if(order_ticket==-1){Alert("Order Not opened! Check journal");return -1;}
      boolean_val=OrderSelect(order_ticket,SELECT_BY_TICKET,MODE_TRADES);
      if(OrderModify(OrderTicket(),OrderOpenPrice(),stop_loss,take_profit,0)==False)
         {
         Alert("Server: SL or TP cannot be set: ",OrderTicket(),".Check with broker/journal. Unmanagable order will close immediately");
         boolean_val=OrderClose(OrderTicket(),OrderLots(),Ask,slippage);
         return -1;
         }
      }
   return order_ticket;
   }

//+------------------------------------------------------------------+
//| Pull Data                                                        |
//+------------------------------------------------------------------+
void pull_dashboard_data(int buy_or_sell)
{
   double sl_input_val= 0;
   double tp1_input_val= 0;
   double tp2_input_val= 0;
   double tp3_input_val= 0;
   double entry_val= 0;

   double tp1_lot_val= StringToDouble(ObjectGetString(0,"MLT_TP1_LOT_INPUT",OBJPROP_TEXT));
   double tp2_lot_val= StringToDouble(ObjectGetString(0,"MLT_TP2_LOT_INPUT",OBJPROP_TEXT));
   double tp3_lot_val= StringToDouble(ObjectGetString(0,"MLT_TP3_LOT_INPUT",OBJPROP_TEXT)); 

   if(ObjectGetInteger(0,"MLT_pips_button",OBJPROP_STATE)) // If Pips is selected
      {
      if(buy_or_sell==OP_BUY && (Digits==3 || Digits==5))
         {
         sl_input_val= Ask-StringToDouble(ObjectGetString(0,"MLT_SL_INPUT",OBJPROP_TEXT))*10*Point;
         tp1_input_val=Ask+StringToDouble(ObjectGetString(0,"MLT_TP1_INPUT",OBJPROP_TEXT))*10*Point;
         tp2_input_val=Ask+StringToDouble(ObjectGetString(0,"MLT_TP2_INPUT",OBJPROP_TEXT))*10*Point;
         tp3_input_val=Ask+StringToDouble(ObjectGetString(0,"MLT_TP3_INPUT",OBJPROP_TEXT))*10*Point;
         }
      if(buy_or_sell==OP_BUY && (Digits==2 || Digits==4))
         {
         sl_input_val= Ask-StringToDouble(ObjectGetString(0,"MLT_SL_INPUT",OBJPROP_TEXT))*Point;
         tp1_input_val=Ask+StringToDouble(ObjectGetString(0,"MLT_TP1_INPUT",OBJPROP_TEXT))*Point;
         tp2_input_val=Ask+StringToDouble(ObjectGetString(0,"MLT_TP2_INPUT",OBJPROP_TEXT))*Point;
         tp3_input_val=Ask+StringToDouble(ObjectGetString(0,"MLT_TP3_INPUT",OBJPROP_TEXT))*Point;
         }
         
      if(buy_or_sell==OP_SELL && (Digits==3 || Digits==5))
         {
         sl_input_val= Bid+StringToDouble(ObjectGetString(0,"MLT_SL_INPUT",OBJPROP_TEXT))*10*Point;
         tp1_input_val=Bid-StringToDouble(ObjectGetString(0,"MLT_TP1_INPUT",OBJPROP_TEXT))*10*Point;
         tp2_input_val=Bid-StringToDouble(ObjectGetString(0,"MLT_TP2_INPUT",OBJPROP_TEXT))*10*Point;
         tp3_input_val=Bid-StringToDouble(ObjectGetString(0,"MLT_TP3_INPUT",OBJPROP_TEXT))*10*Point;
         }
      if(buy_or_sell==OP_SELL && (Digits==2 || Digits==4))
         {
         sl_input_val= Bid+StringToDouble(ObjectGetString(0,"MLT_SL_INPUT",OBJPROP_TEXT))*Point;
         tp1_input_val=Bid-StringToDouble(ObjectGetString(0,"MLT_TP1_INPUT",OBJPROP_TEXT))*Point;
         tp2_input_val=Bid-StringToDouble(ObjectGetString(0,"MLT_TP2_INPUT",OBJPROP_TEXT))*Point;
         tp3_input_val=Bid-StringToDouble(ObjectGetString(0,"MLT_TP3_INPUT",OBJPROP_TEXT))*Point;
         }
      }
  else // if Price is selected
      {
      sl_input_val= StringToDouble(ObjectGetString(0,"MLT_SL_INPUT",OBJPROP_TEXT));
      tp1_input_val= StringToDouble(ObjectGetString(0,"MLT_TP1_INPUT",OBJPROP_TEXT));
      tp2_input_val= StringToDouble(ObjectGetString(0,"MLT_TP2_INPUT",OBJPROP_TEXT));
      tp3_input_val= StringToDouble(ObjectGetString(0,"MLT_TP3_INPUT",OBJPROP_TEXT));
      }
      
   // Preprocess data before export
   if(tp1_lot_val==0){tp1_input_val=0.0;}
   if(tp2_lot_val==0){tp2_input_val=0.0;}
   if(tp3_lot_val==0){tp3_input_val=0.0;}
   
   inf_array[0][0] =sl_input_val;      // Stop value
   inf_array[1][0] =-1;                // No lots for stop
   inf_array[0][1] =entry_val;         // Entry price
   inf_array[1][1] =-1;               // No lots for lots
   inf_array[0][2] =tp1_input_val;     // TP 1 level
   inf_array[1][2] =tp1_lot_val;       // TP 1 lots
   inf_array[0][3] =tp2_input_val;     // TP 2 level
   inf_array[1][3] =tp2_lot_val;       // TP 2 lots  
   inf_array[0][4] =tp3_input_val;     // TP 3 level
   inf_array[1][4] =tp3_lot_val;       // TP 3 lots 

   //--- Create a string for trade management
   if(buy_or_sell==OP_BUY)
      {
      entry_val=Ask;
      sorted_array[0] = entry_val;
      sorted_array[1] = tp1_input_val;
      sorted_array[2] = tp2_input_val;
      sorted_array[3] = tp3_input_val;
      ArraySort(sorted_array,WHOLE_ARRAY,0,MODE_DESCEND);
      } 
   if(buy_or_sell==OP_SELL)
      {
      entry_val=Bid;
      sorted_array[0] = entry_val;
      sorted_array[1] = tp1_input_val;
      sorted_array[2] = tp2_input_val;
      sorted_array[3] = tp3_input_val;
      ArraySort(sorted_array,WHOLE_ARRAY,0,MODE_ASCEND);
      } 
   
   return;
}

//+------------------------------------------------------------------+
//| Buy Button pressed                                               |
//+------------------------------------------------------------------+
void buy_button_pressed()
{
// -- Snippet for authorization
if(!trading_allowed)
   {
   Alert("Sorry Trading is not allowed in this account. Please buy paid version");
   ObjectSetInteger(0,"MLT_buy_button",OBJPROP_STATE,False);
   return;
   }
   
// -- Snippet to check whther connected to server
if(!IsConnected())
   {
   Alert("Error: No Connection");
   ObjectSetInteger(0,"MLT_buy_button",OBJPROP_STATE,False);
   return;
   }
   
   
if(ObjectGetInteger(0,"MLT_buy_button",OBJPROP_STATE)==True) // Make Sure button is releasd before operation
{
  if(!input_double_validator())
   {
   ObjectSetInteger(0,"MLT_buy_button",OBJPROP_STATE,False);
   return;// Return if validation fails and reset button
   } 
   
  pull_dashboard_data(OP_BUY); // Pull dashboard data to arrays
  
  //-- open TP 1 trade
  if(inf_array[0][2]!=0)
  {
  int ticket=order_open(Symbol(),inf_array[1][2],OP_BUY,inf_array[0][0],inf_array[0][2]);
  if(ticket==-1)
   {
   ObjectSetInteger(0,"MLT_buy_button",OBJPROP_STATE,False);
   return; // exit if Open failure.
   } 
   //-- Create Global variable 
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_0"),sorted_array[0]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_1"),sorted_array[1]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_2"),sorted_array[2]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_3"),sorted_array[3]);
  }//------- end of TP 1--------
  
  //-- open TP 2 trade
  if(inf_array[0][3]!=0)
  {
  int ticket=order_open(Symbol(),inf_array[1][3],OP_BUY,inf_array[0][0],inf_array[0][3]);
  if(ticket==-1)
   {
   ObjectSetInteger(0,"MLT_buy_button",OBJPROP_STATE,False);
   return; // exit if Open failure.
   } 
   //-- Create Global variable 
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_0"),sorted_array[0]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_1"),sorted_array[1]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_2"),sorted_array[2]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_3"),sorted_array[3]);
  }//------- end of TP 2--------

  //-- open TP 3 trade
  if(inf_array[0][4]!=0)
  {
  int ticket=order_open(Symbol(),inf_array[1][4],OP_BUY,inf_array[0][0],inf_array[0][4]);
  if(ticket==-1)
   {
   ObjectSetInteger(0,"MLT_buy_button",OBJPROP_STATE,False);
   return; // exit if Open failure.
   } 
   //-- Create Global variable 
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_0"),sorted_array[0]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_1"),sorted_array[1]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_2"),sorted_array[2]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_3"),sorted_array[3]);
  }//------- end of TP 3--------
}
Sleep(250);
ObjectSetInteger(0,"MLT_buy_button",OBJPROP_STATE,False); // Release buy button
return;
}

//+------------------------------------------------------------------+
//| Sell Button pressed                                               |
//+------------------------------------------------------------------+
void sell_button_pressed()
{
// -- Snippet for authorization
if(!trading_allowed)
   {
   Alert("Sorry Trading is not allowed in this account. Please buy paid version");
   ObjectSetInteger(0,"MLT_sell_button",OBJPROP_STATE,False);
   return;
   }
   
// -- Snippet to check whther connected to server
if(!IsConnected())
   {
   Alert("Error: No Connection");
   ObjectSetInteger(0,"MLT_sell_button",OBJPROP_STATE,False);
   return;
   }
   
   
if(ObjectGetInteger(0,"MLT_sell_button",OBJPROP_STATE)==True) // Make Sure button is releasd before operation
{
  if(!input_double_validator())
   {
   ObjectSetInteger(0,"MLT_sell_button",OBJPROP_STATE,False);
   return;// Return if validation fails and reset button
   } 
   
  pull_dashboard_data(OP_SELL); // Pull dashboard data to arrays
  
  //-- open TP 1 trade
  if(inf_array[0][2]!=0)
  {
  int ticket=order_open(Symbol(),inf_array[1][2],OP_SELL,inf_array[0][0],inf_array[0][2]);
  if(ticket==-1)
   {
   ObjectSetInteger(0,"MLT_sell_button",OBJPROP_STATE,False);
   return; // exit if Open failure.
   } 
   //-- Create Global variable 
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_0"),sorted_array[0]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_1"),sorted_array[1]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_2"),sorted_array[2]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_3"),sorted_array[3]);
  }//------- end of TP 1--------
  
  //-- open TP 2 trade
  if(inf_array[0][3]!=0)
  {
  int ticket=order_open(Symbol(),inf_array[1][3],OP_SELL,inf_array[0][0],inf_array[0][3]);
  if(ticket==-1)
   {
   ObjectSetInteger(0,"MLT_sell_button",OBJPROP_STATE,False);
   return; // exit if Open failure.
   } 
   //-- Create Global variable 
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_0"),sorted_array[0]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_1"),sorted_array[1]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_2"),sorted_array[2]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_3"),sorted_array[3]);
  }//------- end of TP 2--------
  
  //-- open TP 3 trade
  if(inf_array[0][4]!=0)
  {
  int ticket=order_open(Symbol(),inf_array[1][4],OP_SELL,inf_array[0][0],inf_array[0][4]);
  if(ticket==-1)
   {
   ObjectSetInteger(0,"MLT_sell_button",OBJPROP_STATE,False);
   return; // exit if Open failure.
   } 
   //-- Create Global variable 
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_0"),sorted_array[0]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_1"),sorted_array[1]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_2"),sorted_array[2]);
   GlobalVariableSet(StringConcatenate("MLT_",ticket,"_3"),sorted_array[3]);
  }//------- end of TP 3--------
}
Sleep(250);
ObjectSetInteger(0,"MLT_sell_button",OBJPROP_STATE,False); // Release buy button
return;
}

//+------------------------------------------------------------------+
//| Trade monitor                                                    |
//+------------------------------------------------------------------+
void trade_monitor()
{
//---- Calculate point offset
double point_offset=0;

if(Digits==3 || Digits==5)
   {
   point_offset=trade_manage_pip_offset*10*Point;
   }
if(Digits==2 || Digits==4)
   {
   point_offset=trade_manage_pip_offset*Point;
   }
int open_trades = OrdersTotal();

if(open_trades>0)
   {
   int w;
   for(w=0;w<open_trades;w++)
      {
      if(OrderSelect(w,SELECT_BY_POS,MODE_TRADES) && OrderMagicNumber()==magic_number && OrderSymbol()==Symbol())
         {
         if(!GlobalVariableCheck(StringConcatenate("MLT_",OrderTicket(),"_0"))){Alert(__FUNCTION__,": Error!Data not found ",StringConcatenate("MLT_",OrderTicket(),"_0"));}
         if(!GlobalVariableCheck(StringConcatenate("MLT_",OrderTicket(),"_1"))){Alert(__FUNCTION__,": Error!Data not found ",StringConcatenate("MLT_",OrderTicket(),"_1"));}
         if(!GlobalVariableCheck(StringConcatenate("MLT_",OrderTicket(),"_2"))){Alert(__FUNCTION__,": Error!Data not found ",StringConcatenate("MLT_",OrderTicket(),"_2"));}
         if(!GlobalVariableCheck(StringConcatenate("MLT_",OrderTicket(),"_3"))){Alert(__FUNCTION__,": Error!Data not found ",StringConcatenate("MLT_",OrderTicket(),"_3"));}
         
         double indx_0 = GlobalVariableGet(StringConcatenate("MLT_",OrderTicket(),"_0"));
         double indx_1 = GlobalVariableGet(StringConcatenate("MLT_",OrderTicket(),"_1"));
         double indx_2 = GlobalVariableGet(StringConcatenate("MLT_",OrderTicket(),"_2"));
         double indx_3 = GlobalVariableGet(StringConcatenate("MLT_",OrderTicket(),"_3"));
         
         if(OrderType()==OP_BUY)
            {
            if(indx_0>0 && Bid>indx_0 && indx_1>0 && OrderStopLoss()!=indx_1+point_offset)
               {
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(indx_1+point_offset,Digits),OrderTakeProfit(),0)){Print(__FUNCTION__,": Error!Order Modify failed:",OrderTicket());}
               }
            else if(indx_1>0 && Bid>indx_1 && indx_2>0 && OrderStopLoss()!=indx_2+point_offset)
               {
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(indx_2+point_offset,Digits),OrderTakeProfit(),0)){Print(__FUNCTION__,": Error!Order Modify failed:",OrderTicket());}
               }
            else if(indx_2>0 && Bid>indx_2 && indx_3>0 && OrderStopLoss()!=indx_3+point_offset)
               {
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(indx_3+point_offset,Digits),OrderTakeProfit(),0)){Print(__FUNCTION__,": Error!Order Modify failed:",OrderTicket());}
               }
            }
         if(OrderType()==OP_SELL)
            {
            if(indx_0>0 && Ask<indx_0 && indx_1>0 && OrderStopLoss()!=indx_1-point_offset)
               {
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(indx_1-point_offset,Digits),OrderTakeProfit(),0)){Print(__FUNCTION__,": Error!Order Modify failed:",OrderTicket());}
               }
            else if(indx_1>0 && Ask<indx_1 && indx_2>0 && OrderStopLoss()!=indx_2-point_offset)
               {
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(indx_2-point_offset,Digits),OrderTakeProfit(),0)){Print(__FUNCTION__,": Error!Order Modify failed:",OrderTicket());}
               }
            else if(indx_2>0 && Ask<indx_2 && indx_3>0 && OrderStopLoss()!=indx_3-point_offset)
               {
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(indx_3-point_offset,Digits),OrderTakeProfit(),0)){Print(__FUNCTION__,": Error!Order Modify failed:",OrderTicket());}
               }
            }
         }
      }
   }

return;
}


//+------------------------------------------------------------------+
//| Clear Global Variables                                           |
//+------------------------------------------------------------------+

void clear_global_variables()
   {
   int vars_total =GlobalVariablesTotal();
   int split_strings,order_number;
   string gvar_name = "NULL";
   
   for(int x=vars_total-1;x>=0;x--) // Index is reversed due to deletion of indexed values
      {
      if(GlobalVariableName(x)!=NULL)
         {
         string result[];
         gvar_name=GlobalVariableName(x);
         split_strings=StringSplit(gvar_name,StringGetCharacter("_",0),result);
         if(result[0]=="MLT" && split_strings==3)
            {
            order_number = StrToInteger(result[1]);
            if(OrderSelect(order_number,SELECT_BY_TICKET) && OrderCloseTime()!=0)
               {
               if(GlobalVariableDel(gvar_name)){Print(__FUNCTION__," Variable deleted: ",gvar_name);}
               else{Print(__FUNCTION__," Variable delete failed: ",gvar_name);}
               }
            }
         }
      }
   return;
   }
   
