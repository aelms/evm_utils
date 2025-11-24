/** \brief Out-of-order, Lossless Actual to Expected Series Comparer
 * 
 * This class implements an series comparer policy with the following behaviour
 * - Actual to expected series items comparison is lossless and out-of-order
 * - Either of Actual or Expected can arrive first
 * - First match of expected to actual is policy compliance
 * - Any leftover items at the check phase is a policy violation, but reported directly in check_phase()
 * - m_fast_item_compare_en=TRUE is default as miscompares are expected with reordering.
 */
class out_of_order_lossless_comparer extends series_comparer;
    
    `uvm_object_utils(out_of_order_lossless_comparer);

    extern function new( string name = "out_of_order_lossless_comparer");

    /** \brief Apply the comparer policy
     * 
     * Starting with the first act and exp, compare the items.  If there is a match,
     * remove them, call policy_compliance, and break.  If there is not a match, continue to 
     * the next exp (if act received) or next act (if exp received), until a match or end
     * of items.
     * 
     */
    extern virtual protected function void apply_policy(item_type_e rx_si_type); 

    /** \brief Policy violation 
     * 
     * Empty implementation.  This policy only reports violation in check_phase() for any leftover items.
     *
    */

    virtual protected function void policy_violation(uvm_sequence_item act, 
                                                     uvm_sequence_item exp, 
                                                     item_type_e       rx_si_type);
    endfunction: policy_violation                                                   

   /** \brief Policy compliance 
     * 
     * Issue a UVM_MEDIUM message indicating act matches exp.
     */
    extern virtual protected function void policy_compliance(uvm_sequence_item act, 
                                                             uvm_sequence_item exp, 
                                                             item_type_e       rx_si_type); 

    /** \brief Check Phase
     * 
     * If there are any remaining act and/or exp, report a single UVM error messages error with the remaining items.
     */
    extern virtual           function void check_phase();

    /** \brief Report Phase */
    virtual           function void report_phase();
    endfunction: report_phase


    /** \brief Reset Phase 
     * 
     * Delete actual and expected queue contents with non-error message.
    */
    extern virtual            function void reset_phase();

endclass: out_of_order_lossless_comparer

function out_of_order_lossless_comparer::new( string name = "out_of_order_lossless_comparer" );
    super.new(name);
    set_fast_item_compare_mode(TRUE);
endfunction: new

function void out_of_order_lossless_comparer::apply_policy(item_type_e rx_si_type); 

    int act_size = act_q.size();
    int exp_size = exp_q.size();

    int act_idx = 0;
    int exp_idx = 0;

    uvm_sequence_item act; 
    uvm_sequence_item exp;

    while( act_idx < act_size && exp_idx < exp_size ) begin

        act = act_q[act_idx];
        exp = exp_q[exp_idx];

        if( exp.compare(act,this) ) begin
            // Match found.  Remove the matched actual and expected, call policy_compliance
            act_q.delete(act_idx);
            exp_q.delete(exp_idx);
            policy_compliance(act,exp,rx_si_type);
            break;
        end else begin
            // No match, continue to next expected (if actual received) or next actual (if expected received)
            if(rx_si_type == ACTUAL) begin
                exp_idx++;
            end else begin
                act_idx++;
            end
        end

    end

endfunction: apply_policy


function void out_of_order_lossless_comparer::policy_compliance(uvm_sequence_item act, 
                                                                uvm_sequence_item exp, 
                                                                item_type_e       rx_si_type);
    `uvm_info( get_type_name(), $sformatf("policy_compliance(): act (%s) matches exp", act.convert2string() ), UVM_MEDIUM);
endfunction: policy_compliance

function void out_of_order_lossless_comparer::check_phase();

    if(act_q.size() || exp_q.size() ) begin
        string err_msg = $sformatf("check_phase(): Leftover sequence_items (%0d act, %0d exp): ", act_q.size(), exp_q.size() );
        foreach(act_q[i]) begin
            err_msg = $sformatf("%s\n\tact: %s",err_msg,act_q[i].convert2string());
        end
        foreach(exp_q[i]) begin
            err_msg = $sformatf("%s\n\texp: %s",err_msg,exp_q[i].convert2string());            
        end
        `uvm_error( get_type_name(), err_msg );
    end

endfunction: check_phase

function void out_of_order_lossless_comparer::reset_phase();
    `uvm_info( get_type_name(), $sformatf("reset_phase(): Deleting %0d act_q items, and %0d exp_q items", act_q.size(), exp_q.size()), UVM_HIGH);
    act_q.delete();
    exp_q.delete();
endfunction: reset_phase

