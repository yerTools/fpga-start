module bouncer(
    input       clk,
    input       rst,
    input       btn,
    output  reg debounced
);
    // Around 9.7 ms wait time
    reg [17:0]  counter;

    always @(posedge clk or posedge rst) begin
        if (rst == 1'b1) begin
            debounced <= 1'b0;
            counter <= 'b0;
        end else if (counter != 'b0) begin
            counter <= counter + 1'b1;
        end else if (btn != debounced) begin
            debounced <= btn;
            counter <= counter + 1'b1;
        end
    end

endmodule

// Count up on each button press and display on LEDs
module debounced_counter(
    input               clk_27MHz,  // Onboard 27 MHz oscillator (Pin H11)
    input               bouncy_btn, // P6
    input               rst_s0,     // S0: T10

    output  reg [5:0]   led         // LED 0 - LED 5 (C13, A13, N16, N14, L14, L16)
);

    wire rst;
    wire clk;

    // Reset is the inverse of the first button
    assign rst = ~rst_s0;

    // Clock signal is the inverse of second button
    assign clk = ~bouncy_btn;

    wire debounced_clk;
    bouncer b(
        .clk(clk_27MHz),
        .rst(rst),
        .btn(clk),
        .debounced(debounced_clk)
    );

    // Count on clock rising edge or reset on button push
    always @(posedge debounced_clk or posedge rst) begin
        if (rst == 1'b1) begin
            led <= 6'b0;
        end else begin
            led <= led + 1'b1;
        end
    end

endmodule