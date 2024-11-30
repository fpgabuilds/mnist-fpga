
# Entity: mac_shifter 
- **File**: mac_shifter.sv

## Diagram
![Diagram](mac_shifter.svg "Diagram")
## Generics

| Generic name | Type     | Value     | Description |
| ------------ | -------- | --------- | ----------- |
| N            | unsigned | undefined |             |

## Ports

| Port name | Direction | Type      | Description |
| --------- | --------- | --------- | ----------- |
| clk_i     | input     |           |             |
| en_i      | input     |           |             |
| value_i   | input     | [N-1:0]   |             |
| mult_i    | input     | [N-1:0]   |             |
| add_i     | input     | [2*N-1:0] |             |
| shift_i   | input     | [5:0]     |             |
| mac_o     | output    | [2*N-1:0] |             |

## Signals

| Name       | Type            | Description |
| ---------- | --------------- | ----------- |
| mult       | logic [2*N-1:0] |             |
| mac_result | logic [2*N-1:0] |             |

## Processes
- unnamed: ( @(posedge clk_i) )
  - **Type:** always_ff
