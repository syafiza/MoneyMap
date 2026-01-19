# MoneyMap Architecture

This document describes the architectural design and patterns used in the MoneyMap MQL5 codebase.

## Design Philosophy

The MoneyMap architecture follows these core principles:

1. **Modularity**: Reusable components in shared libraries
2. **Separation of Concerns**: Data, logic, and execution separated
3. **Resource Management**: Proper lifecycle management to prevent leaks
4. **Defensive Programming**: Comprehensive error handling
5. **Educational Clarity**: Code is easy to understand and learn from

## Component Architecture

```
MoneyMap/
├── Include/                    # Shared library components
│   ├── TradingCore.mqh        # Core trading utilities
│   ├── RiskManager.mqh        # Risk management classes
│   ├── TimeManager.mqh        # Time and session management
│   └── IndicatorManager.mqh   # Indicator lifecycle management
│
└── *.mq5                      # Expert Advisors
    ├── Sclab-SMA.mq5          # Signal display
    ├── Sclab-CompraVenda.mq5  # Basic trading
    ├── Sclab-BreakEven.mq5    # Break-even management
    ├── Sclab-TrailingStop.mq5 # Trailing stop
    ├── Sclab-ControleHoras.mq5# Time-controlled trading
    └── ...
```

## Shared Libraries

### TradingCore.mqh

**Purpose**: Core trading utilities used across all EAs

**Components**:

#### CPositionManager
Manages position queries and validation for a specific symbol and magic number.

**Key Methods**:
- `HasOpenPosition()` - Check if position exists
- `GetPositionTicket()` - Retrieve position ticket
- `GetPositionType()` - Get BUY or SELL type
- `GetPositionOpenPrice()` - Get entry price
- `CountPositions()` - Count all positions

**Usage**:
```mql5
CPositionManager* posManager = new CPositionManager(_Symbol, MagicNumber);
if(posManager.HasOpenPosition())
{
    // Position management logic
}
```

#### COrderManager
Manages pending order queries.

**Key Methods**:
- `HasPendingOrder()` - Check if pending order exists
- `CountOrders()` - Count pending orders
- `GetOrderTicket()` - Retrieve order ticket

#### CPriceUtils
Static utility class for price calculations and normalization.

**Key Methods**:
- `NormalizePrice()` - Normalize to symbol digits
- `CalculateBuyStopLoss()` - Calculate SL for buy
- `CalculateBuyTakeProfit()` - Calculate TP for buy
- `CalculateSellStopLoss()` - Calculate SL for sell
- `CalculateSellTakeProfit()` - Calculate TP for sell

**Why Static?**: These are pure utility functions that don't maintain state.

### RiskManager.mqh

**Purpose**: Break-even and trailing stop management

#### CBreakEvenManager
Automatically moves stop loss to entry price when profit threshold is reached.

**State Management**:
- `m_isActive` - Tracks if break-even has been triggered
- Call `Reset()` when position closes

**Usage Pattern**:
```mql5
// In OnInit
breakEven = new CBreakEvenManager(&trade, _Symbol, MagicNum, TriggerDistance);

// In OnTick
if(hasPosition && !breakEven.IsActive())
{
    breakEven.Update(currentPrice);
}

// When position closes
if(!hasPosition)
{
    breakEven.Reset();
}
```

#### CTrailingStopManager
Dynamically adjusts stop loss as price moves favorably.

**Configuration**:
- `m_triggerDistance` - How far price must move to activate
- `m_stepDistance` - How much to move SL each update

**Sequential Risk Management**:
1. First: Break-even activates
2. Then: Trailing stop takes over

### TimeManager.mqh

**Purpose**: Trading hours and session management

#### CTimeManager
Validates trading times and manages session restrictions.

**Key Features**:
- Trading window validation
- Closing time notifications
- Enable/disable time filters
- Static utilities (new bar detection)

**Usage**:
```mql5
timeManager = new CTimeManager(startHour, startMin, endHour, endMin);
timeManager.SetClosingTime(closeHour, closeMin);
timeManager.Enable();

if(timeManager.IsTradingTime())
{
    // Execute trading logic
}

if(timeManager.IsClosingTime())
{
    // Close positions
}
```

### IndicatorManager.mqh

**Purpose**: Proper indicator lifecycle management

#### CSMAIndicator
Wraps iMA() with proper resource management to prevent memory leaks.

**Critical Pattern**:
```mql5
// WRONG (creates leak):
void OnTick()
{
    int handle = iMA(...);  // Creates new handle every tick!
    // Memory grows continuously
}

// CORRECT (using CSMAIndicator):
CSMAIndicator sma;

int OnInit()
{
    sma.Init(period, shift, method, price);  // Create once
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    sma.Release();  // Clean up
}

void OnTick()
{
    sma.Update(3);  // Just update data
    double value = sma.GetValue(0);
}
```

## Expert Advisor Structure

All EAs follow this standard structure:

