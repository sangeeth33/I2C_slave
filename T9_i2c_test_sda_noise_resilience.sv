class i2c_test_sda_noise_resilience extends i2c_base_test;
    `uvm_component_utils(i2c_test_sda_noise_resilience)

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        i2c_seq_item clean = i2c_seq_item::type_id::create("clean_tx");
        clean.randomize() with { rw == 0; };
        clean.start(env.agt.drv.seq_item_port);

        // Inject glitch on SDA
        `uvm_info("TEST", "Injecting noise pulse on SDA mid-bit", UVM_LOW)
        vif.sda_oe <= 0; #3; vif.sda_oe <= 1; #2;
    endtask
endclass