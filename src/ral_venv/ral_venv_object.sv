/** \brief RAL Virtual Environment Register Object
 *
 * This class wraps the uvm_reg_bus_op structure in a uvm_sequence_item for use in
 * UVM components that require a uvm_sequence_item derived transaction.
 */
class ral_venv_object extends uvm_sequence_item;

    uvm_reg_bus_op bus_op;  ///< The wrapped uvm_reg_bus_op structure

    `uvm_object_utils_begin(ral_venv_object)
        `uvm_field_enum(uvm_access_e, bus_op.kind, UVM_ALL_ON|UVM_STRING)
        `uvm_field_int(bus_op.addr, UVM_ALL_ON|UVM_HEX)
        `uvm_field_int(bus_op.data, UVM_ALL_ON|UVM_HEX)
        `uvm_field_int(bus_op.n_bits, UVM_ALL_ON|UVM_DEC)
        `uvm_field_int(bus_op.byte_en, UVM_ALL_ON|UVM_HEX) 
        `uvm_field_enum(uvm_status_e, bus_op.status, UVM_ALL_ON|UVM_STRING)    
    `uvm_object_utils_end

    function new(string name = "ral_venv_object");
        super.new(name);
    endfunction: new

    `EVM_SLP_CONVERT2STRING

endclass: ral_venv_object
