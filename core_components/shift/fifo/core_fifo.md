
# Entity: core_fifo 
- **File**: core_fifo.sv

## Diagram
![Diagram](core_fifo.svg "Diagram")
## Generics

| Generic name | Type     | Value     | Description |
| ------------ | -------- | --------- | ----------- |
| InputBits    | unsigned | undefined |             |
| OutputBits   | unsigned | undefined |             |
| Depth        | unsigned | undefined |             |

## Ports

| Port name  | Direction | Type             | Description |
| ---------- | --------- | ---------------- | ----------- |
| clk_i      | input     |                  |             |
| rst_i      | input     |                  |             |
| write_en_i | input     |                  |             |
| read_en_i  | input     |                  |             |
| data_i     | input     | [InputBits-1:0]  |             |
| data_o     | output    | [OutputBits-1:0] |             |
| full_o     | output    |                  |             |
| empty_o    | output    |                  |             |

## Signals

| Name             | Type                  | Description |
| ---------------- | --------------------- | ----------- |
| store[Depth-1:0] | logic [InputBits-1:0] |             |
| write_ptr        | logic [AddrBits-1:0]  |             |
| read_ptr         | logic [AddrBits-1:0]  |             |
| count            | logic [ AddrBits-1:0] |             |
| out_offset       | logic [RatioBits-1:0] |             |

## Constants

| Name      | Type | Value                  | Description |
| --------- | ---- | ---------------------- | ----------- |
| AddrBits  |      | (Depth + 1)            |             |
| Ratio     |      | InputBits / OutputBits |             |
| RatioBits |      | (Ratio + 1)            |             |

## Processes
- fifo_write: ( @(posedge clk_i or posedge rst_i) )
  - **Type:** always_ff
- fifo_read: ( @(posedge clk_i or posedge rst_i) )
  - **Type:** always_ff
- fifo_count: ( @(posedge clk_i or posedge rst_i) )
  - **Type:** always_ff
