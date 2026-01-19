# MQL5 Coding Standards

This document defines the coding standards and best practices for the MoneyMap project.

## General Principles

1. **Clarity over cleverness** - Write code that's easy to understand
2. **Consistency** - Follow established patterns throughout the codebase
3. **Documentation** - Comment the "why", not the "what"
4. **Error handling** - Always check return values and handle errors
5. **Resource management** - Clean up what you create

## Naming Conventions

### Variables

| Type | Prefix | Example | Notes |
|------|--------|---------|-------|
| Input parameters | `Inp` | `InpSMAPeriod` | User-configurable |
| Global variables | `g_` | `g_trade`, `g_sma` | Module-level scope |
| Member variables | `m_` | `m_handle`, `m_period` | Class members |
| Local variables | none | `signal`, `price` | Function-level scope |
| Constants | `UPPER_CASE` | `BUFFER_SIZE` | All capitals with underscores |

**Examples**:
```mql5
// Input parameters
input int    InpSMAPeriod = 20;
input double InpLotSize = 1.0;

// Global variables
CTrade           g_trade;
CSMAIndicator    g_sma;
CPositionManager* g_posManager;

// Class member variables
class CMyClass
{
private:
    int    m_period;
    double m_value;
};

// Local variables
void OnTick()
{
    double currentPrice;
    ENUM_TRADE_SIGNAL signal;
}

// Constants
#define BUFFER_SIZE 3
#define MAX_RETRIES 5
```

### Functions

- **Use PascalCase** for function names
- **Verbs first** for actions: `ExecuteBuyOrder()`, `CalculateStopLoss()`
- **Boolean functions** start with `Is`, `Has`, `Can`: `IsValid()`, `HasPosition()`
- **Getter** prefix with `Get`: `GetPositionTicket()`
- **Setter** prefix with `Set`: `SetTriggerDistance()`

**Examples**:
```mql5
// Action functions
void ExecuteSignal(ENUM_TRADE_SIGNAL signal);
double CalculateStopLoss(double entry, double distance);

// Boolean functions
bool IsValidPrice(double price);
bool HasOpenPosition();
bool CanPlaceOrder();

// Getters/Setters
ulong GetPositionTicket();
void SetTriggerDistance(double distance);
```

### Classes

- **Use PascalCase** with descriptive names
- **Prefix with `C`** for classes: `CPositionManager`, `CBreakEvenManager`
- **Name reflects responsibility**: Manager, Calculator, Validator

**Examples**:
```mql5
class CPositionManager { };
class COrderManager { };
class CBreakEvenManager { };
class CPriceUtils { };
```

### Files

- **PascalCase** for include files: `TradingCore.mqh`, `RiskManager.mqh`
- **Descriptive names** reflecting contents
- **`.mqh`** extension for include files
- **`.mq5`** extension for Expert Advisors

## Code Formatting

### Indentation

- **3 spaces** (MQL5 standard) or **4 spaces** (consistency is key)
- **No tabs** - convert tabs to spaces
- **Nested blocks** indent one level deeper

```mql5
int OnInit()
{
   if(condition)
   {
      // Code here
      if(nested)
      {
         // Nested code
      }
   }
   return INIT_SUCCEEDED;
}
```

### Braces

- **Opening brace on new line** (Allman style)
- **Always use braces**, even for single-line if statements
- **Closing brace aligned** with opening statement

```mql5
// Correct
if(condition)
{
   DoSomething();
}

// Also acceptable for very short, clear statements
if(price > 0) return true;

// Wrong - avoid
if(condition)
   DoSomething();  // Missing braces
```

### Spacing

- **Space after keywords**: `if (condition)`, `for (i = 0; ...)`
- **Space around operators**: `a = b + c`, `x > y`
- **No space before semicolon**: `DoSomething();`
- **Blank line** between logical sections

```mql5
// Good spacing
if(price > sma && hasSignal)
{
   double entryPrice = NormalizeDouble(price, _Digits);
   double stopLoss = CalculateStopLoss(entryPrice);
   
   ExecuteBuyOrder(entryPrice, stopLoss);
}
```

### Line Length

- **Maximum 100 characters** per line
- **Break long lines** at logical points
- **Align** continued lines for readability

```mql5
// Long parameter lists - break and align
if(trade.Buy(InpLotSize, _Symbol, entryPrice, 
             stopLoss, takeProfit, "Buy Signal"))
{
   Print("Order executed successfully");
}

// Long conditions - break at logical operators
if(price > sma && 
   volume > threshold &&
   currentTime > startTime)
{
   // Execute logic
}
```

## File Structure

### Header Comment

Every file must start with a header:

```mql5
//+------------------------------------------------------------------+
//|                                            [FileName].mq5/mqh    |
//|                                                   [Author]       |
//|                                            [Description]         |
//+------------------------------------------------------------------+
#property copyright "[Author]"
#property link      "[URL]"
#property version   "1.00"
#property description "[Detailed description]"
```

### Organization Order

1. Header comment and properties
2. Includes
3. Constants and enumerations
4. Global variables
5. `OnInit()` function
6. `OnDeinit()` function
7. `OnTick()` or main event handlers
8. Helper functions (alphabetically)

**Example**:
```mql5
//+------------------------------------------------------------------+
//|                                                MyExpert.mq5      |
//+------------------------------------------------------------------+
#property copyright "MoneyMap"
#property version   "1.00"

// Includes
#include <Trade\Trade.mqh>
#include <Include\TradingCore.mqh>

// Constants
#define BUFFER_SIZE 3

// Global variables
CTrade g_trade;
CSMAIndicator g_sma;

// OnInit
int OnInit() { }

// OnDeinit
void OnDeinit(const int reason) { }

// OnTick
void OnTick() { }

// Helper functions
void ExecuteSignal(ENUM_TRADE_SIGNAL signal) { }
ENUM_TRADE_SIGNAL GenerateSignal() { }
bool GetMarketData() { }
```

