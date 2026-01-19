//+------------------------------------------------------------------+
//|                                       DrawdownManager.mqh        |
//|                                    MoneyMap Drawdown Manager     |
//|          Daily and weekly loss limits to protect capital         |
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Drawdown Protection Manager                                      |
//| Stops trading when daily/weekly loss limits are hit              |
//+------------------------------------------------------------------+
class CDrawdownManager
{
private:
    double            m_dailyStartBalance;      // Balance at day start
    double            m_weeklyStartBalance;     // Balance at week start
    double            m_maxDailyLoss;           // Maximum daily loss amount
    double            m_maxWeeklyLoss;          // Maximum weekly loss amount
    bool              m_tradingAllowed;         // Trading permission flag
    int               m_lastResetDay;           // Last reset day
    int               m_lastResetWeek;          // Last reset week
    string            m_lockoutReason;          // Reason for lockout
    
public:
    //--- Constructor
    CDrawdownManager(double maxDailyLossPercent = 2.0, double maxWeeklyLossPercent = 5.0)
    {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        m_maxDailyLoss = balance * (maxDailyLossPercent / 100.0);
        m_maxWeeklyLoss = balance * (maxWeeklyLossPercent / 100.0);
        m_dailyStartBalance = balance;
        m_weeklyStartBalance = balance;
        m_tradingAllowed = true;
        m_lastResetDay = -1;
        m_lastResetWeek = -1;
        m_lockoutReason = "";
    }
    
    //--- Update and check drawdown limits
    void Update()
    {
        MqlDateTime currentTime;
        TimeToStruct(TimeCurrent(), currentTime);
        
        // Reset daily at start of new day
        if(currentTime.day != m_lastResetDay)
        {
            m_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
            m_lastResetDay = currentTime.day;
            
            // Only re-enable if not locked out for week
            if(m_lockoutReason != "WEEKLY_LIMIT")
            {
                m_tradingAllowed = true;
                m_lockoutReason = "";
            }
            
            Print("Daily reset: Start balance = $", m_dailyStartBalance);
        }
        
        // Reset weekly on Monday
        if(currentTime.day_of_week == 1 && currentTime.day_of_week != m_lastResetWeek)
        {
            m_weeklyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
            m_lastResetWeek = currentTime.day_of_week;
            m_tradingAllowed = true;
            m_lockoutReason = "";
            
            Print("Weekly reset: Start balance = $", m_weeklyStartBalance);
        }
        
        // Check current drawdown
        double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double dailyPnL = currentBalance - m_dailyStartBalance;
        double weeklyPnL = currentBalance - m_weeklyStartBalance;
        
        // Check daily limit
        if(dailyPnL <= -m_maxDailyLoss && m_tradingAllowed)
        {
            m_tradingAllowed = false;
            m_lockoutReason = "DAILY_LIMIT";
            
            Print("⛔ DAILY LOSS LIMIT REACHED!");
            Print("Daily P/L: $", dailyPnL, " / Limit: $", -m_maxDailyLoss);
            Print("Trading disabled until next day");
            
            Alert("DAILY LOSS LIMIT REACHED - Trading disabled!");
        }
        
        // Check weekly limit (supersedes daily)
        if(weeklyPnL <= -m_maxWeeklyLoss)
        {
            m_tradingAllowed = false;
            m_lockoutReason = "WEEKLY_LIMIT";
            
            Print("⛔⛔ WEEKLY LOSS LIMIT REACHED!");
            Print("Weekly P/L: $", weeklyPnL, " / Limit: $", -m_maxWeeklyLoss);
            Print("Trading disabled until next week");
            
            Alert("WEEKLY LOSS LIMIT REACHED - Trading disabled!");
        }
    }
    
    //--- Check if trading is allowed
    bool IsTradingAllowed() const
    {
        return m_tradingAllowed;
    }
    
    //--- Get current daily P/L
    double GetDailyPnL() const
    {
        return AccountInfoDouble(ACCOUNT_BALANCE) - m_dailyStartBalance;
    }
    
    //--- Get current weekly P/L
    double GetWeeklyPnL() const
    {
        return AccountInfoDouble(ACCOUNT_BALANCE) - m_weeklyStartBalance;
    }
    
    //--- Get daily drawdown percentage
    double GetDailyDrawdownPercent() const
    {
        if(m_dailyStartBalance == 0) return 0;
        return (GetDailyPnL() / m_dailyStartBalance) * 100.0;
    }
    
    //--- Get weekly drawdown percentage
    double GetWeeklyDrawdownPercent() const
    {
        if(m_weeklyStartBalance == 0) return 0;
        return (GetWeeklyPnL() / m_weeklyStartBalance) * 100.0;
    }
    
    //--- Get lockout reason
    string GetLockoutReason() const
    {
        return m_lockoutReason;
    }
    
    //--- Get status string
    string GetStatusString() const
    {
        return StringFormat("Daily: %.2f%% | Weekly: %.2f%% | Trading: %s",
                          GetDailyDrawdownPercent(),
                          GetWeeklyDrawdownPercent(),
                          m_tradingAllowed ? "ENABLED" : "DISABLED (" + m_lockoutReason + ")");
    }
    
    //--- Force enable trading (use with caution!)
    void ForceEnable()
    {
        m_tradingAllowed = true;
        m_lockoutReason = "";
        Print("WARNING: Trading manually re-enabled");
    }
};
//+------------------------------------------------------------------+
