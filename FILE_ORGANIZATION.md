# MoneyMap File Organization

## 📁 Current Structure

```
MoneyMap/
├── 📄 Documentation (4 files)
│   ├── README.md
│   ├── ARCHITECTURE.md
│   ├── CODING_STANDARDS.md
│   ├── PERFORMANCE_OPTIMIZATION.md
│   └── TRADING_PRO_GUIDE.md
│
├── 🎯 Production EAs (9 refactored files)
│   ├── Sclab-SMA.mq5                    [Signal Display]
│   ├── Sclab-CompraVenda.mq5            [Basic Buy/Sell]
│   ├── Sclab-BreakEven.mq5              [Break-Even Management]
│   ├── Sclab-TrailingStop.mq5           [Trailing Stop]
│   ├── Sclab-ControleHoras.mq5          [Time Control]
│   ├── Sclab-FechaPosicao.mq5           [Position Closing]
│   ├── Sclab-OrdemPendente.mq5          [Pending Orders]
│   ├── Sclab-PosicaoAberta.mq5          [Open Position]
│   └── Sclab-TradingPro.mq5             [⭐ PRO - All Features]
│
├── 📚 Educational Demos (9 unreferenced files)
│   ├── Sclab-AskBid.mq5
│   ├── Sclab-MqlRates.mq5
│   ├── Sclab-MqlTick.mq5
│   ├── Sclab-NormalizeDouble.mq5
│   ├── Sclab-OnInit.mq5
│   ├── Sclab-TypeFilling-Deviation-ExpertMagicNumber.mq5
│   ├── Sclab-Verificacao.mq5
│   ├── Sclab-Inputs(1).mq5
│   └── Sclab-inputsEnum.mq5
│
└── 📦 Include/ (10 shared libraries)
    ├── TradingCore.mqh              [Position/Order Management]
    ├── RiskManager.mqh              [Break-Even/Trailing]
    ├── TimeManager.mqh              [Trading Hours]
    ├── IndicatorManager.mqh         [Indicator Lifecycle]
    ├── SignalManager.mqh            [⭐ Multi-Confirmation]
    ├── ATRRiskManager.mqh           [⭐ Dynamic SL/TP]
    ├── PartialCloseManager.mqh      [⭐ Scale Out]
    ├── DrawdownManager.mqh          [⭐ Loss Limits]
    ├── PerformanceTracker.mqh       [⭐ Analytics]
    └── LatencyMonitor.mqh           [⭐ Performance]
```

---

## 🎯 Recommended Organization

### Option 1: **Clean Structure** (Recommended)
Move educational demos to a separate folder.

```
MoneyMap/
├── 📄 Docs/
│   └── (all .md files)
│
├── 🎯 Experts/
│   ├── Basic/
│   │   ├── Sclab-SMA.mq5
│   │   ├── Sclab-CompraVenda.mq5
│   │   └── ...
│   │
│   ├── Advanced/
│   │   ├── Sclab-TrailingStop.mq5
│   │   ├── Sclab-ControleHoras.mq5
│   │   └── ...
│   │
│   └── Pro/
│       └── Sclab-TradingPro.mq5
│
├── 📚 Examples/
│   └── (all demo files)
│
└── 📦 Include/
    └── (all .mqh files)
```

### Option 2: **Simple Cleanup**
Just move demos to Examples folder.

```
MoneyMap/
├── (docs)
├── (production EAs - 9 files)
├── Examples/
│   └── (demo files)
└── Include/
    └── (libraries)
```

### Option 3: **Minimal Change**
Add a categorization document, keep structure as-is.

---

## 📋 File Categories

### ⭐ **PRODUCTION READY** - Use These!
| File | Purpose | Complexity | Use Case |
|------|---------|-----------|-----------|
| **Sclab-TradingPro.mq5** | All features | ⭐⭐⭐⭐⭐ | Serious trading |
| Sclab-TrailingStop.mq5 | TS + BE | ⭐⭐⭐⭐ | Trend following |
| Sclab-ControleHoras.mq5 | Time filter | ⭐⭐⭐ | Session trading |
| Sclab-BreakEven.mq5 | Break-even | ⭐⭐⭐ | Risk management |
| Sclab-CompraVenda.mq5 | Basic trading | ⭐⭐ | Learning |
| Sclab-SMA.mq5 | Signal only | ⭐ | Analysis only |

