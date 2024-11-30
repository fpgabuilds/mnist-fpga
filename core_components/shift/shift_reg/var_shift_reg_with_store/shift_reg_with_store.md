
# Entity: shift_reg_with_store 
- **File**: shift_reg_with_store.sv

## Diagram
![Diagram](shift_reg_with_store.svg "Diagram")
## Generics

| Generic name | Type     | Value | Description |
| ------------ | -------- | ----- | ----------- |
| N            | unsigned | 8     |             |
| Length       | unsigned | 3     |             |

## Ports

| Port name | Direction | Type    | Description |
| --------- | --------- | ------- | ----------- |
| clk_i     | input     |         |             |
| en_i      | input     |         |             |
| rst_i     | input     |         |             |
| rst_val_i | input     | [N-1:0] |             |
| data_i    | input     | [N-1:0] |             |
| data_o    | output    | [N-1:0] |             |
| store_o   | output    | [N-1:0] |             |
