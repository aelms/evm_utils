
/** \brief In-order, Lossless Actual to Expected Series Comparer
 * 
 * This class implements an series comparer policy with the following behaviour
 * - Actual to expected series items comparison is lossless and in-order
 * - Either of Actual or Expected can arrive first
 * - Match of first expected to first actual is a policy compliance
 * - Mismatch of first expected to first actual is reported as a UVM error
 *     - Actual item is compared to remaining expected items (if any).  If a match is found,
 *       it is probably that some expected items were lost.  The items up to and including the 
 *       match are added to the error message and removed from the expected stored items. This
 *       may allow the comparison to continue successfully, if there are no further act losses.
 *       Without this behaviour one lost actually will result in a mismatch for every actual
 *       following it.
 * - Any leftover items at the check phase is a policy violation, but reported directly in check_phase()
 */
class in_order_lossless_comparer extends series_comparer;
    
    `uvm_object_utils(in_order_lossless_comparer);

    extern function new( string name = "in_order_lossless_comparer");

    /** \brief Apply the comparer policy
     * 
     * If there is an actual and expected sequence item, remove and compare them
     *  Call policy_compliance on a match.
     *  Call policy_violation on a mismatch.
     * If there are other items (but there should not), call apply_policy(UNSPECIFIED). 
     */
    extern virtual protected function void apply_policy(item_type_e rx_si_type); 

    /** \brief Policy violation 
     * 
     * Start a uvm_error message with act, exp and get_miscompares().  Compare act to
     * remaining stored exp items.  If a match is found, discard stored exp up to and
     * including the match, and include the discarded items in the error message.
    */

    extern virtual protected function void policy_violation(uvm_sequence_item act, 
                                                            uvm_sequence_item exp, 
                                                            item_type_e       rx_si_type); 

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

endclass: in_order_lossless_comparer

function in_order_lossless_comparer::new( string name = "in_order_lossless_comparer" );
    super.new(name);
endfunction: new

function void in_order_lossless_comparer::apply_policy(item_type_e rx_si_type); 

    // Must be an actual and expected to compare
    if(act_q.size() && exp_q.size()) begin

        // Always remove first actual and expected
        uvm_sequence_item act = act_q.pop_front(); 
        uvm_sequence_item exp = exp_q.pop_front();

        // If the first actual and expected match, they comply to the policy
        // else, they violate the policy
        if( exp.compare(act,this) ) begin
            policy_compliance(act,exp,rx_si_type);
        end else begin
            policy_violation(act,exp,rx_si_type);
        end

        // Rerun apply_policy() if there are additional actual and expected. 
        if( act_q.size() && exp_q.size() ) begin
            apply_policy(UNSPECIFIED);
        end

    end

endfunction: apply_policy

function void in_order_lossless_comparer::policy_violation(uvm_sequence_item act, 
                                                          uvm_sequence_item exp, 
                                                          item_type_e       rx_si_type);

    // FAIL: Actual does not match first expected. Start error message with only first act and expected
    //       and cmp_msg to append compare of each exp queue member.
    // 
    //       If a match is found later in the queue, an error is still reported but flagged as an out
    //       of order or lossy match.
    string err_msg = $sformatf("policy_violation(): act (%s) does not match first exp (%s).  Miscompare: %s", 
                               act.convert2string(), exp.convert2string(), get_miscompares());
    string q_cmp_str;
                        
    foreach(exp_q[i]) begin

        if( exp_q[i].compare(act,this) ) begin
            // Match found after first.  Add the cmp_msg to the error message, remove all items up to and 
            // including the match from the expected queue and break
            err_msg = $sformatf("%s\n\texp (%s) matches act.  Discarding all previous exp as lost.", q_cmp_str, exp_q[i].convert2string() );
            exp_q = exp_q[i+1:$]; 
            break;
        end else if( ! m_fast_item_compare_en ) begin
            // Does not match, add it the q_cmp_str, and continue looking.  If a later match is
            // found, all these items will be discarded but will be included in the error msg
            // If a later match is not found, these items are not affected, and q_cmp_str is not needed.
            q_cmp_str = $sformatf("%s\n\texp (%s) does not match", q_cmp_str, exp_q[i].convert2string() );
        end

    end

    `uvm_error( get_type_name(), err_msg ); // Issue the error message

endfunction: policy_violation


function void in_order_lossless_comparer::policy_compliance(uvm_sequence_item act, 
                                                            uvm_sequence_item exp, 
                                                            item_type_e       rx_si_type);
    `uvm_info( get_type_name(), $sformatf("policy_compliance(): act (%s) matches exp", act.convert2string() ), UVM_MEDIUM);
endfunction: policy_compliance

function void in_order_lossless_comparer::check_phase();

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

function void in_order_lossless_comparer::reset_phase();
    `uvm_info( get_type_name(), $sformatf("reset_phase(): Deleting %0d act_q items, and %0d exp_q items", act_q.size(), exp_q.size()), UVM_HIGH);
    act_q.delete();
    exp_q.delete();
endfunction: reset_phase

