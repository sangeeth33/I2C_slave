class i2c_scoreboard extends uvm_component;
    `uvm_component_utils(i2c_scoreboard)

    uvm_analysis_imp #(i2c_seq_item, i2c_scoreboard) mon_imp;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_imp = new("mon_imp", this);
    endfunction

    virtual function void write(i2c_seq_item t);
        `uvm_info("SCB", $sformatf("Checking transaction: %s", t.sprint()), UVM_LOW)
        // Add golden model or memory comparison here
    endfunction
endclass