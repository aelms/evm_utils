
/** \brief RAL field coverage policy
 * 
 * Overview
 * --------
 * This class defines the structure for a family of coverage policies that are applied
 * to the value of a uvm_reg_field.  A coverage policy implements a coverage group with bins that 
 * define *WHAT* coverage is desired for the field.  
 * 
 * The following coverage policies are implemented in this file:
 * - ral_field_all_bits_set_clr_policy : Cover all field bits 0 and 1 for UP TO 32-bits
 * - ral_field_min_mid_max_policy      : Cover field 0, 1 : max-1, max
 * - ral_field_all_values_policy       : Cover all field values from 0 to max-1
 * - ral_field_five_ranges_policy      : Cover min, {min+1:reset-1}, reset, {reset+1:max-1}, max
 * 
 * *HOW and WHEN* the coverage is collected is controlled by a seperate object.  The ral_field_cov_collector
 * provides this as a register callbak, parameterized on the policy, with coverage collected on a 
 * FRONTDOOR read.  The intention is that any policy can be combined with any collector to create 
 * appropriate coverage for most register fields and desired coverage goals.
 * 
 * Other classes can collect coverage directly by calling the policies sample() function at the 
 * appropriate time.
 * 
 * Details
 * -------
 * System Verilog has a couple of restrictions on coverage groups that effected the implementation of 
 * the RAL coverage policy and collector classes.  First, embedded (class) coverage groups MUST be
 * instantiated in their class constructor.  Second, coverage group extension has been added in 
 * IEEE-1800-2023 but does not have widespread support.
 * 
 * This requires the coverage policy to create the coverage group in its constructor and to know 
 * the field being covered as the coverage group depends on this.  This in turn requires the field
 * as a constructor argument and the coverage policy cannot be a uvm_object, and is therefore a
 * uvm_void extension.  The inability to extend coverage groups means the generic base policy cannot 
 * define or interact with a coverage group as every extension will have its own, unique coverage 
 * group for its policy.  
 * 
 * The base policy provides the generic members and methods that can be extended to create a 
 * coverage group unique to the uvm_ral_field and policy, and allow the collector classes
 * to initiate coverage collection on the policy.  The intent is that any generic policy and collector
 * can be combined to provide basic field coverage, collected at the appropriate time.
 * 
 * The coverage group constructor, coverage group sample function, and policy sample function are 
 * defined in a way that allows this.   The following example shows the generic implementation. 
 * There are cases where coverage on the single value returned by uvm_ral_field::get() is not sufficient.
 * A handle to the coverage collector is also provided in the sample function BUT it should be noted 
 * that using this will create a policy-collector pair that can only be used together.
 * 
 * \code
 * 
 *      function new(uvm_reg_field field,
 *                   string        inst_suffix = "");        
 *          super.new(field,inst_suffix); 
 *          m_policy_type = "my_policy";
 *          policy_cg = new( get_fld_max(), cg_name() );
 *      endfunction
 *   
 *      virtual function void sample(uvm_object collector);
 *         policy_cg.sample( m_field.get() );
 *      endfunction
 * 
 *      covergroup policy_cg (uvm_reg_data_t field_max, string name) with function sample(uvm_reg_data_t value);
 *       
 *          option.per_instance = 1;
 *          option.name = name;
 *          
 *          // Policy specific bins on value....
 *
 * \endcode
 * 
 */
virtual class ral_field_coverage_policy extends uvm_void;

    protected uvm_reg_field m_field;          ///< Field being covered
    protected string        m_policy_type;    ///< Policy type, used in cg_name()
    protected string        m_inst_suffix;    ///< Optional per-instance unique suffix used in cg_name() 

    `uvm_type_name_decl("ral_field_coverage_policy")

    /** \brief Constructor
     * 
     * Extensions should set the m_policy_type, check if the given field is appropriate for the
     * policy if there are requirements such as a minimum field width, and create the policy_cg.
     */
    function new(
                 uvm_reg_field field,             ///< field being covered
                 string        inst_suffix = ""   ///< optional per-instance suffix added 
                );
        m_field = field;
        m_inst_suffix = inst_suffix;
    endfunction: new

    /** \brief Sample function
     * 
     * The sample function must be overridden in extensions and should call
     * the policy coverage group(s) sample function with the appropriate values.
     * 
     * The policy has access to the field being covered, and thru it, can access
     * the field's current value and _any_ object in the RAL hierarchy.  In addition
     * the collector object allows collection of additional non-ral informaiton
     * in a policy-collector specific manner. 
     * 
     */
    pure virtual function void sample(uvm_object collector);

    /*  \brief Coverage group name
     * 
     * Constructs the coverage group name as: <field_name>_<field_size>_n_bits_<m_policy_type><inst_suffix>
    */
    protected virtual function string cg_name();
        return $sformatf("%s_%0d_n_bits_%s%s",m_field.get_name(), m_field.get_n_bits(), m_policy_type, m_inst_suffix);
    endfunction: cg_name

    /*  \brief Field maximum value
     * 
     * Returns the field's maximum value based on its width.  This also equates to its bit 
     * mask, independant from its position in the register. 
    */
    protected virtual function uvm_reg_data_t get_fld_max();
        return ( uvm_reg_data_t'(1) << m_field.get_n_bits() ) - 1;
    endfunction: get_fld_max

endclass: ral_field_coverage_policy

/** \brief RAL field all bits set and clr policy
 * 
 * This RAL field coverage policy has the coverage goal that each bit in a field has been
 * sampled 0 / 1, independantly of the value of any other bits.
 * 
 * It is intended to be used on control and status fields that are too large for all values
 * to be covered.  It should also be used instead of min/mid/max where the minimum and 
 * maximum values do not have special meaning.
 */
class ral_field_all_bits_set_clr_policy extends ral_field_coverage_policy;

    `uvm_type_name_decl("ral_field_all_bits_set_clr_policy")

    function new(uvm_reg_field field,
                 string        inst_suffix = "");        
        super.new(field,inst_suffix); 
        m_policy_type = "all_bits_set_clr";
        if( m_field.get_n_bits() > 32 ) begin
            `uvm_fatal( cg_name(), $sformatf("new(): Maximum supported field width is 32.  %s.get_n_bits()=%0d", m_field.get_full_name(), m_field.get_n_bits() ) );
        end
        policy_cg = new( get_fld_max(), cg_name() );
    endfunction: new

    virtual function void sample(uvm_object collector);
        policy_cg.sample( m_field.get() );
    endfunction: sample

    covergroup policy_cg (uvm_reg_data_t mask, string name) with function sample(uvm_reg_data_t value);

        option.per_instance = 1;
        option.name = name;
        
        `EVM_WILDCARD_32_BIT_VECTOR_SET_CLR_BINS(value, mask)

    endgroup: policy_cg

