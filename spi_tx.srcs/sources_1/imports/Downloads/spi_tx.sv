`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module spi_tx
       #(  parameter DATA_WIDTH = 8,
           parameter DATA_CLK_PERIOD = 40
        )
        ( input wire clk,
          input wire rst,
          input wire [DATA_WIDTH-1:0] data_in,
          input wire trigger, //High when new data is on line
          output logic busy, //transmitting to output
          output logic copi, //Controller Out Peripheral In; data_out
          output logic dclk, //Data Clock
          output logic cs //Chip Select; 0 when transmitting, 1 when not
        );

    logic [DATA_WIDTH-1:0] new_data; // to hold new data after trigger
    logic [3:0] bit_counter; // to keep track of where we are in transmission
    logic [7:0] dclk_counter; // to keep track of dclk

    initial begin
        bit_counter <= 4'b0000;
        new_data <= 0;
        busy <= 1'b0;
        cs <= 1'b1;
        copi <= 1'b0;
        dclk_counter <= 4'b0000;
    end 
    
    always_ff @(posedge clk) begin 
        if (rst) begin
            bit_counter <= 4'b0000;
            new_data <= 0;
            busy <= 1'b0;
            cs <= 1'b1;
            copi <= 1'b0;
            dclk_counter <= 4'b0000;
        end else begin
            // receiving new data, queue up MSB to COPI
            if (trigger && !busy) begin
                new_data <= data_in << 1;
                busy <= 1;
                cs <= 0;
                dclk <= 0;
                copi <= data_in[DATA_WIDTH-1];
                bit_counter <= 0;
            // while transmitting
            end if (busy && (bit_counter != (DATA_WIDTH))) begin
                // dclk low (first half of period)
                if (dclk_counter == DATA_CLK_PERIOD/2) begin
                    dclk <= 1;
                    dclk_counter <= dclk_counter + 1;
                // dclk high (second half of period); transmit next bit
                end if (dclk_counter == DATA_CLK_PERIOD) begin 
                    copi <= new_data[DATA_WIDTH-1];
                    new_data <= new_data << 1;
                    bit_counter <= bit_counter + 1;
                    dclk <= 0;
                    dclk_counter <= 0;
                // tick dclk counter up in idle case
                end if (dclk_counter != DATA_CLK_PERIOD && dclk_counter != DATA_CLK_PERIOD/2) begin
                    dclk_counter <= dclk_counter + 1;
                end
            // once full message has been transmitted
            end if (busy && bit_counter == (DATA_WIDTH)) begin
                cs <= 1; 
                busy <= 0;
                bit_counter <= 0;
            end 
        end
    end
endmodule

`default_nettype wire // prevents system from inferring an undeclared logic (good practice)

