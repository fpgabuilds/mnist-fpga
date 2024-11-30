
# Entity: core_shift_reg 
- **File**: core_shift_reg.sv

## Diagram
![Diagram](core_shift_reg.svg "Diagram")
## Generics

| Generic name | Type     | Value     | Description |
| ------------ | -------- | --------- | ----------- |
| Bits         | unsigned | undefined |             |
| Length       | unsigned | undefined |             |

## Ports

| Port name | Direction | Type       | Description |
| --------- | --------- | ---------- | ----------- |
| clk_i     | input     |            |             |
| en_i      | input     |            |             |
| rst_i     | input     |            |             |
| rst_val_i | input     | [Bits-1:0] |             |
| data_i    | input     | [Bits-1:0] |             |
| data_o    | output    | [Bits-1:0] |             |

## Signals

| Name              | Type           | Description |
| ----------------- | -------------- | ----------- |
| store[Length-1:0] | reg [Bits-1:0] |             |
