
/** \brief RAL field read coveage collection
 * 
 * Collects coverage on a uvm_reg_field ( specified in connect() ) according to the coverage policy
 * COV_POLICY type on a frontdoor register read ( uvm_reg_cbs::post_read ).
 */
class ral_field_read_cov_collector#(type COV_POLICY=ral_field_coverage_policy) extends uvm_reg_cbs;

    typedef ral_field_read_cov_collector#(COV_POLICY) this_type_t;

    `uvm_object_param_utils(this_type_t)

    `uvm_type_name_decl($sformatf("ral_field_read_cov_collector#(%S)",COV_POLICY::type_name()))

    COV_POLICY m_cov_policy;

    function new(string name = "ral_field_read_cov_collector");
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

endclass: ral_field_read_cov_collector

// Shorthand Read coverage collection declarations for all policies
typedef ral_field_read_cov_collector#(ral_field_all_bits_set_clr_policy)  ral_field_read_all_bits_set_clr_cov_collector_t;
typedef ral_field_read_cov_collector#(ral_field_min_mid_max_policy)       ral_field_read_min_mid_max_cov_collector_t;
typedef ral_field_read_cov_collector#(ral_field_all_values_policy)        ral_field_read_all_values_cov_collector_t;

class ral_field_read_five_ranges_cov_collector#(int MIN_LEGAL, int MAX_LEGAL) extends ral_field_read_cov_collector#(ral_field_five_ranges_policy#(MIN_LEGAL,MAX_LEGAL));

    typedef ral_field_read_five_ranges_cov_collector#(MIN_LEGAL, MAX_LEGAL) this_type_t;
    
    `uvm_object_param_utils(this_type_t)
    
    `uvm_type_name_decl($sformatf("ral_field_five_ranges_cov_collector#(%0d,%0d)",MIN_LEGAL,MAX_LEGAL))
    
    function new(string name="ral_field_read_five_ranges_cov_collector");
        super.new(name);
    endfunction: new
    
endclass: ral_field_read_five_ranges_cov_collector