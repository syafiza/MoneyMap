//+------------------------------------------------------------------+
//|                                           ATRRiskManager.mqh     |
//|                                      MoneyMap ATR Risk Manager   |
//|     Dynamic stop loss and take profit based on market volatility|
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| ATR-Based Risk Manager                                           |
//| Calculates dynamic SL/TP based on Average True Range             |
//+------------------------------------------------------------------+
class CATRRiskManager
{
private:
    int               m_atrHandle;              // ATR indicator handle
    double            m_atrBuffer[];            // ATR data buffer
    int               m_atrPeriod;              // ATR period
    double            m_stopLossMultiplier;     // SL = ATR * multiplier
    double            m_takeProfitRatio;        // TP = SL * ratio
    bool              m_initialized;            // Initialization flag
    
public:
    //--- Constructor
    CATRRiskManager(int atrPeriod = 14, double slMultiplier = 2.0, double tpRatio = 2.0)
    {
        m_atrHandle = INVALID_HANDLE;
        m_atrPeriod = atrPeriod;
        m_stopLossMultiplier = slMultiplier;
        m_takeProfitRatio = tpRatio;
        m_initialized = false;
        ArraySetAsSeries(m_atrBuffer, true);
    }
    
    //--- Destructor
    ~CATRRiskManager()
    {
        Release();
    }
    
    //--- Initialize ATR indicator
    bool Init(string symbol = NULL, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT)
    {
        if(symbol == NULL) symbol = _Symbol;
        if(timeframe == PERIOD_CURRENT) timeframe = _Period;
        
        m_atrHandle = iATR(symbol, timeframe, m_atrPeriod);
        
        if(m_atrHandle == INVALID_HANDLE)
        {
            Print("ERROR: Failed to create ATR indicator. Error: ", GetLastError());
            return false;
        }
        
        m_initialized = true;
        return true;
    }
    
    //--- Release ATR indicator
    void Release()
    {
        if(m_atrHandle != INVALID_HANDLE)
        {
            IndicatorRelease(m_atrHandle);
            m_atrHandle = INVALID_HANDLE;
        }
        m_initialized = false;
    }
    
    //--- Update ATR data
    bool Update()
    {
        if(!m_initialized || m_atrHandle == INVALID_HANDLE)
            return false;
        
        if(CopyBuffer(m_atrHandle, 0, 0, 3, m_atrBuffer) < 0)
        {
            Print("ERROR: Failed to copy ATR buffer. Error: ", GetLastError());
            return false;
        }
        
        return true;
    }
    
    //--- Get current ATR value
    double GetATR(int index = 0)
    {
        if(index < 0 || index >= ArraySize(m_atrBuffer))
            return 0.0;
        return m_atrBuffer[index];
    }
    
    //--- Calculate dynamic stop loss for buy order
    double CalculateBuyStopLoss(double entryPrice)
    {
        if(!m_initialized) return 0.0;
        
        double atr = m_atrBuffer[0];
        double slDistance = atr * m_stopLossMultiplier;
        
        return NormalizeDouble(entryPrice - slDistance, _Digits);
    }
    
    //--- Calculate dynamic stop loss for sell order
    double CalculateSellStopLoss(double entryPrice)
    {
        if(!m_initialized) return 0.0;
        
        double atr = m_atrBuffer[0];
        double slDistance = atr * m_stopLossMultiplier;
        
        return NormalizeDouble(entryPrice + slDistance, _Digits);
    }
    
    //--- Calculate dynamic take profit for buy order
    double CalculateBuyTakeProfit(double entryPrice, double stopLoss)
    {
        if(!m_initialized) return 0.0;
        
        double slDistance = MathAbs(entryPrice - stopLoss);
        double tpDistance = slDistance * m_takeProfitRatio;
        
        return NormalizeDouble(entryPrice + tpDistance, _Digits);
    }
    
    //--- Calculate dynamic take profit for sell order
    double CalculateSellTakeProfit(double entryPrice, double stopLoss)
    {
        if(!m_initialized) return 0.0;
        
        double slDistance = MathAbs(stopLoss - entryPrice);
        double tpDistance = slDistance * m_takeProfitRatio;
        
        return NormalizeDouble(entryPrice - tpDistance, _Digits);
    }
    
    //--- Calculate position size based on risk percentage
    double CalculatePositionSize(double riskPercent, double entryPrice, double stopLoss)
    {
        double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double riskAmount = accountBalance * (riskPercent / 100.0);
        
        double slDistance = MathAbs(entryPrice - stopLoss);
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        
        double slInTicks = slDistance / tickSize;
        double riskPerLot = slInTicks * tickValue;
        
        if(riskPerLot == 0) return 0.0;
        
        double lotSize = riskAmount / riskPerLot;
        
        // Normalize to lot step
        double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        
        lotSize = MathFloor(lotSize / lotStep) * lotStep;
        lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
        
        return lotSize;
    }
    
    //--- Set stop loss multiplier
    void SetStopLossMultiplier(double multiplier)
    {
        m_stopLossMultiplier = multiplier;
    }
    
    //--- Set take profit ratio
    void SetTakeProfitRatio(double ratio)
    {
        m_takeProfitRatio = ratio;
    }
    
    //--- Get current volatility level (compared to average)
    double GetVolatilityRatio()
    {
        if(ArraySize(m_atrBuffer) < 10) return 1.0;
        
        double avgATR = 0;
        for(int i = 0; i < 10; i++)
            avgATR += m_atrBuffer[i];
        avgATR /= 10;
        
        if(avgATR == 0) return 1.0;
        
        return m_atrBuffer[0] / avgATR;  // >1 = high volatility, <1 = low volatility
    }
};
//+------------------------------------------------------------------+
