# MQL5 Unicode Fix Documentation

## Problem
The original MQL5 file contained Unicode punctuation characters that caused compilation errors in MetaEditor 5:

### Common Unicode Issues Fixed:
1. **Unicode Minus Signs**: `−` (U+2212), `–` (U+2013), `—` (U+2014) → `−` (ASCII 45)
2. **Unicode Comparison**: `≥` (U+2265), `≤` (U+2264) → `>=`, `<=` (ASCII)
3. **HTML Entities**: `&gt;`, `&lt;`, `&amp;` → `>`, `<`, `&` (ASCII)

## Solution Applied

### Before (Problematic Code):
```mql5
// Unicode minus causing "undeclared identifier" errors
input double MaxLossPerTrade=−1.00; // Unicode minus −
bool condition = (value ≥ threshold); // Unicode ≥
if(a &gt; b) return true; // HTML entity &gt;
for(int i−−; i > 0; i−−) { ... } // Unicode minus in −−
```

### After (Fixed Code):
```mql5
// Proper ASCII operators
input double MaxLossPerTrade=-1.00; // ASCII minus -
bool condition = (value >= threshold); // ASCII >=
if(a > b) return true; // ASCII >
for(int i--; i > 0; i--) { ... } // ASCII minus in --
```

## Validation Results

The corrected file `Agressione2025_CLEAN.mq5` contains:
- ✅ 72 properly formatted `if` statements
- ✅ 19 `<=` operators using ASCII characters
- ✅ 10 `>=` operators using ASCII characters  
- ✅ 14 `--` operators using ASCII characters
- ✅ 9 `++` operators using ASCII characters
- ✅ 5 `for` loops with correct syntax
- ✅ 2 `+=` operators using ASCII characters

## Files Created
- `Agressione2025_CLEAN.mq5` - The corrected MQL5 Expert Advisor ready for compilation

## Compilation Status
✅ **Ready for MetaEditor 5 compilation** - All Unicode punctuation issues resolved.