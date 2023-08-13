







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
    // mem_src
    input wire [7:0] mem_key_dout,
    output reg mem_key_clk,
    output reg mem_key_oce,
    output reg mem_key_ce,
    output reg mem_key_wre,
    output reg [13:0] mem_key_ad,
    output reg [7:0] mem_key_din,
    // mem_src
    input wire [7:0] mem_cmd_dout,
    output reg mem_cmd_clk,
    output reg mem_cmd_oce,
    output reg mem_cmd_ce,
    output reg mem_cmd_wre,
    output reg [13:0] mem_cmd_ad,
    output reg [7:0] mem_cmd_din,
    // mem_src
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
    wire wire_mem_src_reseta;
    wire wire_mem_src_resetb;
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
    wire wire_mem_key_reseta;
    wire wire_mem_key_resetb;
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
    wire wire_mem_cmd_reseta;
    wire wire_mem_cmd_resetb;
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
    wire wire_mem_dst_reseta;
    wire wire_mem_dst_resetb;
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


    








    
endmodule