### 📚 **EDUCATIONAL** - Learning Only
| File | Topic | Keep? |
|------|-------|-------|
| Sclab-AskBid.mq5 | Price info | Optional |
| Sclab-MqlRates.mq5 | Candle data | Optional |
| Sclab-MqlTick.mq5 | Tick data | Optional |
| Sclab-NormalizeDouble.mq5 | Price normalization | **Delete** (covered in TradingCore) |
| Sclab-OnInit.mq5 | Initialization | **Delete** (basic concept) |
| Sclab-TypeFilling.mq5 | Trade settings | **Delete** (covered in all EAs) |
| Sclab-Verificacao.mq5 | Verification | Optional |
| Sclab-Inputs(1).mq5 | Input params | **Delete** (basic concept) |
| Sclab-inputsEnum.mq5 | Enum inputs | **Delete** (basic concept) |

---

## 🚀 Quick Actions

### Action A: **Move Demos to Examples** ✅ Recommended
```powershell
# Create Examples folder
New-Item -ItemType Directory -Path "Examples"

# Move demo files
Move-Item "Sclab-AskBid.mq5" "Examples/"
Move-Item "Sclab-MqlRates.mq5" "Examples/"
Move-Item "Sclab-MqlTick.mq5" "Examples/"
Move-Item "Sclab-NormalizeDouble.mq5" "Examples/"
Move-Item "Sclab-OnInit.mq5" "Examples/"
Move-Item "Sclab-TypeFilling-Deviation-ExpertMagicNumber.mq5" "Examples/"
Move-Item "Sclab-Verificacao.mq5" "Examples/"
Move-Item "Sclab-Inputs(1).mq5" "Examples/"
Move-Item "Sclab-inputsEnum.mq5" "Examples/"

# Add README to Examples
```

### Action B: **Delete Redundant Files** ⚠️ Permanent
```powershell
# Delete files covered by new architecture
Remove-Item "Sclab-NormalizeDouble.mq5"
Remove-Item "Sclab-OnInit.mq5"
Remove-Item "Sclab-TypeFilling-Deviation-ExpertMagicNumber.mq5"
Remove-Item "Sclab-Inputs(1).mq5"
Remove-Item "Sclab-inputsEnum.mq5"

# Keep only useful examples
# (MqlRates, MqlTick, AskBid, Verificacao)
```

### Action C: **Create Docs Folder**
```powershell
# Organize documentation
New-Item -ItemType Directory -Path "Docs"
Move-Item "*.md" "Docs/"
```

---

## 💡 My Recommendation

**Do Action A** (Move to Examples) - Benefits:
- ✅ Clean root directory (only production EAs)
- ✅ Preserves educational material
- ✅ Clear separation
- ✅ Easy for others to find what they need

**Structure after cleanup**:
```
MoneyMap/
├── README.md, ARCHITECTURE.md, etc. (5 docs)
├── Sclab-TradingPro.mq5 ⭐
├── Sclab-TrailingStop.mq5
├── Sclab-ControleHoras.mq5
├── ... (6 more production EAs)
├── Examples/ (9 demo files)
└── Include/ (10 libraries)
```

---

## 📊 Size Analysis

| Category | Files | Total Size |
|----------|-------|------------|
| Production EAs | 9 | ~120 KB |
| Demo Files | 9 | ~40 KB |
| Libraries | 10 | ~67 KB |
| Documentation | 5 | ~47 KB |
| **Total** | **33** | **~274 KB** |

---

Would you like me to:
1. **Execute Action A** - Move demos to Examples/ folder?
2. **Execute Action B** - Delete redundant demo files?
3. **Execute Action C** - Organize docs into folder?
4. **All of the above** - Complete organization?
5. **Custom** - Tell me what you prefer?

I recommend **Option 1** (move demos) as a safe, reversible cleanup! 🎯
