
# Entity: core_bram_single_port 
- **File**: core_bram_single_port.sv

## Diagram
![Diagram](core_bram_single_port.svg "Diagram")
## Generics

| Generic name | Type     | Value     | Description |
| ------------ | -------- | --------- | ----------- |
| DataWidth    | unsigned | undefined |             |
| Depth        | unsigned | undefined |             |

## Ports

| Port name  | Direction | Type                 | Description |
| ---------- | --------- | -------------------- | ----------- |
| clk_i      | input     |                      |             |
| write_en_i | input     |                      |             |
| addr_i     | input     | [clog2(Depth+1)-1:0] |             |
| data_i     | input     | [DataWidth-1:0]      |             |
| data_o     | output    | [DataWidth-1:0]      |             |

## Signals

| Name              | Type                | Description |
| ----------------- | ------------------- | ----------- |
| memory[0:Depth-1] | reg [DataWidth-1:0] |             |

## Processes
- unnamed: ( @(posedge clk_i) )
  - **Type:** always
