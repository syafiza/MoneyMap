//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                                           MoneyMap Risk Manager  |
//|                   Break-even and trailing stop management        |
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Break-Even Manager Class                                         |
//| Moves stop loss to entry price when profit threshold reached    |
//+------------------------------------------------------------------+
class CBreakEvenManager
{
private:
    CTrade*           m_trade;               // Trade object pointer
    string            m_symbol;              // Trading symbol
    ulong             m_magicNumber;         // Expert magic number
    double            m_triggerDistance;     // Distance to activate break-even
    bool              m_isActive;            // Break-even active flag
    
public:
    //--- Constructor
    CBreakEvenManager(CTrade* trade, string symbol = NULL, ulong magicNumber = 0, double triggerDistance = 0.0)
    {
        m_trade = trade;
        m_symbol = (symbol == NULL) ? _Symbol : symbol;
        m_magicNumber = magicNumber;
        m_triggerDistance = triggerDistance;
        m_isActive = false;
    }
    
    //--- Reset break-even state (call when position closes)
    void Reset(void)
    {
        m_isActive = false;
    }
    
    //--- Check if break-even is active
    bool IsActive(void) const
    {
        return m_isActive;
    }
    
    //--- Update break-even for current position
    bool Update(double currentPrice)
    {
        if(m_isActive || m_trade == NULL)
            return false;
            
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
            {
                ulong ticket = PositionGetInteger(POSITION_TICKET);
                double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double currentTP = PositionGetDouble(POSITION_TP);
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                
                bool triggerReached = false;
                
                if(posType == POSITION_TYPE_BUY)
                {
                    triggerReached = (currentPrice >= (entryPrice + m_triggerDistance));
                }
                else if(posType == POSITION_TYPE_SELL)
                {
                    triggerReached = (currentPrice <= (entryPrice - m_triggerDistance));
                }
                
                if(triggerReached)
                {
                    if(m_trade.PositionModify(ticket, entryPrice, currentTP))
                    {
                        Print("Break-Even activated successfully. Ticket: ", ticket);
                        m_isActive = true;
                        return true;
                    }
                    else
                    {
                        Print("Break-Even modification failed. Error: ", GetLastError(), 
                              ", RetCode: ", m_trade.ResultRetcode());
                        return false;
                    }
                }
            }
        }
        return false;
    }
};

//+------------------------------------------------------------------+
//| Trailing Stop Manager Class                                      |
//| Dynamically adjusts stop loss to protect profits                |
//+------------------------------------------------------------------+
class CTrailingStopManager
{
private:
    CTrade*           m_trade;               // Trade object pointer
    string            m_symbol;              // Trading symbol
    ulong             m_magicNumber;         // Expert magic number
    double            m_triggerDistance;     // Distance to activate trailing
    double            m_stepDistance;        // Distance to move stop loss
    
public:
    //--- Constructor
    CTrailingStopManager(CTrade* trade, string symbol = NULL, ulong magicNumber = 0, 
                         double triggerDistance = 0.0, double stepDistance = 0.0)
    {
        m_trade = trade;
        m_symbol = (symbol == NULL) ? _Symbol : symbol;
        m_magicNumber = magicNumber;
        m_triggerDistance = triggerDistance;
        m_stepDistance = stepDistance;
    }
    
    //--- Update trailing stop for current position
    bool Update(double currentPrice)
    {
        if(m_trade == NULL)
            return false;
            
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
            {
                ulong ticket = PositionGetInteger(POSITION_TICKET);
                double currentSL = PositionGetDouble(POSITION_SL);
                double currentTP = PositionGetDouble(POSITION_TP);
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                
                bool shouldModify = false;
                double newSL = currentSL;
                
                if(posType == POSITION_TYPE_BUY)
                {
                    if(currentPrice >= (currentSL + m_triggerDistance))
                    {
                        newSL = NormalizeDouble(currentSL + m_stepDistance, _Digits);
                        shouldModify = true;
                    }
                }
                else if(posType == POSITION_TYPE_SELL)
                {
                    if(currentPrice <= (currentSL - m_triggerDistance))
                    {
                        newSL = NormalizeDouble(currentSL - m_stepDistance, _Digits);
                        shouldModify = true;
                    }
                }
                
                if(shouldModify)
                {
                    if(m_trade.PositionModify(ticket, newSL, currentTP))
                    {
                        Print("Trailing Stop updated successfully. New SL: ", newSL);
                        return true;
                    }
                    else
                    {
                        Print("Trailing Stop modification failed. Error: ", GetLastError(),
                              ", RetCode: ", m_trade.ResultRetcode());
                        return false;
                    }
                }
            }
        }
        return false;
    }
    
    //--- Set trigger distance
    void SetTriggerDistance(double distance)
    {
        m_triggerDistance = distance;
    }
    
    //--- Set step distance
    void SetStepDistance(double distance)
    {
        m_stepDistance = distance;
    }
};
//+------------------------------------------------------------------+
