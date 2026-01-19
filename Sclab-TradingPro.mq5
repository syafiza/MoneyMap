//+------------------------------------------------------------------+
//|                                            Sclab-TradingPro.mq5  |
//|                                                   SCLAB YouTube  |
//|                      PROFESSIONAL TRADING EA - ALL FEATURES      |
//+------------------------------------------------------------------+
#property copyright "SCLAB / MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "3.00"
#property description "Professional Trading EA with advanced features:"
#property description "✅ Multi-confirmation signals"
#property description "✅ ATR-based dynamic SL/TP"
#property description "✅ Partial position close (scale out)"
#property description "✅ Multi-timeframe trend filter"
#property description "✅ Daily/Weekly drawdown protection"
#property description "✅ Performance analytics dashboard"
#property description "✅ Break-even and trailing stop"
#property description "✅ Time-based trading filters"

#include <Trade\Trade.mqh>
#include <Include\TradingCore.mqh>
#include <Include\RiskManager.mqh>
#include <Include\TimeManager.mqh>
#include <Include\IndicatorManager.mqh>
#include <Include\SignalManager.mqh>
#include <Include\ATRRiskManager.mqh>
#include <Include\PartialCloseManager.mqh>
#include <Include\DrawdownManager.mqh>
#include <Include\PerformanceTracker.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input group "=== Indicator Settings ==="
input int                     InpSMAPeriod = 20;              // SMA Period
input int                     InpATRPeriod = 14;              // ATR Period
input ENUM_TIMEFRAMES         InpHigherTimeframe = PERIOD_H4; // Higher Timeframe for Trend

input group "=== Trading Settings ==="
input ulong                   InpMagicNumber = 999999;        // Magic Number
input ulong                   InpDeviation = 50;              // Deviation (points)
input ENUM_ORDER_TYPE_FILLING InpFillType = ORDER_FILLING_RETURN; // Order Fill Type

input group "=== Money Management ==="
input double                  InpFixedLotSize = 0.0;          // Fixed Lot Size (0 = auto)
input double                  InpRiskPercent = 1.0;           // Risk Per Trade (%)
input double                  InpATRMultiplier = 2.0;         // ATR Multiplier for SL
input double                  InpRiskRewardRatio = 2.0;       // Risk:Reward Ratio

input group "=== Signal Confirmation ==="
input int                     InpMinConfirmations = 2;        // Minimum Confirmations (1-5)
input bool                    InpUseMultiTimeframe = true;    // Use Multi-TF Trend Filter

input group "=== Risk Management ==="
input double                  InpBreakEvenTrigger = 1.5;      // Break-Even Trigger (ATR multiplier)
input double                  InpTrailingTrigger = 2.0;       // Trailing Stop Trigger (ATR)
input double                  InpTrailing Step = 0.5;         // Trailing Stop Step (ATR)

input group "=== Partial Close Settings ==="
input bool                    InpUsePartialClose = true;      // Enable Partial Close
input double                  InpPartialCloseTarget = 50.0;   // First Target (% of TP)
input double                  InpPartialCloseVolume = 0.5;    // Volume to Close (0.1-0.9)

input group "=== Drawdown Protection ==="
input double                  InpMaxDailyLoss = 2.0;          // Max Daily Loss (%)
input double                  InpMaxWeeklyLoss = 5.0;         // Max Weekly Loss (%)

input group "=== Time Management ==="
input bool                    InpUseTimeFilter = false;       // Use Time Filter
input int                     InpTradingStartHour = 9;        // Trading Start Hour
input int                     InpTradingStartMinute = 0;      // Trading Start Minute
input int                     InpTradingEndHour = 17;         // Trading End Hour
input int                     InpTradingEndMinute = 0;        // Trading End Minute

input group "=== Display Settings ==="
input bool                    InpShowPerformance = true;      // Show Performance Dashboard

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CTrade                g_trade;                  // Trade object
CSMAIndicator         g_sma;                    // SMA indicator
CPositionManager*     g_posManager;             // Position manager
COrderManager*        g_orderManager;           // Order manager
CBreakEvenManager*    g_breakEven;              // Break-even manager
CTrailingStopManager* g_trailingStop;           // Trailing stop manager
CTimeManager*         g_timeManager;            // Time manager
CSignalManager*       g_signalManager;          // Signal confirmation manager
CATRRiskManager*      g_atrRiskManager;         // ATR risk manager
CPartialCloseManager* g_partialClose;           // Partial close manager
CDrawdownManager*     g_drawdownManager;        // Drawdown protection
CPerformanceTracker*  g_performance;            // Performance tracker

