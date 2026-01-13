module Audio_Top (
    input clk,       // 27 MHz => Pin 52
    input s1, s2,    // Taster Pin 4 und Pin 3
    output pdm_out   // An den RC-Filter - Pin 31 => 1 kOhm => {Audio-Out} => 3300 pF => GND
);

    // Drähte für die Verbindung zur PLL
    wire clk_24mhz;

    // --- 1. INSTANZIERUNG DER PLL ---
    // Der Name "Gowin_rPLL" hängt davon ab, wie du das IP genannt hast.
    // Schau in die generierte .v Datei, wie das Modul heißt!
    Gowin_rPLL pll_24mhz (
        .clkout(clk_24mhz), // Unser neuer 24 MHz Takt
        .clkin(clk)          // Input: 27 MHz
    );


    // --- TEIL 2: Der "Clock Enable" Generator (Teiler durch 5) ---
    // Wir wollen ca. 4.8 MHz Sampling Rate.
    reg [2:0] div_cnt;
    reg ce_4_8mhz; // Das ist unser "Enable"-Signal (Strobe)

    always @(posedge clk_24mhz) begin
        if (div_cnt == 4) begin
            div_cnt <= 0;
            ce_4_8mhz <= 1; // Tür auf! Einmaliger Impuls.
        end else begin
            div_cnt <= div_cnt + 1;
            ce_4_8mhz <= 0; // Tür zu.
        end
    end

    // --- TEIL 3: Der Speicher (ROM) ---
    // 4096 Einträge, 16 Bit breit
    reg [15:0] sine_rom [0:4095];

    // Datei laden. Der Synthesizer führt das beim "Brennen" aus.
    // Der Inhalt ist dann fest im Chip "eingebrannt".
    initial begin
        $readmemh("sine.hex", sine_rom);
    end


    // --- TEIL 4: Der Frequenz-Generator (32 Bit für extreme Präzision) ---
    // Damit kommen wir rechnerisch auf 0.001 Hz genau. 
    // Das reicht für jeden Bass der Welt.
    reg [31:0] phase_accumulator;
    reg [31:0] step_size;

    // Berechnung: Step = (Ziel_Hz * 2^32) / 4.800.000
    // Konstante "Magic Number" (2^32 / 4.8M) ≈ 894.78
    // 440 Hz * 895 = 393800
    // 50 Hz (Bass) * 895 = 44750
    
    always @(*) begin
        if (!s1)       step_size = 393800; // 440 Hz
        else if (!s2)  step_size = 44750;  // 50 Hz (Tiefer Bass!)
        else           step_size = 0;
    end


    // --- TEIL 5: Audio & PDM (16 Bit CD-Qualität) ---
    // PDM Akkumulator braucht 17 Bit (16 Bit Audio + 1 Bit Überlauf)
    reg [16:0] pdm_acc;
    reg [15:0] current_sample; // Hier landet der Wert aus der Tabelle

    always @(posedge clk_24mhz) begin
        if (ce_4_8mhz) begin
            // 1. Frequenz weiterzählen (hochpräzise)
            phase_accumulator <= phase_accumulator + step_size;

            // 2. Lookup (Nachschlagen)
            // Wir nutzen die obersten 12 Bits als Adresse (0..4095)
            // phase_accumulator[31:20] sind genau 12 Bits.
            current_sample <= sine_rom[phase_accumulator[31:20]];

            // 3. PDM generieren (CD-Qualität)
            // Wir nehmen das High-Byte des Frequenzzählers als aktuellen "Wert"
            pdm_acc <= pdm_acc[15:0] + current_sample;
        end
    end

    assign pdm_out = pdm_acc[16];

endmodule