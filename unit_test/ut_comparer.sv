/** \brief Unit test comparer
 * 
 * Adds ability to demote errors into info, count demotions, count matches, and report matches.
 */
`define ut_cmp_class(BASE_CMP_T) \
class ut_``BASE_CMP_T extends BASE_CMP_T; \
    `uvm_object_utils(ut_``BASE_CMP_T) \
    boolean_t    m_demote_error = FALSE; \
    int unsigned m_demoted_error_cnt = 0; \
    int unsigned m_matched_item_cnt = 0; \
    function new(string name = "ut_cmp_``BASE_CMP_T"); \
        super.new(name); \
    endfunction: new \
    virtual function void uvm_report_error(string   id, \
                                           string   message, \
                                           int      verbosity                =  UVM_NONE, \
                                           string   filename                 =  "", \
                                           int      line                     =  0, \
                                           string   context_name             =  "", \
                                           bit      report_enabled_checked   =  0 \
                                          ); \
        if(m_demote_error) begin \
            super.uvm_report_info(id,message,verbosity,filename,line,context_name,report_enabled_checked); \
            m_demoted_error_cnt++; \
        end else begin \
            super.uvm_report_error(id,message,verbosity,filename,line,context_name,report_enabled_checked); \
        end \
    endfunction: uvm_report_error \
    virtual function void policy_compliance(uvm_sequence_item act, \
                                            uvm_sequence_item exp, \
                                            item_type_e       rx_si_type); \
        super.policy_compliance(act, exp, rx_si_type); \
        m_matched_item_cnt++; \
    endfunction: policy_compliance \
    virtual function void report_phase(); \
        super.report_phase(); \
        `uvm_info(get_type_name(), $sformatf("Matched %0d items", m_matched_item_cnt ), UVM_NONE) \
    endfunction: report_phase \
endclass: ut_``BASE_CMP_T

`ut_cmp_class(in_order_lossless_comparer)
`ut_cmp_class(out_of_order_lossless_comparer)




