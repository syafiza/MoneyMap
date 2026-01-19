//+------------------------------------------------------------------+
//|                                                  TradingCore.mqh |
//|                                           MoneyMap Trading Core  |
//|                   Core trading utilities and position management |
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property link      "https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Constants                                                         |
//+------------------------------------------------------------------+
#define BUFFER_SIZE 3           // Default buffer size for indicator data
#define INVALID_POSITION -1     // Invalid position index

//+------------------------------------------------------------------+
//| Trade Signal Enumeration                                          |
//+------------------------------------------------------------------+
enum ENUM_TRADE_SIGNAL
{
    SIGNAL_NONE,          // No signal
    SIGNAL_BUY,           // Buy signal
    SIGNAL_SELL,          // Sell signal
    SIGNAL_CLOSE_BUY,     // Close buy position
    SIGNAL_CLOSE_SELL     // Close sell position
};

//+------------------------------------------------------------------+
//| Trade Signal Structure                                            |
//+------------------------------------------------------------------+
struct TradeSignal
{
    ENUM_TRADE_SIGNAL type;          // Signal type
    double            price;         // Signal price
    double            stopLoss;      // Stop loss level
    double            takeProfit;    // Take profit level
    string            comment;       // Signal comment
};

//+------------------------------------------------------------------+
//| Position Manager Class                                            |
//| Manages position queries and validation                          |
//+------------------------------------------------------------------+
class CPositionManager
{
private:
    string            m_symbol;              // Trading symbol
    ulong             m_magicNumber;         // Expert magic number
    
public:
    //--- Constructor
    CPositionManager(string symbol = NULL, ulong magicNumber = 0)
    {
        m_symbol = (symbol == NULL) ? _Symbol : symbol;
        m_magicNumber = magicNumber;
    }
    
    //--- Check if position is open for this EA
    bool HasOpenPosition(void)
    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
                return true;
        }
        return false;
    }
    
    //--- Get position ticket if exists
    ulong GetPositionTicket(void)
    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
                return PositionGetInteger(POSITION_TICKET);
        }
        return 0;
    }
    
    //--- Get current position type
    ENUM_POSITION_TYPE GetPositionType(void)
    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
                return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        }
        return INVALID_POSITION;
    }
    
    //--- Get position open price
    double GetPositionOpenPrice(void)
    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
                return PositionGetDouble(POSITION_PRICE_OPEN);
        }
        return 0.0;
    }
    
    //--- Get current stop loss
    double GetStopLoss(void)
    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
                return PositionGetDouble(POSITION_SL);
        }
        return 0.0;
    }
    
    //--- Get current take profit
    double GetTakeProfit(void)
    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
                return PositionGetDouble(POSITION_TP);
        }
        return 0.0;
    }
    
    //--- Count all positions for this EA
    int CountPositions(void)
    {
        int count = 0;
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
                count++;
        }
        return count;
    }
};

//+------------------------------------------------------------------+
//| Order Manager Class                                               |
//| Manages pending order queries                                    |
//+------------------------------------------------------------------+
class COrderManager
{
private:
    string            m_symbol;              // Trading symbol
    ulong             m_magicNumber;         // Expert magic number
    
public:
    //--- Constructor
    COrderManager(string symbol = NULL, ulong magicNumber = 0)
    {
        m_symbol = (symbol == NULL) ? _Symbol : symbol;
        m_magicNumber = magicNumber;
    }
    
    //--- Check if pending order exists for this EA
    bool HasPendingOrder(void)
    {
        for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
            ulong ticket = OrderGetTicket(i);
            string symbol = OrderGetString(ORDER_SYMBOL);
            ulong magic = OrderGetInteger(ORDER_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
                return true;
        }
        return false;
    }
    
    //--- Count pending orders for this EA
    int CountOrders(void)
    {
        int count = 0;
        for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
            ulong ticket = OrderGetTicket(i);
            string symbol = OrderGetString(ORDER_SYMBOL);
            ulong magic = OrderGetInteger(ORDER_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
                count++;
        }
        return count;
    }
    
    //--- Get first pending order ticket
    ulong GetOrderTicket(void)
    {
        for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
            ulong ticket = OrderGetTicket(i);
            string symbol = OrderGetString(ORDER_SYMBOL);
            ulong magic = OrderGetInteger(ORDER_MAGIC);
            
            if(symbol == m_symbol && magic == m_magicNumber)
                return ticket;
        }
        return 0;
    }
};

//+------------------------------------------------------------------+
//| Price Utilities                                                   |
//+------------------------------------------------------------------+
class CPriceUtils
{
public:
    //--- Normalize price to symbol digits
    static double NormalizePrice(double price, string symbol = NULL)
    {
        if(symbol == NULL) symbol = _Symbol;
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        return NormalizeDouble(price, digits);
    }
    
    //--- Calculate stop loss for buy order
    static double CalculateBuyStopLoss(double entryPrice, double slDistance, string symbol = NULL)
    {
        return NormalizePrice(entryPrice - slDistance, symbol);
    }
    
    //--- Calculate take profit for buy order
    static double CalculateBuyTakeProfit(double entryPrice, double tpDistance, string symbol = NULL)
    {
        return NormalizePrice(entryPrice + tpDistance, symbol);
    }
    
    //--- Calculate stop loss for sell order
    static double CalculateSellStopLoss(double entryPrice, double slDistance, string symbol = NULL)
    {
        return NormalizePrice(entryPrice + slDistance, symbol);
    }
    
    //--- Calculate take profit for sell order
    static double CalculateSellTakeProfit(double entryPrice, double tpDistance, string symbol = NULL)
    {
        return NormalizePrice(entryPrice - tpDistance, symbol);
    }
};
//+------------------------------------------------------------------+
