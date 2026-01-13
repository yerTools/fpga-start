module LED_Matrix(
    input       clk_27MHz,  // 27 MHz => Pin 52
    output[2:0] rgb1,       // Pin 70, 71, 72
    output[2:0] rgb2,       // Pin 73, 74, 75
    output[3:0] abcd,       // Pin 30, 33, 34, 40
    output      clk,        // Pin 35
    output      lat,        // Pin 41
    output      oe          // Pin 42
);
    assign oe = 0;

    wire clk_out;
    reg[7:0] div_counter = 0;
    assign clk_out = div_counter[7];
    always @(posedge clk_27MHz) div_counter <= div_counter + 1;

    assign clk = clk_out;

    reg[8:0] led_counter = 0;

    assign rgb1 = led_counter[2:0];
    assign rgb2 = led_counter[5:3];
    assign abcd = led_counter[8:5];

    always @(negedge clk_out) begin
        led_counter <= led_counter + 1;
    end

    assign lat = led_counter[5:0] == 0 && clk_out;
endmodule