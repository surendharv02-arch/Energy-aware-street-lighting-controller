module street_light #(
    parameter CLK_FREQ_HZ = 50000000,
    parameter BLINK_FREQ_HZ = 1,
    parameter PWM_BITS = 8
)(
    input clk,
    input reset,
    input day_night,
    input energy_mode,
    output reg [7:0] led
);

    // Clock divider for sequential lighting
    localparam DIV_LIMIT =
        CLK_FREQ_HZ / (2 * BLINK_FREQ_HZ);

    reg [31:0] counter;
    reg pattern;

    // PWM counter for brightness control
    reg [PWM_BITS-1:0] pwm_counter;

    // Generate alternating lighting pattern
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 32'd0;
            pattern <= 1'b0;
        end
        else if (counter >= DIV_LIMIT - 1) begin
            counter <= 32'd0;
            pattern <= ~pattern;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end

    // PWM counter
    always @(posedge clk or posedge reset) begin
        if (reset)
            pwm_counter <= {PWM_BITS{1'b0}};
        else
            pwm_counter <= pwm_counter + 1'b1;
    end

    // Street light control
    always @(*) begin
        if (!day_night) begin
            // DAY: all lights OFF
            led = 8'b00000000;
        end
        else if (!energy_mode) begin
            // NORMAL NIGHT: all lights fully ON
            led = 8'b11111111;
        end
        else begin
            // ENERGY-SAVING NIGHT:
            // Alternate between two groups using PWM
            if (pattern == 1'b0) begin
                led[0] = (pwm_counter < 8'd128);
                led[1] = 1'b0;
                led[2] = (pwm_counter < 8'd128);
                led[3] = 1'b0;
                led[4] = (pwm_counter < 8'd128);
                led[5] = 1'b0;
                led[6] = (pwm_counter < 8'd128);
                led[7] = 1'b0;
            end
            else begin
                led[0] = 1'b0;
                led[1] = (pwm_counter < 8'd128);
                led[2] = 1'b0;
                led[3] = (pwm_counter < 8'd128);
                led[4] = 1'b0;
                led[5] = (pwm_counter < 8'd128);
                led[6] = 1'b0;
                led[7] = (pwm_counter < 8'd128);
            end
        end
    end

endmodule 