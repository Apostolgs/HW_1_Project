`timescale 1ns/1ps


/*
  -- bit of description for the thoughts behind this design 
  -- first , we will use a 20ns clock and the specified Baud rates given to us  
  -- BAUD_SEL |  Baud Rate        |   Sample Period  ( 1 / ( Baud Rate * 16 ) )  |    a      |    error (a * 2.5ns)  |   Relative Error (error/Sample Period) * 100%
  --  0 0 0   |  300    bits/sec  |   0.208   millisecond            		 |    384    |    960ns              |   0.462%         	
  --  0 0 1   |  1200   bits/sec  |   51.875  microsecond                        |    96     |    240ns              |   0.462%                       
  --  0 1 0   |  4800   bits/sec  |   13      microsecond                        |    24     |    60ns               |   0.462%                     
  --  0 1 1   |  9600   bits/sec  |   6.5     microsecond                        |    12     |    30ns               |   0.462%                     
  --  1 0 0   |  19200  bits/sec  |   3.255   microsecond                        |    6      |    15ns               |   0.461%                
  --  1 0 1   |  38400  bits/sec  |   1.6275  microsecond                        |    3      |    7.5ns              |   0.461%                     
  --  1 1 0   |  57600  bits/sec  |   1.085   microsecond                        |    2      |    5ns                |   0.461%           
  --  1 1 1   |  115200 bits/sec  |   542.5   nanosecond                         |    1      |    2.5ns              |   0.461%     
  ------------------------------------------------------------------------------
  -- we find Least Common Denominator among Sample Periods , and build a counter to calculate that
  -- after that, every other period is an integer a * LCD(Sample Periods) and we can build a second counter that changes
  -- its value by 1 , every LCD(Sample Periods) time
  -- so, we have the following LCD(S.P.) = 542.5 ns, which we cannot count without a small amount of error , specifically 2.5 ns 
  -- this error, for different Baud Rates , is a * 2.5 ns 
  -- integer a takes values from 1 to 384, which would require 9 bits to 
*/


module baud_controller(reset, clk, baud_enable, baud_select, sample_ENABLE);
	input clk, reset;  // active high reset , 50MHz clk
	input [2:0] baud_select;
	input baud_enable;	
	output reg sample_ENABLE ;
	
	reg [2:0] prev_baud_select ;
 	reg [4:0] LCDcounter; //First counter that will count 540 nanoseconds | changes value every posedge clk
	reg [8:0] Counter_TSample; //Second counter that will count up to 0.208 milliseconds based on baud_select | changes value every 540 nanoseconds | basically counts a
			
	always@(posedge clk or posedge reset)
	begin : COUNTER_540ns	
		if (reset)
		begin
			LCDcounter <= 5'b00000 ;
		end
		else if (LCDcounter == 5'b11011) // 11011 binary = 27 decimal , meaning we count 27 clock cycles of 20ns so we get 540ns counter
		begin
 			LCDcounter <= 5'b00000 ;
		end
		else if (baud_enable == 1'b0)
		begin
			LCDcounter <= 5'b00000 ;
		end
		else
		begin
			LCDcounter <= LCDcounter + 1 ;
		end
	end
	
	always@(LCDcounter or posedge reset)
	begin  
		if (reset)
		begin
			Counter_TSample <= 9'b000000000 ; 
		end
		else if (baud_select != prev_baud_select)
		begin
			Counter_TSample <= 9'b000000000 ;
		end
		else if ( LCDcounter == 5'b11011)
		begin
			Counter_TSample <= Counter_TSample + 1 ;
		end
		prev_baud_select <= baud_select ;
		case(baud_select)
			3'b111 : // Sample Period = 540 nanosecond
				begin 
					if (Counter_TSample == 9'b000000001) //if Counter_TSample = a = 1
					begin
						sample_ENABLE = 1'b1 ;
						Counter_TSample = 9'b000000000 ;
					end
					else sample_ENABLE = 1'b0 ;
				end
			3'b110 : // Sample Period = 1085 microsecond
				begin 
					if (Counter_TSample == 9'b000000010) //if Counter_TSample = a = 2
					begin
						sample_ENABLE = 1'b1 ;
						Counter_TSample = 9'b000000000 ;
					end
					else sample_ENABLE = 1'b0 ;
				end
			3'b101: // Sample Period = 1.6275  microsecond
				begin 
					if (Counter_TSample == 9'b000000011) //if Counter_TSample = a = 3
					begin
						sample_ENABLE = 1'b1 ;
						Counter_TSample = 9'b000000000 ;
					end
					else sample_ENABLE = 1'b0 ;
				end
			3'b100 : // Sample Period = 3.255   microsecond
				begin 
					if (Counter_TSample == 9'b000000110) //if Counter_TSample = a = 6
					begin
						sample_ENABLE = 1'b1 ;
						Counter_TSample = 9'b000000000 ;
					end
					else sample_ENABLE = 1'b0 ;
				end
			3'b011 : // Sample Period = 6.5     microsecond
				begin 
					if (Counter_TSample == 9'b000001100) //if Counter_TSample = a = 12
					begin
						sample_ENABLE = 1'b1 ;
						Counter_TSample = 9'b000000000 ;
					end 
					else sample_ENABLE = 1'b0 ;
				end
			3'b010 : // Sample Period = 13      microsecond
				begin 
					if (Counter_TSample == 9'b000011000) //if Counter_TSample = a = 24
					begin
						sample_ENABLE = 1'b1 ;
						Counter_TSample = 9'b000000000 ;
					end
					else sample_ENABLE = 1'b0 ;
				end
			3'b001 : // Sample Period = 51.875  microsecond 
				begin 
					if (Counter_TSample == 9'b001100000) //if Counter_TSample = a = 96
					begin
						sample_ENABLE = 1'b1 ;
						Counter_TSample = 9'b000000000 ;
					end
					else sample_ENABLE = 1'b0 ;
				end
			3'b000 : // Sample Period = 0.208   millisecond 
				begin 
					if (Counter_TSample == 9'b110000000) //if Counter_TSample = a = 384
					begin
						sample_ENABLE = 1'b1 ;
						Counter_TSample = 9'b000000000 ;
					end
					else sample_ENABLE = 1'b0 ;
				end
			default : Counter_TSample = 9'b000000000 ;
		endcase
	end
endmodule















