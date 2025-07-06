class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)

    uvm_analysis_port #(i2c_seq_item) ap;
    virtual i2c_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "vif not found")
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Can watch for START → Address → Data
        // For now, emit dummy for scoreboard
    endtask
endclass