// Thank you Ahawn Hymel and DigiKey - Source: https://youtu.be/A4VfBoP4Hdk

module and_gate(
    // Inputs
    input   [1:0]   pmod,     // S0 - S1

    // Outputs
    output  [2:0]   led       // LED 0 - LED 2
);

    // Wire (net) declarations (internal to module)
    wire not_pmod_0;

    // Continuous assignment: replicate 1 wire to 2 outputs
    assign not_pmod_0 = ~pmod[0];
    assign led[1:0] = {2{not_pmod_0}};

    // Continuous assignment: NOT and AND operators
    assign led[2] = not_pmod_0 & ~pmod[1];

endmodule