class i2c_test_write_basic extends i2c_base_test;
    `uvm_component_utils(i2c_test_write_basic)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        i2c_sequence seq = i2c_sequence::type_id::create("seq");
        seq.start(env.agt.drv.seq_item_port);
    endtask
endclass