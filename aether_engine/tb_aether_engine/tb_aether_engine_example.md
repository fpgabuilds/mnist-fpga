
# Entity: tb_aether_engine_example 
- **File**: tb_aether_engine_example.sv

## Diagram
![Diagram](tb_aether_engine_example.svg "Diagram")
## Signals

| Name            | Type         | Description |
| --------------- | ------------ | ----------- |
| clk             | logic        |             |
| cmd             | logic [23:0] |             |
| data_output     | logic [15:0] |             |
| interrupt       | logic        |             |
| assert_on       | logic        |             |
| cycle_count = 0 | integer      |             |

## Tasks
- execute_cmd <font id="task_arguments">(input logic [23:0] command)</font>

## Processes
- unnamed: (  )
  - **Type:** always

## Instantiations

- accelerator_inst: aether_engine
