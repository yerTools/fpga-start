// Thank you Ahawn Hymel and DigiKey - Source: https://youtu.be/LwQsyeuf9Sk

// Count up on each button press and display on LEDs
module button_counter(
    // Inputs
    input       [1:0]   pmod,   // S0 - S1

    // Outputs
    output  reg [3:0]   led     // LED 0 - LED 3
);

    wire rst;
    wire clk;

    // Reset is the inverse of the first button
    assign rst = ~pmod[0];

    // Clock signal is the inverse of second button
    assign clk = ~pmod[1];

    // Count on clock rising edge or reset on button push
    always @(posedge clk or posedge rst) begin
        if (rst == 1'b1) begin
            led <= 4'b0;
        end else begin
            led <= led + 1'b1;
        end
    end

endmodule
