`timescale 1ns / 1ps
`default_nettype none

module led_controller(
    input wire clk,
    input wire rst,
    input wire en,
    input wire go_up,
    input wire go_down,
    input wire stop,
    output logic[3:0] q
);

typedef enum {STOP=0, SCROLL_UP=1, SCROLL_DOWN=2} state_t;
state_t scroll_state;

always_ff @(posedge clk) begin
    if (rst) begin 
        scroll_state <= STOP;
        q <= 4'b0001;
    end else begin
        if (en && scroll_state == STOP) begin
            q <= q;
        end if (en && scroll_state == SCROLL_UP) begin
            q <= ((q & 4'b0111) << 1) | ((q & 4'b1000) >> 3);
        end if (en && scroll_state == SCROLL_DOWN) begin
            q <= ((q & 4'b1110) >> 1) | ((q & 4'b0001) << 3);
        end if (go_down) begin
            scroll_state <= SCROLL_DOWN;
        end if (go_up) begin
            scroll_state <= SCROLL_UP;
        end if (stop) begin
            scroll_state <= STOP;
        end
    end
end

endmodule

`default_nettype wire