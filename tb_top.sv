module tb_top;
    logic clk = 0;
    always #5 clk = ~clk;

    i2c_if iif(clk);
    i2c_slave_dut dut (.clk(clk), .scl(iif.scl), .sda(iif.sda));

    initial begin
        uvm_config_db#(virtual i2c_if)::set(null, "*", "vif", iif);
        run_test("i2c_test");
    end
endmodule