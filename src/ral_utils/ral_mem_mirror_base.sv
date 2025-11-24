

/** \brief RAL Memory mirror base
 * 
 * This uvm_mem_cb extension adds uvm_reg_field style mirror predict and check functionality to 
 * ANY uvm_mem.  This base class defines the user interface and specific instances of the parameterized
 * extension (ral_mem_mirror) implement the core functionality.
 * 
 * The core functionality is the same as R/W uvm_reg_field and provided by the callback methods in 
 * ral_mem_mirror.  On frontdoor memory writes, the mirror is updated.  On frontdoor memory reads, the read
 * value is compared to the mirror value (if it exists) and an error is reported if they do not match.  
 * Callbacks are not executed on backdoor writes and reads by default so this functionality is not available.
 * However, the ral_mem_bkdr_wrapper allows callbacks to be executed on backdoor accesses if desired.
 * 
 * In addition, the mirror can be updated directly via the predict() method.  This can be called by a HW 
 * model to set the expected value of memory.  This is independent of RAL accesses and the granularity
 * can be different.  
 * 
 * REPORT DELEGATION
 * -----------------
 * The model provides (optional) report delegation as described in evm_report_delegation.  A UVM 
 * component (i.e. reference model) can be provided to the connect() method.  If not set, the global
 * report object is used.
 *   
 */
virtual class ral_mem_mirror_base extends uvm_reg_cbs;

    protected uvm_mem            m_mem;                     ///< RAL Memory being mirrored

    protected uvm_report_object  m_report_object;           ///< Report object for report delegation

    function new(string name = "ral_mem_mirror_base" );
        super.new(name);
    endfunction: new

    /** \brief connect memory
     * 
     * Adds itself to ral_mem as a callback.
     * 
     * Can be overridden if an application does not want to heed the m_p_mem advice for logic or
     * bit type.
    */
    virtual function void connect_mem(uvm_mem           ral_mem,
                                      uvm_report_object report_object=null);
        m_mem = ral_mem;
        uvm_callbacks#(uvm_mem)::add(ral_mem, this);
        m_report_object = report_object;
    endfunction: connect_mem
    

    /** \brief Predict
     * 
     * Implements prediction on HW update.  This is the method that should be called by a HW model to 
     * predict the contents of memory independant of RAL.  Sets m_p_mem[predict_offset] = predict_value;
     */                                             
    pure virtual function void predict(uvm_reg_addr_t       predict_offset,
                                       uvm_reg_data_logic_t predict_value);

    /** \brief Clear a prediction
     * 
     * This is the method that should be used to clear a memory prediction at the given predict_offset.
     */                                             
    pure virtual function void clear_prediction(uvm_reg_addr_t predict_offset);

    /** \brief Inject error into the design memory
     * 
     * Injects an error into the design memory itself by a read-modify-write (bit flip) thru the backdoor to
     * the predict_offset location.
     * Requires the memory to have a correct backdoor (i.e. one that matches frontdoor).
     */
    pure virtual task          inject_design_error(uvm_reg_addr_t predict_offset);

    /** \brief Get report delegation object */                                                       
    function uvm_report_object uvm_get_report_object();
        if( m_report_object ) begin
            return m_report_object;
        end else begin
            return uvm_coreservice_t::get().get_root();
        end
    endfunction

    `EVM_REPORT_DELEGATION_FUNCTIONS

endclass: ral_mem_mirror_base

