
# Entity: activation_relu 
- **File**: activation_relu.sv

## Diagram
![Diagram](activation_relu.svg "Diagram")
## Generics

| Generic name | Type     | Value     | Description |
| ------------ | -------- | --------- | ----------- |
| N            | unsigned | undefined |             |

## Ports

| Port name | Direction | Type    | Description |
| --------- | --------- | ------- | ----------- |
| clk_i     | input     |         |             |
| en_i      | input     |         |             |
| value_i   | input     | [N-1:0] |             |
| value_o   | output    | [N-1:0] |             |

## Processes
- unnamed: (  )
  - **Type:** always_comb
