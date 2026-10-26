# RISC-V RV32IM System-on-Chip with Modular QuadRAM

A mixed-language (VHDL / Verilog) System-on-Chip architecture featuring an extended RISC-V processor core and a generic banked RAM subsystem, developed at Polytech Nantes.

---

## Architecture Overview

This project integrates a single-cycle RISC-V core with an external synchronous multi-bank RAM :

- **RISC-V Core (`riscvproc-2.v`)** :
  * Implements the **RV32I** base integer instruction set.
  * Extended with the **M Extension** (`mul` and `div` hardware operations).
  * Single-cycle instruction fetch using combinational logic (`assign instr = memory[pc];`).
  * Integrates a 2-state control FSM (`FETCH_EXEC`, `WAIT_DATA`) to freeze the Program Counter during memory reads (`lw`), allowing the synchronous RAM one cycle to output valid data.

- **QuadRAM Subsystem (`quadram.vhd`)** :
  * Composed of four 1-KiB synchronous RAM blocks (`ramchip.vhd`) for a total capacity of 4096 bytes.
  * Dynamically instantiated using VHDL `for...generate` constructs.
  * An address decoder (`decodeur.vhd`) analyzes the two MSBs of the 12-bit address to drive Chip-Select (`CS`) lines.
  * Inactive memory blocks output high impedance (`'Z'`) to safely share the data bus.

- **Mixed-Language Top-Level (`soc_top.vhd`)** :
  * Directly interconnects the Verilog processor core and the VHDL QuadRAM memory bus.

---

## Memory Map

| Bank | Address Range (Hex) | Address Range (Dec) | Active Line |
| :--- | :--- | :--- | :--- |
| **RAM 0** | `0x000` - `0x3FF` | 0 - 1023 | `cs_bus(0)` |
| **RAM 1** | `0x400` - `0x7FF` | 1024 - 2047 | `cs_bus(1)` |
| **RAM 2** | `0x800` - `0xBFF` | 2048 - 3071 | `cs_bus(2)` |
| **RAM 3** | `0xC00` - `0xFFF` | 3072 - 4095 | `cs_bus(3)` |

---

## Repository Structure

```text
├── rtl/
│   ├── decodeur.vhd       # Address decoder for QuadRAM bank selection (VHDL)[cite: 1, 6]
│   ├── quadram.vhd        # 4x1KB banked RAM top-level module (VHDL)[cite: 1, 6]
│   ├── ramchip.vhd        # Synchronous RAM block with CS control (VHDL)[cite: 1, 5]
│   ├── riscvproc-2.v      # RV32IM processor core with load FSM (Verilog)[cite: 1, 12]
│   └── soc_top.vhd        # Mixed-HDL top-level interconnect (VHDL)[cite: 1, 9]
├── tb/
│   ├── instr2.txt         # Test sequence loaded via $readmemh[cite: 1, 13]
│   ├── quadram_tb.vhd     # Testbench for QuadRAM memory boundary checks (VHDL)[cite: 1, 6]
│   ├── ram_tb.vhd         # Testbench for individual RAM component (VHDL)[cite: 1, 4]
│   └── soc_top_tb.vhd     # System-level simulation testbench (VHDL)[cite: 1, 9]
└── README.md
```

---

## Simulation & Validation

Simulated and verified using **Siemens ModelSim** :
1. **Memory Addressing** : Verified inter-bank boundary transitions (such as passing from `0x3FF` to `0x400`).
2. **Synchronization** : Validated that `lw` operations correctly stall `pc` during the `WAIT_DATA` state.
3. **Execution** : Automated execution using `$readmemh("instr2.txt", memory)`.
