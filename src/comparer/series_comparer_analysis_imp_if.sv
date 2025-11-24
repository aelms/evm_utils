`uvm_analysis_imp_decl(_act_imp);
`uvm_analysis_imp_decl(_exp_imp);

/** \brief Series comparer with uvm_analysis_imp interface.
 *
 * UVM component extension that wraps a series comparer in a uvm_component and provides
 * an analysis port interface and phase tasks.
 */
class series_comparer_analysis_imp_if#( type ITEM_T = uvm_sequence_item, type CMP_T = series_comparer ) extends uvm_component;

    typedef series_comparer_analysis_imp_if#(ITEM_T, CMP_T) this_type_t;

    `uvm_object_param_utils( this_type_t );

    `uvm_type_name_decl( $sformatf( "series_comparer_analysis_imp_if(%s, %s)", ITEM_T::type_name(), CMP_T::type_name() ) )

    uvm_analysis_imp_act_imp#(ITEM_T, this_type_t) m_act_imp; ///< actual sequence item analysis port
    uvm_analysis_imp_exp_imp#(ITEM_T, this_type_t) m_exp_imp; ///< expected sequence item analysis port

    CMP_T m_cmp; ///< comparer

    function new(string name = "series_comparer_analysis_imp_if", uvm_component parent = null);
        super.new(name, parent);
        m_cmp = CMP_T::type_id::create("m_cmp", this);
        m_cmp.uvm_set_report_object(this);
        m_act_imp = new("m_act_imp", this);
        m_exp_imp = new("m_exp_imp", this);
    endfunction: new
    
    virtual task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        m_cmp.reset_phase();
    endtask: reset_phase
    
    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        m_cmp.check_phase();
    endfunction: check_phase

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        m_cmp.report_phase();
    endfunction: report_phase

    virtual function void write_act_imp(ITEM_T item);
        m_cmp.write_act(item);
    endfunction: write_act_imp  

    virtual function void write_exp_imp(ITEM_T item);
        m_cmp.write_exp(item);
    endfunction: write_exp_imp  

endclass: series_comparer_analysis_imp_if
    