
/** \brief Actual and Expected Series of Sequence Items Comparer
 * 
 * Overview
 * --------
 * The uvm_comparer policy applies to the immediate comparison of two uvm_sequence_items.  This
 * class extends that to comparing two series of uvm_sequence_items provided to it asynchronously.  
 * The convention in these policies is:
 * - *expected* items describe the predicted correct design behaviour (reference model produced)
 * - *actual* items are the actual observed design behaviour (design monitor produced)
 *
 * This virtual class with pure virtual methods defines the base structure and is extended 
 * to implement a specific policy.  The inorder_loss_comparer follows the recommended behaviour.
 * 
 * Implementing this family as a uvm_comparer extension, that is not a component, provides the
 * flexibility to wrap it in any type of construct, including non-components.  The option to 
 * delegate messages to a component (and include hierachy) is available thru evm_report_delegation.svh.  
 * Conceptually, how two sequences of items is compared is a logical extension of how two individual 
 * items is compared.
 * 
 * This class changes two base uvm_comparer behaviours.  The first is that "lhs"/"rhs" in
 * miscompare messages are replaced with "exp"/"act" respectively for more meaningful messages.
 * The second adds a fast comparison method mode for policies that expect a large number of 
 * mismatches and do not require detailed mismatch information.
 *   
 * Details
 * -------
 * The following methods in this class are not pure virtual provide the public interface and 
 * functionality that is not policy specific: 
 * - write_act(uvm_sequence_item si): Store an actual item and call apply_policy(ACTUAL)
 * - write_exp(uvm_sequence_item_si): Store an expected item and call apply_policy(EXPECTED)
 * 
 * The pure virtual methods in this class *must* be implemented in policy-specific extensions.
 * and they *should* follow these recommendations:
 * 
 * 1) Comparisons performed using uvm_sequence_item::compare()
 *      - expected item used as left-hand-side caller 
 *      - actual item used as uvm_sequence_item rhs (right-hand-side) argument
 *      - provide self (this) as uvm_comparer comparer argument
 * 
 *      Example: exp.compare(act,this)
 * 
 *      Note: This allows the compare() to be customized in the expected item's do_compare() 
 *            and mismatch messages to be customized in the act_exp_compare::get_miscompares() 
 *            directly,
 * 
 * 2) Report uvm_error messages on a policy violation directly.  
 *   This is different than the uvm_comparer to uvm_sequence_item::compare() behaviour that only 
 *   provides return status and defers issuing uvm_messages to higher level components.  This 
 *   recommendation is made as compliance or violation is a fundamental part of each policy.  
 *   In addtion, the policies can have multiple items stored and receipt of a new item can trigger 
 *   multiple, delayed checks resulting in any combination  and number of inconclusive, violation, 
 *   and compliance results on the new and stored items.  This is not easily communicated to 
 *   an upper layer 
 * 
 * 3) Provide uvm_comparer::get_miscompares() in miscompare messages
 * 
 * 4) Use uvm_sequence_item::convert2string() to display items in messages.  A single line, 
 *    grep'able strings, instead of the long, difficult to grep table is recommended.  This
 *    can be implemented using single_line_printer as follows:
 * 
 * \code
 * 
 *  virtual function string convert2string();
 *      return sprint( single_line_printer::get_default() );
 *  endfunction: convert2string
 * 
 * \endcode
 *
 */
