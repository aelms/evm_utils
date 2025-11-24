
/** \brief RAL field read coveage collection
 * 
 * Collects coverage on a uvm_reg_field ( specified in connect() ) according to the coverage policy
 * COV_POLICY type on a frontdoor register read ( uvm_reg_cbs::post_read ).
 */
class evm_ral_field_read_cov_collector#(type COV_POLICY=evm_ral_field_coverage_policy) extends uvm_reg_cbs;

    typedef evm_ral_field_read_cov_collector#(COV_POLICY) this_type_t;

    `uvm_object_param_utils(this_type_t)

    `uvm_type_name_decl($sformatf("evm_ral_field_read_cov_collector#(%S)",COV_POLICY::type_name()))

    COV_POLICY m_cov_policy;

    function new(string name = "evm_ral_field_read_cov_collector");
        super.new(name);
    endfunction: new

    /** \brief Connect 
     * 
     * Attaches this callback to the supplied register field and instantiates m_cov_policy 
     * with the field and inst_suffix.
     */
    virtual function void connect(uvm_reg_field field,
                                  string        inst_suffix="");
        uvm_callbacks#(uvm_reg_field)::add(field,this);
        m_cov_policy = new( field, inst_suffix );
    endfunction: connect

    virtual task post_read( uvm_reg_item rw );
        if( rw.path == UVM_FRONTDOOR ) begin
            m_cov_policy.sample(this);
        end
    endtask: post_read

endclass: evm_ral_field_read_cov_collector

// Shorthand Read coverage collection declarations for all policies
typedef evm_ral_field_read_cov_collector#(evm_ral_field_all_bits_set_clr_policy)  evm_ral_field_read_all_bits_set_clr_cov_collector_t;
typedef evm_ral_field_read_cov_collector#(evm_ral_field_min_mid_max_policy)       evm_ral_field_read_min_mid_max_cov_collector_t;
typedef evm_ral_field_read_cov_collector#(evm_ral_field_all_values_policy)        evm_ral_field_read_all_values_cov_collector_t;

class evm_ral_field_read_five_ranges_cov_collector#(int MIN_LEGAL, int MAX_LEGAL) extends evm_ral_field_read_cov_collector#(evm_ral_field_five_ranges_policy#(MIN_LEGAL,MAX_LEGAL));

    typedef evm_ral_field_read_five_ranges_cov_collector#(MIN_LEGAL, MAX_LEGAL) this_type_t;
    
    `uvm_object_param_utils(this_type_t)
    
    `uvm_type_name_decl($sformatf("ral_field_five_ranges_cov_collector#(%0d,%0d)",MIN_LEGAL,MAX_LEGAL))
    
    function new(string name="evm_ral_field_read_five_ranges_cov_collector");
        super.new(name);
    endfunction: new
    
endclass: evm_ral_field_read_five_ranges_cov_collector