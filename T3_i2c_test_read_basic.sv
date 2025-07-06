class i2c_test_read_basic extends i2c_base_test;
    `uvm_component_utils(i2c_test_read_basic)

    virtual task run_phase(uvm_phase phase);
        // Preload memory (e.g. via DUT probe or reg model)
        // Then read back value
        i2c_seq_item tx = i2c_seq_item::type_id::create("read_tx");
        tx.address = 7'h42;
        tx.rw = 1; // read
        tx.data = 8'h00; // expected placeholder
        start_item(tx);
        finish_item(tx);
    endtask
endclass