MqlTick               g_lastTick;               // Last tick data
MqlRates              g_rates[];                // Rate data

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("╔════════════════════════════════════════╗");
    Print("║  TRADING PRO EA - INITIALIZING...      ║");
    Print("╚════════════════════════════════════════╝");
    
    // Initialize SMA indicator
    if(!g_sma.Init(InpSMAPeriod, 0, MODE_SMA, PRICE_CLOSE))
    {
        Print("ERROR: Failed to initialize SMA indicator");
        return INIT_FAILED;
    }
    
    ArraySetAsSeries(g_rates, true);
    
    // Configure trade object
    g_trade.SetTypeFilling(InpFillType);
    g_trade.SetDeviationInPoints(InpDeviation);
    g_trade.SetExpertMagicNumber(InpMagicNumber);
    
    // Create core managers
    g_posManager = new CPositionManager(_Symbol, InpMagicNumber);
    g_orderManager = new COrderManager(_Symbol, InpMagicNumber);
    Print("✓ Position and Order managers initialized");
    
    // Create ATR risk manager
    g_atrRiskManager = new CATRRiskManager(InpATRPeriod, InpATRMultiplier, InpRiskRewardRatio);
    if(!g_atrRiskManager.Init())
    {
        Print("ERROR: Failed to initialize ATR Risk Manager");
        return INIT_FAILED;
    }
    Print("✓ ATR Risk Manager initialized (Period: ", InpATRPeriod, ", Multiplier: ", InpATRMultiplier, ")");
    
    // Create signal manager with multi-confirmation
    g_signalManager = new CSignalManager(&g_sma, InpMinConfirmations);
    if(InpUseMultiTimeframe)
    {
        if(g_signalManager.EnableMultiTimeframe(InpSMAPeriod, InpHigherTimeframe))
        {
            Print("✓ Multi-Timeframe Filter enabled (", EnumToString(InpHigherTimeframe), ")");
        }
    }
    Print("✓ Signal Manager initialized (Confirmations required: ", InpMinConfirmations, ")");
    
    // Create break-even and trailing stop
    double beTrigger = g_atrRiskManager.GetATR() * InpBreakEvenTrigger;
    double tsTrigger = g_atrRiskManager.GetATR() * InpTrailingTrigger;
    double tsStep = g_atrRiskManager.GetATR() * InpTrailingStep;
    
    g_breakEven = new CBreakEvenManager(&g_trade, _Symbol, InpMagicNumber, beTrigger);
    g_trailingStop = new CTrailingStopManager(&g_trade, _Symbol, InpMagicNumber, tsTrigger, tsStep);
    Print("✓ Risk Management initialized (BE/TS based on ATR)");
    
    // Create partial close manager
    if(InpUsePartialClose)
    {
        g_partialClose = new CPartialCloseManager(&g_trade, _Symbol, InpMagicNumber,
                                                   InpPartialCloseTarget, InpPartialCloseVolume);
        Print("✓ Partial Close enabled (Target: ", InpPartialCloseTarget, "%, Volume: ", InpPartialCloseVolume*100, "%)");
    }
    
    // Create drawdown manager
    g_drawdownManager = new CDrawdownManager(InpMaxDailyLoss, InpMaxWeeklyLoss);
    Print("✓ Drawdown Protection enabled (Daily: ", InpMaxDailyLoss, "%, Weekly: ", InpMaxWeeklyLoss, "%)");
    
    // Create performance tracker
    g_performance = new CPerformanceTracker(InpShowPerformance);
    Print("✓ Performance Tracker initialized");
    
    // Create and configure time manager
    if(InpUseTimeFilter)
    {
        g_timeManager = new CTimeManager(InpTradingStartHour, InpTradingStartMinute,
                                          InpTradingEndHour, InpTradingEndMinute);
        g_timeManager.Enable();
        Print("✓ Time Filter enabled (", InpTradingStartHour, ":", InpTradingStartMinute,
              " - ", InpTradingEndHour, ":", InpTradingEndMinute, ")");
    }
    else
    {
        g_timeManager = new CTimeManager();
        g_timeManager.Disable();
    }
    
    Print("╔════════════════════════════════════════╗");
    Print("║  TRADING PRO EA - READY TO TRADE!     ║");
    Print("╚════════════════════════════════════════╝");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up all resources
    g_sma.Release();
    
    if(g_atrRiskManager != NULL) { delete g_atrRiskManager; g_atrRiskManager = NULL; }
    if(g_posManager != NULL) { delete g_posManager; g_posManager = NULL; }
    if(g_orderManager != NULL) { delete g_orderManager; g_orderManager = NULL; }
    if(g_breakEven != NULL) { delete g_breakEven; g_breakEven = NULL; }
    if(g_trailingStop != NULL) { delete g_trailingStop; g_trailingStop = NULL; }
    if(g_timeManager != NULL) { delete g_timeManager; g_timeManager = NULL; }
    if(g_signalManager != NULL) { delete g_signalManager; g_signalManager = NULL; }
    if(g_partialClose != NULL) { delete g_partialClose; g_partialClose = NULL; }
    if(g_drawdownManager != NULL) { delete g_drawdownManager; g_drawdownManager = NULL; }
    if(g_performance != NULL) { delete g_performance; g_performance = NULL; }
    
    Comment("");
    Print("Trading Pro EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Update drawdown protection
    g_drawdownManager.Update();
    
    // Check if trading is allowed
    if(!g_drawdownManager.IsTradingAllowed())
    {
        Comment("⛔ TRADING DISABLED: ", g_drawdownManager.GetLockoutReason(), "\n",
                g_drawdownManager.GetStatusString());
        return;
    }
    
    // Get market data
    if(!GetMarketData())
        return;
    
    // Check for open positions
    bool hasPosition = g_posManager.HasOpenPosition();
    bool hasPendingOrder = g_orderManager.HasPendingOrder();
    
    // Reset state when no position
    if(!hasPosition)
    {
        g_breakEven.Reset();
        if(g_partialClose != NULL)
            g_partialClose.Reset();
    }
    
    // Manage existing positions
    if(hasPosition)
    {
        ManagePosition();
    }
    
    // Look for new trading opportunities
    if(!hasPosition && !hasPendingOrder && g_timeManager.IsTradingTime())
    {
        LookForSignals();
    }
}

