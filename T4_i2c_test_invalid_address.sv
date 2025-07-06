class i2c_test_invalid_address extends i2c_base_test;
    `uvm_component_utils(i2c_test_invalid_address)

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        i2c_sequence seq = i2c_sequence::type_id::create("invalid_addr_seq");
        seq.randomize() with { address != 7'h42; };
        seq.start(env.agt.drv.seq_item_port);
    endtask
endclass