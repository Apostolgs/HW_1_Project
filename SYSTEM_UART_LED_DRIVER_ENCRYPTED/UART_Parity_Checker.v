`timescale 1ns/1ps

module UART_PChecker (input [7:0] UART_DATA ,output reg parity_bit);

	// Count number of 1's in transmitter data
	reg [3:0] ones_count;

	always @* 
	begin
  		ones_count = 4'b0000;
  		for (int i = 0; i < 8; i = i + 1) begin
    			ones_count = ones_count + UART_DATA[i];
  		end
	end

	// Check for parity
	always @*
	begin
  		if (ones_count[0] == 1'b1)
			parity_bit = 1'b0 ; //even number of 1's -> parity bit = 0
		else
			parity_bit = 1'b1 ; //odd number of 1's -> parity bit = 1
	end
endmodule
