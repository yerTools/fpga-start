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

    // Since we are showing the last row, while we are filling the next row, current_row is row + 1
    reg [4:0]   current_row;

    reg [2:0]   color;
    reg [6:0]   width;

    always @(posedge clk_div[3]) begin
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

                column <= 0;

                if (width == 0) begin
                    if (color == 7) color <= 1;
                    else color  <= color + 1;
                end

                width <= width + 1;
                
                state <= 1;
            end

            // Set the pixel color (clk low)
            1: begin
                clk <= 0;
    
                if ((width[6] == 0 && column <= width[5:0]) || (width[6] == 1 && column >= width[5:0])) begin
                    rgb1 <= 0;
                    rgb2 <= color;
                end else begin
                    rgb1 <= color;
                    rgb2 <= 0;
                end
                

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

                if (current_row == 0) state <= 0;
                else state <= 1;
            end

            default: state <= 0; // Soft reset
        endcase
    end

endmodule