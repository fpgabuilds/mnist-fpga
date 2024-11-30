
# Entity: fifo 
- **File**: fifo.sv

## Diagram
![Diagram](fifo.svg "Diagram")
## Generics

| Generic name | Type     | Value     | Description |
| ------------ | -------- | --------- | ----------- |
| InputWidth   | unsigned | undefined |             |
| OutputWidth  | unsigned | undefined |             |
| Depth        | unsigned | undefined |             |

## Ports

| Port name  | Direction | Type              | Description |
| ---------- | --------- | ----------------- | ----------- |
| clk_i      | input     |                   |             |
| rst_i      | input     |                   |             |
| write_en_i | input     |                   |             |
| read_en_i  | input     |                   |             |
| data_i     | input     | [InputWidth-1:0]  |             |
| data_o     | output    | [OutputWidth-1:0] |             |
| full_o     | output    |                   |             |
| empty_o    | output    |                   |             |

## Signals

| Name             | Type                   | Description |
| ---------------- | ---------------------- | ----------- |
| store[Depth-1:0] | logic [InputWidth-1:0] |             |
| write_ptr        | logic [AddrWidth-1:0]  |             |
| read_ptr         | logic [AddrWidth-1:0]  |             |
| count            | logic [ AddrWidth-1:0] |             |
| out_offset       | logic [RatioWidth-1:0] |             |

## Constants

| Name       | Type | Value                    | Description |
| ---------- | ---- | ------------------------ | ----------- |
| AddrWidth  |      | (Depth + 1)              |             |
| Ratio      |      | InputWidth / OutputWidth |             |
| RatioWidth |      | (Ratio + 1)              |             |

## Processes
- unnamed: ( @(posedge clk_i or posedge rst_i) )
  - **Type:** always_ff
- unnamed: ( @(posedge clk_i or posedge rst_i) )
  - **Type:** always_ff
- unnamed: ( @(posedge clk_i or posedge rst_i) )
  - **Type:** always_ff
