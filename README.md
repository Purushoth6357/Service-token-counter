# Service Token Counter (FPGA)

A simple RTL-based token controller implemented in Verilog for the **Enixs FC-01 FPGA development board**, built around the **Cyclone II EP2C8T144C8**. This is Team 5's EC3552 VLSI Design Mini Project.

The controller generates decimal tokens from **00 to 99**. Pressing the active-low **KEY0** button requests the next token when service mode is enabled. **SW0** resets the token to 00, and **SW1** enables or disables service mode. The current token is output as two BCD digits on the board's eight active-low user LEDs.

## Features

- Sequential two-digit BCD token counter: `00 → 01 → … → 99 → 00`
- Active-low pushbutton input with synchronizer and configurable debounce interval
- Reset input using `SW0`
- Service-mode enable using `SW1`
- Eight-bit token output on the FC-01 user LEDs
- Testbench checks for incrementing, service-mode blocking, reset, and rollover

## Hardware

**Target board:** Enixs FC-01  
**FPGA:** Cyclone II EP2C8T144C8  
**Clock:** 50 MHz oscillator

### Board I/O mapping

| Signal | FC-01 input/output | FPGA package pin | Purpose |
|---|---|---:|---|
| `CLK_50MHZ` | 50 MHz clock | 88 | System clock |
| `KEY0` | Push button KEY0 | 113 | Next token (active-low) |
| `SW0` | Slide switch SW0 | 72 | Reset (active-high) |
| `SW1` | Slide switch SW1 | 73 | Service enable (active-high) |
| `LED_DATA[0]` | LEDG0 | 93 | Ones digit bit 0 |
| `LED_DATA[1]` | LEDG1 | 94 | Ones digit bit 1 |
| `LED_DATA[2]` | LEDG2 | 96 | Ones digit bit 2 |
| `LED_DATA[3]` | LEDG3 | 97 | Ones digit bit 3 |
| `LED_DATA[4]` | LEDG4 | 99 | Tens digit bit 0 |
| `LED_DATA[5]` | LEDG5 | 100 | Tens digit bit 1 |
| `LED_DATA[6]` | LEDG6 | 101 | Tens digit bit 2 |
| `LED_DATA[7]` | LEDG7 | 112 | Tens digit bit 3 |

> **Note:** The FC-01 user LEDs are active-low according to the board manual. Confirm that the RTL output inversion matches your final hardware version before programming. The current top-level source drives `LED_DATA = {token_tens, token_ones}`, so the signal polarity should be reviewed against the LED schematic/observed board behaviour.

## How It Works

1. **Synchronizer:** samples the asynchronous KEY0 signal into the 50 MHz clock domain using two registers.
2. **Debouncer:** waits for a stable button transition before accepting it. The default `DEBOUNCE_COUNT` is `500000`, approximately 10 ms at 50 MHz.
3. **Token counter:** when service mode is enabled and a valid button-press pulse occurs, increments the BCD ones digit. At 9, ones rolls to 0 and tens increments. At 99, the counter returns to 00.
4. **LED output:** outputs the two BCD digits through `LED_DATA[7:0]`.

### Controls

| Control | State | Behaviour |
|---|---|---|
| SW0 | 1 | Reset token and input-control state |
| SW0 | 0 | Normal operation |
| SW1 | 1 | Service mode enabled; valid KEY0 press increments token |
| SW1 | 0 | Service mode disabled; token does not increment |
| KEY0 | 0 | Button pressed |
| KEY0 | 1 | Button released |

## Repository Contents

| File | Description |
|---|---|
| `token_service_controller.v` | Synthesizable top-level Verilog design |
| `tb_token_service_controller.v` | Simulation testbench |
| `tb_waveform.png` | Example ModelSim waveform screenshot |
| `PIN_PLANNER.jpeg` | Quartus pin-planner reference |

## Simulating with ModelSim

The testbench overrides the debounce parameter to `4` so tests run quickly. This override affects simulation only; the FPGA source's default remains 500000.

Open ModelSim in the repository directory and run:

```tcl
vlib work
vlog token_service_controller.v
vlog tb_token_service_controller.v
vsim work.tb_token_service_controller
add wave -r /*
run -all
```

The testbench checks:

1. Reset initializes the token to `00`.
2. Consecutive valid presses produce `01`, `02`, and `03`.
3. Disabling service mode prevents incrementing.
4. Reset returns the token to `00`.
5. Decimal rollover `09 → 10`.
6. Maximum rollover `99 → 00`.

The rollover tests set internal counter registers hierarchically for simulation convenience. These assignments exist only in the testbench and are not synthesizable logic.

## Quartus II Setup

1. Create a new Quartus II project.
2. Select device **Cyclone II / EP2C8T144C8**.
3. Add `token_service_controller.v` to the project.
4. Set `token_service_controller` as the top-level entity.
5. Add the board pin assignments shown above to the project's `.qsf` file.
6. Set the 50 MHz clock constraint (20 ns period).
7. Compile the design and review the compilation, pin assignment, and timing reports.
8. Use Quartus Programmer and the FC-01 onboard USB Blaster to download the generated `.sof` file.

Do not treat the package pin table as a substitute for checking the target board's schematic and Quartus pin-assignment report.

## Limitations

- The output presents the token as two BCD nibbles on eight LEDs, not as a human-readable seven-segment display.
- There is no persistent queue, customer database, or separate display panel; this project demonstrates the token-generation controller in FPGA RTL.
- Resource utilization and maximum operating frequency should be recorded from the actual Quartus compilation rather than estimated.

## Project

**Course:** EC3552 – VLSI Design Mini Project  
**Team:** 5  
**Project:** Token-Based Service Centre Controller  
**Platform:** Enixs FC-01, Cyclone II EP2C8T144C8
