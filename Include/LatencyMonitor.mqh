//+------------------------------------------------------------------+
//|                                      LatencyMonitor.mqh          |
//|                                   MoneyMap Latency Monitor       |
//|            Monitor EA performance and execution time              |
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Latency Monitor and Performance Optimizer                        |
//| Tracks OnTick execution time and identifies bottlenecks          |
//+------------------------------------------------------------------+
class CLatencyMonitor
{
private:
    ulong             m_tickStartTime;          // Tick processing start time (microseconds)
    ulong             m_totalTicks;             // Total ticks processed
    ulong             m_totalTime;              // Total time spent (microseconds)
    ulong             m_maxTickTime;            // Slowest tick time
    ulong             m_avgTickTime;            // Average tick time
    double            m_avgTimeMs;              // Average time in milliseconds
    bool              m_displayWarnings;        // Show warnings for slow ticks
    ulong             m_warningThreshold;       // Threshold for warnings (microseconds)
    
public:
    //--- Constructor
    CLatencyMonitor(ulong warningThresholdMs = 10)
    {
        m_totalTicks = 0;
        m_totalTime = 0;
        m_maxTickTime = 0;
        m_avgTickTime = 0;
        m_displayWarnings = true;
        m_warningThreshold = warningThresholdMs * 1000;  // Convert ms to microseconds
    }
    
    //--- Start timing a tick
    void StartTick()
    {
        m_tickStartTime = GetMicrosecondCount();
    }
    
    //--- End timing and record
    void EndTick()
    {
        ulong tickTime = GetMicrosecondCount() - m_tickStartTime;
        
        m_totalTicks++;
        m_totalTime += tickTime;
        
        if(tickTime > m_maxTickTime)
            m_maxTickTime = tickTime;
        
        m_avgTickTime = m_totalTime / m_totalTicks;
        m_avgTimeMs = m_avgTickTime / 1000.0;
        
        // Warn about slow ticks
        if(m_displayWarnings && tickTime > m_warningThreshold)
        {
            Print("⚠️ SLOW TICK: ", tickTime / 1000.0, " ms (Threshold: ", m_warningThreshold / 1000.0, " ms)");
        }
    }
    
    //--- Get average execution time in milliseconds
    double GetAvgTimeMs() const
    {
        return m_avgTimeMs;
    }
    
    //--- Get max execution time in milliseconds
    double GetMaxTimeMs() const
    {
        return m_maxTickTime / 1000.0;
    }
    
    //--- Get statistics string
    string GetStatsString() const
    {
        return StringFormat("Latency: Avg %.2fms | Max %.2fms | Ticks: %d",
                          m_avgTimeMs,
                          m_maxTickTime / 1000.0,
                          m_totalTicks);
    }
    
    //--- Check if performance is acceptable (< 5ms average)
    bool IsPerformanceGood() const
    {
        return m_avgTimeMs < 5.0;
    }
    
    //--- Reset statistics
    void Reset()
    {
        m_totalTicks = 0;
        m_totalTime = 0;
        m_maxTickTime = 0;
        m_avgTickTime = 0;
    }
    
    //--- Enable/disable warnings
    void SetDisplayWarnings(bool display)
    {
        m_displayWarnings = display;
    }
    
    //--- Set warning threshold
    void SetWarningThreshold(ulong thresholdMs)
    {
        m_warningThreshold = thresholdMs * 1000;
    }
};

//+------------------------------------------------------------------+
//| Tick Rate Limiter - Prevent over-processing                      |
//| Only process every N ticks or after time threshold               |
//+------------------------------------------------------------------+
class CTickRateLimiter
{
private:
    int               m_processEveryNTicks;     // Process every N ticks
    int               m_tickCounter;            // Current tick counter
    datetime          m_lastProcessTime;        // Last processing timestamp
    int               m_minSecondsBetween;      // Minimum seconds between processing
    
public:
    //--- Constructor
    CTickRateLimiter(int processEveryNTicks = 1, int minSecondsBetween = 0)
    {
        m_processEveryNTicks = processEveryNTicks;
        m_tickCounter = 0;
        m_lastProcessTime = 0;
        m_minSecondsBetween = minSecondsBetween;
    }
    
    //--- Check if should process this tick
    bool ShouldProcess()
    {
        m_tickCounter++;
        
        // Check tick count threshold
        if(m_tickCounter < m_processEveryNTicks)
            return false;
        
        // Check time threshold
        datetime currentTime = TimeCurrent();
        if(m_minSecondsBetween > 0)
        {
            if(currentTime - m_lastProcessTime < m_minSecondsBetween)
                return false;
        }
        
        // Reset and process
        m_tickCounter = 0;
        m_lastProcessTime = currentTime;
        return true;
    }
    
    //--- Reset counter
    void Reset()
    {
        m_tickCounter = 0;
        m_lastProcessTime = 0;
    }
};

//+------------------------------------------------------------------+
//| Cached Indicator Values - Avoid redundant updates                |
//+------------------------------------------------------------------+
class CIndicatorCache
{
private:
    datetime          m_lastUpdateTime;         // Last update bar time
    bool              m_needsUpdate;            // Update flag
    
public:
    //--- Constructor
    CIndicatorCache()
    {
        m_lastUpdateTime = 0;
        m_needsUpdate = true;
    }
    
    //--- Check if indicators need update (new bar formed)
    bool NeedsUpdate()
    {
        datetime currentBarTime = iTime(_Symbol, _Period, 0);
        
        if(currentBarTime != m_lastUpdateTime)
        {
            m_lastUpdateTime = currentBarTime;
            m_needsUpdate = true;
            return true;
        }
        
        return false;
    }
    
    //--- Mark as updated
    void MarkUpdated()
    {
        m_needsUpdate = false;
    }
    
    //--- Force update
    void ForceUpdate()
    {
        m_needsUpdate = true;
    }
};
//+------------------------------------------------------------------+
