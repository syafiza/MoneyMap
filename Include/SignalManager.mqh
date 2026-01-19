//+------------------------------------------------------------------+
//|                                            SignalManager.mqh     |
//|                                        MoneyMap Signal Manager   |
//|            Multi-confirmation signal system for high probability |
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "1.00"
#property strict

#include "IndicatorManager.mqh"

//+------------------------------------------------------------------+
//| Signal Confirmation Enumeration                                  |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_CONFIRMATION
{
    CONFIRM_NONE         = 0,
    CONFIRM_PRICE_SMA    = 1,   // Price vs SMA
    CONFIRM_CANDLE       = 2,   // Candle pattern
    CONFIRM_VOLUME       = 4,   // Volume spike
    CONFIRM_MOMENTUM     = 8,   // Price momentum
    CONFIRM_TREND_MTF    = 16   // Multi-timeframe trend
};

//+------------------------------------------------------------------+
//| Multi-Confirmation Signal Manager                                |
//| Validates trading signals using multiple confirmations           |
//+------------------------------------------------------------------+
class CSignalManager
{
private:
    CSMAIndicator*    m_sma;                    // Primary SMA indicator
    CSMAIndicator*    m_smaHigherTF;            // Higher timeframe SMA
    int               m_requiredConfirmations;  // Minimum confirmations needed
    long              m_volumeBuffer[];         // Volume data
    bool              m_useMultiTimeframe;      // Enable MTF filter
    ENUM_TIMEFRAMES   m_higherTimeframe;        // Higher TF for trend filter
    
public:
    //--- Constructor
    CSignalManager(CSMAIndicator* sma, int requiredConfirmations = 2)
    {
        m_sma = sma;
        m_requiredConfirmations = requiredConfirmations;
        m_smaHigherTF = NULL;
        m_useMultiTimeframe = false;
        m_higherTimeframe = PERIOD_H4;
        ArraySetAsSeries(m_volumeBuffer, true);
    }
    
    //--- Destructor
    ~CSignalManager()
    {
        if(m_smaHigherTF != NULL)
        {
            delete m_smaHigherTF;
            m_smaHigherTF = NULL;
        }
    }
    
    //--- Enable multi-timeframe filtering
    bool EnableMultiTimeframe(int smaPeriod, ENUM_TIMEFRAMES higherTF = PERIOD_H4)
    {
        m_higherTimeframe = higherTF;
        m_smaHigherTF = new CSMAIndicator();
        
        if(!m_smaHigherTF.Init(smaPeriod, 0, MODE_SMA, PRICE_CLOSE, _Symbol, higherTF))
        {
            Print("ERROR: Failed to initialize higher timeframe SMA");
            delete m_smaHigherTF;
            m_smaHigherTF = NULL;
            return false;
        }
        
        m_useMultiTimeframe = true;
        return true;
    }
    
    //--- Validate signal with multiple confirmations
    bool ValidateSignal(ENUM_TRADE_SIGNAL signal, const MqlTick &tick, const MqlRates &rates[])
    {
        if(signal == SIGNAL_NONE) return false;
        
        int confirmations = 0;
        int confirmedFlags = 0;
        
        // Confirmation 1: Price vs SMA
        if(CheckPriceSMA(signal, tick))
        {
            confirmations++;
            confirmedFlags |= CONFIRM_PRICE_SMA;
        }
        
        // Confirmation 2: Candle pattern
        if(CheckCandlePattern(signal, rates))
        {
            confirmations++;
            confirmedFlags |= CONFIRM_CANDLE;
        }
        
        // Confirmation 3: Volume spike
        if(CheckVolume())
        {
            confirmations++;
            confirmedFlags |= CONFIRM_VOLUME;
        }
        
        // Confirmation 4: Momentum
        if(CheckMomentum(signal, rates))
        {
            confirmations++;
            confirmedFlags |= CONFIRM_MOMENTUM;
        }
        
        // Confirmation 5: Multi-timeframe trend (if enabled)
        if(m_useMultiTimeframe && CheckMultiTimeframeTrend(signal))
        {
            confirmations++;
            confirmedFlags |= CONFIRM_TREND_MTF;
        }
        
        bool isValid = (confirmations >= m_requiredConfirmations);
        
        if(isValid)
        {
            Print("Signal VALIDATED: ", EnumToString(signal), 
                  ", Confirmations: ", confirmations, "/", m_requiredConfirmations,
                  ", Flags: ", confirmedFlags);
        }
        
        return isValid;
    }
    
private:
    //--- Check price vs SMA confirmation
    bool CheckPriceSMA(ENUM_TRADE_SIGNAL signal, const MqlTick &tick)
    {
        double smaValue = m_sma.GetValue(0);
        
        if(signal == SIGNAL_BUY)
            return (tick.last > smaValue);
        else if(signal == SIGNAL_SELL)
            return (tick.last < smaValue);
            
        return false;
    }
    
    //--- Check candle pattern confirmation
    bool CheckCandlePattern(ENUM_TRADE_SIGNAL signal, const MqlRates &rates[])
    {
        if(ArraySize(rates) < 2) return false;
        
        bool isBullish = (rates[1].close > rates[1].open);
        bool isBearish = (rates[1].close < rates[1].open);
        double candleSize = MathAbs(rates[1].close - rates[1].open);
        double minSize = (rates[1].high - rates[1].low) * 0.5;  // At least 50% body
        
        if(signal == SIGNAL_BUY)
            return (isBullish && candleSize >= minSize);
        else if(signal == SIGNAL_SELL)
            return (isBearish && candleSize >= minSize);
            
        return false;
    }
    
    //--- Check volume confirmation
    bool CheckVolume()
    {
        if(CopyTickVolume(_Symbol, _Period, 0, 10, m_volumeBuffer) < 10)
            return false;
        
        // Calculate average volume of last 10 bars
        long avgVolume = 0;
        for(int i = 1; i < 10; i++)
            avgVolume += m_volumeBuffer[i];
        avgVolume /= 9;
        
        // Current volume should be 1.3x average or higher
        return (m_volumeBuffer[0] >= avgVolume * 1.3);
    }
    
    //--- Check momentum confirmation
    bool CheckMomentum(ENUM_TRADE_SIGNAL signal, const MqlRates &rates[])
    {
        if(ArraySize(rates) < 3) return false;
        
        // Simple momentum: current close vs 2 bars ago
        double momentum = rates[0].close - rates[2].close;
        
        if(signal == SIGNAL_BUY)
            return (momentum > 0);
        else if(signal == SIGNAL_SELL)
            return (momentum < 0);
            
        return false;
    }
    
    //--- Check multi-timeframe trend alignment
    bool CheckMultiTimeframeTrend(ENUM_TRADE_SIGNAL signal)
    {
        if(!m_useMultiTimeframe || m_smaHigherTF == NULL)
            return false;
        
        // Update higher timeframe SMA
        if(!m_smaHigherTF.Update(3))
            return false;
        
        double higherTFSMA = m_smaHigherTF.GetValue(0);
        double currentPrice = iClose(_Symbol, m_higherTimeframe, 0);
        
        if(signal == SIGNAL_BUY)
            return (currentPrice > higherTFSMA);  // Uptrend on higher TF
        else if(signal == SIGNAL_SELL)
            return (currentPrice < higherTFSMA);  // Downtrend on higher TF
            
        return false;
    }
};
//+------------------------------------------------------------------+
