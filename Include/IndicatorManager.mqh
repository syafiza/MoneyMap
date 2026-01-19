//+------------------------------------------------------------------+
//|                                              IndicatorManager.mqh|
//|                                        MoneyMap Indicator Manager|
//|                   Efficient indicator lifecycle management       |
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| SMA Indicator Wrapper Class                                      |
//| Manages Simple Moving Average indicator lifecycle               |
//+------------------------------------------------------------------+
class CSMAIndicator
{
private:
    int               m_handle;              // Indicator handle
    double            m_buffer[];            // Data buffer
    int               m_period;              // MA period
    int               m_shift;               // MA shift
    ENUM_MA_METHOD    m_method;              // MA method
    ENUM_APPLIED_PRICE m_appliedPrice;       // Applied price
    string            m_symbol;              // Symbol
    ENUM_TIMEFRAMES   m_timeframe;           // Timeframe
    bool              m_initialized;         // Initialization flag
    
public:
    //--- Constructor
    CSMAIndicator(void)
    {
        m_handle = INVALID_HANDLE;
        m_period = 20;
        m_shift = 0;
        m_method = MODE_SMA;
        m_appliedPrice = PRICE_CLOSE;
        m_symbol = _Symbol;
        m_timeframe = _Period;
        m_initialized = false;
        ArraySetAsSeries(m_buffer, true);
    }
    
    //--- Destructor
    ~CSMAIndicator(void)
    {
        Release();
    }
    
    //--- Initialize indicator
    bool Init(int period, int shift = 0, ENUM_MA_METHOD method = MODE_SMA, 
              ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE, 
              string symbol = NULL, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT)
    {
        m_period = period;
        m_shift = shift;
        m_method = method;
        m_appliedPrice = appliedPrice;
        m_symbol = (symbol == NULL) ? _Symbol : symbol;
        m_timeframe = (timeframe == PERIOD_CURRENT) ? _Period : timeframe;
        
        m_handle = iMA(m_symbol, m_timeframe, m_period, m_shift, m_method, m_appliedPrice);
        
        if(m_handle == INVALID_HANDLE)
        {
            Print("Failed to create SMA indicator. Error: ", GetLastError());
            return false;
        }
        
        m_initialized = true;
        return true;
    }
    
    //--- Release indicator handle
    void Release(void)
    {
        if(m_handle != INVALID_HANDLE)
        {
            IndicatorRelease(m_handle);
            m_handle = INVALID_HANDLE;
        }
        m_initialized = false;
    }
    
    //--- Update indicator data
    bool Update(int bufferSize = 3)
    {
        if(!m_initialized || m_handle == INVALID_HANDLE)
        {
            Print("SMA indicator not initialized");
            return false;
        }
        
        if(CopyBuffer(m_handle, 0, 0, bufferSize, m_buffer) < 0)
        {
            Print("Failed to copy SMA buffer data. Error: ", GetLastError());
            return false;
        }
        
        return true;
    }
    
    //--- Get indicator value at index
    double GetValue(int index = 0)
    {
        if(index < 0 || index >= ArraySize(m_buffer))
            return 0.0;
        return m_buffer[index];
    }
    
    //--- Get indicator handle
    int GetHandle(void) const
    {
        return m_handle;
    }
    
    //--- Check if initialized
    bool IsInitialized(void) const
    {
        return m_initialized;
    }
    
    //--- Get all buffer values
    bool GetBuffer(double &dest[], int bufferSize = 3)
    {
        if(!Update(bufferSize))
            return false;
            
        ArrayResize(dest, bufferSize);
        ArraySetAsSeries(dest, true);
        
        for(int i = 0; i < bufferSize; i++)
            dest[i] = m_buffer[i];
            
        return true;
    }
};
//+------------------------------------------------------------------+
