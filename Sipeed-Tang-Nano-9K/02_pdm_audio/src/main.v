module Audio_Top (
    input clk,       // 27 MHz => Pin 52
    output pdm_out   // An den RC-Filter - Pin 31 => 1 kOhm => {Audio-Out} => 3300 pF => GND
);

    // --- TEIL 1: Der "Clock Enable" Generator (Teiler durch 6) ---
    // Wir wollen ca. 4.5 MHz Sampling Rate.
    reg [2:0] div_cnt;
    reg ce_4_5mhz; // Das ist unser "Enable"-Signal (Strobe)

    always @(posedge clk) begin
        if (div_cnt == 5) begin
            div_cnt <= 0;
            ce_4_5mhz <= 1; // Tür auf! Einmaliger Impuls.
        end else begin
            div_cnt <= div_cnt + 1;
            ce_4_5mhz <= 0; // Tür zu.
        end
    end

    // --- TEIL 2: Audio Logik (nur wenn Tür offen) ---

    // 1. Die Audio-Quelle: Ein Sägezahn
    // 4.5 MHz / 8192 (13 bit) = ca. 550 Hz. 
    // Das ist fast ein C#5 Ton (554Hz). Perfekt hörbar.
    reg [12:0] saw_wave;
    
    // 2. Der PDM Modulator (1st Order Delta-Sigma)
    // Wir brauchen einen Akkumulator, der ein Bit breiter ist als unser Signal.
    reg [13:0] accumulator;

    always @(posedge clk) begin
        // WICHTIG: Alles passiert nur, wenn ce_4_5mhz aktiv ist!
        if (ce_4_5mhz) begin
            // A. Sägezahn generieren
            saw_wave <= saw_wave + 1;

            // B. PDM Modulator
            // Addiere den aktuellen Audio-Wert zum Speicher
            accumulator <= accumulator[12:0] + saw_wave;
        end
    end

    // Das Überlauf-Bit ist unser Output
    // Der Output ist ein "Draht", der braucht kein Enable.
    // Er zeigt einfach immer den Zustand des obersten Bits.
    assign pdm_out = accumulator[13];

endmodule