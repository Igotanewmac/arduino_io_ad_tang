







module arduino_io_ad (
    // sysclk
    input wire sysclk,
    // arduino
    input wire [7:0] arduino_datain,
    output reg [7:0] arduino_dataout,
    input wire arduino_clock,
    input wire arduino_commit,
    input wire arduino_readwrite,
    input wire arduino_reset,
    // mem_src
    input wire [7:0] mem_src_dout,
    output reg mem_src_clk,
    output reg mem_src_oce,
    output reg mem_src_ce,
    output reg mem_src_wre,
    output reg [13:0] mem_src_ad,
    output reg [7:0] mem_src_din,
    // mem_key
    input wire [7:0] mem_key_dout,
    output reg mem_key_clk,
    output reg mem_key_oce,
    output reg mem_key_ce,
    output reg mem_key_wre,
    output reg [13:0] mem_key_ad,
    output reg [7:0] mem_key_din,
    // mem_cmd
    input wire [7:0] mem_cmd_dout,
    output reg mem_cmd_clk,
    output reg mem_cmd_oce,
    output reg mem_cmd_ce,
    output reg mem_cmd_wre,
    output reg [13:0] mem_cmd_ad,
    output reg [7:0] mem_cmd_din,
    // mem_dst
    input wire [7:0] mem_dst_dout,
    output reg mem_dst_clk,
    output reg mem_dst_oce,
    output reg mem_dst_ce,
    output reg mem_dst_wre,
    output reg [13:0] mem_dst_ad,
    output reg [7:0] mem_dst_din
);

reg [23:0] reg_input_buffer;

always @(posedge arduino_clock) begin
    reg_input_buffer[23:8] <= reg_input_buffer[15:0];
    reg_input_buffer[7:0] <= arduino_datain;
end


reg [8:0] statemachine_arduino_commit;

always @(posedge sysclk) begin
    case (statemachine_arduino_commit)
        
        // wait for commit line to go high
        8'h00 : begin
            if (arduino_commit) statemachine_arduino_commit <= 8'h01;
        end

        // check if it is a read or a write
        8'h01 : begin
            if (arduino_readwrite) statemachine_arduino_commit <= 8'h06;
            else statemachine_arduino_commit <= 8'h02;
        end
        
        // read request.
        
        // set up the bank for reading
        8'h02 : begin
            // select the right type of read
            case (reg_input_buffer[15:14])
                2'b00 : begin
                    // src
                    mem_src_ad <= reg_input_buffer[13:0];
                    mem_src_ce <= 1'b1;
                    mem_src_oce <= 1'b1;
                end
                2'b01 : begin
                    // key
                    mem_key_ad <= reg_input_buffer[13:0];
                    mem_key_ce <= 1'b1;
                    mem_key_oce <= 1'b1;
                end
                2'b10 : begin
                    // cmd
                    mem_cmd_ad <= reg_input_buffer[13:0];
                    mem_cmd_ce <= 1'b1;
                    mem_cmd_oce <= 1'b1;
                end
                2'b11 : begin
                    // dst
                    mem_dst_ad <= reg_input_buffer[13:0];
                    mem_dst_ce <= 1'b1;
                    mem_dst_oce <= 1'b1;
                end
            endcase
            statemachine_arduino_commit <= 8'h03;
        end

        // clock high
        8'h03 : begin

            case (reg_input_buffer[15:14])
                2'b00 : mem_src_clk <= 1'b1;
                2'b01 : mem_key_clk <= 1'b1;
                2'b10 : mem_cmd_clk <= 1'b1;
                2'b11 : mem_dst_clk <= 1'b1;
            endcase
            statemachine_arduino_commit <= 8'h04;
        end

        // clock low
        8'h04 : begin
            case (reg_input_buffer[15:14])
                2'b00 : mem_src_clk <= 1'b0;
                2'b01 : mem_key_clk <= 1'b0;
                2'b10 : mem_cmd_clk <= 1'b0;
                2'b11 : mem_dst_clk <= 1'b0;
            endcase
            statemachine_arduino_commit <= 8'h05;
        end

        // do the actual read
        8'h05 : begin
            case (reg_input_buffer[15:14])
                2'b00 : arduino_dataout <= mem_src_dout;
                2'b01 : arduino_dataout <= mem_key_dout;
                2'b10 : arduino_dataout <= mem_cmd_dout;
                2'b11 : arduino_dataout <= mem_dst_dout;
            endcase
            statemachine_arduino_commit <= 8'h09;
        end

        

        // write request
        8'h06 : begin
            case (reg_input_buffer[23:22])
                2'b00 : begin
                    mem_src_ad <= reg_input_buffer[21:8];
                    mem_src_din <= reg_input_buffer[7:0];
                    mem_src_ce <= 1'b1;
                    mem_src_wre <= 1'b1;
                end
                2'b01 : begin
                    mem_key_ad <= reg_input_buffer[21:8];
                    mem_key_din <= reg_input_buffer[7:0];
                    mem_key_ce <= 1'b1;
                    mem_key_wre <= 1'b1;
                end
                2'b10 : begin
                    mem_cmd_ad <= reg_input_buffer[21:8];
                    mem_cmd_din <= reg_input_buffer[7:0];
                    mem_cmd_ce <= 1'b1;
                    mem_cmd_wre <= 1'b1;
                end
                2'b11 : begin
                    mem_dst_ad <= reg_input_buffer[21:8];
                    mem_dst_din <= reg_input_buffer[7:0];
                    mem_dst_ce <= 1'b1;
                    mem_dst_wre <= 1'b1;
                end
            endcase
            statemachine_arduino_commit <= 8'h07;
        end

        // clock high
        8'h07 : begin
            case (reg_input_buffer[23:22])
                2'b00 : mem_src_clk <= 1'b1;
                2'b01 : mem_key_clk <= 1'b1;
                2'b10 : mem_cmd_clk <= 1'b1;
                2'b11 : mem_dst_clk <= 1'b1;
            endcase
            statemachine_arduino_commit <= 8'h08;
        end

        // clock low
        8'h08 : begin
            case (reg_input_buffer[23:22])
                2'b00 : mem_src_clk <= 1'b0;
                2'b01 : mem_key_clk <= 1'b0;
                2'b10 : mem_cmd_clk <= 1'b0;
                2'b11 : mem_dst_clk <= 1'b0;
            endcase
            statemachine_arduino_commit <= 8'h09;
        end

        // clean up
        8'h09 : begin
            mem_src_ce <= 1'b0;
            mem_src_oce <= 1'b0;
            mem_src_wre <= 1'b0;
            mem_key_ce <= 1'b0;
            mem_key_oce <= 1'b0;
            mem_key_wre <= 1'b0;
            mem_cmd_ce <= 1'b0;
            mem_cmd_oce <= 1'b0;
            mem_cmd_wre <= 1'b0;
            mem_dst_ce <= 1'b0;
            mem_dst_oce <= 1'b0;
            mem_dst_wre <= 1'b0;
            statemachine_arduino_commit <= 8'h0A;
        end

        // all done wait for arduino clock to go down
        8'h0A : begin
            if (!arduino_clock) statemachine_arduino_commit <= 8'h00;
        end

    endcase
    
end
   
endmodule








// encryption engine

