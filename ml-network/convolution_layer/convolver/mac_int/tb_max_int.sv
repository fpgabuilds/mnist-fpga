// module tb_mac_int;
//   parameter N = 8;

//   logic [N-1:0] value;
//   logic [N-1:0] mult;
//   logic [2*N-1:0] add;
//   logic [2*N-1:0] mac;

//   mac #(N) uut (
//         .value_i(value),
//         .mult_i(mult),
//         .add_i(add),
//         .mac_o(mac)
//       );

//   initial
//   begin
//     // Mult Zero
//     $display("Test 1: Multiply Zero, Time: %0t", $time);
//     value = 8'h8A;
//     mult = 8'h00;
//     add = 8'hBA;
//     #10;
//     assert(mac == 8'hBA)
//           else
//             $display("Test 1 failed: output = %d, expected %d", mac, 8'hBA);

//     // Mult One
//     value = 8'h28;
//     mult = 8'h01;
//     add = 8'hC1;
//     #10;
//     assert(mac == 8'hE9)
//           else
//             $display("Test 2 failed: output = %d, expected %d", mac, 8'hE9);

//     // Add Zero
//     value = 8'h2F;
//     mult = 8'h04;
//     add = 8'h00;
//     #10;
//     assert(mac == 8'hBC)
//           else
//             $display("Test 3 failed: output = %d, expected %d", mac, 8'hBC);

//     // Random numbers 1
//     value = 8'h01;
//     mult = 8'h20;
//     add = 8'h13;
//     #10;
//     assert(mac == 8'h33)
//           else
//             $display("Test 4 failed: output = %d, expected %d", mac, 8'h33);


//     // Random numbers 1
//     value = 8'h03;
//     mult = 8'h10;
//     add = 8'h34;
//     #10;
//     assert(mac == 8'h64)
//           else
//             $display("Test 7 failed: output = %d, expected %d", mac, 8'h64);


//     #10 $finish;
//   end
// endmodule