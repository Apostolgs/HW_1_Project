`include "LED_Decoder.v"
`timescale 1ns / 1ps

module FourDigitLEDdriver(reset, clk, Rx_Data, FERROR, PERROR, VALID, an3, an2, an1, an0, a, b, c, d, e, f, g);

input clk, reset; 
input reg [7:0] Rx_Data ;	// received msg from UART_Receiver
input reg FERROR, PERROR, VALID ; 	//inputs from Rx
output an3, an2, an1, an0;	// our anodes
output a, b, c, d, e, f, g;	// our signals

//	   a
//   	 ------
//    f |      |  b
//	|  g   |
//	 ------
//      |      |
//    e |      |  c
//	 ------ 
//	   d

reg a,b,c,d,e,f,g,dp;
reg an0,an1,an2,an3;
wire [6:0] LED;

reg [3:0] char;		// based on your received message, use this 4bit signal to drive our decoder
reg [3:0] counter; 	// counter to compute the time that the anodes will be active  - period 320ns
reg [3:0] ANcounter; 	//counter to compute transition from current state to the next in our Anode FSM - 
reg [15:0] Char_to_Display ;

/////////////////////////////////////////////////////////////////////		
//  Set char values to present them at the correct anode at a time //  
/////////////////////////////////////////////////////////////////////	
always@(posedge clk or posedge reset)
begin
	if (reset)
	begin
	  char = 4'hF ;  // add the required code to set char signal value
	end
  else if (ANcounter[3] && ANcounter[2]) // we change char with prep time 320ns before every anode activation
	begin
	  char = Char_to_Display[15:12] ; // we present AN3 with char 
	end
  else if (ANcounter[3] == 1'b1 && ANcounter[2] == 1'b0 ) // add the required code to set char signal value
	begin
      char = Char_to_Display[11:8] ;  // we present AN2 with char 
    end
  else if (ANcounter[3] == 1'b0 && ANcounter[2] == 1'b1 )
    begin
      char = Char_to_Display[7:4];  // we present AN1 with char 
    end
  else if (ANcounter[3] || ANcounter[2] == 1'b0 )
	begin
		char = Char_to_Display[3:0];  //we present AN0 with char 
	end
  else
    begin
      char = 4'b1111;  
    end
end


//////////////////////////
//     Anodes Set	//   
//////////////////////////
always@(posedge clk or posedge reset)
begin
	if (reset)
	begin
		an3 <= 1'b1;
		an2 <= 1'b1;
		an1 <= 1'b1;
		an0 <= 1'b1;
	end
  else if (ANcounter == 4'b1110) // add the required code to drive the anodes
	begin
		an3 <= 1'b0;
	    	an2 <= 1'b1;
		an1 <= 1'b1;
		an0 <= 1'b1;
	
	end
  else if (ANcounter == 4'b1010) // add the required code to drive the anodes
	begin
		an3 <= 1'b1;
		an2 <= 1'b0;
		an1 <= 1'b1;
		an0 <= 1'b1;
	end
  else if (ANcounter == 4'b0110) // add the required code to drive the anodes
	begin
		an3 <= 1'b1;
		an2 <= 1'b1;
		an1 <= 1'b0;
		an0 <= 1'b1;
	
	end
  else if (ANcounter == 4'b0010) // add the required code to drive the anodes
	begin
		an3 <= 1'b1;
		an2 <= 1'b1;
		an1 <= 1'b1;
		an0 <= 1'b0;
	
	end
	else
	begin
		an3 <= 1'b1;  //we use a 4-bit counter ANcounter , and we have anodes return to logic 1 after each anode activation, for prep time while we change char
		an2 <= 1'b1;
		an1 <= 1'b1;
		an0 <= 1'b1;
	end
end


////////////////////////////////
//     Decoder Instantiation  //
////////////////////////////////
LEDdecoder LEDdecoderINSTANCE (.char(char),.LED(LED)); 

always@(LED)
begin
	a = LED[6];
  	b = LED[5];
  	c = LED[4];
  	d = LED[3];
  	e = LED[2];
  	f = LED[1];
  	g = LED[0];
end 

//////////////////////////////////////////////////
//      Counter for the 16 states of Anode FSM  //
//      Counts 16*320 ns			//
//////////////////////////////////////////////////
  always@(counter or posedge reset)
    begin
      if (reset)
      begin
          ANcounter <= 4'b1111;  //reset ANcounter at posedge reset - reset value = 1111
      end
      else if (ANcounter == 4'b0000)  //overflow condition 
        begin
          if (counter == 4'b0000)
            begin
              ANcounter <= 4'b1111;
            end
         end
      else if (counter == 4'b0000 )  //happens once every 320ns
        begin
          ANcounter <= ANcounter - 1'b1;  //therefore this changes once every 320ns
        end
    end

 
 
  
//////////////////////////////////////////////////
//		Counter-320ns         	        //
//////////////////////////////////////////////////
  always@(posedge clk or posedge reset)                                         
    begin
	  if (reset)
	  begin
		counter <= 4'b0000;
	  end	
	  else 
	  begin
		if (counter == 4'b0000)
		begin
			counter <= 4'b1111;
		end
		else
		begin
			counter <= counter - 1'b1;
		end
	end
end

// 16-bit REGISTER
always @ (posedge reset or posedge VALID)
begin
	if (reset)
	begin
		Char_to_Display <= 16'hFFFF ;
	end
	else if (FERROR || PERROR) 
	begin
		Char_to_Display <= 16'hAAAA ;
	end
	else
	begin
		Char_to_Display[7:0] <= Rx_Data ;
	end
	
end
always @ (posedge VALID) Char_to_Display[15:8] <= Char_to_Display[7:0] ;
endmodule
