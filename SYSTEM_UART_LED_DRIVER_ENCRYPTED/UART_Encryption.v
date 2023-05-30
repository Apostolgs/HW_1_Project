`timescale 1ns/1ps

module uart_encryption(DATA_IN , key, DATA_OUT);
	
	/* 
	we will perform a simple encryption using DATA_OUT = DATA_IN XOR key
	this way, we can encrypt the data before tranmittion , and then after we receive them to decrypt, 
	we just XOR again with same key (in our case baud select) and we will get the original message
	because ((A XOR B) XOR B) = A 
	*/
	
	input [7:0] DATA_IN ; //DATA 
	input [2:0] key ; //we will set it so key for encryption is the same as baud select
	output reg [7:0] DATA_OUT ;

	always @ (DATA_IN)
	begin
		DATA_OUT[2:0] = DATA_IN[2:0] ^ key ; 
		DATA_OUT[5:3] = DATA_IN[5:3] ^ key ; 
		DATA_OUT[7:6] = DATA_IN[7:6] ^ key[1:0] ;  
	end

endmodule	
 	