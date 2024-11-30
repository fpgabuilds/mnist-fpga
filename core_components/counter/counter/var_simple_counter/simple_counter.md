
# Entity: simple_counter 
- **File**: simple_counter.sv

## Diagram
![Diagram](simple_counter.svg "Diagram")
## Generics

| Generic name | Type     | Value     | Description |
| ------------ | -------- | --------- | ----------- |
| Bits         | unsigned | undefined |             |

## Ports

| Port name | Direction | Type       | Description |
| --------- | --------- | ---------- | ----------- |
| clk_i     | input     |            |             |
| en_i      | input     |            |             |
| rst_i     | input     |            |             |
| count_o   | output    | [Bits-1:0] |             |

## Signals

| Name       | Type             | Description |
| ---------- | ---------------- | ----------- |
| next_count | logic [Bits-1:0] |             |

## Processes
- unnamed: ( @(posedge clk_i or posedge rst_i) )
  - **Type:** always_ff
