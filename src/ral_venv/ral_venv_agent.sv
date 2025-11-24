/** \brief RAL Virtual Environment Agent
 *
 * The RAL Virtual Environment Agent provides the functionality to receive
 * and execute UVM register layer transactions.
 */
class ral_venv_agent extends uvm_agent;

    `uvm_component_utils(ral_venv_agent)                                    

    uvm_sequencer#(ral_venv_object)          m_sqr; 
    uvm_seq_item_pull_port#(ral_venv_object) m_seq_item_port;

    uvm_reg_block                            m_reg_blk;

    function new(string name = "ral_venv_agent", uvm_component parent = null);
        super.new(name, parent);
        m_seq_item_port    = new("m_seq_item_port", this);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if ( m_sqr == null ) begin
            m_sqr = uvm_sequencer#(ral_venv_object)::type_id::create("m_sqr", this);
        end
    endfunction: build_phase 

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_sqr.seq_item_export.connect(m_seq_item_port);
    endfunction: connect_phase

    virtual task run_phase(uvm_phase phase);
        forever begin
            ral_venv_object req;
            ral_venv_object rsp;
            uvm_reg         target_reg;

            // Get new request
            m_seq_item_port.get(req);
            `uvm_info( get_type_name(), $sformatf("req: %s", req.convert2string()), UVM_MEDIUM )
            m_seq_item_port.item_done();
            
            // Get the targeted register
            target_reg = m_reg_blk.default_map.get_reg_by_offset(req.bus_op.addr);
            if( target_reg == null ) begin
                `uvm_info( get_type_name(), "req has no target register", UVM_MEDIUM )
            end else begin
                `uvm_info( get_type_name(), $sformatf("req target register %s", target_reg.get_full_name()), UVM_MEDIUM )
            end

            // Create and return a ral_venv_object response for the req
            rsp = ral_venv_object::type_id::create("rsp");
            rsp.bus_op = req.bus_op;
            rsp.bus_op.status = ( target_reg != null ) ? UVM_IS_OK : UVM_NOT_OK;
            rsp.bus_op.data = uvm_reg_data_t'(0);
            if( req.bus_op.kind == UVM_READ ) begin
                rsp.bus_op.data = target_reg.get_mirrored_value();
            end
            `uvm_info(get_type_name(), $sformatf("rsp: %s", rsp.convert2string()), UVM_MEDIUM)

            // Return the response
            m_seq_item_port.put_response(rsp);

        end
    endtask: run_phase
    
endclass: ral_venv_agent