// Thank you Ahawn Hymel and DigiKey - Source: https://youtu.be/LwQsyeuf9Sk

// Count up on each button press and display on LEDs
module clock_counter(
    // Inputs
    input               clk_27MHz,  // Onboard 27 MHz oscillator (Pin H11)
    input       [1:0]   pmod,       // S0 - S1

    // Outputs
    output  reg [3:0]   led         // LED 0 - LED 3
);

    reg         clk_1Hz;
    reg [23:0]  div_counter;

    always @(posedge clk_27MHz or posedge rst) begin
        if (rst == 1'b1) begin
            clk_1Hz <= 1'b0;
            div_counter <= 'b0;
        end else if (div_counter == 13499999) begin
            clk_1Hz <= ~clk_1Hz;
            div_counter <= 'b0;
        end else begin
            div_counter <= div_counter + 1'b1;
        end
    end

    wire rst;
    wire clk;

    // Reset is the inverse of the first button
    assign rst = ~pmod[0];

    // Clock signal is the inverse of second button
    assign clk = ~pmod[1] | clk_1Hz;

    // Count on clock rising edge or reset on button push
    always @(posedge clk or posedge rst) begin
        if (rst == 1'b1) begin
            led <= 4'b0;
        end else begin
            led <= led + 1'b1;
        end
    end

endmodule
