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
    reg [31:0] note;

    // Berechnung: Step = (Ziel_Hz * 2^32) / 4.800.000
    // Konstante "Magic Number" (2^32 / 4.8M) ≈ 894.78
    // 440 Hz * 895 = 393800
    // 50 Hz (Bass) * 895 = 44750
    
    // --- NOTEN DEFINITIONEN (Step Sizes) ---
    localparam SILENCE = 0;
    localparam E2 = 73739;
    localparam A2 = 98426;
    localparam AS2 = 104278;
    localparam B2 = 110478;
    localparam C3 = 117046;
    localparam D3 = 131381;
    localparam DS3 = 139192;
    localparam E3 = 147469;
    localparam F3 = 156238;
    localparam FS3 = 165534;
    localparam G3 = 175687;
    localparam A3 = 196852;
    localparam B3 = 220957;
    localparam C4 = 233973;
    localparam DS4 = 278393;
    localparam E4 = 294910;
    localparam F4 = 312484;
    localparam FS4 = 331060;
    localparam G4 = 351375;
    localparam GS4 = 371602;
    localparam A4 = 394396;
    localparam B4 = 441914;
    localparam C5 = 468194;
    localparam D5 = 525531;
    localparam E5 = 589893;
    localparam F5 = 624968;
    localparam G5 = 701499;
    localparam A5 = 787406;

    // --- TEMPO GENERATOR (Der Dirigent) ---
    // Wir wollen ca. 14 Noten pro Sekunde (70ms pro Note)
    // 24 MHz / 1.680.000 = 14,2857142857 Hz
    reg [23:0] tempo_cnt;
    reg next_note_strobe; // Ein kurzer Impuls, wenn die nächste Note dran ist

    always @(posedge clk_24mhz) begin
        if (tempo_cnt == 1680000) begin
            tempo_cnt <= 0;
            next_note_strobe <= 1;
        end else begin
            tempo_cnt <= tempo_cnt + 1;
            next_note_strobe <= 0;
        end
    end

    // --- DER SONG (At Doom's Gate) ---
    reg [7:0] note_index; // Wir haben erstmal nur Platz für 256 Noten (8 Bit)

    always @(posedge clk_24mhz) begin
        if (next_note_strobe) begin
            note_index <= note_index + 1;
        end
    end

    // Die "Walze" der Spieluhr
    always @(*) begin
        case (note_index)
            // DOOM E1M1 (At Doom's Gate)
            // 1 Zeile = 1 Sechzehntel Note (ca. 70ms Delay empfohlen)

            // --- Riff Teil 1 (Das klassische "Dun-Dun-DUN-Dun") ---
            0: note = E2;   // Start
            1: note = E2;   // ->
            2: note = E2;
            3: note = E2;   // ->
            4: note = E3;   // (Die hohe Note)
            5: note = E3;   // ->
            6: note = E2;
            7: note = E2;   // ->
            8: note = E2;
            9: note = E2;   // ->
            10: note = D3;
            11: note = D3;  // ->
            12: note = E2;
            13: note = E2;  // ->
            14: note = E2;
            15: note = E2;  // ->

            // --- Riff Ende 1 ---
            16: note = C3;
            17: note = C3;  // ->
            18: note = E2;
            19: note = E2;  // ->
            20: note = E2;
            21: note = E2;  // ->
            22: note = AS2; // (Im Code NOTE_AS2)
            23: note = AS2; // ->
            24: note = E2;
            25: note = E2;  // ->
            26: note = E2;
            27: note = E2;  // ->
            28: note = B2;
            29: note = B2;  // ->
            30: note = C3;
            31: note = C3;  // ->

            // --- Riff Teil 2 (Wiederholung) ---
            32: note = E2;
            33: note = E2;  // ->
            34: note = E2;
            35: note = E2;  // ->
            36: note = E3;
            37: note = E3;  // ->
            38: note = E2;
            39: note = E2;  // ->
            40: note = E2;
            41: note = E2;  // ->
            42: note = D3;
            43: note = D3;  // ->
            44: note = E2;
            45: note = E2;  // ->
            46: note = E2;
            47: note = E2;  // ->

            // --- Riff Ende 2 (Langer Ton) ---
            48: note = C3;
            49: note = C3;  // ->
            50: note = E2;
            51: note = E2;  // ->
            52: note = E2;
            53: note = E2;  // ->
            54: note = AS2; // Langes Halten (Dotted Half)
            55: note = AS2; // ->
            56: note = AS2; // ->
            57: note = AS2; // ->
            58: note = AS2; // ->
            59: note = AS2; // ->
            60: note = AS2; // ->
            61: note = AS2; // ->
            62: note = AS2; // ->
            63: note = AS2; // ->

            // --- Riff Teil 3 (Vor dem Solo) ---
            64: note = E2;
            65: note = E2;  // ->
            66: note = E2;
            67: note = E2;  // ->
            68: note = E3;
            69: note = E3;  // ->
            70: note = E2;
            71: note = E2;  // ->
            72: note = E2;
            73: note = E2;  // ->
            74: note = D3;
            75: note = D3;  // ->
            76: note = E2;
            77: note = E2;  // ->
            78: note = E2;
            79: note = E2;  // ->

            // --- Das Schnelle Solo (Shredding) ---
            // Hier jede Zeile eine neue Note (Doppeltes Tempo!)
            80: note = FS3;
            81: note = D3;
            82: note = B2;
            83: note = A3;
            84: note = FS3;
            85: note = B2;
            86: note = D3;
            87: note = FS3;
            88: note = A3;
            89: note = FS3;
            90: note = D3;
            91: note = B2;

            // --- Kurze Pause / Loop Ende ---
            92: note = SILENCE;
            93: note = SILENCE;

            // --- Übergang / Riff (kurz) ---
            94: note = E2;
            95: note = E2;  // ->
            96: note = E2;
            97: note = E2;  // ->
            98: note = E3;
            99: note = E3;  // ->
            100: note = E2;
            101: note = E2; // ->
            102: note = E2;
            103: note = E2; // ->
            104: note = D3;
            105: note = D3; // ->
            106: note = E2;
            107: note = E2; // ->
            108: note = E2;
            109: note = E2; // ->

            // --- Solo 2 (Der hohe Lauf) ---
            // B3, G3, E3, G3, B3, E4, G3, B3, E4, B3, G4, B4
            110: note = B3;
            111: note = G3;
            112: note = E3;
            113: note = G3;
            114: note = B3;
            115: note = E4;
            116: note = G3;
            117: note = B3;
            118: note = E4;
            119: note = B3;
            120: note = G4;
            121: note = B4;

            // --- Mittelteil (Tonartwechsel zu A) ---
            // Das "Dun-Dun" Riff, aber tiefer/anders
            122: note = A2;
            123: note = A2; // ->
            124: note = A3;
            125: note = A3; // ->
            126: note = A2;
            127: note = A2; // ->
            128: note = G3;
            129: note = G3; // ->
            130: note = A2;
            131: note = A2; // ->
            132: note = F3;
            133: note = F3; // ->
            134: note = A2;
            135: note = A2; // ->
            136: note = DS3; // (Code: DS3)
            137: note = DS3; // ->
            138: note = A2;
            139: note = A2; // ->
            140: note = A2;
            141: note = A2; // ->
            142: note = E3;
            143: note = E3; // ->
            144: note = F3;
            145: note = F3; // ->

            // --- Mittelteil Wiederholung ---
            146: note = A2;
            147: note = A2; // ->
            148: note = A3;
            149: note = A3; // ->
            150: note = A2;
            151: note = A2; // ->
            152: note = G3;
            153: note = G3; // ->
            154: note = A2;
            155: note = A2; // ->
            156: note = F3;
            157: note = F3; // ->
            158: note = A2;
            159: note = A2; // ->
            160: note = DS3; // (Langer Ton)
            161: note = DS3; // ->
            162: note = DS3; // ->
            163: note = DS3; // ->

            // --- Solo 3 (Variante) ---
            // A3, F3, D3, A3, F3, D3, C4, A3, F3, A3, F3, D3
            164: note = A3;
            165: note = F3;
            166: note = D3;
            167: note = A3;
            168: note = F3;
            169: note = D3;
            170: note = C4;
            171: note = A3;
            172: note = F3;
            173: note = A3;
            174: note = F3;
            175: note = D3;

            // --- Zurück zum Haupt-Riff (Start) ---
            176: note = E2;
            177: note = E2; // ->
            178: note = E2;
            179: note = E2; // ->
            180: note = E3;
            181: note = E3; // ->
            182: note = E2;
            183: note = E2; // ->
            184: note = SILENCE;
            185: note = SILENCE;

            // --- Rückkehr zum Haupt-Riff (E) ---
            186: note = E2;
            187: note = E2; // ->
            188: note = E2;
            189: note = E2; // ->
            190: note = E3;
            191: note = E3; // ->
            192: note = E2;
            193: note = E2; // ->
            194: note = E2;
            195: note = E2; // ->
            196: note = D3;
            197: note = D3; // ->
            198: note = E2;
            199: note = E2; // ->
            200: note = E2;
            201: note = E2; // ->
            202: note = C3;
            203: note = C3; // ->
            204: note = E2;
            205: note = E2; // ->
            206: note = E2;
            207: note = E2; // ->
            208: note = AS2; // (AS2)
            209: note = AS2; // ->
            210: note = E2;
            211: note = E2; // ->
            212: note = E2;
            213: note = E2; // ->
            214: note = B2;
            215: note = B2; // ->
            216: note = C3;
            217: note = C3; // ->

            // --- Haupt-Riff Teil 2 (Vor dem letzten Solo) ---
            218: note = E2;
            219: note = E2; // ->
            220: note = E2;
            221: note = E2; // ->
            222: note = E3;
            223: note = E3; // ->
            224: note = E2;
            225: note = E2; // ->
            226: note = E2;
            227: note = E2; // ->
            228: note = D3;
            229: note = D3; // ->
            230: note = E2;
            231: note = E2; // ->
            232: note = E2;
            233: note = E2; // ->

            // --- Solo 4 (Das chromatische Ende) ---
            // F#3, D#3, B2, F#3, D#3, B2, G3, D3, B2, D#4, D#3, B2
            234: note = FS3;
            235: note = DS3;
            236: note = B2;
            237: note = FS3;
            238: note = DS3;
            239: note = B2;
            240: note = G3;
            241: note = D3;
            242: note = B2;
            243: note = DS4; // (DS4 - Hoch!)
            244: note = DS3;
            245: note = B2;

            // --- LOOP ENDE ---
            // Hier würde der Song normalerweise wieder bei 0 anfangen.
            // Wir setzen noch einen fetten End-Akkord, falls du nicht loopst:
            246: note = E2;
            247: note = E2; // ->
            248: note = E2; // ->
            249: note = E2; // ->
            
            // Loop oder Stille am Ende
            default: note = SILENCE; 
        endcase
    end

    // --- TEIL 5: Audio & PDM (16 Bit CD-Qualität) ---
    // PDM Akkumulator braucht 17 Bit (16 Bit Audio + 1 Bit Überlauf)
    reg [16:0] pdm_acc;
    reg [15:0] current_sample; // Hier landet der Wert aus der Tabelle

    always @(posedge clk_24mhz) begin
        if (ce_4_8mhz) begin
            // 1. Frequenz weiterzählen (hochpräzise)
            phase_accumulator <= phase_accumulator + note;

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