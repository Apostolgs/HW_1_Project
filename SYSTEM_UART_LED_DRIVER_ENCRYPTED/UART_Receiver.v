`timescale 1ns/1ps
`include "UART_Parity_Checker.v"
`include "UART_Baud_Controller.v"
`include "UART_Encryption.v"

module uart_receiver(reset, clk, baud_select, RX_EN, Rx_DATA, RxD, Rx_FERROR, Rx_PERROR, Rx_VALID) ;
	input clk, reset ;
	input [2:0] baud_select ;
	input RX_EN ;
	input RxD ;
	output reg [7:0] Rx_DATA ;
	output reg Rx_FERROR ; // Framing Error //
	output reg Rx_PERROR ; // Parity Error //
	output reg Rx_VALID ; // Rx_DATA is Valid //
	//--------------//
	reg [7:0] Rx_TEMP_DATA ;
	reg rx_baud_enable ;
	reg [7:0] Rx_DECRYPTED_DATA ;
	//--------------//
	baud_controller baud_controller_rx_instance(reset, clk, rx_baud_enable, baud_select, Rx_sample_ENABLE) ;
	UART_PChecker rx_pchecker_instance( Rx_TEMP_DATA, rx_parity_bit) ;
	uart_encryption uart_encryption_rx_instance(.DATA_IN(Rx_TEMP_DATA) , .key(baud_select), .DATA_OUT(Rx_DECRYPTED_DATA));
	//--------------//
	parameter IDLE = 2'b00 ;
	parameter ACTIVE = 2'b01 ;
	//--------------//
	reg [1:0] current_state ;
	reg [1:0] next_state ;
	reg [3:0] T_CNT ; //will count 16 times * Rx_sample_ENABLE = T
	reg [3:0] ACTIVE_CNT ; //will count 11 * T which is the amount of time it will take for our transmitter to send 
	//--------------//
	reg Rx_TEMP_FERROR ;
	reg Rx_TEMP_PERROR ;
	reg Rx_TEMP_VALID ;
	reg Rx_TEMP_PBIT ;
	//--------------//
	always @ (posedge clk or reset or RX_EN) 
  	begin : T_COUNTER
  		if (reset || !RX_EN) 
        	begin	
			T_CNT <= 4'b0000 ;
		end
    		else if (T_CNT == 4'b1111 && Rx_sample_ENABLE)
      		begin
              		T_CNT <= 4'b0000 ;
            	end
		else if (Rx_sample_ENABLE)
		begin
        		T_CNT <= T_CNT + 1;
    		end
	end
	//----------------//
  	always @ (T_CNT or reset )
    	begin : COUNTER_11x_T
              	if (reset || !RX_EN) 
			begin
      		  		ACTIVE_CNT <= 4'b0000 ;
			end
              	else if (ACTIVE_CNT == 4'b1100 /*&& T_CNT == 4'b1111*/)
			begin
        			ACTIVE_CNT <= 4'b0000 ;
			end
     		else if (T_CNT == 4'b1111 )
			begin
        			ACTIVE_CNT <= ACTIVE_CNT + 1 ;
			end
    	end
	//--------------//
	always @ (posedge clk or reset)
	begin : STATE_MEMORY
		if (reset)
		begin
			current_state <= IDLE ;
		end
		else
		begin
			current_state <= next_state ;
		end
	end
	//--------------//
	always @ (current_state or RX_EN or RxD or ACTIVE_CNT)
	begin : NEXT_STATE_LOGIC
		case(current_state)
		IDLE :
		begin
			if (RX_EN && !RxD)
			begin
				rx_baud_enable = 1'b1 ;
				next_state = ACTIVE ;
				T_CNT = 4'b0000 ;
			end
			else 
			begin
				rx_baud_enable = 1'b0 ;
				next_state = IDLE ;
			end
		end
		ACTIVE : 
		begin
			rx_baud_enable = 1'b0 ;
			if (ACTIVE_CNT == 4'b1011 && T_CNT == 4'b1111)
			begin 
				rx_baud_enable = 1'b0 ;
				next_state = IDLE ;
				ACTIVE_CNT = 4'b0000 ;
			end
			else 
			begin
				rx_baud_enable = 1'b1 ;
				next_state = ACTIVE ;
			end
		end
		default :
		begin
			rx_baud_enable = 1'b0 ;
			next_state = IDLE ;
		end
		endcase
	end

	//--------------//
	always @ (current_state or RX_EN or RxD or Rx_sample_ENABLE)
	begin : OUTPUT_LOGIC
		case(current_state)
		IDLE :
		begin
			if (!RX_EN) //if not enabled output whatever
			begin
				Rx_DATA = 8'hZZ ;
				Rx_FERROR = 1'b0 ; 
	 			Rx_PERROR = 1'b0 ; 
				Rx_VALID = 1'b0 ;
			end
			else if (RX_EN)  //if enabled, we are waiting for start bit, !RxD, so output is whatever we received last
			begin
				Rx_DATA = Rx_DECRYPTED_DATA ;
				Rx_FERROR = Rx_TEMP_FERROR ;
				Rx_PERROR = Rx_TEMP_PERROR ;
				Rx_VALID = Rx_TEMP_VALID ;
			end
		end	
		ACTIVE : 
		begin
			Rx_VALID = Rx_TEMP_VALID ; 	
			case(ACTIVE_CNT)
			4'b0000 : // TxD = Start bit communication starting
			begin 
				Rx_TEMP_DATA = 8'hZZ ;
				Rx_TEMP_FERROR = 1'b0 ; 
	 			Rx_TEMP_PERROR = 1'b0 ; 
				Rx_TEMP_VALID = 1'b0 ;
			end
			4'b0001 : // Tx_DATA [0]
			begin
	 			Rx_TEMP_PERROR = 1'b0 ; 
				Rx_TEMP_VALID = 1'b0 ;			
				case(T_CNT)
				default :
				begin
					Rx_TEMP_DATA[0] <= RxD ;
					if (Rx_TEMP_DATA[0] != RxD)
					begin
						Rx_TEMP_FERROR = 1'b1 ;
					end
				end
				endcase
			end
			4'b0010 :
			begin
	 			Rx_TEMP_PERROR = 1'b0 ; 
				Rx_TEMP_VALID = 1'b0 ;			
				case(T_CNT)
				default :
				begin
					Rx_TEMP_DATA[1] <= RxD ;
					if (Rx_TEMP_DATA[1] != RxD)
					begin
						Rx_TEMP_FERROR = 1'b1 ;
					end
				end
				endcase
			end
			4'b0011 :
			begin
	 			Rx_TEMP_PERROR = 1'b0 ; 
				Rx_TEMP_VALID = 1'b0 ;			
				case(T_CNT)
				default :
				begin
					Rx_TEMP_DATA[2] <= RxD ;
					if (Rx_TEMP_DATA[2] != RxD)
					begin
						Rx_TEMP_FERROR = 1'b1 ;
					end
				end
				endcase
			end
			4'b0100 :
			begin
	 			Rx_TEMP_PERROR = 1'b0 ; 
				Rx_TEMP_VALID = 1'b0 ;			
				case(T_CNT)
				default :
				begin
					Rx_TEMP_DATA[3] <= RxD ;
					if (Rx_TEMP_DATA[3] != RxD)
					begin
						Rx_TEMP_FERROR = 1'b1 ;
					end
				end
				endcase
			end
			4'b0101 :
			begin
	 			Rx_TEMP_PERROR = 1'b0 ; 
				Rx_TEMP_VALID = 1'b0 ;			
				case(T_CNT)
				default :
				begin
					Rx_TEMP_DATA[4] <= RxD ;
					if (Rx_TEMP_DATA[4] != RxD)
					begin
						Rx_TEMP_FERROR = 1'b1 ;
					end
				end
				endcase
			end
			4'b0110 :
			begin
	 			Rx_TEMP_PERROR = 1'b0 ; 
				Rx_TEMP_VALID = 1'b0 ;			
				case(T_CNT)
				default :
				begin
					Rx_TEMP_DATA[5] <= RxD ;
					if (Rx_TEMP_DATA[5] != RxD)
					begin
						Rx_TEMP_FERROR = 1'b1 ;
					end
				end
				endcase
			end
			4'b0111 :
			begin
	 			Rx_TEMP_PERROR = 1'b0 ; 
				Rx_TEMP_VALID = 1'b0 ;			
				case(T_CNT)
				default :
				begin
					Rx_TEMP_DATA[6] <= RxD ;
					if (Rx_TEMP_DATA[6] != RxD)
					begin
						Rx_TEMP_FERROR = 1'b1 ;
					end
				end
				endcase
			end
			4'b1000 :
			begin
	 			Rx_TEMP_PERROR = 1'b0 ; 
				Rx_TEMP_VALID = 1'b0 ;			
				case(T_CNT)
				default :
				begin
					Rx_TEMP_DATA[7] <= RxD ;
					if (Rx_TEMP_DATA[7] != RxD)
					begin
						Rx_TEMP_FERROR = 1'b1 ;
					end
				end
				endcase
			end
			4'b1001 :
			begin
	 			Rx_TEMP_PERROR = 1'b0 ; 
				Rx_TEMP_VALID = 1'b0 ;			
				case(T_CNT)
				4'b1111 :
				begin
					Rx_TEMP_PBIT <= RxD ;
				end
				default :
				begin
					Rx_TEMP_PBIT <= RxD ;
					if (Rx_TEMP_PBIT != RxD)
					begin
						Rx_TEMP_FERROR = 1'b1 ;
					end
				end
				endcase
				
			end
			4'b1010 :
			begin
				if (rx_parity_bit != Rx_TEMP_PBIT)
				begin
					Rx_TEMP_PERROR = 1'b1 ;
				end
				else 
				begin
					Rx_TEMP_PERROR = 1'b0 ;
				end
				if (!Rx_TEMP_FERROR && !Rx_TEMP_PERROR)
				begin
					Rx_TEMP_VALID = 1'b1 ;
				end
				else 		
				begin
					Rx_TEMP_VALID = 1'b0 ;
				end
				Rx_DATA = Rx_DECRYPTED_DATA ;
				Rx_FERROR = Rx_TEMP_FERROR ;
				Rx_PERROR = Rx_TEMP_PERROR ;	
			end
			4'b1011 : 
			begin
				Rx_TEMP_PBIT = 1'bX ;
				Rx_TEMP_DATA = 8'hZZ ;
				Rx_TEMP_FERROR = 1'b0 ;
				Rx_TEMP_PERROR = 1'b0 ;
				Rx_TEMP_VALID = 1'b0 ;
			end
			endcase 
		end
	endcase
	end
endmodule

