module encryption_engine (
    // sysclk connection
    input wire sysclk,
    // arduino connections
    input wire arduino_execute,
    output reg arduino_isfinished,
    input wire arduino_reset,
    // mem_src
    input wire [7:0] mem_src_dout,
    output reg mem_src_clk,
    output reg mem_src_oce,
    output reg mem_src_ce,
    output reg mem_src_wre,
    output reg [13:0] mem_src_ad,
    output reg [7:0] mem_src_din,
    // mem_key
    input wire [7:0] mem_key_dout,
    output reg mem_key_clk,
    output reg mem_key_oce,
    output reg mem_key_ce,
    output reg mem_key_wre,
    output reg [13:0] mem_key_ad,
    output reg [7:0] mem_key_din,
    // mem_cmd
    input wire [7:0] mem_cmd_dout,
    output reg mem_cmd_clk,
    output reg mem_cmd_oce,
    output reg mem_cmd_ce,
    output reg mem_cmd_wre,
    output reg [13:0] mem_cmd_ad,
    output reg [7:0] mem_cmd_din,
    // mem_dst
    input wire [7:0] mem_dst_dout,
    output reg mem_dst_clk,
    output reg mem_dst_oce,
    output reg mem_dst_ce,
    output reg mem_dst_wre,
    output reg [13:0] mem_dst_ad,
    output reg [7:0] mem_dst_din,
    // mem_ram
    input wire [7:0] mem_ram_dout,
    output reg mem_ram_clk,
    output reg mem_ram_oce,
    output reg mem_ram_ce,
    output reg mem_ram_wre,
    output reg [13:0] mem_ram_ad,
    output reg [7:0] mem_ram_din
);
    

    // registers

    // program flow
    reg [13:0] reg_program_counter;
    reg [7:0] reg_command_buffer;

    // defines src and dst banks for bank operations
    reg [7:0] reg_bank_select;

    // state machines
    reg [7:0] statemachine_program;
    reg [7:0] statemachine_command;


    // command parsing registers
    reg [13:0] reg_int_address_01;

    reg [7:0] reg_int_data_01;




    // lfsr registers
    reg [15:0] lfsr_single;
    reg [15:0] lfsr_multi [2:0];

    


    // always and forever
    always @(posedge sysclk) begin
        // are we in a reset condition?
        if (arduino_reset) begin
            // reset condition!
            arduino_isfinished <= 1'b0;
            reg_program_counter <= 14'd0;
            reg_command_buffer <= 8'd0;
            reg_bank_select <= 8'd0;
            statemachine_program <= 8'h00;
            statemachine_command <= 8'h00;
            reg_int_address_01 <= 14'd0;
            reg_int_data_01 <= 8'd0;
        end
        else begin
            // enter command processor
            case (statemachine_program)
                // check to see if execution has been triggered
                8'h00 : begin
                    arduino_isfinished <= 1'b0;
                    reg_program_counter <= 14'd0;
                    if (arduino_execute) statemachine_program <= 8'h01;
                end

                // set programcounter to cmd memory
                8'h01 : begin
                    mem_cmd_ad <= reg_program_counter;
                    mem_cmd_ce <= 1'b1;
                    mem_cmd_oce <= 1'b1;
                    statemachine_program <= 8'h02;
                end
                
                // clock high
                8'h02 : begin
                    mem_cmd_clk <= 1'b1;
                    statemachine_program <= 8'h03;
                end
                
                // clock low
                8'h03 : begin
                    mem_cmd_clk <= 1'b0;
                    statemachine_program <= 8'h04;
                end

                // copy data to command buffer
                8'h04 : begin
                    reg_command_buffer <= mem_cmd_dout;
                    statemachine_program <= 8'h05;
                end

                // finish up memory transaction
                8'h05 : begin
                    mem_cmd_ce <= 1'b0;
                    mem_cmd_oce <= 1'b0;
                    statemachine_program <= 8'h06;
                end
                
                
                // reset command state machine
                8'h06 : begin
                    statemachine_command <= 8'd0;
                    statemachine_program <= 8'h07;
                end
                

                // execute command block
                8'h07 : begin
                    // decide which command we have
                    case (reg_command_buffer)
                        
                        
                        // 0x00 no-op
                        8'h00 : begin
                            arduino_isfinished <= 1'b0;
                            statemachine_program <= 8'hFE;
                        end

                        // 0x01 signal finished.
                        8'h01 : begin
                            statemachine_program <= 8'hFF;
                        end




                        // memory bank register commands

                        // 0x19 copy bank select register top dst 0x0000
                        8'h19 :begin
                            case (statemachine_command)

                                // set up memory access
                                8'h00 : begin
                                    mem_dst_ad <= 14'd0;
                                    mem_dst_din <= reg_bank_select;
                                    mem_dst_ce <= 1'b1;
                                    mem_dst_wre <= 1'b1;
                                    statemachine_command <= 8'h01;
                                end
                                // clock high
                                8'h01 : begin
                                    mem_dst_clk <= 1'b1;
                                    statemachine_command <= 8'h02;
                                end
                                // clock low
                                8'h02 : begin
                                    mem_dst_clk <= 1'b0;
                                    statemachine_command <= 8'h03;
                                end
                                // clean up
                                8'h03 : begin
                                    mem_dst_ce <= 1'b0;
                                    mem_dst_wre <= 1'b0;
                                    statemachine_program <= 8'hFE;
                                end
                                

                            endcase
                        end

                        // 0x20 set bank select register to immediate value
                        8'h20 : begin
                            case (statemachine_command)

                                // increment prgram counter by one
                                8'h00 : begin
                                    reg_program_counter <= reg_program_counter + 1;
                                    statemachine_command <= 8'h01;
                                end
                                
                                // set cmd memory state
                                8'h01 : begin
                                    mem_cmd_ad <= reg_program_counter;
                                    mem_cmd_ce <= 1'b1;
                                    mem_cmd_oce <= 1'b1;
                                    statemachine_command <= 8'h02;
                                end
                                
                                // clock up
                                8'h02 : begin
                                    mem_cmd_clk <= 1'b1;
                                    statemachine_command <= 8'h03;
                                end
                                
                                // clock down
                                8'h03 : begin
                                    mem_cmd_clk <= 1'b0;
                                    statemachine_command <= 8'h04;
                                end

                                // copy to register
                                8'h04 : begin
                                    reg_bank_select <= mem_cmd_dout;
                                    statemachine_command <= 8'h05;
                                end
                                
                                // finish up memory transaction
                                8'h05 : begin
                                    mem_cmd_ce <= 1'b0;
                                    mem_cmd_oce <= 1'b0;
                                    statemachine_program <= 8'hFE;
                                end
                                
                            endcase
                        end
                        
                        
                        
                        
                        // 0x21 load address into bank

                        // memory bank commands
                        // 0x22 fill bankA with immedeate value
                        8'h22 : begin
                            case (statemachine_command)
                                // initialise
                                8'h00 : begin
                                    reg_int_address_01 <= 14'd0;
                                    statemachine_command <= 8'h01;
                                end
                                // increment program counter
                                8'h01 : begin
                                    reg_program_counter <= reg_program_counter + 1;
                                    statemachine_command <= 8'h02;
                                end
                                // set up cmd memory
                                8'h02 : begin
                                    mem_cmd_ad <= reg_program_counter;
                                    mem_cmd_ce <= 1'b1;
                                    mem_cmd_oce <= 1'b1;
                                    statemachine_command <= 8'h03;
                                end
                                // clock up
                                8'h03 : begin
                                    mem_cmd_clk <= 1'b1;
                                    statemachine_command <= 8'h04;
                                end
                                // clock down
                                8'h04 : begin
                                    mem_cmd_clk <= 1'b0;
                                    statemachine_command <= 8'h05;
                                end
                                // copy dout to register
                                8'h05 : begin
                                    reg_int_data_01 <= mem_cmd_dout;
                                    statemachine_command <= 8'h06;
                                end
                                // finish up memory transaction
                                8'h06 : begin
                                    mem_cmd_ce <= 1'b0;
                                    mem_cmd_oce <= 1'b0;
                                    statemachine_command <= 8'h07;
                                end
                                // set address on destination
                                8'h07 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : begin
                                            mem_src_ad <= reg_int_address_01;
                                            mem_src_din <= reg_int_data_01;
                                            mem_src_ce <= 1'b1;
                                            mem_src_wre <= 1'b1;
                                            statemachine_command <= 8'h08;
                                        end
                                        2'b01 : begin
                                            mem_key_ad <= reg_int_address_01;
                                            mem_key_din <= reg_int_data_01;
                                            mem_key_ce <= 1'b1;
                                            mem_key_wre <= 1'b1;
                                            statemachine_command <= 8'h08;
                                        end
                                        2'b10 : begin
                                            mem_cmd_ad <= reg_int_address_01;
                                            mem_cmd_din <= reg_int_data_01;
                                            mem_cmd_ce <= 1'b1;
                                            mem_cmd_wre <= 1'b1;
                                            statemachine_command <= 8'h08;
                                        end
                                        2'b11 : begin
                                            mem_dst_ad <= reg_int_address_01;
                                            mem_dst_din <= reg_int_data_01;
                                            mem_dst_ce <= 1'b1;
                                            mem_dst_wre <= 1'b1;
                                            statemachine_command <= 8'h08;
                                        end
                                    endcase
                                    //statemachine_command <= 8'h08;
                                end
                                // clock up
                                8'h08 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : mem_src_clk <= 1'b1;
                                        2'b01 : mem_key_clk <= 1'b1;
                                        2'b10 : mem_cmd_clk <= 1'b1;
                                        2'b11 : mem_dst_clk <= 1'b1;
                                    endcase
                                    statemachine_command <= 8'h09;
                                end
                                // clock down
                                8'h09 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : mem_src_clk <= 1'b0;
                                        2'b01 : mem_key_clk <= 1'b0;
                                        2'b10 : mem_cmd_clk <= 1'b0;
                                        2'b11 : mem_dst_clk <= 1'b0;
                                    endcase
                                    statemachine_command <= 8'h0A;
                                end
                                // finish up memory transaction
                                8'h0A : begin
                                    mem_src_ce <= 1'b0;
                                    mem_src_wre <= 1'b0;
                                    mem_key_ce <= 1'b0;
                                    mem_key_wre <= 1'b0;
                                    mem_cmd_ce <= 1'b0;
                                    mem_cmd_wre <= 1'b0;
                                    mem_dst_ce <= 1'b0;
                                    mem_dst_wre <= 1'b0;
                                    statemachine_command <= 8'h0B;
                                end
                                // increment address counter
                                8'h0B : begin
                                    reg_int_address_01 <= reg_int_address_01 + 1;
                                    statemachine_command <= 8'h0C;
                                end
                                // loop or exit
                                8'h0C : begin
                                    if (reg_int_address_01 == 14'd0) statemachine_program <= 8'hFE;
                                    else statemachine_command <= 8'h07;
                                end
                                
                            endcase
                        end



                        // 0x23 fill bankA byte 0x0000 to bankB
                        



                        // 0x24 copy bankA to bankB
                        
                        8'h24 : begin
                            case (statemachine_command)

                                // initialise
                                8'h00 : begin
                                    reg_int_address_01 <= 14'd0;
                                    statemachine_command = 8'h01;
                                end
                                
                                // set address to bank A and B
                                8'h01 : begin
                                    
                                    mem_src_ad <= reg_int_address_01;
                                    mem_key_ad <= reg_int_address_01;
                                    mem_cmd_ad <= reg_int_address_01;
                                    mem_dst_ad <= reg_int_address_01;
                                    

                                    // bank A
                                    case (reg_bank_select[7:6])
                                        2'b00 : begin
                                            mem_src_ce <= 1'b1;
                                            mem_src_oce <= 1'b1;
                                        end
                                        2'b01 : begin
                                            mem_key_ce <= 1'b1;
                                            mem_key_oce <= 1'b1;
                                        end
                                        2'b10 : begin
                                            mem_cmd_ce <= 1'b1;
                                            mem_cmd_oce <= 1'b1;
                                        end
                                        2'b11 : begin
                                            mem_dst_ce <= 1'b1;
                                            mem_dst_oce <= 1'b1;
                                        end
                                    endcase

                                    // bank b
                                    case (reg_bank_select[5:4])
                                        2'b00 : begin
                                            mem_src_ce <= 1'b1;
                                            mem_src_wre <= 1'b1;
                                        end
                                        2'b01 : begin
                                            mem_key_ce <= 1'b1;
                                            mem_key_wre <= 1'b1;
                                        end
                                        2'b10 : begin
                                            mem_cmd_ce <= 1'b1;
                                            mem_cmd_wre <= 1'b1;
                                        end
                                        2'b11 : begin
                                            mem_dst_ce <= 1'b1;
                                            mem_dst_wre <= 1'b1;
                                        end
                                    endcase
                                    statemachine_command <= 8'h02;
                                end
                                
                                // clock A up
                                8'h02 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : mem_src_clk <= 1'b1;
                                        2'b01 : mem_key_clk <= 1'b1;
                                        2'b10 : mem_cmd_clk <= 1'b1;
                                        2'b11 : mem_dst_clk <= 1'b1;
                                    endcase
                                    statemachine_command <= 8'h03;
                                end
                                
                                // clock A down
                                8'h03 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : mem_src_clk <= 1'b0;
                                        2'b01 : mem_key_clk <= 1'b0;
                                        2'b10 : mem_cmd_clk <= 1'b0;
                                        2'b11 : mem_dst_clk <= 1'b0;
                                    endcase
                                    statemachine_command <= 8'h04;
                                end
                                
                                // copy data from A
                                8'h04 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : reg_int_data_01 <= mem_src_dout;
                                        2'b01 : reg_int_data_01 <= mem_key_dout;
                                        2'b10 : reg_int_data_01 <= mem_cmd_dout;
                                        2'b11 : reg_int_data_01 <= mem_dst_dout;
                                    endcase
                                    statemachine_command <= 8'h05;
                                end

                                // copy data to B
                                8'h05 : begin
                                    case (reg_bank_select[5:4])
                                        2'b00 : mem_src_din <= reg_int_data_01;
                                        2'b01 : mem_key_din <= reg_int_data_01;
                                        2'b10 : mem_cmd_din <= reg_int_data_01;
                                        2'b11 : mem_dst_din <= reg_int_data_01;
                                    endcase
                                    statemachine_command <= 8'h06;
                                end


                                
                                // clock B up
                                8'h06 : begin
                                    case (reg_bank_select[5:4])
                                        2'b00 : mem_src_clk <= 1'b1;
                                        2'b01 : mem_key_clk <= 1'b1;
                                        2'b10 : mem_cmd_clk <= 1'b1;
                                        2'b11 : mem_dst_clk <= 1'b1;
                                    endcase
                                    statemachine_command <= 8'h07;
                                end
                                
                                // clock B down
                                8'h07 : begin
                                    case (reg_bank_select[5:4])
                                        2'b00 : mem_src_clk <= 1'b0;
                                        2'b01 : mem_key_clk <= 1'b0;
                                        2'b10 : mem_cmd_clk <= 1'b0;
                                        2'b11 : mem_dst_clk <= 1'b0;
                                    endcase
                                    statemachine_command <= 8'h08;
                                end
                                

                                // increment address
                                8'h08 : begin
                                    reg_int_address_01 <= reg_int_address_01 + 1;
                                    statemachine_command <= 8'h09;
                                end
                                
                                // check for loop
                                8'h09 : begin
                                    if ( reg_int_address_01 == 0 ) statemachine_command <= 8'h0A;
                                    else statemachine_command <= 8'h01;
                                end
                                
                                // finish up
                                8'h0A : begin
                                    mem_src_ce <= 1'b0;
                                    mem_src_oce <= 1'b0;
                                    mem_src_wre <= 1'b0;
                                    mem_key_ce <= 1'b0;
                                    mem_key_oce <= 1'b0;
                                    mem_key_wre <= 1'b0;
                                    mem_cmd_ce <= 1'b0;
                                    mem_cmd_oce <= 1'b0;
                                    mem_cmd_wre <= 1'b0;
                                    mem_dst_ce <= 1'b0;
                                    mem_dst_oce <= 1'b0;
                                    mem_dst_wre <= 1'b0;
                                    statemachine_program <= 8'hFE;
                                end

                            endcase
                        end
                        
                        // ram commands
                        // 0x25 copy bankA to ram
                        8'h25 : begin
                            case (statemachine_command) 
                                // initialise
                                8'h00 : begin
                                    reg_int_address_01 <= 14'd0;
                                    statemachine_command <= 8'h01;
                                end
                                // set address to bank A
                                8'h01 : begin
                                    mem_src_ad <= reg_int_address_01;
                                    mem_key_ad <= reg_int_address_01;
                                    mem_cmd_ad <= reg_int_address_01;
                                    mem_dst_ad <= reg_int_address_01;
                                    case (reg_bank_select[7:6])
                                        2'b00 : begin
                                            mem_src_ce <= 1'b1;
                                            mem_src_oce <= 1'b1;
                                        end
                                        2'b01 : begin
                                            mem_key_ce <= 1'b1;
                                            mem_key_oce <= 1'b1;
                                        end
                                        2'b10 : begin
                                            mem_cmd_ce <= 1'b1;
                                            mem_cmd_oce <= 1'b1;
                                        end
                                        2'b11 : begin
                                            mem_dst_ce <= 1'b1;
                                            mem_dst_oce <= 1'b1;
                                        end
                                    endcase
                                    statemachine_command <= 8'h02;
                                end
                                // clock high
                                8'h02 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : mem_src_clk <= 1'b1;
                                        2'b01 : mem_key_clk <= 1'b1;
                                        2'b10 : mem_cmd_clk <= 1'b1;
                                        2'b11 : mem_dst_clk <= 1'b1;
                                    endcase
                                    statemachine_command <= 8'h03;
                                end
                                // clock low
                                8'h03 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : mem_src_clk <= 1'b0;
                                        2'b01 : mem_key_clk <= 1'b0;
                                        2'b10 : mem_cmd_clk <= 1'b0;
                                        2'b11 : mem_dst_clk <= 1'b0;
                                    endcase
                                    statemachine_command <= 8'h04;
                                end
                                // set data to bank ram
                                8'h04 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : mem_ram_din <= mem_src_dout;
                                        2'b01 : mem_ram_din <= mem_key_dout;
                                        2'b10 : mem_ram_din <= mem_cmd_dout;
                                        2'b11 : mem_ram_din <= mem_dst_dout;
                                    endcase
                                    mem_ram_ad <= reg_int_address_01;
                                    mem_ram_ce <= 1'b1;
                                    mem_ram_wre <= 1'b1;
                                    statemachine_command <= 8'h05;
                                end
                                // clock high
                                8'h05 : begin
                                    mem_ram_clk <= 1'b1;
                                    statemachine_command <= 8'h06;
                                end
                                // clock low
                                8'h06 : begin
                                    mem_ram_clk <= 1'b0;
                                    statemachine_command <= 8'h07;
                                end
                                // increment address counter
                                8'h07 : begin
                                    reg_int_address_01 <= reg_int_address_01 + 1;
                                    statemachine_command <= 8'h08;
                                end
                                // check for loop
                                8'h08 : begin
                                    if ( reg_int_address_01 == 0 ) statemachine_command <= 8'h0A;
                                    else statemachine_command <= 8'h01;
                                end
                                // finish up
                                8'h0A : begin
                                    mem_src_ce <= 1'b0;
                                    mem_src_oce <= 1'b0;
                                    mem_src_wre <= 1'b0;
                                    mem_key_ce <= 1'b0;
                                    mem_key_oce <= 1'b0;
                                    mem_key_wre <= 1'b0;
                                    mem_cmd_ce <= 1'b0;
                                    mem_cmd_oce <= 1'b0;
                                    mem_cmd_wre <= 1'b0;
                                    mem_dst_ce <= 1'b0;
                                    mem_dst_oce <= 1'b0;
                                    mem_dst_wre <= 1'b0;
                                    mem_ram_ce <= 1'b0;
                                    mem_ram_oce <= 1'b0;
                                    mem_ram_wre <= 1'b0;
                                    
                                    statemachine_program <= 8'hFE;
                                end
                            endcase
                            
                        end



                        // 0x26 copy ram to bankA
                        8'h26 : begin
                            case (statemachine_command)

                                // initialise
                                8'h00 : begin
                                    reg_int_address_01 <= 14'd0;
                                    mem_ram_ce <= 1'b1;
                                    mem_ram_oce <= 1'b1;
                                    case (reg_bank_select[7:6])
                                        2'b00 : mem_src_ce <= 1'b1;
                                        2'b01 : mem_key_ce <= 1'b1;
                                        2'b10 : mem_cmd_ce <= 1'b1;
                                        2'b11 : mem_dst_ce <= 1'b1;
                                    endcase
                                    mem_src_wre <= 1'b1;
                                    mem_key_wre <= 1'b1;
                                    mem_cmd_wre <= 1'b1;
                                    mem_dst_wre <= 1'b1;
                                    statemachine_command <= 8'h01;
                                end
                                // set address to ram
                                8'h01 : begin
                                    mem_ram_ad <= reg_int_address_01;
                                    statemachine_command <= 8'h02;
                                end
                                // clock high
                                8'h02 : begin
                                    mem_ram_clk <= 1'b1;
                                    statemachine_command <= 8'h03;
                                end
                                // clock low
                                8'h03 : begin
                                    mem_ram_clk <= 1'b0;
                                    statemachine_command <= 8'h04;
                                end
                                // set address and data to bank A
                                8'h04 : begin
                                    mem_src_ad <= reg_int_address_01;
                                    mem_key_ad <= reg_int_address_01;
                                    mem_cmd_ad <= reg_int_address_01;
                                    mem_dst_ad <= reg_int_address_01;
                                    mem_src_din <= mem_ram_dout;
                                    mem_key_din <= mem_ram_dout;
                                    mem_cmd_din <= mem_ram_dout;
                                    mem_dst_din <= mem_ram_dout;
                                    statemachine_command <= 8'h05;
                                end
                                // clock high
                                8'h05 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : mem_src_clk <= 1'b1;
                                        2'b01 : mem_key_clk <= 1'b1;
                                        2'b10 : mem_cmd_clk <= 1'b1;
                                        2'b11 : mem_dst_clk <= 1'b1;
                                    endcase
                                    statemachine_command <= 8'h06;
                                end
                                // clock low
                                8'h06 : begin
                                    mem_src_clk <= 1'b0;
                                    mem_key_clk <= 1'b0;
                                    mem_cmd_clk <= 1'b0;
                                    mem_dst_clk <= 1'b0;
                                    statemachine_command <= 8'h07;
                                end
                                // increment address counter
                                8'h07 : begin
                                    reg_int_address_01 = reg_int_address_01 + 1;
                                    statemachine_command <= 8'h08;
                                end
                                // check for loop
                                8'h08 : begin
                                    if ( reg_int_address_01 == 0 ) statemachine_command <= 8'h09;
                                    else statemachine_command <= 8'h01;
                                end
                                // finish up
                                8'h09 : begin
                                    mem_src_ce <= 1'b0;
                                    mem_src_oce <= 1'b0;
                                    mem_src_wre <= 1'b0;
                                    mem_key_ce <= 1'b0;
                                    mem_key_oce <= 1'b0;
                                    mem_key_wre <= 1'b0;
                                    mem_cmd_ce <= 1'b0;
                                    mem_cmd_oce <= 1'b0;
                                    mem_cmd_wre <= 1'b0;
                                    mem_dst_ce <= 1'b0;
                                    mem_dst_oce <= 1'b0;
                                    mem_dst_wre <= 1'b0;
                                    mem_ram_ce <= 1'b0;
                                    mem_ram_oce <= 1'b0;
                                    mem_ram_wre <= 1'b0;
                                    statemachine_program <= 8'hFE;
                                end
                                


                            endcase
                        end





                        // fun commands

                        // 0x30 bankC = bankA ^ bankB
                        8'h30 : begin
                            case (statemachine_command)
                                
                                // initialise
                                8'h00 : begin
                                    reg_int_address_01 <= 14'd0;
                                    // bank A
                                    case (reg_bank_select[7:6])
                                        2'b00 : begin
                                            mem_src_ce <= 1'b1;
                                            mem_src_oce <= 1'b1;
                                        end
                                        2'b01 : begin
                                            mem_key_ce <= 1'b1;
                                            mem_key_oce <= 1'b1;
                                        end
                                        2'b10 : begin
                                            mem_cmd_ce <= 1'b1;
                                            mem_cmd_oce <= 1'b1;
                                        end
                                        2'b11 : begin
                                            mem_dst_ce <= 1'b1;
                                            mem_dst_oce <= 1'b1;
                                        end
                                    endcase
                                    // bank B
                                    case (reg_bank_select[5:4])
                                        2'b00 : begin
                                            mem_src_ce <= 1'b1;
                                            mem_src_oce <= 1'b1;
                                        end
                                        2'b01 : begin
                                            mem_key_ce <= 1'b1;
                                            mem_key_oce <= 1'b1;
                                        end
                                        2'b10 : begin
                                            mem_cmd_ce <= 1'b1;
                                            mem_cmd_oce <= 1'b1;
                                        end
                                        2'b11 : begin
                                            mem_dst_ce <= 1'b1;
                                            mem_dst_oce <= 1'b1;
                                        end
                                    endcase
                                    // bank C
                                    case (reg_bank_select[3:2])
                                        2'b00 : begin
                                            mem_src_ce <= 1'b1;
                                            mem_src_wre <= 1'b1;
                                        end
                                        2'b01 : begin
                                            mem_key_ce <= 1'b1;
                                            mem_key_wre <= 1'b1;
                                        end
                                        2'b10 : begin
                                            mem_cmd_ce <= 1'b1;
                                            mem_cmd_wre <= 1'b1;
                                        end
                                        2'b11 : begin
                                            mem_dst_ce <= 1'b1;
                                            mem_dst_wre <= 1'b1;
                                        end
                                    endcase
                                    statemachine_command <= 8'h01;
                                end
                                // set address to all banks
                                8'h01 : begin
                                    mem_src_ad <= reg_int_address_01;
                                    mem_key_ad <= reg_int_address_01;
                                    mem_cmd_ad <= reg_int_address_01;
                                    mem_dst_ad <= reg_int_address_01;
                                    statemachine_command <= 8'h02;
                                end
                                // clock up bank A and B
                                8'h02 : begin
                                    case (reg_bank_select[7:6])
                                        2'b00 : mem_src_clk <= 1'b1;
                                        2'b01 : mem_key_clk <= 1'b1;
                                        2'b10 : mem_cmd_clk <= 1'b1;
                                        2'b11 : mem_dst_clk <= 1'b1;
                                    endcase
                                    case (reg_bank_select[5:4])
                                        2'b00 : mem_src_clk <= 1'b1;
                                        2'b01 : mem_key_clk <= 1'b1;
                                        2'b10 : mem_cmd_clk <= 1'b1;
                                        2'b11 : mem_dst_clk <= 1'b1;
                                    endcase
                                    statemachine_command <= 8'h03;
                                end
                                // clock down
                                8'h03 : begin
                                    mem_src_clk <= 1'b0;
                                    mem_key_clk <= 1'b0;
                                    mem_cmd_clk <= 1'b0;
                                    mem_dst_clk <= 1'b0;
                                    statemachine_command <= 8'h04;
                                end
                                // perform encryption
                                8'h04 : begin
                                    case (reg_bank_select[7:2])
                                        6'b000000 : mem_src_din <= mem_src_dout ^ mem_src_dout;
                                        6'b000001 : mem_key_din <= mem_src_dout ^ mem_src_dout;
                                        6'b000010 : mem_cmd_din <= mem_src_dout ^ mem_src_dout;
                                        6'b000011 : mem_dst_din <= mem_src_dout ^ mem_src_dout;
                                        6'b000100 : mem_src_din <= mem_src_dout ^ mem_key_dout;
                                        6'b000101 : mem_key_din <= mem_src_dout ^ mem_key_dout;
                                        6'b000110 : mem_cmd_din <= mem_src_dout ^ mem_key_dout;
                                        6'b000111 : mem_dst_din <= mem_src_dout ^ mem_key_dout;
                                        6'b001000 : mem_src_din <= mem_src_dout ^ mem_cmd_dout;
                                        6'b001001 : mem_key_din <= mem_src_dout ^ mem_cmd_dout;
                                        6'b001010 : mem_cmd_din <= mem_src_dout ^ mem_cmd_dout;
                                        6'b001011 : mem_dst_din <= mem_src_dout ^ mem_cmd_dout;
                                        6'b001100 : mem_src_din <= mem_src_dout ^ mem_dst_dout;
                                        6'b001101 : mem_key_din <= mem_src_dout ^ mem_dst_dout;
                                        6'b001110 : mem_cmd_din <= mem_src_dout ^ mem_dst_dout;
                                        6'b001111 : mem_dst_din <= mem_src_dout ^ mem_dst_dout;
                                        6'b010000 : mem_src_din <= mem_key_dout ^ mem_src_dout;
                                        6'b010001 : mem_key_din <= mem_key_dout ^ mem_src_dout;
                                        6'b010010 : mem_cmd_din <= mem_key_dout ^ mem_src_dout;
                                        6'b010011 : mem_dst_din <= mem_key_dout ^ mem_src_dout;
                                        6'b010100 : mem_src_din <= mem_key_dout ^ mem_key_dout;
                                        6'b010101 : mem_key_din <= mem_key_dout ^ mem_key_dout;
                                        6'b010110 : mem_cmd_din <= mem_key_dout ^ mem_key_dout;
                                        6'b010111 : mem_dst_din <= mem_key_dout ^ mem_key_dout;
                                        6'b011000 : mem_src_din <= mem_key_dout ^ mem_cmd_dout;
                                        6'b011001 : mem_key_din <= mem_key_dout ^ mem_cmd_dout;
                                        6'b011010 : mem_cmd_din <= mem_key_dout ^ mem_cmd_dout;
                                        6'b011011 : mem_dst_din <= mem_key_dout ^ mem_cmd_dout;
                                        6'b011100 : mem_src_din <= mem_key_dout ^ mem_dst_dout;
                                        6'b011101 : mem_key_din <= mem_key_dout ^ mem_dst_dout;
                                        6'b011110 : mem_cmd_din <= mem_key_dout ^ mem_dst_dout;
                                        6'b011111 : mem_dst_din <= mem_key_dout ^ mem_dst_dout;
                                        6'b100000 : mem_src_din <= mem_cmd_dout ^ mem_src_dout;
                                        6'b100001 : mem_key_din <= mem_cmd_dout ^ mem_src_dout;
                                        6'b100010 : mem_cmd_din <= mem_cmd_dout ^ mem_src_dout;
                                        6'b100011 : mem_dst_din <= mem_cmd_dout ^ mem_src_dout;
                                        6'b100100 : mem_src_din <= mem_cmd_dout ^ mem_key_dout;
                                        6'b100101 : mem_key_din <= mem_cmd_dout ^ mem_key_dout;
                                        6'b100110 : mem_cmd_din <= mem_cmd_dout ^ mem_key_dout;
                                        6'b100111 : mem_dst_din <= mem_cmd_dout ^ mem_key_dout;
                                        6'b101000 : mem_src_din <= mem_cmd_dout ^ mem_cmd_dout;
                                        6'b101001 : mem_key_din <= mem_cmd_dout ^ mem_cmd_dout;
                                        6'b101010 : mem_cmd_din <= mem_cmd_dout ^ mem_cmd_dout;
                                        6'b101011 : mem_dst_din <= mem_cmd_dout ^ mem_cmd_dout;
                                        6'b101100 : mem_src_din <= mem_cmd_dout ^ mem_dst_dout;
                                        6'b101101 : mem_key_din <= mem_cmd_dout ^ mem_dst_dout;
                                        6'b101110 : mem_cmd_din <= mem_cmd_dout ^ mem_dst_dout;
                                        6'b101111 : mem_dst_din <= mem_cmd_dout ^ mem_dst_dout;
                                        6'b110000 : mem_src_din <= mem_dst_dout ^ mem_src_dout;
                                        6'b110001 : mem_key_din <= mem_dst_dout ^ mem_src_dout;
                                        6'b110010 : mem_cmd_din <= mem_dst_dout ^ mem_src_dout;
                                        6'b110011 : mem_dst_din <= mem_dst_dout ^ mem_src_dout;
                                        6'b110100 : mem_src_din <= mem_dst_dout ^ mem_key_dout;
                                        6'b110101 : mem_key_din <= mem_dst_dout ^ mem_key_dout;
                                        6'b110110 : mem_cmd_din <= mem_dst_dout ^ mem_key_dout;
                                        6'b110111 : mem_dst_din <= mem_dst_dout ^ mem_key_dout;
                                        6'b111000 : mem_src_din <= mem_dst_dout ^ mem_cmd_dout;
                                        6'b111001 : mem_key_din <= mem_dst_dout ^ mem_cmd_dout;
                                        6'b111010 : mem_cmd_din <= mem_dst_dout ^ mem_cmd_dout;
                                        6'b111011 : mem_dst_din <= mem_dst_dout ^ mem_cmd_dout;
                                        6'b111100 : mem_src_din <= mem_dst_dout ^ mem_dst_dout;
                                        6'b111101 : mem_key_din <= mem_dst_dout ^ mem_dst_dout;
                                        6'b111110 : mem_cmd_din <= mem_dst_dout ^ mem_dst_dout;
                                        6'b111111 : mem_dst_din <= mem_dst_dout ^ mem_dst_dout;
                                    endcase
                                    statemachine_command <= 8'h05;
                                end
                                // clock up bank C
                                8'h05 : begin
                                    case (reg_bank_select[3:2])
                                        2'b00 : mem_src_clk <= 1'b1;
                                        2'b01 : mem_key_clk <= 1'b1;
                                        2'b10 : mem_cmd_clk <= 1'b1;
                                        2'b11 : mem_dst_clk <= 1'b1;
                                    endcase
                                    statemachine_command <= 8'h06;
                                end
                                // clock down
                                8'h06 : begin
                                    mem_src_clk <= 1'b0;
                                    mem_key_clk <= 1'b0;
                                    mem_cmd_clk <= 1'b0;
                                    mem_dst_clk <= 1'b0;
                                    statemachine_command <= 8'h07;
                                end
                                // increment address register
                                8'h07 : begin
                                    reg_int_address_01 = reg_int_address_01 + 1;
                                    statemachine_command <= 8'h08;
                                end
                                // check for loop
                                8'h08 : begin
                                    if ( reg_int_address_01 == 14'd0 ) statemachine_command <= 8'h09;
                                    else statemachine_command <= 8'h01;
                                end
                                // finish up
                                8'h09 : begin
                                    mem_src_ce <= 1'b0;
                                    mem_src_oce <= 1'b0;
                                    mem_src_wre <= 1'b0;
                                    mem_key_ce <= 1'b0;
                                    mem_key_oce <= 1'b0;
                                    mem_key_wre <= 1'b0;
                                    mem_cmd_ce <= 1'b0;
                                    mem_cmd_oce <= 1'b0;
                                    mem_cmd_wre <= 1'b0;
                                    mem_dst_ce <= 1'b0;
                                    mem_dst_oce <= 1'b0;
                                    mem_dst_wre <= 1'b0;
                                    statemachine_program <= 8'hFE;
                                end
                                



                            endcase
                        end


                        // 0x31 set lfsr_single to immedeate
                        8'h31 : begin
                            case (statemachine_command)
                                
                                // initialise
                                8'h00 : begin
                                    mem_cmd_ce <= 1'b1;
                                    mem_cmd_oce <= 1'b1;
                                    statemachine_command <= 8'h01;
                                end
                                // increment program counter
                                8'h01 : begin
                                    reg_program_counter = reg_program_counter + 1;
                                    statemachine_command <= 8'h02;
                                end
                                // set address to cmd
                                8'h02 : begin
                                    mem_cmd_ad <= reg_program_counter;
                                    statemachine_command <= 8'h03;
                                end
                                // clock high
                                8'h03 : begin
                                    mem_cmd_clk <= 1'b1;
                                    statemachine_command <= 8'h04;
                                end
                                // clock low
                                8'h04 : begin
                                    mem_cmd_clk <= 1'b0;
                                    statemachine_command <= 8'h05;
                                end
                                // copy dout to lfsr
                                8'h05 : begin
                                    lfsr_single[15:8] <= mem_cmd_dout;
                                    statemachine_command <= 8'h06;
                                end
                                // increment program counter
                                8'h06 : begin
                                    reg_program_counter <= reg_program_counter + 1;
                                    statemachine_command <= 8'h07;
                                end
                                // set address to cmd
                                8'h07 : begin
                                    mem_cmd_ad <= reg_program_counter;
                                    statemachine_command <= 8'h08;
                                end
                                // clock high
                                8'h08 : begin
                                    mem_cmd_clk <= 1'b1;
                                    statemachine_command <= 8'h09;
                                end
                                // clock low
                                8'h09 : begin
                                    mem_cmd_clk <= 1'b0;
                                    statemachine_command <= 8'h0A;
                                end
                                // copy dount to lfsr
                                8'h0A : begin
                                    lfsr_single[7:0] <= mem_cmd_dout;
                                    statemachine_command <= 8'h0B;
                                end
                                // finish
                                8'h0B : begin
                                    mem_cmd_ce <= 1'b0;
                                    mem_cmd_oce <= 1'b0;
                                    statemachine_program <= 8'hFE;
                                end
                                
                            endcase
                        end


                        // 0x32 set lfsr_single to address
                        
                        
                        // 0x33 step lfsr_single
                        8'h33 : begin
                            case (statemachine_command)
                                8'h00 : begin
                                    lfsr_single[15:1] <= lfsr_single[14:0];
                                    statemachine_command <= 8'h01;
                                end
                                8'h01 : begin
                                    lfsr_single[0] <= (((lfsr_single[15]^lfsr_single[13])^lfsr_single[12])^lfsr_single[10]);
                                    statemachine_program <= 8'hFE;
                                end
                            endcase
                        end


                        // 0x34 copy lfsr_single to dst 0x0000
                        8'h34 : begin
                            case (statemachine_command)

                                // initialise
                                8'h00 : begin
                                    mem_dst_ce <= 1'b1;
                                    mem_dst_wre <= 1'b1;
                                    statemachine_command <= 8'h01;
                                end
                                // set address and data to dst
                                8'h01 : begin
                                    mem_dst_ad <= 14'd0;
                                    mem_dst_din <= lfsr_single[15:8];
                                    statemachine_command <= 8'h02;
                                end
                                // clock high
                                8'h02 : begin
                                    mem_dst_clk <= 1'b1;
                                    statemachine_command <= 8'h03;
                                end
                                // clock low
                                8'h03 : begin
                                    mem_dst_clk <= 1'b0;
                                    statemachine_command <= 8'h04;
                                end
                                // set address and data to dst
                                8'h04 : begin
                                    mem_dst_ad <= 14'd1;
                                    mem_dst_din <= lfsr_single[7:0];
                                    statemachine_command <= 8'h05;
                                end
                                // clock high
                                8'h05 : begin
                                    mem_dst_clk <= 1'b1;
                                    statemachine_command <= 8'h06;
                                end
                                // clock low
                                8'h06 : begin
                                    mem_dst_clk <= 1'b0;
                                    statemachine_command <= 8'h07;
                                end
                                // finish
                                8'h07 : begin
                                    mem_dst_ce <= 1'b0;
                                    mem_dst_wre <= 1'b0;
                                    statemachine_program <= 8'hFE;
                                end
                                
                            endcase
                        end














                        
                        
                    endcase
                end





                // special case
                // increment program counter and go again.
                8'hFE : begin
                    reg_program_counter <= reg_program_counter + 1;
                    statemachine_program <= 8'h01;
                end
                
                // special case
                // signal isfinished and stop here.
                8'hFF : begin
                    arduino_isfinished <= 1'b1;
                    // reset on execute go low
                    if (!arduino_execute) statemachine_program <= 8'h00;
                end
                

                
            endcase
        end
    end




endmodule


































module top (
            input wire sysclk,
            input wire [7:0] arduino_datain,
            output reg [7:0] arduino_dataout,
            input wire arduino_clock,
            input wire arduino_commit,
            input wire arduino_readwrite,
            input wire arduino_reset,
            input wire arduino_execute,
            output reg arduino_isfinished
            );

    wire [7:0] wire_arduino_dataout;
    always @(wire_arduino_dataout) begin
        arduino_dataout <= wire_arduino_dataout;
    end

    wire wire_arduino_isfinished;
    always @(wire_arduino_isfinished) begin
        arduino_isfinished <= wire_arduino_isfinished;
    end


            
    wire [7:0] wire_mem_src_douta;
    wire [7:0] wire_mem_src_doutb;
    wire wire_mem_src_clka;
    wire wire_mem_src_clkb;
    wire wire_mem_src_ocea;
    wire wire_mem_src_oceb;
    wire wire_mem_src_cea;
    wire wire_mem_src_ceb;
    // wire wire_mem_src_reseta;
    // wire wire_mem_src_resetb;
    wire wire_mem_src_wrea;
    wire wire_mem_src_wreb;
    wire [13:0] wire_mem_src_ada;
    wire [13:0] wire_mem_src_adb;
    wire [7:0] wire_mem_src_dina;
    wire [7:0] wire_mem_src_dinb;
    Gowin_DPB blockmem_src(
        .douta(wire_mem_src_douta), //output [7:0] douta
        .doutb(wire_mem_src_doutb), //output [7:0] doutb
        .clka(wire_mem_src_clka), //input clka
        .ocea(wire_mem_src_ocea), //input ocea
        .cea(wire_mem_src_cea), //input cea
        .reseta(arduino_reset), //input reseta
        .wrea(wire_mem_src_wrea), //input wrea
        .clkb(wire_mem_src_clkb), //input clkb
        .oceb(wire_mem_src_oceb), //input oceb
        .ceb(wire_mem_src_ceb), //input ceb
        .resetb(arduino_reset), //input resetb
        .wreb(wire_mem_src_wreb), //input wreb
        .ada(wire_mem_src_ada), //input [13:0] ada
        .dina(wire_mem_src_dina), //input [7:0] dina
        .adb(wire_mem_src_adb), //input [13:0] adb
        .dinb(wire_mem_src_dinb) //input [7:0] dinb
    );

    wire [7:0] wire_mem_key_douta;
    wire [7:0] wire_mem_key_doutb;
    wire wire_mem_key_clka;
    wire wire_mem_key_clkb;
    wire wire_mem_key_ocea;
    wire wire_mem_key_oceb;
    wire wire_mem_key_cea;
    wire wire_mem_key_ceb;
    // wire wire_mem_key_reseta;
    // wire wire_mem_key_resetb;
    wire wire_mem_key_wrea;
    wire wire_mem_key_wreb;
    wire [13:0] wire_mem_key_ada;
    wire [13:0] wire_mem_key_adb;
    wire [7:0] wire_mem_key_dina;
    wire [7:0] wire_mem_key_dinb;
    Gowin_DPB blockmem_key(
        .douta(wire_mem_key_douta), //output [7:0] douta
        .doutb(wire_mem_key_doutb), //output [7:0] doutb
        .clka(wire_mem_key_clka), //input clka
        .ocea(wire_mem_key_ocea), //input ocea
        .cea(wire_mem_key_cea), //input cea
        .reseta(arduino_reset), //input reseta
        .wrea(wire_mem_key_wrea), //input wrea
        .clkb(wire_mem_key_clkb), //input clkb
        .oceb(wire_mem_key_oceb), //input oceb
        .ceb(wire_mem_key_ceb), //input ceb
        .resetb(arduino_reset), //input resetb
        .wreb(wire_mem_key_wreb), //input wreb
        .ada(wire_mem_key_ada), //input [13:0] ada
        .dina(wire_mem_key_dina), //input [7:0] dina
        .adb(wire_mem_key_adb), //input [13:0] adb
        .dinb(wire_mem_key_dinb) //input [7:0] dinb
    );

    wire [7:0] wire_mem_cmd_douta;
    wire [7:0] wire_mem_cmd_doutb;
    wire wire_mem_cmd_clka;
    wire wire_mem_cmd_clkb;
    wire wire_mem_cmd_ocea;
    wire wire_mem_cmd_oceb;
    wire wire_mem_cmd_cea;
    wire wire_mem_cmd_ceb;
    // wire wire_mem_cmd_reseta;
    // wire wire_mem_cmd_resetb;
    wire wire_mem_cmd_wrea;
    wire wire_mem_cmd_wreb;
    wire [13:0] wire_mem_cmd_ada;
    wire [13:0] wire_mem_cmd_adb;
    wire [7:0] wire_mem_cmd_dina;
    wire [7:0] wire_mem_cmd_dinb;
    Gowin_DPB blockmem_cmd(
        .douta(wire_mem_cmd_douta), //output [7:0] douta
        .doutb(wire_mem_cmd_doutb), //output [7:0] doutb
        .clka(wire_mem_cmd_clka), //input clka
        .ocea(wire_mem_cmd_ocea), //input ocea
        .cea(wire_mem_cmd_cea), //input cea
        .reseta(arduino_reset), //input reseta
        .wrea(wire_mem_cmd_wrea), //input wrea
        .clkb(wire_mem_cmd_clkb), //input clkb
        .oceb(wire_mem_cmd_oceb), //input oceb
        .ceb(wire_mem_cmd_ceb), //input ceb
        .resetb(arduino_reset), //input resetb
        .wreb(wire_mem_cmd_wreb), //input wreb
        .ada(wire_mem_cmd_ada), //input [13:0] ada
        .dina(wire_mem_cmd_dina), //input [7:0] dina
        .adb(wire_mem_cmd_adb), //input [13:0] adb
        .dinb(wire_mem_cmd_dinb) //input [7:0] dinb
    );


    wire [7:0] wire_mem_dst_douta;
    wire [7:0] wire_mem_dst_doutb;
    wire wire_mem_dst_clka;
    wire wire_mem_dst_clkb;
    wire wire_mem_dst_ocea;
    wire wire_mem_dst_oceb;
    wire wire_mem_dst_cea;
    wire wire_mem_dst_ceb;
    // wire wire_mem_dst_reseta;
    // wire wire_mem_dst_resetb;
    wire wire_mem_dst_wrea;
    wire wire_mem_dst_wreb;
    wire [13:0] wire_mem_dst_ada;
    wire [13:0] wire_mem_dst_adb;
    wire [7:0] wire_mem_dst_dina;
    wire [7:0] wire_mem_dst_dinb;
    Gowin_DPB blockmem_dst(
        .douta(wire_mem_dst_douta), //output [7:0] douta
        .doutb(wire_mem_dst_doutb), //output [7:0] doutb
        .clka(wire_mem_dst_clka), //input clka
        .ocea(wire_mem_dst_ocea), //input ocea
        .cea(wire_mem_dst_cea), //input cea
        .reseta(arduino_reset), //input reseta
        .wrea(wire_mem_dst_wrea), //input wrea
        .clkb(wire_mem_dst_clkb), //input clkb
        .oceb(wire_mem_dst_oceb), //input oceb
        .ceb(wire_mem_dst_ceb), //input ceb
        .resetb(arduino_reset), //input resetb
        .wreb(wire_mem_dst_wreb), //input wreb
        .ada(wire_mem_dst_ada), //input [13:0] ada
        .dina(wire_mem_dst_dina), //input [7:0] dina
        .adb(wire_mem_dst_adb), //input [13:0] adb
        .dinb(wire_mem_dst_dinb) //input [7:0] dinb
    );






    wire [7:0] wire_mem_ram_dout;
    wire wire_mem_ram_clk;
    wire wire_mem_ram_oce;
    wire wire_mem_ram_ce;
    //wire wire_mem_ram_reset;
    wire wire_mem_ram_wre;
    wire [13:0] wire_mem_ram_ad;
    wire [7:0] wire_mem_ram_din;
    Gowin_SP blockmem_ram(
        .dout(wire_mem_ram_dout), //output [7:0] dout
        .clk(wire_mem_ram_clk), //input clk
        .oce(wire_mem_ram_oce), //input oce
        .ce(wire_mem_ram_ce), //input ce
        .reset(arduino_reset), //input reset
        .wre(wire_mem_ram_wre), //input wre
        .ad(wire_mem_ram_ad), //input [13:0] ad
        .din(wire_mem_ram_din) //input [7:0] din
    );






















    arduino_io_ad myarduino_io_ad(
                                    .sysclk(sysclk),
                                    // arduino
                                    .arduino_datain(arduino_datain),
                                    .arduino_dataout(wire_arduino_dataout),
                                    .arduino_clock(arduino_clock),
                                    .arduino_commit(arduino_commit),
                                    .arduino_readwrite(arduino_readwrite),
                                    .arduino_reset(arduino_reset),
                                    // mem_src
                                    .mem_src_dout(wire_mem_src_douta),
                                    .mem_src_clk(wire_mem_src_clka),
                                    .mem_src_oce(wire_mem_src_ocea),
                                    .mem_src_ce(wire_mem_src_cea),
                                    .mem_src_wre(wire_mem_src_wrea),
                                    .mem_src_ad(wire_mem_src_ada),
                                    .mem_src_din(wire_mem_src_dina),
                                    // mem_key
                                    .mem_key_dout(wire_mem_key_douta),
                                    .mem_key_clk(wire_mem_key_clka),
                                    .mem_key_oce(wire_mem_key_ocea),
                                    .mem_key_ce(wire_mem_key_cea),
                                    .mem_key_wre(wire_mem_key_wrea),
                                    .mem_key_ad(wire_mem_key_ada),
                                    .mem_key_din(wire_mem_key_dina),
                                    // mem_cmd
                                    .mem_cmd_dout(wire_mem_cmd_douta),
                                    .mem_cmd_clk(wire_mem_cmd_clka),
                                    .mem_cmd_oce(wire_mem_cmd_ocea),
                                    .mem_cmd_ce(wire_mem_cmd_cea),
                                    .mem_cmd_wre(wire_mem_cmd_wrea),
                                    .mem_cmd_ad(wire_mem_cmd_ada),
                                    .mem_cmd_din(wire_mem_cmd_dina),
                                    // mem_dst
                                    .mem_dst_dout(wire_mem_dst_douta),
                                    .mem_dst_clk(wire_mem_dst_clka),
                                    .mem_dst_oce(wire_mem_dst_ocea),
                                    .mem_dst_ce(wire_mem_dst_cea),
                                    .mem_dst_wre(wire_mem_dst_wrea),
                                    .mem_dst_ad(wire_mem_dst_ada),
                                    .mem_dst_din(wire_mem_dst_dina)
    );


    



    encryption_engine my_encryption_engine(  
                                    // sysclk
                                    .sysclk(sysclk),
                                    // arduino connections
                                    .arduino_execute(arduino_execute),
                                    .arduino_isfinished(wire_arduino_isfinished),
                                    .arduino_reset(arduino_reset),
                                    // mem_src
                                    .mem_src_dout(wire_mem_src_doutb),
                                    .mem_src_clk(wire_mem_src_clkb),
                                    .mem_src_oce(wire_mem_src_oceb),
                                    .mem_src_ce(wire_mem_src_ceb),
                                    .mem_src_wre(wire_mem_src_wreb),
                                    .mem_src_ad(wire_mem_src_adb),
                                    .mem_src_din(wire_mem_src_dinb),
                                    // mem_key
                                    .mem_key_dout(wire_mem_key_doutb),
                                    .mem_key_clk(wire_mem_key_clkb),
                                    .mem_key_oce(wire_mem_key_oceb),
                                    .mem_key_ce(wire_mem_key_ceb),
                                    .mem_key_wre(wire_mem_key_wreb),
                                    .mem_key_ad(wire_mem_key_adb),
                                    .mem_key_din(wire_mem_key_dinb),
                                    // mem_cmd
                                    .mem_cmd_dout(wire_mem_cmd_doutb),
                                    .mem_cmd_clk(wire_mem_cmd_clkb),
                                    .mem_cmd_oce(wire_mem_cmd_oceb),
                                    .mem_cmd_ce(wire_mem_cmd_ceb),
                                    .mem_cmd_wre(wire_mem_cmd_wreb),
                                    .mem_cmd_ad(wire_mem_cmd_adb),
                                    .mem_cmd_din(wire_mem_cmd_dinb),
                                    // mem_dst
                                    .mem_dst_dout(wire_mem_dst_doutb),
                                    .mem_dst_clk(wire_mem_dst_clkb),
                                    .mem_dst_oce(wire_mem_dst_oceb),
                                    .mem_dst_ce(wire_mem_dst_ceb),
                                    .mem_dst_wre(wire_mem_dst_wreb),
                                    .mem_dst_ad(wire_mem_dst_adb),
                                    .mem_dst_din(wire_mem_dst_dinb),
                                    // mem_ram
                                    .mem_ram_dout(wire_mem_ram_dout),
                                    .mem_ram_clk(wire_mem_ram_clk),
                                    .mem_ram_oce(wire_mem_ram_oce),
                                    .mem_ram_ce(wire_mem_ram_ce),
                                    .mem_ram_wre(wire_mem_ram_wre),
                                    .mem_ram_ad(wire_mem_ram_ad),
                                    .mem_ram_din(wire_mem_ram_din)
                                    
    );




    
endmodule














