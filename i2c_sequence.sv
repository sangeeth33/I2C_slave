class i2c_sequence extends uvm_sequence #(i2c_seq_item);
    `uvm_object_utils(i2c_sequence)

    function new(string name = "i2c_sequence");
        super.new(name);
    endfunction

    virtual task body();
        repeat (5) begin
            i2c_seq_item req = i2c_seq_item::type_id::create("req");
            assert(req.randomize());
            start_item(req);
            finish_item(req);
        end
    endtask
endclass