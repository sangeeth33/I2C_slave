class i2c_test_full_buffer_write extends i2c_base_test;
    `uvm_component_utils(i2c_test_full_buffer_write)

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        // Fill entire buffer depth
        for (int i = 0; i < MEM_DEPTH; i++) begin
            i2c_seq_item item = i2c_seq_item::type_id::create($sformatf("tx_%0d", i));
            item.randomize() with { rw == 0; };
            item.data = i; // for debugging
            item.start(env.agt.drv.seq_item_port);
        end
    endtask
endclass