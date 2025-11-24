/* \brief RAL Virtual Environment
 *
 * UVM Environment extension that provides the functionality for RAL to read and write registers 
 * without a physical interface.
*/
class ral_venv#(type REG_BLK_T = uvm_reg_block) extends uvm_env;

    `uvm_component_utils(ral_venv)

    REG_BLK_T                    m_reg_blk;    ///< Registers and memory model
    protected ral_venv_agent     m_agent;      ///< Agent for executing ral_venv_object transactions
    protected ral_venv_adapter   m_adapter;    ///< Adapter for converting between uvm_reg_bus_op and ral_venv_object

    function new(string name = "ral_venv_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if( m_reg_blk == null ) begin
            m_reg_blk = REG_BLK_T::type_id::create("m_reg_blk", this);
            m_reg_blk.build();
            m_reg_blk.lock_model();
        end
        
        if ( m_agent == null ) begin
            m_agent = ral_venv_agent::type_id::create("m_agent", this);
        end
        m_agent.m_reg_blk = m_reg_blk;
        
        if ( m_adapter == null ) begin
            m_adapter = ral_venv_adapter::type_id::create("m_adapter", this);
        end
        
        m_reg_blk.default_map.set_sequencer(m_agent.m_sqr, m_adapter);
        m_reg_blk.set_auto_predict(1);

    endfunction: build_phase
    
endclass: ral_venv