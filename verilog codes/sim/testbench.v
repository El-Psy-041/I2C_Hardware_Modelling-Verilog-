`timescale 1ns / 1ps


module testbench();
    reg reset;
    wire sda_line, scl;
    wire [2:0]state_out;
  //  wire [3:0] addr_count_out;


    wire scl,sda_line;
    wire [6:0] addr_data_out;

    wire[7:0] data_data_out;
   // wire[3:0] data_count_out;
   // wire flag;
  //  wire tflag;
   // wire addr_flag;
    reg i2c_clk;           // I2C clock signal



    initial begin
        i2c_clk = 0;
        forever #5000 i2c_clk = ~i2c_clk;  // 10 µs period (100 kHz)
    end


    // Instantiate the main module
    main dut1(
        .reset(reset)
    );

    master dut2(.reset(reset),
        .sda_line(sda_line),
        .scl(scl),
        .i2c_clk(i2c_clk),  // Pass i2c_clk to the slave module
        .state_out(state_out));

    slave dut5(.scl(scl),
         .i2c_clk(i2c_clk),  // Pass i2c_clk to the slave module
        .sda_line(sda_line),
        .addr_data_out(addr_data_out),
       // .addr_count_out(addr_count_out),
        .data_data_out(data_data_out)
       // .data_count_out(data_count_out),
       // .flag(flag),
        //.tflag(tflag),
       // .addr_flag(addr_flag)
       );


    // Test Stimulus
    initial begin
        reset = 1;
        #27000 reset = 0;  // Trigger Start Condition
        #300000 $finish;
    end

    // Monitor Outputs
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, testbench);
    end
endmodule