virtual class series_comparer extends uvm_comparer;

    protected uvm_sequence_item act_q[$];
    protected uvm_sequence_item exp_q[$];

    protected uvm_report_object m_report_object;  ///< Delegate report object. See evm_report_delegation.svh

    protected boolean_t         m_fast_item_compare_en = FALSE; ///< Enable fast item compare mode.  See set_fast_item_compare_mode()
    local     int unsigned      m_original_threshold;    ///< Stores original threshold on enabling fast compare mode
    local     int unsigned      m_original_show_max;     ///< Stores original show_max on enabling fast compare mode
    local     int unsigned      m_original_verbosity;    ///< Stores original verbosity on enabling fast compare mode

    typedef enum { ACTUAL,       ///< Actual item
                   EXPECTED,     ///< Expected item                   
                   UNSPECIFIED   ///< Unspecified item type (e.g. on recursive calls to apply_policy)
                 } item_type_e;  ///< Item type used to indicate the type that triggered an action

    extern function              new(string name = "series_comparer");

    /** \brief Write actual item
     * 
     * Adds si to the back of act_q and calls apply_policy(ACTUAL).
     */
    extern virtual function void write_act(uvm_sequence_item si);

    /** \brief Write expected
     * 
     * Adds si to the back of exp_q and calls apply_policy(EXPECTED).
     */
    extern virtual function void write_exp(uvm_sequence_item si);

    /** \brief Enable/Disable fast compare mode
     *      
     * fast_compare mode modifies the default uvm_comparer behaviour of comparing two
     * uvm_sequence_item to be more efficient.  This is useful for a policy where a large
     * number of items are expected to mismatch and the mismatch side-effects are not 
     * important.  An example would be an environment where design and verification are
     * not initially in sync until the first successful match.
     *
     * When enabled, the following changes occur to the compare() behaviour.  The threshold
     * is set to 1, meaning a compare fails on the first mismatching field.  The original 
     * threshold is stored and restored on enabling and disabling fast compare mode respectively.
     * The miscompares string is not generated by the compare_field(), compare_field_int(), 
     * compare_field_real(), and compare_string() methods.
     *  
     * Note: Per class description recommendation 1, the series_comparer must be used as the
     *       argument to uvm_sequence_item::compare().
     *
     * Default is disabled (false).
    */
     extern virtual function void set_fast_item_compare_mode(boolean_t fast_item_compare_en);

    /** \brief Apply policy
     * 
     * \param[in] rx_si_type: UVM sequence_item type that caused apply_policy() to be called  
     * 
     * Compares the stored sequence items in a policy specific manner.  The rx_si_type indicates 
     * which of actual, expected (or unspecified) was received and initiated the queue comparison.
     * 
     * The outcome of a compare() mismatch is policy specific.  For example, with the in-order 
     * and lossless policy, a miscompare is an immediate violation.  But if the policy allows 
     * out-of-order matches, a mismatch is not a violation as the expected may not have been 
     * created yet.  
     * 
     * If policy violation or compliance cannot be determined, the item should be left in the
     * appropriate queue for future comparison.
     *
     * When a policy violation or compliance definitively occurs, handle_policy_violation() or 
     * handle_policy_compliance() should be called.   The act and exp (if applicable) sequence 
     * items that apply to the violation should be removed from storage IF they are no longer
     * required for future checks.
     * 
     * 
     */
    pure virtual protected function void apply_policy(item_type_e rx_si_type); 
    
    /** \brief Handle Policy Violation
     * 
     * \param[in] act       : Actual uvm_sequence_item violating the policy (may be empty)
     * \param[in] exp       : Expected uvm_sequence_item violating the policy (may be empty)
     * \param[in] rx_si_type: Received uvm_sequence_item type that resulted in the policy violation
     * 
     * This method should follow the recommendations in the series_comparer description.
     * 
     * Called when a policy violation has been determined to have occured in apply_policy().  
     * Recommended to create an issue a uvm error message but can be defered to another method or
     * object, in an extension specific manner.
     * Specific policies may perform further checks on the stored items.  One example, is on
     * reception of an act item that does not match the first exp by the in-order, lossless policy.  
     * This can occur when act items were not created (i.e. unexpected discard).  
     * 
     * Providing up to 1 act and exp item on a policy violation will cover the majority of policies.  All
     * of apply_policy(), policy_violation() and policy_compliance() are pure virtual. So any policy
     * that requires more than 1 act/exp item can define and implement a custom method instead of 
     * policy_violation().
     */
    pure virtual protected function void policy_violation(uvm_sequence_item act, 
                                                          uvm_sequence_item exp, 
                                                          item_type_e       rx_si_type); 

    /** \brief Handle Policy Compliance
     * 
     * \param[in] act       : Actual uvm_sequence_item(s) complying to the policy (may be empty)
     * \param[in] exp       : Expected uvm_sequence_item(s) complying to the policy (may be empty)
     * \param[in] rx_si_type: Received uvm_sequence_item type that resulted in the policy compliance
     * 
     * This method should follow the recommendations in the series_comparer description.
     * 
     * Called when a policy compliance has been determined to have occured in apply_policy().  
     * 
     */
    pure virtual protected function void policy_compliance(uvm_sequence_item act, 
                                                           uvm_sequence_item exp, 
                                                           item_type_e       rx_si_type); 

    /** \brief Check Phase
     * 
     * Implement in an extension to implement the policy executed at the check_phase.  Can 
     * be called by a uvm_component::check_phase() task.  It is expected that all actual and 
     * expected items have been provided when called so this task should apply the policy check
    */
    pure virtual           function void check_phase();

    /** \brief Report Phase
     * 
     * Implement in an extension to implement the policy executed at the report_phase.  Can 
     * be called by a uvm_component::report_phase() task.  
    */
    pure virtual           function void report_phase();

    /** \brief Reset Phase
     * 
     * Implement in an extension to implement the policy executed at the reset_phase.  Can 
     * be called by a uvm_component::reset_phase() task.
     */
    pure virtual           function void reset_phase();

    
    // ********************************************************************************
    // This section provides optional delegation of UVM messages to a uvm_report object
    // See evm_report_delegation.svh
    virtual function void uvm_set_report_object(uvm_report_object report_object);
        m_report_object=report_object;
    endfunction
    
    function uvm_report_object uvm_get_report_object();
        if( m_report_object ) begin
            return m_report_object;
        end else begin
            return uvm_coreservice_t::get().get_root();
        end
    endfunction
    
    `EVM_REPORT_DELEGATION_FUNCTIONS
    // ********************************************************************************
    
    /** \brief Get miscompare string 
     * 
     * The default uvm_comparer::get_miscompares() returns the results of the last executed
     * compare() using this uvm_comparer.  By default this is all the mismatching fields with 
     * the field name and "lhs"/"rhs" identify the values.
     * 
     * This extension replaces "lhs " and "rhs " with "exp " and "act "" respectively, for 
     * more meaningful msg's in this context.
     * 
    */
    extern virtual function string get_miscompares();


    // ********************************************************************************
    /** \brief Comparison methods
     * 
     * Adds fast-compare mode functionality to the base uvm_comparer comparison methods.
     */
    extern virtual function bit compare_field (string name, 
                                               uvm_bitstream_t lhs, 
                                               uvm_bitstream_t rhs, 
                                               int size,
                                               uvm_radix_enum radix=UVM_NORADIX);

    extern virtual function bit compare_field_int (string name, 
                                                   uvm_integral_t lhs, 
                                                   uvm_integral_t rhs, 
                                                   int size,
                                                   uvm_radix_enum radix=UVM_NORADIX); 

    extern virtual function bit compare_field_real (string name, 
                                                    real lhs, 
                                                    real rhs);

    extern virtual function bit compare_string (string name,
                                                string lhs,
                                                string rhs);
    // ********************************************************************************
                                             

endclass: series_comparer

function series_comparer::new(string name = "series_comparer");
    super.new(name);
endfunction: new

function void series_comparer::write_act(uvm_sequence_item si);
    act_q.push_back(si);
    apply_policy(ACTUAL);
endfunction: write_act

function void series_comparer::write_exp(uvm_sequence_item si);
    exp_q.push_back(si);
    apply_policy(EXPECTED);
endfunction: write_exp

function void series_comparer::set_fast_item_compare_mode(boolean_t fast_item_compare_en);
    if(m_fast_item_compare_en != fast_item_compare_en) begin
        m_fast_item_compare_en = fast_item_compare_en;
        if( m_fast_item_compare_en ) begin
            m_original_threshold = get_threshold();
            m_original_show_max  = get_show_max();
            m_original_verbosity = get_verbosity();
            set_threshold( 1 );
            set_show_max( 1 );
            set_verbosity( UVM_DEBUG + 1 );
        end else begin
            set_threshold( m_original_threshold );
            set_show_max( m_original_show_max );
            set_verbosity( m_original_verbosity );
        end
    end 
endfunction: set_fast_item_compare_mode 

function string series_comparer::get_miscompares();
    string miscmp_str = super.get_miscompares(); 
    miscmp_str = text::replace( miscmp_str, "lhs ", "exp " );
    miscmp_str = text::replace( miscmp_str, "rhs ", "act " );
    return miscmp_str;
endfunction: get_miscompares

function bit series_comparer::compare_field (string name, 
                                             uvm_bitstream_t lhs, 
                                             uvm_bitstream_t rhs, 
                                             int size,
                                             uvm_radix_enum radix=UVM_NORADIX);
                                            
    if( m_fast_item_compare_en ) begin
        uvm_bitstream_t mask;
  
        if(size <= 64)
            return compare_field_int(name, lhs, rhs, size, radix);
  
        mask = -1;
        mask >>= (UVM_STREAMBITS-size);
        if((lhs & mask) !== (rhs & mask)) begin
            set_result( 1 );
            return 0;
        end
    end else begin
        return super.compare_field(name, lhs, rhs, size, radix);
    end

    return 1;

endfunction: compare_field

function bit series_comparer::compare_field_int (string name, 
                                                 uvm_integral_t lhs, 
                                                 uvm_integral_t rhs, 
                                                 int size,
                                                 uvm_radix_enum radix=UVM_NORADIX); 
    if( m_fast_item_compare_en ) begin
        logic [63:0] mask;
  
        mask = -1;
        mask >>= (64-size);
        if((lhs & mask) !== (rhs & mask)) begin
            set_result( 1 );
            return 0;
        end
    end else begin
        return super.compare_field_int(name, lhs, rhs, size, radix);
    end 
    return 1;

endfunction: compare_field_int

function bit series_comparer::compare_field_real (string name, 
                                                  real lhs, 
                                                  real rhs);
    if( m_fast_item_compare_en ) begin
        if( lhs != rhs ) begin
            set_result( 1 );
            return 0;
        end
    end else begin
        return super.compare_field_real(name, lhs, rhs);
    end 
    return 1;

endfunction: compare_field_real

function bit series_comparer::compare_string (string name,
                                              string lhs,
                                              string rhs);
    if( m_fast_item_compare_en ) begin
        if( lhs != rhs ) begin
            set_result( 1 );
            return 0;
        end
    end else begin
        return super.compare_string(name, lhs, rhs);
    end 
    return 1;
endfunction: compare_string