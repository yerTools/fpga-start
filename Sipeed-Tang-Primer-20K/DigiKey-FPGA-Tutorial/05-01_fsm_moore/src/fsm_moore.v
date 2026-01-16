// Thank you Ahawn Hymel and DigiKey - Source: https://youtu.be/pK6XN7sFosI

// State machine that counts up when button is pressed
module fsm_moore (
    // Inputs
    input               clk,
    input               rst_btn,
    input               go_btn,

    // Outputs
    output  reg [3:0]   led,
    output  reg         done_sig
);

    // States
    localparam STATE_IDLE       = 2'd0;
    localparam STATE_COUNTING   = 2'd1;
    localparam STATE_DONE       = 2'd2;
    
    // Max counts for clock divider and counter (4 Hz)
    localparam MAX_CLK_COUNT    = 22'd3374999;
    localparam MAX_LED_COUNT    = 4'hf;

    // Internal signals
    wire rst;
    wire go;

    // Internal storage elements
    reg         div_clk;
    reg [1:0]   state;
    reg [21:0]  clk_count;

    // Invert active-low buttons
    assign rst  = ~rst_btn;
    assign go   = ~go_btn;

    // Clock divider
    always @(posedge clk or posedge rst) begin
        if (rst == 1'b1) begin
            clk_count <= 22'b0;
        end else if (clk_count == MAX_CLK_COUNT) begin
            clk_count <= 24'b0;
            div_clk <= ~div_clk;
        end else begin
            clk_count <= clk_count + 1'b1;
        end
    end

    // State transition logic
    always @ (posedge div_clk or posedge rst) begin
        // On reset, return to idle state
        if (rst == 1'b1) begin
            state <= STATE_IDLE;
        end else begin
            // Define the state transitions
            case (state)
                // Wait for go button to be pressed
                STATE_IDLE: begin
                    if (go == 1'b1) begin
                        state <= STATE_COUNTING;
                    end
                end

                // Go from counting to done if counting reaches max
                STATE_COUNTING: begin
                    if (led == MAX_LED_COUNT) begin
                        state <= STATE_DONE;
                    end
                end

                // Spend one clock cycle in done state
                STATE_DONE: state <= STATE_IDLE;

                // Go to idle if in unknown state
                default: state <= STATE_IDLE;
            endcase
        end
    end

    // Handle the LED counter
    always @ (posedge div_clk or posedge rst) begin
        if (rst == 1'b1) begin
            led <= 4'd0;
        end else begin
            if (state == STATE_COUNTING) begin
                led <= led + 1;
            end else begin
                led <= 4'd0;
            end
        end
    end

    // Handle done LED output
    always @(*) begin
        if (state == STATE_DONE) begin
            done_sig = 1'b1;
        end else begin
            done_sig = 1'b0;
        end
    end

endmodule