endclass: ral_field_all_bits_set_clr_policy

/** \brief RAL field min, mid, max policy
 * 
 * This RAL field coverage policy has the coverage goal that the field has had the minimum,
 * any middle, and the maximum values.
 * 
 * It is intended to be used on control and status fields that are too large to cover all 
 * values and where the minimum and maximum values are special.  Stimulus that covers this
 * set would also cover the all bits set/clr.  So the choice to use this policy or all bits
 * should depend on whether min and max are really special and required; let the debates
 * begin.   
 */
class ral_field_min_mid_max_policy extends ral_field_coverage_policy;

    `uvm_type_name_decl("ral_field_min_mid_max_policy")

    function new(uvm_reg_field field,
                 string        inst_suffix = "");        
        super.new(field,inst_suffix); 
        m_policy_type = "min_mid_max";
        if( get_fld_max() < 3 ) begin
            `uvm_fatal( cg_name(), $sformatf("new(): Using min/mid/max policy on field with a max value of %0d", get_fld_max() ) );
        end
        policy_cg = new( get_fld_max(), cg_name() );
    endfunction: new

    virtual function void sample(uvm_object collector);
        policy_cg.sample( m_field.get() );
    endfunction: sample

    covergroup policy_cg (uvm_reg_data_t field_max, string name) with function sample(uvm_reg_data_t value);
        
        option.per_instance = 1;
        option.name = name;

        coverpoint value {
            bins min_b = { 0 };
            bins mid_b = { [ 1 : field_max-1 ] };
            bins max_b = { field_max };
        }

    endgroup: policy_cg

endclass: ral_field_min_mid_max_policy

/** \brief RAL field min, mid, max
 * 
 * This RAL field coverage policy has the coverage goal that evey value from 0 to the field
 * maximum has been covered.
 * 
 * It is intended to be used on control and status fields that are small enough that all
 * values can be covered and all values are meaningful.   
 */
class ral_field_all_values_policy extends ral_field_coverage_policy;

    `uvm_type_name_decl("ral_field_all_values_policy")

    function new(uvm_reg_field field,
                 string        inst_suffix = "");        
        super.new(field,inst_suffix); 
        m_policy_type = "all_values";
        policy_cg = new( get_fld_max(), cg_name() );
    endfunction: new

    virtual function void sample(uvm_object collector);
        policy_cg.sample( m_field.get() );
    endfunction: sample

    covergroup policy_cg (int field_max, string name) with function sample(uvm_reg_data_t value);
        
        option.per_instance = 1;
        option.name = name;

        coverpoint value {
            option.auto_bin_max = field_max + 1;
            bins all_values_b[] = { [ 0: field_max ] };
        }

    endgroup: policy_cg

endclass: ral_field_all_values_policy

/** \brief RAL field five ranges policy
 * 
 *  This RAL field coverage policy 
 */
class ral_field_five_ranges_policy#(int unsigned MIN_LEGAL, int unsigned MAX_LEGAL) extends ral_field_coverage_policy;

    `uvm_type_name_decl($sformatf("ral_field_five_ranges_policy#(%0d,%0d)",MIN_LEGAL,MAX_LEGAL))

    function new(uvm_reg_field field,
                 string        inst_suffix = "");        
        super.new(field,inst_suffix); 
        m_policy_type = "five_ranges";
        if( get_fld_max() <= MIN_LEGAL || !( m_field.get_reset() inside {[MIN_LEGAL+2:MAX_LEGAL-2]} ) || get_fld_max() < MAX_LEGAL ) begin
            `uvm_fatal( cg_name(), $sformatf("new(): Field not suitable for policy.  max=%0d, reset=%0d, MIN_LEGAL=%0d, MAX_LEGAL=%0d",
                                             get_fld_max(), m_field.get_reset(), MIN_LEGAL, MAX_LEGAL ) );
        end
        policy_cg = new( m_field.get_reset(), cg_name() );
    endfunction: new

    virtual function void sample(uvm_object collector);
        policy_cg.sample( m_field.get() );
    endfunction: sample

    covergroup policy_cg(uvm_reg_data_t reset_value, string name) with function sample(uvm_reg_data_t value);

        option.per_instance = 1;
        option.name = name;

        coverpoint value {
            bins min_b         = {MIN_LEGAL};
            bins below_reset_b = {[MIN_LEGAL+1:reset_value-1]};
            bins reset_b       = {reset_value};
            bins above_reset_b = {[reset_value+1:MAX_LEGAL-1]};
            bins max_b         = {MAX_LEGAL};
        }

    endgroup: policy_cg

endclass: ral_field_five_ranges_policy
