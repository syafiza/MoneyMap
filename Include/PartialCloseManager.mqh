//+------------------------------------------------------------------+
//|                                       PartialCloseManager.mqh    |
//|                                   MoneyMap Partial Close Manager |
//|         Scale out of positions to lock profits and let winners run|
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Partial Close Manager                                            |
//| Manages partial position closes at multiple targets              |
//+------------------------------------------------------------------+
class CPartialCloseManager
{
private:
    CTrade*           m_trade;                  // Trade object
    string            m_symbol;                 // Trading symbol
    ulong             m_magicNumber;            // Expert magic number
    double            m_firstTargetPercent;     // First target as % of TP distance
    double            m_firstTargetVolume;      // Volume to close at first target
    bool              m_firstTargetHit;         // First target reached flag
    bool              m_slMovedToBreakEven;     // SL moved to BE flag
    
public:
    //--- Constructor
    CPartialCloseManager(CTrade* trade, string symbol = NULL, ulong magicNumber = 0,
                         double firstTargetPercent = 50.0, double firstTargetVolume = 0.5)
    {
        m_trade = trade;
        m_symbol = (symbol == NULL) ? _Symbol : symbol;
        m_magicNumber = magicNumber;
        m_firstTargetPercent = firstTargetPercent;
        m_firstTargetVolume = firstTargetVolume;
        Reset();
    }
    
    //--- Reset state
    void Reset()
    {
        m_firstTargetHit = false;
        m_slMovedToBreakEven = false;
    }
    
    //--- Update and check for partial close opportunities
    bool Update(double currentPrice)
    {
        if(m_trade == NULL) return false;
        
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
            {
                ulong ticket = PositionGetInteger(POSITION_TICKET);
                double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double tp = PositionGetDouble(POSITION_TP);
                double sl = PositionGetDouble(POSITION_SL);
                double volume = PositionGetDouble(POSITION_VOLUME);
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                
                // Calculate first target price
                double firstTarget = CalculateFirstTarget(entryPrice, tp);
                
                // Check if first target reached
                if(!m_firstTargetHit)
                {
                    bool targetReached = false;
                    
                    if(posType == POSITION_TYPE_BUY)
                        targetReached = (currentPrice >= firstTarget);
                    else if(posType == POSITION_TYPE_SELL)
                        targetReached = (currentPrice <= firstTarget);
                    
                    if(targetReached)
                    {
                        return ExecutePartialClose(ticket, volume, entryPrice, tp);
                    }
                }
                
                return true;
            }
        }
        
        return false;
    }
    
private:
    //--- Calculate first target price
    double CalculateFirstTarget(double entry, double tp)
    {
        double distance = MathAbs(tp - entry);
        double targetDistance = distance * (m_firstTargetPercent / 100.0);
        
        if(tp > entry)  // BUY
            return entry + targetDistance;
        else  // SELL
            return entry - targetDistance;
    }
    
    //--- Execute partial close
    bool ExecutePartialClose(ulong ticket, double totalVolume, double entryPrice, double tp)
    {
        // Calculate volume to close
        double closeVolume = NormalizeDouble(totalVolume * m_firstTargetVolume, 2);
        double minVolume = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
        
        if(closeVolume < minVolume)
        {
            Print("Partial close volume too small: ", closeVolume);
            return false;
        }
        
        // Close partial position
        if(m_trade.PositionClosePartial(ticket, closeVolume))
        {
            Print("SUCCESS: Partial close executed. Ticket: ", ticket,
                  ", Closed: ", closeVolume, " lots at first target");
            
            m_firstTargetHit = true;
            
            // Move SL to break-even on remaining position
            if(!m_slMovedToBreakEven)
            {
                if(m_trade.PositionModify(ticket, entryPrice, tp))
                {
                    Print("SUCCESS: SL moved to break-even after partial close");
                    m_slMovedToBreakEven = true;
                }
                else
                {
                    Print("WARNING: Failed to move SL to break-even. Error: ", GetLastError());
                }
            }
            
            return true;
        }
        else
        {
            Print("ERROR: Partial close failed. Error: ", GetLastError(),
                  ", RetCode: ", m_trade.ResultRetcode());
            return false;
        }
    }
    
public:
    //--- Set first target percentage
    void SetFirstTargetPercent(double percent)
    {
        m_firstTargetPercent = percent;
    }
    
    //--- Set first target volume (0.0 - 1.0)
    void SetFirstTargetVolume(double volume)
    {
        m_firstTargetVolume = MathMax(0.1, MathMin(0.9, volume));
    }
    
    //--- Check if first target was hit
    bool IsFirstTargetHit() const
    {
        return m_firstTargetHit;
    }
};
//+------------------------------------------------------------------+
