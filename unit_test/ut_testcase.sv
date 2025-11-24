//-----------------------------------------------------------------------------
// Test: EVM Utilities unit tests
//
// Description:
// - Environment 
//  - RAL venv extension with a generic register block 
//  - RAL register logger
//  - 4 pairs of duts and comparers (in order lossless, in order lossy, out of order lossless, out of order lossy)  
// - Testcase
//  - Sequence of items direct to comparers and thru dut with optional losses and reordering
//  - Register reset sequence
//  - Register access sequence
//
//-----------------------------------------------------------------------------
class ut_testcase extends uvm_test;

    `uvm_component_utils( ut_testcase )

    ut_env               m_env;
    uvm_reg_hw_reset_seq m_reg_reset_seq;
    uvm_reg_access_seq   m_reg_access_seq;

    function new( string name = "my_unit_test", uvm_component parent = null );
        super.new(name, parent);
        uvm_report_server::set_server( evm_report_server::type_id::create("evm_report_server") );
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = ut_env::type_id::create("m_env", this);
        if( $test$plusargs("skip_cmp_test") ) begin
            `uvm_info( get_type_name(), "Comparer test skipped with +skip_cmp_test", UVM_NONE );
        end else begin
            uvm_config_db#(uvm_object_wrapper)::set(this, "*.m_ut_agt.m_sqr.main_phase", "default_sequence", ut_random_sequence::get_type());
        end
    endfunction: build_phase

    virtual task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        if( $test$plusargs("uvm_error") ) begin
            `uvm_error(get_type_name(), "Error from +uvm_error");
        end
        if( $test$plusargs("skip_ral_reset_test") ) begin
            `uvm_info( get_type_name(), "RAL reset test skipped with +skip_ral_reset_test", UVM_NONE );
        end else begin
            m_reg_reset_seq = uvm_reg_hw_reset_seq::type_id::create("m_reg_reset_seq");
            m_reg_reset_seq.model = m_env.m_reg_blk;
            m_reg_reset_seq.start(m_env.m_ral_agt.m_sqr);
        end

        if( $test$plusargs("skip_ral_access_test") ) begin
            `uvm_info(get_type_name(), "RAL access test skipped with +skip_ral_access_test", UVM_NONE)
        end else begin
            m_reg_access_seq = uvm_reg_access_seq::type_id::create("m_reg_access_seq");
            m_reg_access_seq.model = m_env.m_reg_blk;
            m_reg_access_seq.start(m_env.m_ral_agt.m_sqr);
        end
        phase.drop_objection(this);
    endtask: main_phase


    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        if( m_env.m_iol_cmp4lsy_dut.m_cmp.m_matched_item_cnt > 0 && 
            m_env.m_iol_cmp4lsy_dut.m_cmp.m_demoted_error_cnt != 1 ) begin
            `uvm_error(get_type_name(), $sformatf("Dropped %0d items but %0d errors reported", m_env.m_iolsy_dut.m_drop_item_cnt, m_env.m_iol_cmp4lsy_dut.m_cmp.m_demoted_error_cnt))
        end
        if( m_env.m_ool_cmp4oolsy_dut.m_cmp.m_matched_item_cnt > 0 && 
            m_env.m_ool_cmp4oolsy_dut.m_cmp.m_demoted_error_cnt != 1 ) begin
            `uvm_error(get_type_name(), $sformatf("Dropped %0d items but %0d errors reported", m_env.m_oolsy_dut.m_drop_item_cnt, m_env.m_ool_cmp4oolsy_dut.m_cmp.m_demoted_error_cnt))
        end
    endfunction: report_phase

 
endclass : ut_testcase