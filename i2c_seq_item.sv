class i2c_seq_item extends uvm_sequence_item;
    rand bit [6:0] address;
    rand bit       rw;
    rand bit [7:0] data;

    `uvm_object_utils(i2c_seq_item)

    function new(string name = "i2c_seq_item");
        super.new(name);
    endfunction

    function void do_print(uvm_printer printer);
        super.do_print(printer);
        $display("ADDR: 0x%0h, RW: %0b, DATA: 0x%0h", address, rw, data);
    endfunction
endclass