module full_adder(
    // Inputs
    input   [2:0]   pmod,   // S0 - S2

    // Outputs
    output  [1:0]   led     // LED 0 - LED 1
);

    wire xor_s0_s1;
    wire and_s0_s1;

    assign xor_s0_s1 = pmod[0] ^ pmod[1];
    assign and_s0_s1 = pmod[0] & pmod[1];

    assign led[0] = xor_s0_s1 ^ pmod[2];
    assign led[1] = (xor_s0_s1 & pmod[2]) | and_s0_s1;

endmodule