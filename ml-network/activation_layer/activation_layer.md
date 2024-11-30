
# Entity: activation_layer 
- **File**: activation_layer.sv

## Diagram
![Diagram](activation_layer.svg "Diagram")
## Generics

| Generic name | Type         | Value     | Description |
| ------------ | ------------ | --------- | ----------- |
| Bits         | unsigned     | undefined |             |
| EngineCount  | logic [11:0] | 4095      |             |

## Ports

| Port name             | Direction | Type                    | Description |
| --------------------- | --------- | ----------------------- | ----------- |
| clk_i                 | input     |                         |             |
| en_i                  | input     |                         |             |
| activation_function_i | input     | [2:0]                   |             |
| value_i               | input     | wire signed  [Bits-1:0] |             |
| value_o               | output    | [Bits-1:0]              |             |

## Signals

| Name                               | Type                    | Description |
| ---------------------------------- | ----------------------- | ----------- |
| next_outputs_relu[EngineCount-1:0] | logic signed [Bits-1:0] |             |

## Constants

| Name               | Type | Value | Description |
| ------------------ | ---- | ----- | ----------- |
| ActivFBits_Bitsone |      | 0     |             |
| ActivFBits_Relu    |      | 1     |             |

## Processes
- unnamed: ( @(posedge clk_i) )
  - **Type:** always_ff
