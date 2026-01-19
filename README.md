# MoneyMap - MQL5 Trading Algorithms

Professional-grade MQL5 trading algorithms and educational material for MetaTrader 5, developed by SCLAB.

## 🎯 Overview

MoneyMap is a collection of refactored, production-quality Expert Advisors (EAs) demonstrating various trading concepts including:

- **Signal Generation**: SMA-based trend following
- **Risk Management**: Break-even and trailing stop automation
- **Time Management**: Trading hours control and session filtering
- **Position Management**: Automated position and order handling

All code follows best practices with modular architecture, proper resource management, and comprehensive error handling.

## 📚 Educational Resources

This repository is designed as educational material. Each EA demonstrates specific trading concepts:

- `Sclab-SMA.mq5` - Signal display and indicator management
- `Sclab-CompraVenda.mq5` - Basic buy/sell execution
- `Sclab-BreakEven.mq5` - Break-even management
- `Sclab-TrailingStop.mq5` - Trailing stop implementation
- `Sclab-ControleHoras.mq5` - Time-based trading filters
- `Sclab-FechaPosicao.mq5` - Position closing utilities
- `Sclab-OrdemPendente.mq5` - Order placement examples
- `Sclab-PosicaoAberta.mq5` - Position validation

**YouTube Channel**: [SCLAB](https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g)

## 🏗️ Architecture

### Shared Libraries (`Include/` directory)

The codebase uses modular shared libraries to eliminate code duplication:

#### `TradingCore.mqh`
- `CPositionManager` - Position queries and validation
- `COrderManager` - Pending order management
- `CPriceUtils` - Price normalization and calculation
- Trade signal enumerations and structures

#### `RiskManager.mqh`
- `CBreakEvenManager` - Automatic break-even management
- `CTrailingStopManager` - Dynamic trailing stop implementation

#### `TimeManager.mqh`
- `CTimeManager` - Trading hours validation and session control

#### `IndicatorManager.mqh`
- `CSMAIndicator` - SMA lifecycle management (prevents memory leaks!)

### Design Patterns

- **Resource Management**: All indicators created in `OnInit()`, released in `OnDeinit()`
- **Separation of Concerns**: Market data, signal generation, and execution separated
- **Defensive Programming**: Comprehensive error handling and input validation
- **Reusable Components**: Manager classes for common functionality

## 🚀 Installation

1. **Clone or download** this repository
2. **Copy files** to your MetaTrader 5 directory:
   - EAs (`.mq5` files) → `MQL5/Experts/`
   - Libraries (`Include/` folder) → `MQL5/Experts/Include/`
3. **Compile** in MetaEditor (F7 on each file)
4. **Attach** EA to a chart in MetaTrader 5

## ⚙️ Configuration

Each EA has configurable input parameters organized into groups:

### Common Parameters

- **Indicator Settings**: SMA period, shift, method, applied price
- **Trading Settings**: Magic number, deviation, fill type
- **Money Management**: Lot size, stop loss, take profit
- **Risk Management**: Break-even trigger, trailing stop settings
- **Time Management**: Trading hours, closing time (where applicable)

### Example Configuration

```mql5
// Indicator Settings
InpSMAPeriod = 20          // SMA lookback period
InpSMAMethod = MODE_SMA    // Simple moving average

// Money Management
InpLotSize = 1.0           // Trade volume
InpStopLoss = 50.0         // Points
InpTakeProfit = 100.0      // Points

// Risk Management
InpBreakEvenTrigger = 30.0 // Move SL to BE at +30 points
InpTrailingTrigger = 40.0  // Start trailing at +40 points
InpTrailingStep = 10.0     // Move SL in 10-point steps
```

## 📖 Usage Examples

### Basic Signal Display

Use `Sclab-SMA.mq5` to visualize buy/sell signals without trading:

```
1. Attach Sclab-SMA.mq5 to chart
2. Set InpSMAPeriod to desired value (default: 20)
3. Set InpShowComment = true
4. EA displays "BUY" or "SELL" based on price vs SMA
```

### Automated Trading with Risk Management

Use `Sclab-TrailingStop.mq5` for full automated trading:

```
1. Attach Sclab-TrailingStop.mq5 to chart
2. Configure lot size and risk parameters
3. EA will:
   - Open positions based on SMA signals
   - Move stop loss to break-even when profitable
   - Trail stop loss to protect profits
```

### Time-Controlled Trading

Use `Sclab-ControleHoras.mq5` to restrict trading hours:

```
1. Attach Sclab-ControleHoras.mq5 to chart
2. Set InpUseTimeFilter = true
3. Configure trading hours (e.g., 9:00 - 17:00)
4. Set closing time (e.g., 17:50)
5. EA only trades during specified hours and auto-closes positions
```

## ⚠️ Risk Disclaimer

**WARNING**: Trading financial instruments carries significant risk. These EAs are provided for **educational purposes only**. 

- Past performance does not guarantee future results
- Always test on a demo account first
- Use proper risk management (1-2% per trade max)
- Never trade with money you cannot afford to lose
- The authors are not responsible for any trading losses

## 🔧 Development

### Code Standards

- **Language**: English (variables, functions, comments)
- **Formatting**: Consistent indentation, clear spacing
- **Naming**: Descriptive names with proper prefixes (Inp*, g_*, m_*)
- **Documentation**: File headers and function documentation
- **Error Handling**: Comprehensive error checking with logging

See `CODING_STANDARDS.md` for detailed guidelines.

### Testing

All EAs should be tested using:

1. **Compilation**: Verify 0 errors, 0 warnings (F7 in MetaEditor)
2. **Strategy Tester**: Backtest on historical data (Ctrl+R in MT5)
3. **Demo Account**: Forward test on live market data
4. **Code Review**: Peer review for quality assurance

### Contributing

Contributions are welcome! Please:

1. Follow existing code style and standards
2. Test thoroughly before submitting
3. Update documentation as needed
4. Submit pull requests with clear descriptions

## 📄 License

This project is provided for educational purposes. Please respect the original authors' work and provide attribution when using or modifying the code.

## 🔗 Links

- **YouTube Channel**: [SCLAB](https://www.youtube.com/channel/UCX9926NagPLxyUcSkqDhE_g)
- **MetaTrader 5**: [Download](https://www.metatrader5.com/)
- **MQL5 Documentation**: [Reference](https://www.mql5.com/en/docs)

## 📞 Support

For questions and support:
- Watch the SCLAB YouTube tutorials
- Refer to the MQL5 documentation
- Test on demo accounts before live trading

---

**Remember**: Education is the best investment in trading success! 📚💹
