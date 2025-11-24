/* \brief RAL Virtual Environment
 *
 * An environment that provides RAL register read and write access with only the RAL model.  This 
 * environment can be used to develop and test RAL environment components, such as RAL sequences, 
 * before the design is available.
 * The function to build a RAL model is specific to the uvm_reg_block extension.  Therefore, this
 * class is virtual, with the pure virtual function build_m_reg_blk() that must be implemented in 
 * an extension.
*/
virtual class evm_ral_venv#(type REG_BLK_T = uvm_reg_block) extends uvm_env;

    typedef evm_ral_venv#( REG_BLK_T ) this_type;

    `uvm_component_param_utils(this_type)

    `uvm_type_name_decl( $sformatf("evm_ral_mem#(%s)",$typename(REG_BLK_T)))

    REG_BLK_T           m_reg_blk;    ///< Registers and memory model
    evm_ral_venv_agent  m_ral_agt;    ///< Agent for executing ral_venv_object transactions

    extern function new( string name = "evm_ral_venv", uvm_component parent = null );
    extern virtual function void build_phase(uvm_phase phase);
      pure virtual function void build_m_reg_blk();
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual task reset_phase(uvm_phase phase);

endclass: evm_ral_venv

function evm_ral_venv::new( string name = "evm_ral_venv", uvm_component parent );
    super.new(name, parent);
endfunction: new

function void evm_ral_venv::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if( m_reg_blk == null ) begin
        evm_ral_venv_backdoor ral_backdoor = evm_ral_venv_backdoor::type_id::create( "ral_backdoor", this );
        m_reg_blk = REG_BLK_T::type_id::create( "m_reg_blk", this );
        build_m_reg_blk();
        ral_backdoor.build_backdoor( m_reg_blk );
        m_reg_blk.lock_model();
        m_reg_blk.reset();
    end
    
    if ( m_ral_agt == null ) begin
        m_ral_agt = evm_ral_venv_agent::type_id::create( "m_ral_agt", this );
    end
    m_ral_agt.m_reg_blk = m_reg_blk;
endfunction: build_phase

function void evm_ral_venv::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_reg_blk.default_map.set_sequencer(m_ral_agt.m_sqr);
    m_reg_blk.default_map.set_auto_predict(1);
endfunction: connect_phase

task evm_ral_venv::reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    m_reg_blk.reset();
endtask: reset_phase