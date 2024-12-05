#include "Vconvolution_layer.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <memory>
#include <iostream>

// #define BITS 8
// #define ENGINE_COUNT 2

// #define MAX_MATRIX_SIZE 10
// #define MATRIX_SIZE 5

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    // Initialize Traces
    Verilated::traceEverOn(true);

    const int MAX_SIM_TIME = 1000; // Maximum simulation time, if not finished it will error
    const int MATRIX_SIZE = 5;
    const int KERNEL_SIZE = 3;

    const std::array<int, 18> VALID_0_LIST = {
        1, 1, 1,
        2, 2, 2,
        2, 3, 3,

        0, 0, 0,
        0, 0, 0,
        0, 0, 0
    };

    const std::array<int, 18> VALID_1_LIST = {
        1, 1, 2,
        2, 2, 3,
        3, 3, 3,

        0, 0, 0,
        0, 0, 0,
        0, 0, 0
    };

    // Create an instance of our module under test
    auto tb = std::make_unique<Vconvolution_layer>();
    // Create an instance of Trace module
    auto tfp = std::make_unique<VerilatedFstC>();
    tb->trace(tfp.get(), 99);  // Trace 99 levels of hierarchy
    tfp->open("dump.fst");

    // Initialize signals
    tb->clk_i = 0;
    tb->rst_i = 1;
    tb->start_i = 0;
    //tb->kernel_weights_i //see below
    tb->reg_bcfg1_i = 0x0002;  // Shift = 0, EngineCount = 2
    tb->reg_bcfg2_i = 0x0000 + MATRIX_SIZE;  // MatrixSize = 5
    tb->reg_cprm1_i = 0x0041;  // Stride = 1, save_to_mem = 1 to export on all
    tb->has_data_i = 0;
    tb->req_next_i = 0;
    tb->activation_data_i = 0;
    //tb->used_data_o
    //tb->conv_valid_o
    //tb->data_o
    //tb->conv_done_o
    //tb->conv_running_o
    tb->assert_on_i = 0;
    

    // Initialize kernel weights
    tb->kernel_weights_i[0][0] = 0x01;  // top left
    tb->kernel_weights_i[0][1] = 0x02;  // top middle
    tb->kernel_weights_i[0][2] = 0x03;  // top right
    tb->kernel_weights_i[0][3] = 0x04;  // middle left
    tb->kernel_weights_i[0][4] = 0x05;  // center
    tb->kernel_weights_i[0][5] = 0x06;  // middle right
    tb->kernel_weights_i[0][6] = 0x07;  // bottom left
    tb->kernel_weights_i[0][7] = 0x08;  // bottom middle
    tb->kernel_weights_i[0][4] = 0x05;  // center
    tb->kernel_weights_i[0][5] = 0x06;  // middle right
    tb->kernel_weights_i[0][6] = 0x07;  // bottom left
    tb->kernel_weights_i[0][7] = 0x08;  // bottom middle
    tb->kernel_weights_i[0][8] = 0x09;  // bottom right

    tb->kernel_weights_i[1][0] = 0x0A;   // 10
    tb->kernel_weights_i[1][1] = 0xF6;   // -10
    tb->kernel_weights_i[1][2] = 0x14;   // 20
    tb->kernel_weights_i[1][3] = 0xEC;   // -20
    tb->kernel_weights_i[1][4] = 0x1E;   // 30
    tb->kernel_weights_i[1][5] = 0xE2;   // -30
    tb->kernel_weights_i[1][6] = 0x28;   // 40
    tb->kernel_weights_i[1][7] = 0xD8;   // -40
    tb->kernel_weights_i[1][8] = 0x32;   // 50

    // Main simulation loop
    int sim_time = 0;
    int valid_count = 0;

    bool stage1_done = false;

    while (sim_time < MAX_SIM_TIME) {
        if (stage1_done) {
            break;
        }
        tb->clk_i = !tb->clk_i; // Setup clock

        if (sim_time == 2) {
            tb->assert_on_i = 1;
            tb->rst_i = 0;
        }

        if (sim_time == 4) {
            tb->start_i = 1;
            tb->has_data_i = 1;
        }

        if (sim_time == 6) {
            tb->req_next_i = 1;
            tb->start_i = 0;
            tb->reg_bcfg2_i = 0x0010;  // Test register cloning
        }

        // First test sequence
        if (valid_count <= (MATRIX_SIZE - KERNEL_SIZE + 1) && sim_time >= 4) { //should be 4
            if (tb->clk_i) {
                // Input data
                int i = (sim_time - 4) / 2; // should be -6
                if (i < MATRIX_SIZE * MATRIX_SIZE) {
                    tb->activation_data_i = i;
                }

                // Output data
                if (tb->conv_valid_o) {
                    if (VALID_0_LIST[valid_count] != tb->data_o[0]) {
                        std::cout << "Time: " << sim_time << ", Convolution 0 failed: output = " << 
                            static_cast<int>(tb->data_o[0]) << ", expected " << VALID_0_LIST[valid_count] << std::endl;
                    }
                    if (VALID_1_LIST[valid_count] != tb->data_o[1]) {
                        std::cout << "Time: " << sim_time << ", Convolution 1 failed: output = " << 
                            static_cast<int>(tb->data_o[1]) << ", expected " << VALID_1_LIST[valid_count] << std::endl;
                    }
                    valid_count++;
                }
            }
        }

        // Check for first conv_done
        if (tb->conv_done_o) {
            tb->rst_i = 1;
            stage1_done = true;
        }

        tb->eval();
        tfp->dump(sim_time);
        sim_time++;
    }

    bool stage2_done = false;
    int stage2_start_time = sim_time;
    while (sim_time < MAX_SIM_TIME) {
        if (stage2_done) {
            break;
        }
        tb->clk_i = !tb->clk_i; // Setup clock

        if (stage2_start_time == sim_time) {
            tb->rst_i = 0; // Clear reset if it was on

            // Reset matrix size, if the previous was correct
            // then the matrix size did not change
            tb->reg_bcfg2_i = 0x0000 + MATRIX_SIZE;  
        }

        if (sim_time == stage2_start_time + 2) {
            tb->start_i = 1;
        }

        if (sim_time == stage2_start_time + 4) {
            tb->start_i = 0;
        }


        // Second test sequence
        if (valid_count <= 2 * (MATRIX_SIZE - KERNEL_SIZE + 1) && sim_time >= stage2_start_time + 2) { //should be 4
            if (tb->clk_i) {
                // Input data
                int i = (sim_time - stage2_start_time - 6) / 2; //should be -4
                if (i < MATRIX_SIZE * MATRIX_SIZE) {
                    tb->activation_data_i = -i;
                }

                // Output data
                if (tb->conv_valid_o) {
                    if (VALID_0_LIST[valid_count] != tb->data_o[0]) {
                        std::cout << "Time: " << sim_time << ", Convolution 0 failed: output = " << 
                            static_cast<int>(tb->data_o[0]) << ", expected " << VALID_0_LIST[valid_count] << std::endl;
                    }
                    if (VALID_1_LIST[valid_count] != tb->data_o[1]) {
                        std::cout << "Time: " << sim_time << ", Convolution 1 failed: output = " << 
                            static_cast<int>(tb->data_o[1]) << ", expected " << VALID_1_LIST[valid_count] << std::endl;
                    }
                    valid_count++;
                }
            }
        }


        // End simulation when second conv_done is detected
        if (tb->conv_done_o) {
            stage2_done = true;
        }

        tb->eval();
        tfp->dump(sim_time);
        sim_time++;
    }

    // Few extra clock cycles for looks
    int stage3_start_time = sim_time;
    while (sim_time <= stage3_start_time + 6) {  
        tb->clk_i = !tb->clk_i; // Setup clock
        tb->eval();
        tfp->dump(sim_time);
        sim_time++;
    }

    if (!stage1_done || !stage2_done) {
        std::cout << "Time: " << sim_time << ", Convolution did not finish in the max time: "
            << MAX_SIM_TIME << std::endl;
    }

    tfp->close();
    return 0;
}
