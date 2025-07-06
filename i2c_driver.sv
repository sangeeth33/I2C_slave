class i2c_driver extends uvm_driver #(i2c_seq_item);
    `uvm_component_utils(i2c_driver)

    virtual i2c_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "vif not found")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            i2c_seq_item req;
            seq_item_port.get_next_item(req);

            // Simplified I²C write sequence
            vif.sda_oe <= 1; #10; // START
            send_byte({req.address, req.rw});
            if (req.rw == 0) send_byte(req.data);
            vif.sda_oe <= 0; #10; // STOP

            seq_item_port.item_done();
        end
    endtask

    task send_byte(bit [7:0] data);
        foreach (data[i]) begin
            vif.sda_oe <= ~data[i];
            #10; // SCL cycle
        end
    endtask
endclass