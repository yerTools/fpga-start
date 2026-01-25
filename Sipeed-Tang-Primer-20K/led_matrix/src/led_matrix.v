module color_for(
    input       [5:0]    x_pos,
    input       [5:0]    y_pos,
    output reg  [7:0]    red,
    output reg  [7:0]    green,
    output reg  [7:0]    blue
);
    always @(*) begin
        red <= x_pos + y_pos + y_pos + y_pos;
        green <= 0;
        blue <= 0;
    end
endmodule

module led_matrix(
    input           clk_27MHz,

    output reg  [2:0]   rgb1,
    output reg  [2:0]   rgb2,
    output reg  [4:0]   row,
    output reg          clk,
    output reg          oe,
    output reg          latch
);
    reg [15:0]   clk_div;
    always @(posedge clk_27MHz) clk_div <= clk_div + 1;


    reg [2:0]   state;

    reg [5:0]   column;
    reg [7:0]   color_depth;

    // Since we are showing the last row, while we are filling the next row, current_row is row + 1
    reg [4:0]   current_row;

    wire    [7:0]   red1;
    wire    [7:0]   green1;
    wire    [7:0]   blue1;
    wire    [7:0]   red2;
    wire    [7:0]   green2;
    wire    [7:0]   blue2;

    color_for(
        .x_pos(column),
        .y_pos(current_row + 6'd0),
        .red(red1),
        .green(green1),
        .blue(blue1)
    );


    color_for(
        .x_pos(column),
        .y_pos(current_row + 6'd32),
        .red(red2),
        .green(green2),
        .blue(blue2)
    );

    always @(posedge clk_27MHz) begin
        case (state)
            // This is a soft reset state to set get everything into an knowing state
            0: begin 
                rgb1 <= 0;
                rgb2 <= 0;

                row <=  5'b11111;
                current_row  <= 0;
            
                clk   <= 0;
                oe    <= 0; // Show the last row
                latch <= 0;

                column      <= 0;
                color_depth <= 0;
                
                state <= 1;
            end

            // Set the pixel color (clk low)
            1: begin
                clk <= 0;
    
                if (red1 > color_depth) rgb1[0] <= 1;
                else rgb1[0] <= 0;
                if (green1 > color_depth) rgb1[1] <= 1;
                else rgb1[1] <= 0;
                if (blue1 > color_depth) rgb1[2] <= 1;
                else rgb1[2] <= 0;
                

                if (red2 > color_depth) rgb2[0] <= 1;
                else rgb2[0] <= 0;
                if (green2 > color_depth) rgb2[1] <= 1;
                else rgb2[1] <= 0;
                if (blue2 > color_depth) rgb2[2] <= 1;
                else rgb2[2] <= 0;
                

                column <= column + 1;

                state <= 2;
            end

            // Shift the current color
            2: begin
                clk <= 1;

                // Check if we reached the end of the column
                if (column == 0) state <= 3;
                else state <= 1;
            end
    
            // Disable output for latching the current row
            3: begin
                clk <= 0;
                oe  <= 1;
        
                state <= 4;
            end

            // Latch and increment row
            4: begin
                latch <= 1;
                
                row <= current_row;
                current_row <= current_row + 1;

                state <= 5;
            end

            // Enable output
            5: begin
                latch <= 0;
                oe    <= 0;

                if (current_row == 0) state <= 6;
                else state <= 1;
            end

            // Increment color depth
            6: begin
                if (color_depth == 254) begin
                    color_depth <= 0;
                    state <= 0;
                end else begin
                    color_depth <= color_depth + 1;
                    state <= 1;
                end
            end

            default: state <= 0; // Soft reset
        endcase
    end

endmodule

