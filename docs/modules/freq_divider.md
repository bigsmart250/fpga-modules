# freq_divider / any_freq_divider — 时钟分频

## freq_divider — 整数分频

### 参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `DIV_COEF` | 2 | 分频系数，≥1 |
| `POLARITY` | 1 | 分频输出高电平段极性 |

### 端口

| 方向 | 信号 | 说明 |
|---|---|---|
| in | `clk` / `rst_n` | 时钟 / 低有效异步复位 |
| in | `clk_en` | 分频使能，拉低时输出保持空闲电平 |
| out | `div_clk` | 分频时钟（寄存器输出，占空比约 50%） |
| out | `clk_valid` | 输出有效标志 |

### 要点

- `DIV_COEF = 1` 时 `div_clk` 直通 `clk`（组合路径，仅透传）；
- ⚠ `div_clk` 是寄存器生成的门控风格时钟，**只建议用作同域使能或低速外设时钟**；用它驱动高速逻辑时注意全程时钟约束与偏斜；
- 例程见 `sim/tb_freq_divider.v`。

## any_freq_divider — 任意比例分频使能

### 原理

相位累加器：每个 `clk_en` 周期累加 `DIVISOR`，累计达到 `DIVIDEND` 时输出一个 `clk_valid` 单周期脉冲并回绕。平均每 `DIVIDEND` 个输入使能周期产生 `DIVISOR` 个脉冲，实现非整数比例的均匀切分（如 10/3）。

### 参数与端口

| 参数/端口 | 说明 |
|---|---|
| `DIVIDEND` / `DIVISOR` | 比例分子/分母，要求 1 ≤ DIVISOR ≤ DIVIDEND，违例仿真期报错 |
| `clk` / `rst_n` / `clk_en` | 同上 |
| `div_clk` | 每次 `clk_valid` 翻转一次的方波输出 |
| `clk_valid` | 单周期有效脉冲（推荐优先使用这个，而不是 div_clk） |

### 要点

- 输出脉冲在时间轴上是均匀分布的（误差 ±1 周期内摊平），比"计数取整"式分频平滑；
- 例程见 `sim/tb_any_freq_divider.v`。
