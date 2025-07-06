interface i2c_if(input logic clk);
    logic scl;
    logic sda;
    logic scl_oe, sda_oe;

    assign scl = scl_oe ? 1'b0 : 1'bz;
    assign sda = sda_oe ? 1'b0 : 1'bz;

    modport dut (inout scl, inout sda, input clk);
    modport tb  (output scl_oe, sda_oe, input scl, sda, input clk);
endinterface