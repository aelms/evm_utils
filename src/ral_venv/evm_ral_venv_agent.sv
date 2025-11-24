/** \brief RAL Virtual Environment Agent
 *
 * The RAL Virtual Environment Agent provides the functionality to receive and execute UVM 
 * register layer transactions directly on the RAL model.  Acceses return UVM_IS_OK status 
 * and reads return the mirror value.  The write value is already applied to the mirror by 
 * RAL access so no additional action is required.
 */
class evm_ral_venv_agent extends uvm_agent;

    `uvm_component_utils(evm_ral_venv_agent)                                    

    uvm_sequencer#(uvm_reg_item)          m_sqr; 
    uvm_seq_item_pull_port#(uvm_reg_item) m_seq_item_port;

    uvm_reg_block                         m_reg_blk;

    rand int                              m_ns_delay;

    constraint ns_delay_c { m_ns_delay inside {[1:5]}; }

    extern function new(string name = "evm_ral_venv_agent", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);

endclass: evm_ral_venv_agent

function evm_ral_venv_agent::new(string name, uvm_component parent);
    super.new(name, parent);
    m_seq_item_port    = new("m_seq_item_port", this);
endfunction: new

function void evm_ral_venv_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if ( m_sqr == null ) begin
        m_sqr = uvm_sequencer#(uvm_reg_item)::type_id::create("m_sqr", this);
    end
endfunction: build_phase 

function void evm_ral_venv_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_seq_item_port.connect(m_sqr.seq_item_export);
endfunction: connect_phase

task evm_ral_venv_agent::run_phase(uvm_phase phase);

    forever begin
        uvm_reg_item req;

        // Get new request
        m_seq_item_port.get_next_item(req);
        `uvm_info( get_type_name(), $sformatf("req: %s", req.convert2string()), UVM_MEDIUM );
        
        // Get the targeted register
        if ( req.element_kind == UVM_REG ) begin
            uvm_reg target_reg;
            $cast(target_reg, req.element);
            req.set_id_info(req);
            if ( req.kind == UVM_READ ) begin
                req.value = new[1];
                req.value[0] = target_reg.get_mirrored_value();
            end
        end else begin
            `uvm_error( get_type_name(), $sformatf("req.element_kind (%s) unsupported", req.element_kind.name() ) );
        end

        // Generated response
        `uvm_info(get_type_name(), $sformatf("req: %s", req.convert2string()), UVM_MEDIUM);

        if( randomize() != 1) begin
            `uvm_fatal( get_type_name(), "Randomize failed" );
        end
        // Wait for random response delay;
        #(realtime'(m_ns_delay) * 1.0ns);
        m_seq_item_port.item_done(req);

    end
endtask: run_phase
