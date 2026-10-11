## 📑 Table of Contents

* [Problem Statement](#-problem-statement)
* [Features](#-features)
* [Operating Modes](#-operating-modes)
* [System Architecture](#-system-architecture)
* [Design Parameters](#-design-parameters)
* [I/O Description](#-io-description)
* [Simulation Results](#-simulation-results)
* [Resource and Timing Analysis](#-resource-and-timing-analysis)
* [Repository Structure](#-repository-structure)
* [Getting Started](#-getting-started)
* [Demonstration Guide](#-demonstration-guide)
* [Future Improvements](#-future-improvements)

\---

## 🎯 Problem Statement

A campus wants to reduce energy consumption by controlling street lights automatically. Based on a simulated ambient-light condition, the system should switch between day/night modes and control multiple lights using a predefined energy-saving strategy.

**Expected FPGA output:**

|Element|Role|
|-|-|
|LEDs|Individual street-light status|
|Switch|Simulated day/night condition|
|Presentation|Demonstrate normal lighting and energy-saving mode, with sequential/PWM control|

\---

## ✨ Features

* **Day/night automation**: lights are fully off during the day.
* **Normal night mode**: all 8 street lights at full brightness.
* **Energy-saving night mode**: lights alternate between two groups, each dimmed to **50% brightness** by PWM.
* **Parameterized design**: clock frequency, blink rate, and PWM resolution are configurable.
* **Asynchronous reset** for safe start-up.
* **Tiny footprint**: 58 logic elements (<1% of the device), no memory, no multipliers, no PLLs.

\---

## ⚙️ Operating Modes

|`day\_night`|`energy\_mode`|Mode|LED behaviour|
|:-:|:-:|-|-|
|0|X|**Day**|All LEDs OFF (`00000000`)|
|1|0|**Normal night**|All LEDs fully ON (`11111111`)|
|1|1|**Energy-saving night**|Alternating groups (even / odd LEDs), each at 50% PWM duty|

### Energy-saving strategy

* **Group A:** `led\[0], led\[2], led\[4], led\[6]`
* **Group B:** `led\[1], led\[3], led\[5], led\[7]`
* A 1-bit `pattern` register toggles every half blink period (default: every 0.5 s at 1 Hz), swapping which group is active.
* The active group is gated by the PWM comparator `pwm\_counter < 128`, giving a 50% duty cycle. Combined with only half of the lights being active at a time, average power drops to roughly **25% of normal night mode** (an estimate from duty cycle, not a measured value).

\---

## 🧩 System Architecture

The design consists of three blocks, as shown in the RTL schematic:

1. **Clock divider / pattern generator**: a 32-bit counter counts up to `DIV\_LIMIT - 1`, then resets and toggles `pattern`.
2. **PWM counter**: a free-running 8-bit counter used as the PWM reference.
3. **Light-control logic**: combinational multiplexing that selects off, full-on, or the PWM alternating pattern based on `day\_night` and `energy\_mode`.

```
            ┌────────────────────┐
 clk ──────►│ Clock divider      │── pattern ──┐
 reset ────►│ (32-bit counter)   │              │
            └────────────────────┘              ▼
            ┌────────────────────┐        ┌───────────────┐
 clk ──────►│ PWM counter (8-bit)│───────►│ Light-control │──► led\[7:0]
 reset ────►└────────────────────┘        │ logic (MUX)   │
 day\_night ────────────────────────────►  │               │
 energy\_mode ──────────────────────────►  └───────────────┘
```

## 🔧 Design Parameters

|Parameter|Default|Description|
|-|-|-|
|`CLK\_FREQ\_HZ`|`50000000`|Input clock frequency (50 MHz)|
|`BLINK\_FREQ\_HZ`|`1`|Pattern-swap frequency in energy-saving mode|
|`PWM\_BITS`|`8`|PWM counter width (256 brightness steps)|

Derived constant: `DIV\_LIMIT = CLK\_FREQ\_HZ / (2 \* BLINK\_FREQ\_HZ)`

\---

## 🔌 I/O Description

|Signal|Direction|Width|Description|
|-|:-:|:-:|-|
|`clk`|Input|1|System clock (50 MHz)|
|`reset`|Input|1|Asynchronous active-high reset|
|`day\_night`|Input|1|`0` = day, `1` = night (simulated ambient light)|
|`energy\_mode`|Input|1|`0` = normal, `1` = energy-saving (effective at night)|
|`led\[7:0]`|Output|8|Street-light status outputs|

Total of **12 pins** used (4 inputs + 8 outputs).

\---

## 📊 Simulation Results

Functional simulation was performed in the Quartus II Simulation Waveform Editor.

### Normal night mode (`energy\_mode = 0`)

With `day\_night = 1`, all LEDs are `11111111`; when `day\_night` drops to `0`, they go to `00000000`.



### Energy-saving mode (`energy\_mode = 1`)

With `day\_night = 1`, only alternate LEDs are active (`10101010` shown); `day\_night = 0` forces all LEDs off.


\---

## 📈 Resource and Timing Analysis

**Target:** Cyclone II **EP2C8T144C8** · **Tool:** Quartus II 13.0.1 (64-bit) · **Result:** 0 errors, 11 warnings

|Parameter|Quartus Report|
|-|-:|
|Total Logic Elements|58 / 8,256 (<1%)|
|Total Combinational Functions|56 / 8,256 (<1%)|
|Dedicated Logic Registers|41 / 8,256 (<1%)|
|Total Registers|41|
|Total Memory Bits|0 / 165,888 (0%)|
|Total Pins|12 / 85 (14%)|
|Embedded Multiplier 9-bit Elements|0 / 36 (0%)|
|Total PLLs|0 / 2 (0%)|

|Timing|Value|
|-|-|
|Target clock|50 MHz|
|Clock period|20 ns|

\---

## 📁 Repository Structure

```
.
├── src/
│   └── street\_light.v                # Top-level Verilog module
├── report/
│    └── Resource\_and\_timing\_analysis.txt

└── result/
│       ├── rtl\_schematic.jpeg
│       ├── simulation\_waveform\_1.jpeg
│       └── simulation\_waveform\_2.jpeg   
└── README.md
```

\---

## 🚀 Getting Started

### Prerequisites

* Intel/Altera **Quartus II 13.0.1** (or compatible)
* Cyclone II **EP2C8T144C8** development board
* 50 MHz on-board clock

### Build and program

1. Create a new Quartus II project and select device **EP2C8T144C8**.
2. Add `src/street\_light.v` and set `street\_light` as the top-level entity.
3. Assign pins for `clk`, `reset`, `day\_night`, `energy\_mode`, and `led\[7:0]` according to your board's schematic.
4. Run **Compile Design** (Processing → Start Compilation).
5. Open the Programmer and load the generated `.sof` file onto the board.

### Simulate

1. Create a Vector Waveform File (`.vwf`) and add all I/O signals.
2. Apply a clock and toggle `day\_night`, `energy\_mode`, and `reset`.
3. Run **Functional Simulation** and inspect `led\[7:0]`.

\---

## 🎬 Demonstration Guide

|Step|Action|Expected result|
|:-:|-|-|
|1|Pulse `reset`|Counters cleared, system initialised|
|2|Set `day\_night = 0`|All LEDs OFF (daytime)|
|3|Set `day\_night = 1`, `energy\_mode = 0`|All LEDs fully ON (normal lighting)|
|4|Set `energy\_mode = 1`|Alternating LED groups at 50% brightness, swapping every 0.5 s|
|5|Set `day\_night = 0` again|All LEDs OFF regardless of energy mode|

\---

## 🔮 Future Improvements

* Add a debouncer/synchroniser for the physical switch inputs.
* Replace the switch with a real LDR/ADC ambient-light sensor.
* Add a configurable PWM duty-cycle input for multi-level dimming.
* Add motion-sensor input to brighten lights only when pedestrians or vehicles are present.
* Add a self-checking testbench with scaled-down parameters.

\---



## 👤 Author

GLADVIN SAMUVEL V M

Electronics & Communication Engineering, Aspiring VLSI Engineer

Focus Areas: RTL Design | Verilog HDL | ASIC | Digital IC Design | RISC V
