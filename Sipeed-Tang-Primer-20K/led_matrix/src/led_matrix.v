module color_for_cycles(
    input        [31:0] frame,
    input        [5:0]  x_pos,
    input        [5:0]  y_pos,
    output reg   [7:0]  red,
    output reg   [7:0]  green,
    output reg   [7:0]  blue
);
    // Hilfsvariablen für signed math (damit wir negative Werte haben)
    wire signed [6:0] dx = $signed({1'b0, x_pos}) - 32; // -32 bis +31
    wire signed [6:0] dy = $signed({1'b0, y_pos}) - 32;
    
    // Abstand zum Quadrat (Wurzel ziehen ist zu teuer, Quadrat reicht für Optik)
    wire [15:0] dist_sq = dx*dx + dy*dy;
    
    // Animations-Geschwindigkeit anpassen (Bits shiften)
    wire [7:0] time_val = frame[7:0]; 

    always @(*) begin
        // Der Trick: Abstand + Zeit. Das Überlaufen (Overflow) erzeugt die Ringe.
        // Wir nehmen verschiedene Bits von dist_sq für verschiedene Farben -> Regenbogen
        red   <= dist_sq[9:2] + time_val;       
        green <= dist_sq[9:2] + time_val + 85;  // +85 für Phasenverschiebung
        blue  <= dist_sq[9:2] + time_val + 170; // +170 für Phasenverschiebung
    end
endmodule

module color_for_xor(
    input        [31:0] frame,
    input        [5:0]  x_pos,
    input        [5:0]  y_pos,
    output reg   [7:0]  red,
    output reg   [7:0]  green,
    output reg   [7:0]  blue
);
    // Langsame Zeit für fließende Bewegung
    wire [7:0] t = frame[9:2];
    
    always @(*) begin
        // Verknüpfung von X, Y und Zeit mit Sinus-ähnlichen Verzerrungen durch XOR
        // Die Formel: (x + t) ^ (y + t) erzeugt bewegte Karos
        
        red   <= (x_pos + t) ^ (y_pos - t);
        
        // Etwas komplexere Formel für Grün
        green <= (x_pos + y_pos + t) ^ (x_pos - t);
        
        // Blau basiert auf einer Rotation
        blue  <= ((x_pos << 1) + t) ^ ((y_pos >> 1) + t);
    end
endmodule

module color_for_green(
    input        [31:0] frame,
    input        [5:0]  x_pos,
    input        [5:0]  y_pos,
    output reg   [7:0]  red,
    output reg   [7:0]  green,
    output reg   [7:0]  blue
);
    // Schnellere Animation für Glitch-Effekt
    wire [7:0] t = frame[9:2];

    always @(*) begin
        red   <= 0; // Matrix ist meistens grün ;)
        
        // Erzeugt vertikale Streifen, die sich bewegen
        // "&&" maskiert Pixel aus, erzeugt "Lücken" im Regen
        if (((x_pos * 3 + t) & 8'h20) && ((y_pos + t*2) & 8'h10)) begin
            green <= 255; // Helles Pixel
            blue  <= 100; // Leichtes Cyan Leuchten
        end else begin
            // Nachleuchten simulieren (einfacher Gradient im Hintergrund)
            green <= (y_pos + t*4); 
            blue  <= 0;
        end
    end
endmodule

module color_for(
    input        [31:0] frame,
    input        [5:0]  x_pos,
    input        [5:0]  y_pos,
    output reg   [7:0]  red,
    output reg   [7:0]  green,
    output reg   [7:0]  blue
);

    // --- 1. Koordinaten zentrieren ---
    wire signed [6:0] dx = $signed({1'b0, x_pos}) - 32;
    wire signed [6:0] dy = $signed({1'b0, y_pos}) - 32;
    
    // R^2 (Abstand zur Mitte zum Quadrat)
    wire [11:0] r2 = dx*dx + dy*dy;
    
    // Vermeide Division durch Null für die Tiefe
    // Wir nutzen r2 + 8 als Divisor.
    // Ein echter Raymarcher geht "in die Tiefe" (Z).
    // Tiefe Z ist proportional zu 1/Radius.
    // Da Division teuer ist, nutzen wir eine Lookup-Logik über Shifts oder eine einfache Näherung.
    // Wir nehmen hier eine "Look-Up" ähnliche Struktur für Z:
    // Je kleiner r2, desto größer Z.
    // Wir faken das mit einer Bit-Invertierung von r2, geshiftet.
    wire [7:0] inv_radius = 8'd255 - (r2[9:2]); // 255 in der Mitte, 0 außen

    // --- 2. Zeit & Bewegung ---
    // t_move zieht uns in den Tunnel.
    wire [7:0] t_move = frame[7:0]; 
    wire [7:0] t_rot  = frame[12:5];

    // Z-Koordinate im "virtuellen" Raum
    // Wir addieren die Zeit zur inversen Tiefe -> Bewegung nach vorne.
    wire [7:0] z_depth = inv_radius + t_move;


    // --- 3. Frostbyte Noise Imitation ---
    // Der Shader nutzt "Dot Noise" (Goldener Schnitt).
    // Wir nutzen "Integer Hashing".
    // Wir rotieren die Koordinaten basierend auf der Tiefe (Twist-Effekt).
    
    wire signed [7:0] twist_x = dx + (dy * z_depth[7:5]); // Leichter Twist
    wire signed [7:0] twist_y = dy - (dx * z_depth[7:5]);

    // Das ist unser "Raymarch Step" (nur einer statt 10, aber komplex):
    // Wir verknüpfen X, Y und Z mit XOR und Additionen.
    // Die Konstanten (3, 5) sorgen dafür, dass es chaotisch aussieht (wie Noise).
    wire [7:0] noise_raw = (twist_x * 3 + z_depth) ^ (twist_y * 5 + t_rot);
    
    // Wir machen das "Grieseln" weicher, indem wir benachbarte Werte mitteln (Blur Fake)
    // oder wir lassen es scharf für den "Frost"-Look.
    // Wir fügen eine "Turbulenz" hinzu: abs(sin(z)) -> Dreieckswelle von Z
    wire [4:0] tri_z = z_depth[4:0];
    wire [4:0] turbulence = (tri_z > 16) ? (32 - tri_z) : tri_z; // 0..16..0
    
    // Kombiniere Noise und Turbulenz
    wire [7:0] pattern = noise_raw + (turbulence << 3);


    // --- 4. Beleuchtung & Nebel ---
    // ACES Tonemap macht Kontrast hoch. Wir machen das manuell.
    // Die Mitte (Tunnel Ende) soll leuchten.
    
    // Fog: Je weiter außen (r2 groß), desto dunkler.
    // r2 geht bis ca 2000. r2 >> 3 geht bis 250.
    wire [8:0] fog_calc = 9'd300 - (r2 >> 2); 
    wire [7:0] fog = (fog_calc[8]) ? 8'd0 : fog_calc[7:0]; // Clamp auf 0 wenn negativ

    always @(*) begin
        // Der Frostbyte Shader ist bläulich/türkis mit weißen Highlights.
        
        // Pattern filtert die Pixel.
        // Wenn Pattern hoch ist -> hell.
        
        // Blaukanal: Basis-Atmosphäre
        // pattern[7] ist das MSB, also das gröbste Rauschen.
        blue  <= (fog > 0) ? (fog[7:1] + pattern[6:0]) : 0;
        
        // Grünkanal: Etwas weniger, für den Türkis-Look
        green <= (fog > 0) ? ((fog >> 2) + (pattern >> 1)) : 0;
        
        // Rotkanal: Nur in den hellsten Spitzen (weißes Licht)
        // Wir nutzen thresholding: Wenn Pattern sehr hell ist, gib Rot dazu.
        if (pattern > 200) 
            red <= pattern;
        else 
            red <= pattern >> 3; // Dunkles Lila im Hintergrund
            
        // ACES Fake: Kontrast erhöhen
        // Wenn es hell ist, mach es noch heller (Sättigung)
    end

endmodule

module led_matrix(
    input           clk_27MHz,
    input           rst_n,      // Active Low Reset hinzugefügt

    output reg [2:0] rgb1,      // Obere Hälfte (Zeilen 0-31)
    output reg [2:0] rgb2,      // Untere Hälfte (Zeilen 32-63)
    output reg [4:0] row,       // Zeilenadresse (A, B, C, D, E)
    output reg       clk,       // Shift Clock
    output reg       oe,        // Output Enable (Active Low -> 0 = Licht an)
    output reg       latch      // Latch Data
);

    // --- State Machine Definitionen ---
    localparam STATE_RESET      = 0;
    localparam STATE_SHIFT_DATA = 1;
    localparam STATE_SHIFT_CLK  = 2;
    localparam STATE_LATCH      = 3;
    localparam STATE_EXPOSURE   = 4; // Neuer State für BCM Wartezeit
    localparam STATE_NEXT_ROW   = 5;

    reg [2:0] state;

    // --- Counter und Positionen ---
    reg [5:0] column;       // 0 bis 63
    reg [4:0] current_row;  // 0 bis 31 (Scanline)
    
    // --- BCM Variablen ---
    reg [2:0] bit_index;    // Welches Bit zeigen wir gerade? (0 bis 7)
    reg [15:0] oe_counter;  // Zähler für die Leuchtdauer

    // Basis-Zeiteinheit für das LSB (Bit 0). 
    // Bei 27MHz sind 100 Ticks ca. 3.7us. 
    // Bit 0 = 100 Ticks, Bit 7 = 12800 Ticks.
    parameter LSB_PERIOD = 15; 

    // --- Farb-Generierung ---
    wire [7:0] red1, green1, blue1;
    wire [7:0] red2, green2, blue2;

    reg [31:0]  frame;

    // Instanz für die obere Panel-Hälfte
    color_for c1 (
        .frame(frame),
        .x_pos(column),
        .y_pos({1'b0, current_row}), // 0..31
        .red(red1), .green(green1), .blue(blue1)
    );

    // Instanz für die untere Panel-Hälfte
    color_for c2 (
        .frame(frame),
        .x_pos(column),
        .y_pos({1'b1, current_row}), // 32..63
        .red(red2), .green(green2), .blue(blue2)
    );

    always @(posedge clk_27MHz or negedge rst_n) begin
        if (!rst_n) begin
            state       <= STATE_RESET;
            rgb1        <= 0;
            rgb2        <= 0;
            row         <= 0;
            clk         <= 0;
            oe          <= 1; // Display aus
            latch       <= 0;
            column      <= 0;
            current_row <= 0;
            bit_index   <= 0;
            oe_counter  <= 0;
            frame       <= 0;
        end else begin
            case (state)
                
                // 0: Initialisierung
                STATE_RESET: begin
                    oe    <= 1; // Sicherstellen, dass Display aus ist
                    latch <= 0;
                    state <= STATE_SHIFT_DATA;
                end

                // 1: Daten setzen (Bit Slicing)
                STATE_SHIFT_DATA: begin
                    clk <= 0;
                    
                    // HIER IST DIE MAGIE: Wir prüfen nur das aktuelle 'bit_index'
                    // Anstatt (color > counter), nehmen wir einfach das n-te Bit.
                    
                    rgb1[0] <= red1[bit_index];
                    rgb1[1] <= green1[bit_index];
                    rgb1[2] <= blue1[bit_index];

                    rgb2[0] <= red2[bit_index];
                    rgb2[1] <= green2[bit_index];
                    rgb2[2] <= blue2[bit_index];

                    state <= STATE_SHIFT_CLK;
                end

                // 2: Daten schieben (Clock High)
                STATE_SHIFT_CLK: begin
                    clk <= 1;
                    column <= column + 1;
                    
                    // Wenn Spalte überläuft (63 -> 0), sind wir fertig mit der Zeile
                    if (column == 6'd63) 
                        state <= STATE_LATCH;
                    else 
                        state <= STATE_SHIFT_DATA;
                end

                // 3: Zeile Latchen & Output Enable vorbereiten
                STATE_LATCH: begin
                    clk   <= 0;
                    latch <= 1;     // Daten übernehmen
                    oe    <= 1;     // Display kurz aus während Zeilenwechsel (Ghosting Schutz)
                    
                    // Adresse setzen für die Daten, die wir gerade geschoben haben
                    row   <= current_row; 
                    
                    oe_counter <= 0; // Timer resetten
                    state <= STATE_EXPOSURE;
                end

                // 4: Belichtung (BCM Timing)
                STATE_EXPOSURE: begin
                    latch <= 0;
                    oe    <= 0; // Display AN!

                    // Wir bleiben hier für: LSB_PERIOD * 2^bit_index
                    // (1 << bit_index) ist der binäre Shift für 2^n
                    if (oe_counter >= (LSB_PERIOD * (16'd1 << bit_index))) begin
                        oe    <= 1; // Display AUS
                        state <= STATE_NEXT_ROW;
                    end else begin
                        oe_counter <= oe_counter + 1;
                    end
                end

                // 5: Nächste Zeile oder nächstes Bit vorbereiten
                STATE_NEXT_ROW: begin
                    // Wir bereiten den Zeilenzähler schon für den nächsten Shift vor
                    current_row <= current_row + 1;

                    // Wenn wir alle 32 Zeilen (0-31) durch haben:
                    if (current_row == 5'd31) begin
                        if (bit_index == 7) frame <= frame + 1;

                        current_row <= 0;
                        bit_index   <= bit_index + 1; // Zum nächsten Helligkeits-Bit wechseln

                        // Wenn wir Bit 7 fertig haben, fangen wir wieder bei Bit 0 an
                        // (bit_index ist 3 bit breit, läuft also automatisch 7->0 über)
                    end
                    
                    state <= STATE_SHIFT_DATA;
                end

            endcase
        end
    end

endmodule