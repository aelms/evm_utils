/** \brief Unit test environment */
class ut_env extends uvm_env;

    typedef series_comparer_analysis_imp_if#(ut_sequence_item, ut_in_order_lossless_comparer) iol_cmp_t;
    typedef series_comparer_analysis_imp_if#(ut_sequence_item, ut_out_of_order_lossless_comparer) ool_cmp_t;
    
    `uvm_component_utils(ut_env)

    ut_agent            m_agt;                ///< Sequence of items 
 
    ut_design_queue     m_iol_dut;            ///< In-order lossless dut
    iol_cmp_t           m_iol_cmp4iol_dut;    ///< In-order lossless comparer

    ut_design_queue     m_iolsy_dut;          ///< In-order lossy dut 
    iol_cmp_t           m_iol_cmp4lsy_dut;    ///< In-order lossless comparer

    ut_design_queue     m_ool_dut;            ///< Out-of-order lossless dut
    ool_cmp_t           m_ool_cmp4ool_dut;    ///< Out-of-order lossless comparer

    ut_design_queue     m_oolsy_dut;          ///< Out-of-order lossy dut
    ool_cmp_t           m_ool_cmp4oolsy_dut;  ///< Out-of-order lossless comparer
    
    ut_block            m_block;
    ut_field_edge_event m_field_edge_event;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_agt = ut_agent::type_id::create("m_agt", this);

        // In-order lossless comparer components
        m_iol_dut = ut_design_queue::type_id::create("m_iol_dut", this); 
        m_iol_cmp4iol_dut = iol_cmp_t::type_id::create("m_iol_cmp4iol_dut", this);

        // In-order lossy comparer components
        m_iolsy_dut = ut_design_queue::type_id::create("m_iolsy_dut", this); 
        m_iolsy_dut.m_wait_for_last  = TRUE; // Configure to wait for last item before sending out
        m_iolsy_dut.m_drop_item_cnt  = 1;    // Configure to drop 1 item; guarenteed to cause 1 error in comparer
        m_iol_cmp4lsy_dut = iol_cmp_t::type_id::create("m_iol_cmp4lsy_dut", this);
        m_iol_cmp4lsy_dut.m_cmp.m_demote_error = TRUE;

        // Out-of-order lossless comparer components
        m_ool_dut = ut_design_queue::type_id::create("m_ool_dut", this); 
        m_ool_dut.m_wait_for_last  = TRUE; // Configure to wait for last item before sending out
        m_ool_dut.m_reorder_items  = TRUE; // Configure to reorder items
        m_ool_cmp4ool_dut = ool_cmp_t::type_id::create("m_ool_cmp4ool_dut", this);

        // Out-of-order lossy comparer components
        m_oolsy_dut = ut_design_queue::type_id::create("m_oolsy_dut", this);
        m_oolsy_dut.m_wait_for_last = TRUE; // Configure to wait for last item before sending out
        m_oolsy_dut.m_reorder_items = TRUE; // Configure to reorder items
        m_oolsy_dut.m_drop_item_cnt = 1;    // Configure to drop 1 item; guarenteed to cause 1 error in comparer
        m_ool_cmp4oolsy_dut = ool_cmp_t::type_id::create("m_ool_cmp4oolsy_dut", this);
        m_ool_cmp4oolsy_dut.m_cmp.m_demote_error = TRUE;

        m_block    = ut_block::type_id::create("m_block", this);
        m_field_edge_event = ut_field_edge_event::type_id::create("m_field_edge_event", this);

        m_field_edge_event.connect( m_block.m_test_reg.one_bit_rw );

    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Inorder lossless comparer connections
        m_agt.m_drv.item_ap.connect(m_iol_dut.input_imp);
        m_agt.m_drv.item_ap.connect(m_iol_cmp4iol_dut.m_exp_imp);
        m_iol_dut.output_ap.connect(m_iol_cmp4iol_dut.m_act_imp);

        // Inorder lossy comparer connections
        m_agt.m_drv.item_ap.connect(m_iolsy_dut.input_imp);
        m_agt.m_drv.item_ap.connect(m_iol_cmp4lsy_dut.m_exp_imp);
        m_iolsy_dut.output_ap.connect(m_iol_cmp4lsy_dut.m_act_imp);

        // Out-of-order lossless comparer connections
        m_agt.m_drv.item_ap.connect(m_ool_dut.input_imp);
        m_agt.m_drv.item_ap.connect(m_ool_cmp4ool_dut.m_exp_imp);
        m_ool_dut.output_ap.connect(m_ool_cmp4ool_dut.m_act_imp);        

        // Out-of-order lossy comparer connections
        m_agt.m_drv.item_ap.connect(m_oolsy_dut.input_imp);
        m_agt.m_drv.item_ap.connect(m_ool_cmp4oolsy_dut.m_exp_imp);
        m_oolsy_dut.output_ap.connect(m_ool_cmp4oolsy_dut.m_act_imp);        

    endfunction: connect_phase

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        if( m_iol_cmp4lsy_dut.m_cmp.m_demoted_error_cnt != 1 ) begin
            `uvm_error(get_type_name(), $sformatf("Dropped %0d items but %0d errors reported", m_iolsy_dut.m_drop_item_cnt, m_iol_cmp4lsy_dut.m_cmp.m_demoted_error_cnt))
        end
        if( m_ool_cmp4oolsy_dut.m_cmp.m_demoted_error_cnt != 1 ) begin
            `uvm_error(get_type_name(), $sformatf("Dropped %0d items but %0d errors reported", m_oolsy_dut.m_drop_item_cnt, m_ool_cmp4oolsy_dut.m_cmp.m_demoted_error_cnt))
        end
    endfunction: report_phase

endclass: ut_env