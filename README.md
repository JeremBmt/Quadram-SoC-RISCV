# ⚙️ RISC-V RV32IM System-on-Chip with Modular QuadRAM

A mixed-language (VHDL / Verilog) System-on-Chip architecture featuring an extended RISC-V processor core and a generic banked RAM subsystem, developed at Polytech Nantes[cite: 3, 12].

---

## 📌 Architecture Overview

This project integrates a single-cycle RISC-V core with an external synchronous multi-bank RAM[cite: 9, 12]:

* 🧠 **RISC-V Core (`riscvproc-2.v`)**[cite: 1]:
  * Implements the **RV32I** base integer instruction set[cite: 7].
  * Extended with the **M Extension** (`mul` and `div` hardware operations)[cite: 7, 13].
  * Single-cycle instruction fetch using combinational logic (`assign instr = memory[pc];`)[cite: 7, 12].
  * Integrates a 2-state control FSM (`FETCH_EXEC`, `WAIT_DATA`) to freeze the Program Counter during memory reads (`lw`), allowing the synchronous RAM one cycle to output valid data[cite: 9, 13].

* 💾 **QuadRAM Subsystem (`quadram.vhd`)**[cite: 1]:
  * Composed of four 1-KiB synchronous RAM blocks (`ramchip.vhd`) for a total capacity of 4096 bytes[cite: 1, 6, 15].
  * Dynamically instantiated using VHDL `for...generate` constructs[cite: 6].
  * An address decoder (`decodeur.vhd`) analyzes the two MSBs of the 12-bit address to drive Chip-Select (`CS`) lines[cite: 1, 6].
  * Inactive memory blocks output high impedance (`'Z'`) to safely share the data bus[cite: 5].

* 🔄 **Mixed-Language Top-Level (`soc_top.vhd`)**[cite: 1]:
  * Directly interconnects the Verilog processor core and the VHDL QuadRAM memory bus[cite: 9, 19].

---

## 🗺️ Memory Map

| Bank | Address Range (Hex) | Address Range (Dec) | Active Line |
| :--- | :--- | :--- | :--- |
| **RAM 0** | `0x000` - `0x3FF` | 0 - 1023 | `cs_bus(0)`[cite: 15, 16] |
| **RAM 1** | `0x400` - `0x7FF` | 1024 - 2047 | `cs_bus(1)`[cite: 15, 16] |
| **RAM 2** | `0x800` - `0xBFF` | 2048 - 3071 | `cs_bus(2)`[cite: 15, 18] |
| **RAM 3** | `0xC00` - `0xFFF` | 3072 - 4095 | `cs_bus(3)`[cite: 15, 18] |

---

## 📁 Repository Structure

```text
├── decodeur.vhd       # Address decoder for QuadRAM bank selection (VHDL)[cite: 1, 6]
├── ramchip.vhd        # Synchronous RAM block with CS control (VHDL)[cite: 1, 5]
├── quadram.vhd        # 4x1KB banked RAM top-level module (VHDL)[cite: 1, 6]
├── riscvproc-2.v      # RV32IM processor core with load FSM (Verilog)[cite: 1, 12]
├── soc_top.vhd        # Mixed-HDL top-level interconnect (VHDL)[cite: 1, 9]
├── quadram_tb.vhd     # Testbench for QuadRAM memory boundary checks (VHDL)[cite: 1, 6]
├── ram_tb.vhd         # Testbench for individual RAM component (VHDL)[cite: 1, 4]
├── soc_top_tb.vhd     # System-level simulation testbench (VHDL)[cite: 1, 9]
└── instr2.txt         # Test sequence loaded via $readmemh[cite: 1, 13]
```

---

## 🧪 Simulation & Validation

Simulated and verified using **Siemens ModelSim**[cite: 4, 13]:
1. **Memory Addressing**: Verified inter-bank boundary transitions (such as passing from `0x3FF` to `0x400`)[cite: 6].
2. **Synchronization**: Validated that `lw` operations correctly stall `pc` during the `WAIT_DATA` state[cite: 9, 13].
3. **Execution**: Automated execution using `$readmemh("instr2.txt", memory)`[cite: 13].