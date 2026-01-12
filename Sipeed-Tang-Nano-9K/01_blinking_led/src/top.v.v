module Top (
    input clk,          // Der 27 MHz Takt vom Board => Pin 52
    output reg led_1,   // Eine der Onboard-LEDs (z.B. Pin 10, 11, 13, 14, 15, 16) => Pin 10

    input s1,           // Einen der Onboard-Taster (Pin 3 oder Pin 4) => Pin 4 (Muss Pullup sein)
    output led_2,       // Eine der Onboard-LEDs (z.B. Pin 10, 11, 13, 14, 15, 16) => Pin 13

    input s2,           // Einen der Onboard-Taster (Pin 3 oder Pin 4) => Pin 3 (Muss Pullup sein)
    output led_3        // Eine der Onboard-LEDs (z.B. Pin 10, 11, 13, 14, 15, 16) => Pin 15
);

    // Ein 25-Bit breiter Speicher für unsere Zahl
    // 2^25 ist ca. 33 Millionen -> passt für ca. 1 Sekunde Taktung
    reg [24:0] counter;

    // "always" Block: Wird bei jedem Takt-Anstieg (posedge) ausgeführt
    always @(posedge clk) begin
        counter <= counter + 1; // Zähle hoch
        
        // Wir nehmen das höchste Bit (MSB).
        // Das kippt viel langsamer als das unterste Bit.
        led_1 <= counter[24];     
    end

    // assign erzeugt eine direkte "Verdrahtung".
    // Das passiert SOFORT, nicht erst beim nächsten Takt.
    // Die LED ist dann an, wenn der Taster gedrueckt ist.
    assign led_2 = s1;

    // assign erzeugt eine direkte "Verdrahtung".
    // Das passiert SOFORT, nicht erst beim nächsten Takt.
    // Die LED ist dann aus, wenn der Taster gedrueckt ist.
    assign led_3 = ~s2;

endmodule