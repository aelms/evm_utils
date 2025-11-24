/** \brief RAL Virtual Envionment Register Adapater
 * 
 * UVM register adapter that translates between RAL domain uvm_reg_bus_op transactions 
 * and the virtual physical layer ral_venv_object transactions.  
 */
class ral_venv_adapter extends uvm_reg_adapter;
    
    `uvm_object_utils(ral_venv_adapter);

    protected uvm_report_object   m_report_object;      ///< Report object for report delegation

    function new(string name = "ral_venv_adapter");
        super.new(name);
        supports_byte_enable = 0;
        provides_responses = 1;
    endfunction: new

    extern virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);


    extern virtual function void bus2reg(uvm_sequence_item  bus_item,
                                         ref uvm_reg_bus_op rw );                                         

    extern virtual function void uvm_set_report_object(uvm_report_object report_object);
    
    extern function uvm_report_object uvm_get_report_object();

    `EVM_REPORT_DELEGATION_FUNCTIONS

    `EVM_SLP_CONVERT2STRING

endclass: ral_venv_adapter

function uvm_sequence_item ral_venv_adapter::reg2bus(const ref uvm_reg_bus_op rw);
    ral_venv_object op = ral_venv_object::type_id::create("op");
    op.bus_op = rw;
    return op;
endfunction: reg2bus

function void ral_venv_adapter::bus2reg(uvm_sequence_item  bus_item,
                                        ref uvm_reg_bus_op rw );
    ral_venv_object op;
    if( !$cast(op, bus_item) ) begin
        `uvm_fatal( get_type_name(), $sformatf("bus_item is not a ral_venv_object (%s)", $typename(bus_item) ) );
    end
    rw = op.bus_op;
endfunction: bus2reg


function void ral_venv_adapter::uvm_set_report_object(uvm_report_object report_object);
  m_report_object=report_object;
endfunction: uvm_set_report_object

function uvm_report_object ral_venv_adapter::uvm_get_report_object();
  if( m_report_object ) begin
     return m_report_object;
  end else begin
     return uvm_coreservice_t::get().get_root();
  end
endfunction: uvm_get_report_object