//+------------------------------------------------------------------+
//| Get market data (tick, rates, indicators)                        |
//+------------------------------------------------------------------+
bool GetMarketData()
{
    // Get tick data
    if(!SymbolInfoTick(_Symbol, g_lastTick))
    {
        Print("ERROR: Failed to get tick data");
        return false;
    }
    
    // Get rate data
    if(CopyRates(_Symbol, _Period, 0, 10, g_rates) < 10)
    {
        Print("ERROR: Failed to get rate data");
        return false;
    }
    
    // Update SMA
    if(!g_sma.Update(3))
        return false;
    
    // Update ATR
    if(!g_atrRiskManager.Update())
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Manage existing position                                         |
//+------------------------------------------------------------------+
void ManagePosition()
{
    // Step 1: Partial close at first target
    if(InpUsePartialClose && g_partialClose != NULL)
    {
        if(!g_partialClose.IsFirstTargetHit())
        {
            g_partialClose.Update(g_lastTick.last);
        }
    }
    
    // Step 2: Activate break-even
    if(!g_breakEven.IsActive())
    {
        g_breakEven.Update(g_lastTick.last);
    }
    
    // Step 3: Trail stop loss
    if(g_breakEven.IsActive())
    {
        g_trailingStop.Update(g_lastTick.last);
    }
}

//+------------------------------------------------------------------+
//| Look for new trading signals                                     |
//+------------------------------------------------------------------+
void LookForSignals()
{
    // Generate preliminary signal
    ENUM_TRADE_SIGNAL signal = GeneratePreliminarySignal();
    
    if(signal == SIGNAL_NONE)
        return;
    
    // Validate signal with multiple confirmations
    if(!g_signalManager.ValidateSignal(signal, g_lastTick, g_rates))
    {
        Print("Signal rejected - insufficient confirmations");
        return;
    }
    
    // Execute validated signal
    ExecuteSignal(signal);
}

//+------------------------------------------------------------------+
//| Generate preliminary signal based on SMA                         |
//+------------------------------------------------------------------+
ENUM_TRADE_SIGNAL GeneratePreliminarySignal()
{
    double smaValue = g_sma.GetValue(0);
    bool bullishCandle = (g_rates[1].close > g_rates[1].open);
    bool bearishCandle = (g_rates[1].close < g_rates[1].open);
    
    if(g_lastTick.last > smaValue && bullishCandle)
        return SIGNAL_BUY;
    
    if(g_lastTick.last < smaValue && bearishCandle)
        return SIGNAL_SELL;
    
    return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Execute validated signal with ATR-based risk management          |
//+------------------------------------------------------------------+
void ExecuteSignal(ENUM_TRADE_SIGNAL signal)
{
    if(signal == SIGNAL_BUY)
    {
        double entryPrice = CPriceUtils::NormalizePrice(g_lastTick.ask);
        double stopLoss = g_atrRiskManager.CalculateBuyStopLoss(entryPrice);
        double takeProfit = g_atrRiskManager.CalculateBuyTakeProfit(entryPrice, stopLoss);
        
        // Calculate position size
        double lotSize = InpFixedLotSize;
        if(lotSize == 0)
        {
            lotSize = g_atrRiskManager.CalculatePositionSize(InpRiskPercent, entryPrice, stopLoss);
        }
        
        if(lotSize == 0)
        {
            Print("ERROR: Invalid lot size calculated");
            return;
        }
        
        if(g_trade.Buy(lotSize, _Symbol, entryPrice, stopLoss, takeProfit, "Pro BUY"))
        {
            Print("✓ BUY ORDER EXECUTED | Lots: ", lotSize,
                  " | Entry: ", entryPrice, " | SL: ", stopLoss, " | TP: ", takeProfit,
                  " | ATR: ", DoubleToString(g_atrRiskManager.GetATR(), _Digits));
        }
        else
        {
            Print("✗ BUY ORDER FAILED | RetCode: ", g_trade.ResultRetcode());
        }
    }
    else if(signal == SIGNAL_SELL)
    {
        double entryPrice = CPriceUtils::NormalizePrice(g_lastTick.bid);
        double stopLoss = g_atrRiskManager.CalculateSellStopLoss(entryPrice);
        double takeProfit = g_atrRiskManager.CalculateSellTakeProfit(entryPrice, stopLoss);
        
        // Calculate position size
        double lotSize = InpFixedLotSize;
        if(lotSize == 0)
        {
            lotSize = g_atrRiskManager.CalculatePositionSize(InpRiskPercent, entryPrice, stopLoss);
        }
        
        if(lotSize == 0)
        {
            Print("ERROR: Invalid lot size calculated");
            return;
        }
        
        if(g_trade.Sell(lotSize, _Symbol, entryPrice, stopLoss, takeProfit, "Pro SELL"))
        {
            Print("✓ SELL ORDER EXECUTED | Lots: ", lotSize,
                  " | Entry: ", entryPrice, " | SL: ", stopLoss, " | TP: ", takeProfit,
                  " | ATR: ", DoubleToString(g_atrRiskManager.GetATR(), _Digits));
        }
        else
        {
            Print("✗ SELL ORDER FAILED | RetCode: ", g_trade.ResultRetcode());
        }
    }
}

//+------------------------------------------------------------------+
//| Trade transaction event handler                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
    // Track closed positions for performance analytics
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
    {
        if(HistoryDealSelect(trans.deal))
        {
            long dealMagic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
            
            if(dealMagic == InpMagicNumber)
            {
                double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
                double volume = HistoryDealGetDouble(trans.deal, DEAL_VOLUME);
                
                // Record in performance tracker
                g_performance.RecordTrade(profit, volume);
            }
        }
    }
}
//+------------------------------------------------------------------+
