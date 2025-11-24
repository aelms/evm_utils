/** \brief Unit test register block 
 * 
 * Simple register block with 
 * - one 32-bit wide register at address 0
 * - one `MEM_RAL_BIT_WIDTH wide, `MEM_SIZE deep at address `MEM_SIZE 
 */
class ut_block extends uvm_reg_block;

    `uvm_object_utils(ut_block)

    ral_field_all_bits_set_clr_policy    m_absc_cov;
    ral_field_min_mid_max_policy         m_mmm_cov;
    ral_field_all_values_policy          m_av_cov;
    ral_field_five_ranges_policy#(0,255) m_fr_cov;

    rand ut_reg m_test_reg;
    uvm_mem     m_test_mem;

    function new(string name="ut_block");
        super.new(name, UVM_NO_COVERAGE);
        default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN );

        m_test_reg = ut_reg::type_id::create("m_test_reg");
        m_test_reg.configure(this);
        default_map.add_reg(m_test_reg, 0 );
        
        m_test_mem = new("m_test_mem", `MEM_SIZE, `MEM_RAL_BIT_WIDTH);
        m_test_mem.configure(this);
        default_map.add_mem(m_test_mem, `MEM_SIZE );
        
        lock_model();

        m_absc_cov = new(m_test_reg.eight_bits_rw);
        m_mmm_cov = new(m_test_reg.eight_bits_rw);
        m_av_cov = new(m_test_reg.eight_bits_rw);
        m_fr_cov = new(m_test_reg.eight_bits_rw);
    endfunction: new

    function void self_test();
        void'( m_test_reg.eight_bits_rw.predict(4) );
        m_absc_cov.sample(this);
        m_mmm_cov.sample(this);
        m_av_cov.sample(this);
        m_fr_cov.sample(this);
        if(m_absc_cov.policy_cg.get_inst_coverage() != (100.0/2) ) begin
            `uvm_error( get_type_name(), $sformatf("self_test(): Expected m_abs_cov to be %f%%, observed %f%%", (100.0/2), m_absc_cov.policy_cg.get_inst_coverage() ) );
        end
        if(int'( m_mmm_cov.policy_cg.get_inst_coverage() ) != int'(100.0/3) ) begin
            `uvm_error( get_type_name(), $sformatf("self_test(): Expected m_mmm_cov to be %f%%, observed %f%%", (100.0/3), m_mmm_cov.policy_cg.get_inst_coverage() ) );
        end
        if(m_av_cov.policy_cg.get_inst_coverage() != (100.0/256) ) begin
            `uvm_error( get_type_name(), $sformatf("self_test(): Expected m_av_cov to be %f%%, observed %f%%", (100.0/256), m_av_cov.policy_cg.get_inst_coverage() ) );
        end
        if(m_fr_cov.policy_cg.get_inst_coverage() != (100.0/5) ) begin
            `uvm_error( get_type_name(), $sformatf("self_test(): Expected m_fr_cov to be %f%%, observed %f%%", (100.0/5), m_fr_cov.policy_cg.get_inst_coverage() ) );
        end
    endfunction: self_test
    
endclass: ut_block
