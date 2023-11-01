module backend(
    input i_resetbAll,
    input i_clk,
    input i_sclk,
    input i_sdin,
    input i_clk_vco1,
    input i_clk_vco2,
    output reg o_ready,
    output reg o_vco1_fast,
    output reg o_resetb1,
    output reg [2:0] o_gainA1,
    output reg o_resetb2,
    output reg [1:0] o_gainA2,
    output reg o_resetbvco1,
    output reg o_resetbvco2
);

reg [4:0] counter; //count clock cycles of main clock
reg [4:0] counter1; // to count the time period for which frequency is measured for VCO's
reg [4:0] startup_state;  // represent the stage of sequence 
reg [4:0] shift_register; // to store the data for amplifiers
reg [3:0] data_received;  // to count the no.of data points received
reg [5:0] counter_vco1 = 0; // counts clock cycles of VCO1 in a time period 
reg [5:0] counter_vco2 = 0;  // counts clock cycles of VCO2 in a time period 
reg [5:0] frequency_vco1 = 0; //  frequncy of VCO1
reg [5:0] frequency_vco2 = 0; // frequency of VCO2

always @(posedge i_clk or negedge i_resetbAll)
    begin
     if (!i_resetbAll)
    	begin
        // Reset the entire backend
        counter_vco1 <= 0;
        counter_vco2 <= 0;
        startup_state <= 0;
        shift_register <= 0;
        data_received <= 0;
        o_resetb1 <= 0;
        o_resetb2 <= 0;
        o_gainA1 <= 0;
        o_gainA2 <= 0;
        o_resetbvco1 <= 0;
        o_resetbvco2 <= 0;
        o_ready <= 0;
		counter1 <= 0;
     end 
	 else 
	   begin
        // start of start_up sequence
        case(startup_state)
            0: begin
            // Receive serial data
              if (data_received <= 5) begin
                // Set o_gainA1 and o_gainA2 based on serial data
                 o_gainA1 <= shift_register[4:2];
                 o_gainA2 <= shift_register[1:0];
              end 
			  if(data_received == 5) begin
               startup_state <= 1;
			  end
             end			
            1: begin
                // Wait for five clock cycles
                if (counter < 5) begin
                    counter <= counter + 1;
                end else begin
                    startup_state <= 2;
                end
            end
            2: begin
                // Set o_resetbvco1 & o_resetbvco2
                o_resetbvco1 <= 1;
                o_resetbvco2 <= 1;
                startup_state <= 3;
				counter <= 0;
            end
            3: begin
                // Wait for 20 clock cycles
                if (counter < 20) begin
                    counter <= counter + 1;
                end else begin
                    startup_state <= 4;
                end
            end
            4: begin
                // Set o_resetb1 & o_resetb2
                o_resetb1 <= 1;
                o_resetb2 <= 1;
                startup_state <= 5;
				counter <= 0;
            end
            5: begin
                // Wait for 10 clock cycles 
                if (counter < 10)
				begin
                    counter <= counter + 1;
				end
				else
				   begin
                    startup_state <= 6;
                  end
            end
            6: begin
                // Determine the faster VCO
				counter <= 0;
				if (counter1 <4)
				 begin
				    counter1 <= counter1 +1; // used 4 clock cycles to determine the time period for which we are comparing the frequency 
				 end
				else
                  begin				
					startup_state <= 7;
					frequency_vco1 <= counter_vco1;  
					frequency_vco2 <= counter_vco2;
					counter_vco1 <= 0;
					counter_vco2 <= 0;
				    if(frequency_vco1 < frequency_vco2 )  // condition to compare frequency of VCO1 and VCO2
						begin
							o_vco1_fast <= 1;
						end
				    else 
						begin
							o_vco1_fast <= 0;
						end	
				 end
             end
            7: begin
                // Set o_ready
                o_ready <= 1;
                startup_state <= 8;
            end
            default: begin
                // No more actions required, hold values.
            end
        endcase
    end
	
end

always @(posedge i_sclk )
	   begin
		   shift_register<= (shift_register<<1) + i_sdin; //store the values of sdin by left shifting the shift_register
           data_received <= data_received + 1;
	   end
always @(posedge i_clk_vco1 && startup_state == 6)
  begin
	 counter_vco1 <= counter_vco1 +1; // count the clock cycles of VCO1
  end
always @(posedge i_clk_vco2 && startup_state == 6)
  begin
	 counter_vco2 <= counter_vco2 +1;  // count the clock cycles of VCO1
  end


endmodule
