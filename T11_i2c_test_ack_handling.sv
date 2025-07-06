class i2c_test_ack_handling extends i2c_base_test;
    `uvm_component_utils(i2c_test_ack_handling)

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        // Valid address → expect ACK
        i2c_seq_item valid = i2c_seq_item::type_id::create("valid_ack");
        valid.randomize() with { address == 7'h42; rw == 0; };
        valid.start(env.agt.drv.seq_item_port);

        // Invalid address → expect NACK (no response)
        i2c_seq_item invalid = i2c_seq_item::type_id::create("invalid_nack");
        invalid.randomize() with { address != 7'h42; };
        invalid.start(env.agt.drv.seq_item_port);
    endtask
endclass