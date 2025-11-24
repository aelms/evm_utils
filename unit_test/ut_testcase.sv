//-----------------------------------------------------------------------------
// Test: Act to exp series comparer ut_testcase
//
// Description:
//  Tests the inorder_losses_comparer with series of actual and expected
//  queue of simple sequence items (single byte).  Items are provided to
//  comparer either all exp first OR act/exp randomly interleaved (default)
//  - random exp series of 5-10 items with matching act.  Expect pass.
//  - random exp series of 5-10 items with first act rotated to back.  All exp 
//    sent first. Expect 2 errors on first act and on leftover act.
//  - random exp series of 5-10 items, no act.  Expect 1 error on check_phase()
//  - no exp, random act series of 5-10 items.  Expect 1 error on check_phase()
//  - fast compare.  2 queues of 10,000 items not matching.
//
//-----------------------------------------------------------------------------
class ut_testcase extends uvm_test;

    `uvm_component_utils( ut_testcase )

    // Test Environment
    ut_env                       m_env;

    function new( string name = "my_unit_test", uvm_component parent = null );
        super.new( name, parent );
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = ut_env::type_id::create("m_env", this);
        uvm_config_db#(uvm_object_wrapper)::set(this, "*.m_sqr.main_phase", "default_sequence", ut_random_sequence::get_type());
    endfunction: build_phase


    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this, "Test running");
        super.run_phase(phase);               
        m_env.m_field_edge_event.self_test();
        phase.drop_objection(this, "Test complete");
    endtask: run_phase

 
endclass : ut_testcase