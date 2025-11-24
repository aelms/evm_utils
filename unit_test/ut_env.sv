/** \brief Unit test environment */
class ut_env extends evm_ral_venv#(chip_reg_block);

    typedef evm_series_comparer_analysis_imp_if#(ut_sequence_item, ut_evm_in_order_lossless_comparer) iol_cmp_t;
    typedef evm_series_comparer_analysis_imp_if#(ut_sequence_item, ut_evm_out_of_order_lossless_comparer) ool_cmp_t;

    `uvm_component_utils(ut_env)

    evm_ral_reg_logger  m_reg_logger;         ///< RAL register access logger

    ut_agent            m_ut_agt;             ///< Sequence of items

    ut_design_queue     m_iol_dut;            ///< In-order lossless dut
    iol_cmp_t           m_iol_cmp4iol_dut;    ///< In-order lossless comparer

    ut_design_queue     m_iolsy_dut;          ///< In-order lossy dut
    iol_cmp_t           m_iol_cmp4lsy_dut;    ///< In-order lossless comparer

    ut_design_queue     m_ool_dut;            ///< Out-of-order lossless dut
    ool_cmp_t           m_ool_cmp4ool_dut;    ///< Out-of-order lossless comparer

    ut_design_queue     m_oolsy_dut;          ///< Out-of-order lossy dut
    ool_cmp_t           m_ool_cmp4oolsy_dut;  ///< Out-of-order lossless comparer

    function new(string name, uvm_component parent);
        ut_report_catcher rc; 
        super.new( name, parent );
        rc = ut_report_catcher::type_id::create("rc");
        uvm_report_cb::add( null, rc );
    endfunction: new

    virtual function void build_m_reg_blk();
        m_reg_blk.build( .base_addr(0) );
    endfunction: build_m_reg_blk

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_reg_logger = evm_ral_reg_logger::type_id::create("m_reg_logger", this);

        m_ut_agt = ut_agent::type_id::create("m_ut_agt", this);

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

    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        m_reg_logger.connect(m_reg_blk);

        // Inorder lossless comparer connections
        m_ut_agt.m_drv.item_ap.connect(m_iol_dut.input_imp);
        m_ut_agt.m_drv.item_ap.connect(m_iol_cmp4iol_dut.m_exp_imp);
        m_iol_dut.output_ap.connect(m_iol_cmp4iol_dut.m_act_imp);

        // Inorder lossy comparer connections
        m_ut_agt.m_drv.item_ap.connect(m_iolsy_dut.input_imp);
        m_ut_agt.m_drv.item_ap.connect(m_iol_cmp4lsy_dut.m_exp_imp);
        m_iolsy_dut.output_ap.connect(m_iol_cmp4lsy_dut.m_act_imp);

        // Out-of-order lossless comparer connections
        m_ut_agt.m_drv.item_ap.connect(m_ool_dut.input_imp);
        m_ut_agt.m_drv.item_ap.connect(m_ool_cmp4ool_dut.m_exp_imp);
        m_ool_dut.output_ap.connect(m_ool_cmp4ool_dut.m_act_imp);

        // Out-of-order lossy comparer connections
        m_ut_agt.m_drv.item_ap.connect(m_oolsy_dut.input_imp);
        m_ut_agt.m_drv.item_ap.connect(m_ool_cmp4oolsy_dut.m_exp_imp);
        m_oolsy_dut.output_ap.connect(m_ool_cmp4oolsy_dut.m_act_imp);

    endfunction: connect_phase


endclass: ut_env