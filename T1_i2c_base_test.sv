class i2c_base_test extends uvm_test;
    `uvm_component_utils(i2c_base_test)

    i2c_env env;
    virtual i2c_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = i2c_env::type_id::create("env", this);
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("BASE_TEST", "VIF not found")
    endfunction
endclass