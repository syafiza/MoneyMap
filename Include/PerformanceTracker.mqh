//+------------------------------------------------------------------+
//|                                    PerformanceTracker.mqh        |
//|                                 MoneyMap Performance Tracker     |
//|             Track and display EA performance metrics              |
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Performance Tracking and Analytics                               |
//| Monitors trade statistics and displays performance dashboard     |
//+------------------------------------------------------------------+
class CPerformanceTracker
{
private:
    int               m_totalTrades;            // Total number of trades
    int               m_winningTrades;          // Number of winning trades
    int               m_losingTrades;           // Number of losing trades
    double            m_totalProfit;            // Sum of all profits
    double            m_totalLoss;              // Sum of all losses (absolute)
    double            m_largestWin;             // Largest single win
    double            m_largestLoss;            // Largest single loss (absolute)
    double            m_grossProfit;            // Total of wins
    double            m_grossLoss;              // Total of losses
    int               m_consecutiveWins;        // Current win streak
    int               m_consecutiveLosses;      // Current loss streak
    int               m_maxConsecutiveWins;     // Max win streak
    int               m_maxConsecutiveLosses;   // Max loss streak
    double            m_initialBalance;         // Starting balance
    bool              m_displayOnChart;         // Show stats on chart
    
public:
    //--- Constructor
    CPerformanceTracker(bool displayOnChart = true)
    {
        Reset();
        m_displayOnChart = displayOnChart;
        m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    }
    
    //--- Reset all statistics
    void Reset()
    {
        m_totalTrades = 0;
        m_winningTrades = 0;
        m_losingTrades = 0;
        m_totalProfit = 0;
        m_totalLoss = 0;
        m_largestWin = 0;
        m_largestLoss = 0;
        m_grossProfit = 0;
        m_grossLoss = 0;
        m_consecutiveWins = 0;
        m_consecutiveLosses = 0;
        m_maxConsecutiveWins = 0;
        m_maxConsecutiveLosses = 0;
    }
    
    //--- Record a trade result
    void RecordTrade(double profit, double volume)
    {
        m_totalTrades++;
        
        if(profit > 0)
        {
            // Winning trade
            m_winningTrades++;
            m_totalProfit += profit;
            m_grossProfit += profit;
            
            if(profit > m_largestWin)
                m_largestWin = profit;
            
            m_consecutiveWins++;
            m_consecutiveLosses = 0;
            
            if(m_consecutiveWins > m_maxConsecutiveWins)
                m_maxConsecutiveWins = m_consecutiveWins;
        }
        else if(profit < 0)
        {
            // Losing trade
            m_losingTrades++;
            double absLoss = MathAbs(profit);
            m_totalLoss += absLoss;
            m_grossLoss += absLoss;
            
            if(absLoss > m_largestLoss)
                m_largestLoss = absLoss;
            
            m_consecutiveLosses++;
            m_consecutiveWins = 0;
            
            if(m_consecutiveLosses > m_maxConsecutiveLosses)
                m_maxConsecutiveLosses = m_consecutiveLosses;
        }
        
        if(m_displayOnChart)
            DisplayStats();
    }
    
    //--- Display statistics on chart
    void DisplayStats()
    {
        double winRate = CalculateWinRate();
        double profitFactor = CalculateProfitFactor();
        double avgWin = CalculateAvgWin();
        double avgLoss = CalculateAvgLoss();
        double sharpeRatio = CalculateSharpeRatio();
        double netProfit = m_totalProfit - m_totalLoss;
        double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double totalReturn = ((currentBalance - m_initialBalance) / m_initialBalance) * 100.0;
        
        string stats = StringFormat(
            "\n╔════════════════════════════════╗\n" +
            "║   EA PERFORMANCE DASHBOARD     ║\n" +
            "╠════════════════════════════════╣\n" +
            "║ Total Trades:      %4d        ║\n" +
            "║ Win Rate:          %.1f%%       ║\n" +
            "║ Profit Factor:     %.2f        ║\n" +
            "╠════════════════════════════════╣\n" +
            "║ Avg Win:          $%.2f      ║\n" +
            "║ Avg Loss:         $%.2f      ║\n" +
            "║ Largest Win:      $%.2f      ║\n" +
            "║ Largest Loss:     $%.2f      ║\n" +
            "╠════════════════════════════════╣\n" +
            "║ Win Streak:        %d / %d       ║\n" +
            "║ Loss Streak:       %d / %d       ║\n" +
            "╠════════════════════════════════╣\n" +
            "║ Net P/L:          $%.2f      ║\n" +
            "║ Total Return:      %.2f%%       ║\n" +
            "║ Sharpe Ratio:      %.2f        ║\n" +
            "╚════════════════════════════════╝",
            m_totalTrades,
            winRate,
            profitFactor,
            avgWin,
            avgLoss,
            m_largestWin,
            m_largestLoss,
            m_consecutiveWins, m_maxConsecutiveWins,
            m_consecutiveLosses, m_maxConsecutiveLosses,
            netProfit,
            totalReturn,
            sharpeRatio
        );
        
        Comment(stats);
    }
    
    //--- Calculate win rate
    double CalculateWinRate() const
    {
        return (m_totalTrades > 0) ? ((double)m_winningTrades / m_totalTrades) * 100.0 : 0.0;
    }
    
    //--- Calculate profit factor
    double CalculateProfitFactor() const
    {
        return (m_grossLoss > 0) ? m_grossProfit / m_grossLoss : 0.0;
    }
    
    //--- Calculate average win
    double CalculateAvgWin() const
    {
        return (m_winningTrades > 0) ? m_totalProfit / m_winningTrades : 0.0;
    }
    
    //--- Calculate average loss
    double CalculateAvgLoss() const
    {
        return (m_losingTrades > 0) ? m_totalLoss / m_losingTrades : 0.0;
    }
    
    //--- Calculate simple Sharpe ratio
    double CalculateSharpeRatio() const
    {
        if(m_totalTrades < 2) return 0.0;
        
        double avgProfit = (m_totalProfit - m_totalLoss) / m_totalTrades;
        // Simplified: would need trade-by-trade returns for accurate calculation
        return avgProfit / (m_totalLoss / m_totalTrades);
    }
    
    //--- Get statistics summary
    string GetSummary() const
    {
        return StringFormat("Trades: %d | Win Rate: %.1f%% | PF: %.2f | Net: $%.2f",
                          m_totalTrades,
                          CalculateWinRate(),
                          CalculateProfitFactor(),
                          m_totalProfit - m_totalLoss);
    }
    
    //--- Enable/disable chart display
    void SetDisplayOnChart(bool display)
    {
        m_displayOnChart = display;
        if(!display) Comment("");
    }
};
//+------------------------------------------------------------------+
