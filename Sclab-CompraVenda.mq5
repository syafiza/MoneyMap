//+------------------------------------------------------------------+
//|                                           Sclab-CompraVenda.mq5  |
//|                                                   SCLAB YouTube  |
//|                      SMA-based Buy/Sell EA (Refactored)          |
//+------------------------------------------------------------------+
#property copyright "SCLAB"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "2.00"
#property description "Simple trading EA using SMA crossover strategy"
#property description "Refactored: Proper resource management, modular design, English naming"

#include <Trade\Trade.mqh>
#include <Include\TradingCore.mqh>
#include <Include\IndicatorManager.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input int    InpSMAPeriod = 20;        // SMA Period
input double InpLotSize = 5.0;         // Lot Size
input double InpStopLoss = 5.0;        // Stop Loss (points)
input double InpTakeProfit = 5.0;      // Take Profit (points)

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CTrade            g_trade;             // Trade object
CSMAIndicator     g_sma;               // SMA indicator manager
CPositionManager* g_posManager;        // Position manager
MqlTick           g_lastTick;          // Last tick data

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize SMA indicator
    if(!g_sma.Init(InpSMAPeriod, 0, MODE_SMA, PRICE_CLOSE))
    {
        Print("ERROR: Failed to initialize SMA indicator");
        return INIT_FAILED;
    }
    
    // Create position manager
    g_posManager = new CPositionManager(_Symbol, 0);
    
    Print("Buy/Sell EA initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up resources
    g_sma.Release();
    
    if(g_posManager != NULL)
    {
        delete g_posManager;
        g_posManager = NULL;
    }
    
    Comment("");
    Print("Buy/Sell EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Get current tick
    if(!SymbolInfoTick(_Symbol, g_lastTick))
    {
        Print("ERROR: Failed to get tick data. Error: ", GetLastError());
        return;
    }
    
    // Update SMA indicator
    if(!g_sma.Update(3))
        return;
    
    // Check for open positions
    bool hasPosition = g_posManager.HasOpenPosition();
    
    // Generate and process signal
    ENUM_TRADE_SIGNAL signal = GenerateSignal();
    
    if(signal == SIGNAL_BUY && !hasPosition)
    {
        ExecuteBuyOrder();
    }
    else if(signal == SIGNAL_SELL && !hasPosition)
    {
        ExecuteSellOrder();
    }
}

//+------------------------------------------------------------------+
//| Generate trading signal based on SMA                             |
//+------------------------------------------------------------------+
ENUM_TRADE_SIGNAL GenerateSignal()
{
    double smaValue = g_sma.GetValue(0);
    
    if(g_lastTick.last > smaValue)
        return SIGNAL_BUY;
    else if(g_lastTick.last < smaValue)
        return SIGNAL_SELL;
    
    return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Execute buy order with proper price normalization                |
//+------------------------------------------------------------------+
void ExecuteBuyOrder()
{
    double entryPrice = CPriceUtils::NormalizePrice(g_lastTick.ask);
    double stopLoss = CPriceUtils::CalculateBuyStopLoss(entryPrice, InpStopLoss);
    double takeProfit = CPriceUtils::CalculateBuyTakeProfit(entryPrice, InpTakeProfit);
    
    if(g_trade.Buy(InpLotSize, _Symbol, entryPrice, stopLoss, takeProfit, "SMA Buy"))
    {
        Print("BUY order executed successfully. Entry: ", entryPrice, 
              ", SL: ", stopLoss, ", TP: ", takeProfit);
    }
    else
    {
        Print("BUY order failed. Error: ", GetLastError(), 
              ", RetCode: ", g_trade.ResultRetcode(),
              ", Description: ", g_trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Execute sell order with proper price normalization               |
//+------------------------------------------------------------------+
void ExecuteSellOrder()
{
    double entryPrice = CPriceUtils::NormalizePrice(g_lastTick.bid);
    double stopLoss = CPriceUtils::CalculateSellStopLoss(entryPrice, InpStopLoss);
    double takeProfit = CPriceUtils::CalculateSellTakeProfit(entryPrice, InpTakeProfit);
    
    if(g_trade.Sell(InpLotSize, _Symbol, entryPrice, stopLoss, takeProfit, "SMA Sell"))
    {
        Print("SELL order executed successfully. Entry: ", entryPrice,
              ", SL: ", stopLoss, ", TP: ", takeProfit);
    }
    else
    {
        Print("SELL order failed. Error: ", GetLastError(),
              ", RetCode: ", g_trade.ResultRetcode(),
              ", Description: ", g_trade.ResultRetcodeDescription());
    }
}
//+------------------------------------------------------------------+