```mql5
// 1. Includes
#include <Trade\Trade.mqh>
#include <Include\TradingCore.mqh>
// ... other includes

// 2. Input Parameters (organized in groups)
input group "=== Indicator Settings ==="
input int InpSMAPeriod = 20;
// ...

// 3. Global Variables (with proper prefixes)
CTrade g_trade;                    // g_ for global
CSMAIndicator g_sma;
CPositionManager* g_posManager;    // Pointer for dynamic allocation

// 4. OnInit - Initialize resources
int OnInit()
{
    // Initialize indicators
    if(!g_sma.Init(...)) return INIT_FAILED;
    
    // Create managers
    g_posManager = new CPositionManager(...);
    
    return INIT_SUCCEEDED;
}

// 5. OnDeinit - Clean up resources
void OnDeinit(const int reason)
{
    g_sma.Release();
    if(g_posManager != NULL) delete g_posManager;
}

// 6. OnTick - Main logic
void OnTick()
{
    if(!GetMarketData()) return;     // Data acquisition
    
    bool hasPosition = g_posManager.HasOpenPosition();
    
    if(hasPosition)
    {
        // Risk management logic
    }
    else
    {
        ENUM_TRADE_SIGNAL signal = GenerateSignal();
        ExecuteSignal(signal);
    }
}

// 7. Helper Functions (alphabetically)
void ExecuteSignal(ENUM_TRADE_SIGNAL signal) { }
ENUM_TRADE_SIGNAL GenerateSignal() { }
bool GetMarketData() { }
```

## Design Patterns

### 1. Manager Pattern
Each major concern has a dedicated manager class:
- Position management → `CPositionManager`
- Order management → `COrderManager`
- Risk management → `CBreakEvenManager`, `CTrailingStopManager`
- Time management → `CTimeManager`

**Benefits**: 
- Encapsulation of related functionality
- Reusability across EAs
- Easier testing and maintenance

### 2. Resource Acquisition Is Initialization (RAII)
Resources acquired in `OnInit()`, released in `OnDeinit()`:

```mql5
int OnInit()
{
    // Acquire
    g_sma.Init(...);
    g_posManager = new CPositionManager(...);
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    // Release
    g_sma.Release();
    delete g_posManager;
}
```

**Why**: Prevents memory leaks and ensures clean shutdown.

### 3. Separation of Concerns
Each function has one clear responsibility:

- `GetMarketData()` - Data acquisition only
- `GenerateSignal()` - Signal logic only
- `ExecuteSignal()` - Order execution only

**Benefits**: Easier to understand, test, and modify.

### 4. Early Return Pattern
Validate inputs and fail fast:

```mql5
void OnTick()
{
    if(!GetMarketData()) return;  // Exit early if data fails
    
    // Main logic only executes with valid data
}
```

## Error Handling Strategy

### Three-Layer Approach

1. **Prevention**: Input validation in `OnInit()`
2. **Detection**: Check return values and error codes
3. **Logging**: Comprehensive error messages

**Example**:
```mql5
// Prevention
if(!g_sma.Init(period))
{
    Print("ERROR: Invalid SMA parameters");
    return INIT_FAILED;
}

// Detection
if(!SymbolInfoTick(_Symbol, tick))
{
    Print("ERROR: Failed to get tick. Error: ", GetLastError());
    return;  // Safe exit
}

// Logging
if(!trade.Buy(...))
{
    Print("BUY failed. RetCode: ", trade.ResultRetcode(),
          ", Description: ", trade.ResultRetcodeDescription());
}
```

## Memory Management

### Rules
1. **Create once**: Indicators in `OnInit()`, not `OnTick()`
2. **Clean up**: Always release in `OnDeinit()`
3. **Check pointers**: Before delete, verify `!= NULL`
4. **Set to NULL**: After delete, set pointer to NULL

### Common Mistakes (AVOIDED)

❌ **Creating indicator every tick** (Sclab-SMA.mq5 v1.0):
```mql5
void OnTick()
{
    int handle = iMA(...);  // LEAK!
}
```

✅ **Correct approach** (Sclab-SMA.mq5 v2.0):
```mql5
CSMAIndicator g_sma;

int OnInit() { g_sma.Init(...); }
void OnDeinit() { g_sma.Release(); }
void OnTick() { g_sma.Update(3); }
```

## Extension Guidelines

### Adding a New EA

1. Start with template structure (see "Expert Advisor Structure")
2. Include necessary shared libraries
3. Follow naming conventions (see CODING_STANDARDS.md)
4. Implement initialization, cleanup, and main logic
5. Test compilation and basic functionality

### Adding a New Manager Class

1. Create in appropriate `.mqh` file
2. Follow existing class patterns
3. Include constructor/destructor
4. Implement cleanup methods
5. Add comprehensive error handling
6. Document usage patterns

### Adding a New Indicator

1. Create wrapper class in `IndicatorManager.mqh`
2. Pattern: Init(), Update(), GetValue(), Release()
3. Store handle and buffer as member variables
4. Implement proper cleanup in Release()

## Performance Considerations

1. **Minimize API calls**: Cache frequently accessed data
2. **Early termination**: Use early returns to avoid unnecessary work
3. **Efficient loops**: Iterate backward when deleting (positions/orders)
4. **Lazy evaluation**: Only calculate what's needed when needed

## Testing Strategy

Since MQL5 lacks standard unit testing frameworks:

1. **Compilation**: Must have 0 errors, 0 warnings
2. **Strategy Tester**: Backtest each EA on historical data
3. **Memory monitoring**: Watch Task Manager during backtests
4. **Demo trading**: Forward test on live data
5. **Code review**: Peer review for quality

## Further Reading

- [MQL5 Documentation](https://www.mql5.com/en/docs)
- [Object-Oriented Programming in MQL5](https://www.mql5.com/en/articles/44)
- [Memory Management in MQL5](https://www.mql5.com/en/articles/157)
