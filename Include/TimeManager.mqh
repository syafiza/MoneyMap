//+------------------------------------------------------------------+
//|                                                  TimeManager.mqh |
//|                                           MoneyMap Time Manager  |
//|                   Trading hours and session management           |
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Time Manager Class                                                |
//| Manages trading hours and session validation                     |
//+------------------------------------------------------------------+
class CTimeManager
{
private:
    int               m_tradingStartHour;      // Trading start hour
    int               m_tradingStartMinute;    // Trading start minute
    int               m_tradingEndHour;        // Trading end hour
    int               m_tradingEndMinute;      // Trading end minute
    int               m_closeStartHour;        // Position closing start hour
    int               m_closeStartMinute;      // Position closing start minute
    bool              m_enabled;               // Time filter enabled
    
public:
    //--- Constructor
    CTimeManager(int startHour = 0, int startMinute = 0, int endHour = 23, int endMinute = 59)
    {
        m_tradingStartHour = startHour;
        m_tradingStartMinute = startMinute;
        m_tradingEndHour = endHour;
        m_tradingEndMinute = endMinute;
        m_closeStartHour = 23;
        m_closeStartMinute = 50;
        m_enabled = false;
    }
    
    //--- Enable time filter
    void Enable(void)
    {
        m_enabled = true;
    }
    
    //--- Disable time filter
    void Disable(void)
    {
        m_enabled = false;
    }
    
    //--- Set trading hours
    void SetTradingHours(int startHour, int startMinute, int endHour, int endMinute)
    {
        m_tradingStartHour = startHour;
        m_tradingStartMinute = startMinute;
        m_tradingEndHour = endHour;
        m_tradingEndMinute = endMinute;
    }
    
    //--- Set closing time
    void SetClosingTime(int hour, int minute)
    {
        m_closeStartHour = hour;
        m_closeStartMinute = minute;
    }
    
    //--- Check if current time is within trading hours
    bool IsTradingTime(void) const
    {
        if(!m_enabled)
            return true;
            
        MqlDateTime currentTime;
        TimeToStruct(TimeCurrent(), currentTime);
        
        // Check if hour is within range
        if(currentTime.hour < m_tradingStartHour || currentTime.hour > m_tradingEndHour)
            return false;
            
        // Check start boundary
        if(currentTime.hour == m_tradingStartHour && currentTime.min < m_tradingStartMinute)
            return false;
            
        // Check end boundary
        if(currentTime.hour == m_tradingEndHour && currentTime.min > m_tradingEndMinute)
            return false;
            
        return true;
    }
    
    //--- Check if current time is closing time
    bool IsClosingTime(void) const
    {
        if(!m_enabled)
            return false;
            
        MqlDateTime currentTime;
        TimeToStruct(TimeCurrent(), currentTime);
        
        // Check if we've reached closing hour
        if(currentTime.hour > m_closeStartHour)
            return true;
            
        // Check closing boundary
        if(currentTime.hour == m_closeStartHour && currentTime.min >= m_closeStartMinute)
            return true;
            
        return false;
    }
    
    //--- Get current time as string
    static string GetCurrentTimeString(void)
    {
        MqlDateTime currentTime;
        TimeToStruct(TimeCurrent(), currentTime);
        return StringFormat("%02d:%02d:%02d", currentTime.hour, currentTime.min, currentTime.sec);
    }
    
    //--- Check if it's a new bar
    static bool IsNewBar(void)
    {
        static datetime lastBarTime = 0;
        datetime currentBarTime = iTime(_Symbol, _Period, 0);
        
        if(currentBarTime != lastBarTime)
        {
            lastBarTime = currentBarTime;
            return true;
        }
        return false;
    }
};
//+------------------------------------------------------------------+
