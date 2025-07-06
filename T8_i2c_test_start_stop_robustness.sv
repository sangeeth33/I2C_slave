class i2c_test_start_stop_robustness extends i2c_base_test;
    `uvm_component_utils(i2c_test_start_stop_robustness)

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        // Simulate START → STOP without transaction
        `uvm_info("TEST", "Issuing START then STOP without data", UVM_LOW)
        vif.sda_oe <= 1; vif.scl_oe <= 1; #10; // Idle
        vif.sda_oe <= 0; #10; // START
        vif.scl_oe <= 0; #10;
        vif.sda_oe <= 0; vif.scl_oe <= 1; #10;
        vif.sda_oe <= 1; #10; // STOP
    endtask
endclass