## Input Parameters

### Organization

- **Group related inputs** using `input group`
- **Descriptive comments** for each parameter
- **Reasonable defaults** that work out-of-box

```mql5
input group "=== Indicator Settings ==="
input int                InpSMAPeriod = 20;              // SMA Period
input ENUM_MA_METHOD     InpSMAMethod = MODE_SMA;        // MA Method

input group "=== Money Management ==="
input double             InpLotSize = 1.0;               // Lot Size
input double             InpStopLoss = 50.0;             // Stop Loss (points)

input group "=== Risk Management ==="
input double             InpBreakEvenTrigger = 30.0;     // Break-Even Trigger
```

### Validation

Validate inputs in `OnInit()`:

```mql5
int OnInit()
{
   // Validate inputs
   if(InpLotSize <= 0)
   {
      Print("ERROR: Invalid lot size: ", InpLotSize);
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpSMAPeriod < 1)
   {
      Print("ERROR: Invalid SMA period: ", InpSMAPeriod);
      return INIT_PARAMETERS_INCORRECT;
   }
   
   return INIT_SUCCEEDED;
}
```

## Error Handling

### Check All API Calls

```mql5
// Get tick data
if(!SymbolInfoTick(_Symbol, tick))
{
   Print("ERROR: Failed to get tick data. Error: ", GetLastError());
   return;
}

// Copy indicator buffer
if(CopyBuffer(handle, 0, 0, 3, buffer) < 0)
{
   Print("ERROR: Failed to copy buffer. Error: ", GetLastError());
   return;
}

// Place order
if(!trade.Buy(lot, symbol, price, sl, tp, ""))
{
   Print("ERROR: Buy order failed. RetCode: ", trade.ResultRetcode(),
         ", Description: ", trade.ResultRetcodeDescription());
}
```

### Logging Standards

- **ERROR**: For failures that prevent operation
- **WARNING**: For issues that don't stop execution
- **INFO**: For successful operations (optional)

```mql5
Print("ERROR: Failed to initialize SMA indicator");
Print("WARNING: High spread detected: ", spread);
Print("INFO: Position opened. Ticket: ", ticket);
```

## Resource Management

### Critical Pattern

```mql5
// Global variables
CSMAIndicator g_sma;
CPositionManager* g_posManager;  // Pointer for dynamic allocation

int OnInit()
{
   // Initialize indicator
   if(!g_sma.Init(period))
      return INIT_FAILED;
   
   // Create manager
   g_posManager = new CPositionManager(_Symbol, MagicNumber);
   
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   // Release indicator
   g_sma.Release();
   
   // Delete manager
   if(g_posManager != NULL)
   {
      delete g_posManager;
      g_posManager = NULL;  // Prevent double-delete
   }
}
```

### Common Mistakes

❌ **Creating resources in OnTick**:
```mql5
void OnTick()
{
   int handle = iMA(...);  // WRONG - Creates leak!
}
```

✅ **Create once in OnInit**:
```mql5
int handle;

int OnInit()
{
   handle = iMA(...);  // Create once
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(handle);  // Clean up
}
```

## Documentation

### Function Comments

Document public functions and complex logic:

```mql5
//+------------------------------------------------------------------+
//| Calculate stop loss for buy order                                |
//| Parameters:                                                       |
//|   entryPrice - Order entry price                                 |
//|   slDistance - Distance in points                                |
//| Returns: Normalized stop loss price                              |
//+------------------------------------------------------------------+
double CalculateBuyStopLoss(double entryPrice, double slDistance)
{
   return NormalizeDouble(entryPrice - slDistance, _Digits);
}
```

### Inline Comments

Comment the "why", not the "what":

```mql5
// Bad - states the obvious
i++;  // Increment i

// Good - explains the reason
i++;  // Skip first candle (incomplete)

// Good - explains complex logic
// Calculate SL: entry - 2*ATR for volatile conditions
double sl = entryPrice - (2.0 * atr);
```

## Best Practices Summary

### DO ✅

- Initialize resources in `OnInit()`
- Clean up in `OnDeinit()`
- Check all API return values
- Use manager classes for common tasks
- Normalize all price values
- Group related input parameters
- Write descriptive variable names
- Keep functions focused and small
- Use early returns to prevent nesting
- Log errors with context

### DON'T ❌

- Create indicators in `OnTick()`
- Ignore error return values
- Use magic numbers in code
- Create massive OnTick functions
- Forget to release resources
- Use single-letter variable names (except loop counters)
- Mix concerns in one function
- Leave debug Print() statements
- Hard-code symbol or period
- Forget input validation

## Code Review Checklist

Before committing code:

- [ ] 0 compilation errors
- [ ] 0 compilation warnings
- [ ] All resources released in OnDeinit
- [ ] All API calls checked for errors
- [ ] Input parameters validated
- [ ] Functions are focused and small
- [ ] Naming follows conventions
- [ ] Code is properly formatted
- [ ] Comments explain complex logic
- [ ] No hardcoded magic numbers
- [ ] Tested in Strategy Tester

## Further Reading

- [MQL5 Style Guide](https://www.mql5.com/en/articles/129)
- [MQL5 Best Practices](https://www.mql5.com/en/articles/68)
- [Clean Code Principles](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
