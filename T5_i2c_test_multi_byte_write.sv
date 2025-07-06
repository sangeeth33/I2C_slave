class i2c_test_multi_byte_write extends i2c_base_test;
    `uvm_component_utils(i2c_test_multi_byte_write)

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        foreach (int i[5]) begin
            i2c_seq_item req = i2c_seq_item::type_id::create($sformatf("write_%0d", i));
            req.randomize() with { rw == 0; };
            req.start(env.agt.drv.seq_item_port);
        end
    endtask
endclass