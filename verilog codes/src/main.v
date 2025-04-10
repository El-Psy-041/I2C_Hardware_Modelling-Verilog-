`timescale 1ns / 1ps




module main(input reset);

wire scl;
wire sda_line;
master main_master(.reset(reset),.sda_line(sda_line),.scl(scl));
slave main_slave(.sda_line(sda_line),.scl(scl));

endmodule

////////////////////////////////////////////////////////////////////////////////////

module master(input reset,i2c_clk, inout sda_line, output reg scl,[2:0]state_out);



wire reset;
reg sda_o, sda_t;
wire sda_i;

assign sda_line = sda_t ? 1'bz : sda_o;
assign sda_i = sda_line;
reg sda;

reg [2:0]state = 3'b000;
reg [2:0] state_out;
reg sda_master_enable;
reg [6:0]addr_reg = 7'h69;   //69 = 1101001
reg [2:0]count = 3'd6;
reg rw_reg = 1;          //FOR NOW transmitting data from master to slave;
reg [7:0] data_reg = 8'b10001010;
reg data_out;
reg addr_ack_bit;
reg data_ack_bit;

reg [2:0]data_count = 3'd7;



parameter   IDLE_STATE = 3'b000,
            START_STATE = 3'b001,
            ADDR_STATE = 3'b010,
            RW_STATE = 3'b011,
            ADDR_ACK_STATE = 3'b100,
            DATA_STATE = 3'b101,
            DATA_ACK_STATE = 3'b110,
            STOP_STATE = 3'b111;





always @(posedge i2c_clk) begin

    if (reset == 1) begin
        state <= IDLE_STATE;
        sda_t <= 1;
        scl <= 1'bx;
    end


    else if(reset == 0) begin
        case(state)
            IDLE_STATE: begin
                sda_t<=0;
                sda_o<=1;
                scl<=1;
                state_out <= IDLE_STATE;
                state<=START_STATE;

            end
            START_STATE: begin
                sda_o<=0;
                state_out <= START_STATE;
                state<=ADDR_STATE;
            end
             ADDR_STATE: begin
                sda_t<=0;
                state_out <= ADDR_STATE;
                if (count == 0) begin
                    sda_o <= addr_reg[count];
                    state <= RW_STATE;
                    count <= 3'd6;
                end else begin
                    sda_o <= addr_reg[count];
                    count <= count - 1;
                end
            end
            RW_STATE: begin
                sda_o<=rw_reg;
                state_out <= RW_STATE;
                state<=ADDR_ACK_STATE;
                end
            ADDR_ACK_STATE: begin
                sda_t <= 1;
                state_out <= ADDR_ACK_STATE;

            end
            DATA_STATE: begin
                sda_t <= 0;
                state_out <= DATA_STATE;
                if (data_count == 0) begin
                    sda_o <= data_reg[data_count];
                    state <= DATA_ACK_STATE;
                end else begin
                    sda_o <= data_reg[data_count];
                    data_count <= data_count - 1;
                end
            end

            DATA_ACK_STATE: begin
                sda_t <= 1;
                state_out <= DATA_ACK_STATE;
                data_ack_bit <= sda_i;
                state <= (data_ack_bit) ? DATA_STATE : STOP_STATE;
            end

            STOP_STATE: begin
                sda_t <= 0;
                sda_o <= 1;
                scl <= 1;
                state_out <= STOP_STATE;

            end

        endcase
    end


end

always @(posedge scl) begin
    if(state_out == ADDR_ACK_STATE) begin
        sda = sda_i;  // Capture it properly
        addr_ack_bit = sda;
        if(addr_ack_bit == 1) begin
            state <= ADDR_STATE;  // Retry address phase if no ACK
        end
        else if(addr_ack_bit == 0) begin
            state <= DATA_STATE;  // Proceed to data transmission
        end
    end
end

always @(posedge scl) begin
    if(state_out == DATA_ACK_STATE) begin
        sda = sda_i;  // Capture it properly
        addr_ack_bit = sda;
        if(data_ack_bit == 1) begin
            state <= STOP_STATE;
        end
        else if(addr_ack_bit == 0) begin
            state <= STOP_STATE;
        end
    end
end








always @(i2c_clk) begin
    if(state == ADDR_STATE || state == RW_STATE || state == ADDR_ACK_STATE || state == DATA_STATE ||state == DATA_ACK_STATE) begin    //Starting of scl after completing starting state;
        scl <= ~i2c_clk;
    end

    if(state_out == DATA_ACK_STATE) begin
        scl <= 1;
    end
end





endmodule



///////////////////////////////////////////////////////////////


module slave(input scl,i2c_clk,inout sda_line,output addr_data_out,addr_count_out,data_data_out,data_count_out,addr_flag,flag,tflag);

    reg sda_o;
    reg sda_t = 1;
    wire sda_i;

    assign sda_line = (sda_t) ? 1'bz : sda_o;
    assign sda_i = sda_line;
    reg sda;
    wire clk;
    reg flag_reg = 1'bz;
    wire flag;
    reg tflag_reg = 1'b0;
    wire tflag;
    reg [6:0] addr_data =  7'b0000000;
    reg [6:0] addr_data_out;
    reg [3:0] addr_count = 4'b1010; //here from 9 to 0 10 states // we require 8 bits (7+1)  //+1 bit for starting posedge of scl from Hi-im state;
    reg [3:0] addr_count_out;
    reg addr_flag_reg = 1'b0;
    wire addr_flag;

    reg [7:0] data_data =  8'b00000000;
    reg [7:0] data_data_out;
    reg [3:0] data_count = 4'b1010; //here from 9 to 0 10 states // we require 8 bits (7+1)  //+1 bit for starting posedge of scl from Hi-im state;
    reg [3:0] data_count_out;

    parameter slave_addr = 8'h69;        //for now change the addr of slave here. for testing







    always @(posedge scl) begin
        if(flag_reg == 1) begin
            if(addr_flag == 0) begin
                if(addr_count <= 10 && addr_count >= 4)  begin
                    sda = sda_i;

                    addr_data = addr_data | (sda << addr_count-4) ; //same case with addr_data
                    addr_data_out[6:0] <= addr_data[6:0];

                    addr_count <= addr_count -1;           //Some fucked up shit combining bloacking and non blocking is not advisable but for now its giving me correct result so gud!!
                    addr_count_out <= addr_count -1;
                end

                else if(addr_count > 0 && addr_count != 1 && addr_count != 2)begin
                    addr_count <= addr_count -1;
                    addr_count_out <= addr_count -1;
                end
            end

            else if(addr_flag ==1) begin
                if(data_count <= 9 && data_count >= 3)  begin
                    sda = sda_i;

                    data_data = data_data | (sda << data_count-2) ;
                    data_data_out[7:0] <= data_data[7:0];

                    data_count <= data_count -1;
                    data_count_out <= data_count -1;

                end

                else begin
                    data_count <= data_count -1;
                    data_count_out <= data_count -1;
                end

            end
        end



    end


        always @(negedge scl) begin


            if(addr_count == 2) begin
                sda_t<=0;
                if (addr_data == slave_addr) begin
                    sda_o = 1'b0;
                    addr_count <= addr_count -1;
                    addr_count_out <= addr_count -1;
                    addr_flag_reg<=1;

                end

                else begin
                    sda_o = 1'b1;         //NACK
                    addr_count <= addr_count -1;
                    addr_count_out <= addr_count -1;
                    addr_flag_reg<=0;               //If NACK then resend data from master and re store it in slave

                end
            end

            else if(addr_count ==1) begin
                sda_t<=1;
                addr_data <= 7'b0000000;
                addr_data_out[6:0] <= 7'b0000000;
                addr_count <= 4'b1010;
                addr_count_out <= 4'b1010;

            end


            if(addr_flag_reg == 1) begin
                if(data_count == 1) begin
                    tflag_reg <= 1;
                    sda_t<=0;
                    sda_o = 1'b0;
                end



            end
        end


    always @(negedge sda_line) begin
    #1;              //Giving Delay to avoid race condition between sda_line and scl
        if(scl == 1)
            flag_reg <= 1;   //Starting condition detected
    end
    always @(posedge sda_line) begin
    #1;
        if(scl == 1) begin
            flag_reg <= 0;        //stopping condition detected;
            if(tflag_reg == 1) begin
                tflag_reg<=0;
                sda_t<=1;
            end
         end

    end



    assign flag = flag_reg;       //Do notconfuse non blocking /blocking  sign to assign sign here "=" simply means they are equal so when ever the reg changes the wire changes;
    //Above is the good choice to see reg output in testbench waveform since testbench only takes wires:)
    assign tflag = tflag_reg;
    assign addr_flag = addr_flag_reg;







endmodule



////////////////////////////////////////////////////////////

/////////////////////////////////////////
