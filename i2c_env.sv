class i2c_env extends uvm_env;
    `uvm_component_utils(i2c_env)

    i2c_agent agt;
    i2c_scoreboard scb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = i2c_agent::type_id::create("agt", this);
        scb = i2c_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        agt.mon.ap.connect(scb.mon_imp);
    endfunction
endclass