# Examples - Educational MQL5 Demos

This folder contains basic MQL5 educational examples demonstrating fundamental concepts. These are **learning materials** - not production-ready trading EAs.

---

## 📚 What's in This Folder

### Market Data Examples

#### `Sclab-AskBid.mq5`
**Purpose**: Display Ask/Bid prices  
**Demonstrates**: `SymbolInfoDouble()`, SYMBOL_ASK, SYMBOL_BID  
**Learning**: How to get current market prices

#### `Sclab-MqlTick.mq5`
**Purpose**: Display tick data structure  
**Demonstrates**: `SymbolInfoTick()`, MqlTick structure  
**Learning**: Understanding tick data (bid, ask, last, volume, time)

#### `Sclab-MqlRates.mq5`
**Purpose**: Display candlestick data  
**Demonstrates**: `CopyRates()`, MqlRates structure  
**Learning**: Working with OHLC candlestick data

---

### Basic Concepts

#### `Sclab-OnInit.mq5`
**Purpose**: Demonstrate EA initialization  
**Demonstrates**: `OnInit()`, `OnDeinit()`, initialization patterns  
**Learning**: EA lifecycle management basics

#### `Sclab-NormalizeDouble.mq5`
**Purpose**: Price normalization examples  
**Demonstrates**: `NormalizeDouble()`, `_Digits`, price formatting  
**Learning**: Proper price handling (NOW covered in `TradingCore.mqh`)

---

### Input Parameters

#### `Sclab-Inputs(1).mq5`
**Purpose**: Basic input parameter example  
**Demonstrates**: `input` keyword, parameter types  
**Learning**: How to create user-configurable settings

#### `Sclab-inputsEnum.mq5`
**Purpose**: Enumeration inputs  
**Demonstrates**: `enum`, enumeration types as inputs  
**Learning**: Creating dropdown selection inputs

---

### Trading Settings

#### `Sclab-TypeFilling-Deviation-ExpertMagicNumber.mq5`
**Purpose**: Trade execution settings  
**Demonstrates**: Order filling types, deviation, magic numbers  
**Learning**: Trade configuration basics (NOW covered in all production EAs)

---

### Utilities

#### `Sclab-Verificacao.mq5`
**Purpose**: Verification/validation examples  
**Demonstrates**: Checking conditions, validation patterns  
**Learning**: Error checking and validation techniques

---

## ⚠️ Important Notes

### These Are NOT Production Ready!

❌ **Don't use for live trading**  
❌ **No error handling**  
❌ **No resource management**  
❌ **Basic concepts only**  

### Use These Instead: ✅

For **production trading**, use the refactored EAs in the main folder:

| If You Want... | Use This Production EA |
|----------------|------------------------|
| Learn basics | `Sclab-CompraVenda.mq5` |
| Risk management | `Sclab-BreakEven.mq5` or `Sclab-TrailingStop.mq5` |
| Time filters | `Sclab-ControleHoras.mq5` |
| **ALL features** | `Sclab-TradingPro.mq5` ⭐ |

---

## 🎓 Learning Path

### Beginner Path:
1. **Start here**: Read these examples to understand basics
2. **Then study**: Production EAs to see best practices
3. **Compare**: Notice the differences in quality

### What You'll Learn:

**From Examples/** (this folder):
- Basic MQL5 syntax
- Fundamental concepts
- Simple patterns

**From Production EAs** (main folder):
- Professional architecture
- Error handling
- Resource management
- Modular design
- Best practices

---

## 📖 Related Documentation

- **Main README**: `../README.md` - Project overview
- **Architecture**: `../ARCHITECTURE.md` - Design patterns explained
- **Coding Standards**: `../CODING_STANDARDS.md` - How to write quality code
- **Trading Pro Guide**: `../TRADING_PRO_GUIDE.md` - Advanced features

---

## 🔄 Concepts Covered in New Architecture

Many concepts from these examples are now **better implemented** in the shared libraries:

| Old Example | New Implementation | Location |
|-------------|-------------------|----------|
| `Sclab-NormalizeDouble.mq5` | `CPriceUtils` | `Include/TradingCore.mqh` |
| `Sclab-TypeFilling...` | Trade configuration | All production EAs |
| `Sclab-OnInit.mq5` | RAII pattern | All production EAs |
| `Sclab-Verificacao.mq5` | Comprehensive validation | All production EAs |

---

**Recommendation**: Study these examples for concepts, but **use production EAs** for actual trading! 🎯
