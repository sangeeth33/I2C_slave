class i2c_test_repeated_start extends i2c_base_test;
    `uvm_component_utils(i2c_test_repeated_start)

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        i2c_seq_item w = i2c_seq_item::type_id::create("write_then_repeat_start");
        w.randomize() with { rw == 0; };
        w.start(env.agt.drv.seq_item_port);

        // simulate repeated START by initiating next read without STOP
        i2c_seq_item r = i2c_seq_item::type_id::create("followup_read");
        r.randomize() with { rw == 1; };
        r.start(env.agt.drv.seq_item_port);
    endtask
endclass