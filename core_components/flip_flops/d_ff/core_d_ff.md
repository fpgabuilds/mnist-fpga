
# Entity: core_d_ff 
- **File**: core_d_ff.sv

## Diagram
![Diagram](core_d_ff.svg "Diagram")
## Generics

| Generic name | Type     | Value | Description                                |
| ------------ | -------- | ----- | ------------------------------------------ |
| Bits         | unsigned | 1     | Bit width of the data, leave off for 1 bit |

## Ports

| Port name | Direction | Type       | Description |
| --------- | --------- | ---------- | ----------- |
| clk_i     | input     |            |             |
| rst_i     | input     |            |             |
| en_i      | input     |            |             |
| data_i    | input     | [Bits-1:0] |             |
| data_o    | output    | [Bits-1:0] |             |

## Processes
- unnamed: ( @(posedge clk_i or posedge rst_i) )
  - **Type:** always_ff
