
# Entity: core_shift_reg_store 
- **File**: core_shift_reg_store.sv

## Diagram
![Diagram](core_shift_reg_store.svg "Diagram")
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
| store_o   | output    | [Bits-1:0] |             |
