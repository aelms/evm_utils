

/** \brief RAL Memory Mirror
 * 
 * This class extends the ral_mem_mirror_base to provide a mirror for a specific RAL and HW access
 * width.  All bits as R/W and contiguous in both the RAL access and prediction domains.  This is 
 * fine for most designs using memory as bulk storage.  Designs that do not have this behaviour can 
 * be handled in extensions.  For example, a memory used by HW to store 7-bit samples at each byte, 
 * is handled by simply always predicting each bit-8 as 0.  
 * 
 * Runtime Efficiency
 * ------------------
 * Directly modelling a large design memory requires a large simulation memory.  To reduce this,
 * the model uses a sparse array to store predicted memory values.  Locations can also be cleared, 
 * if the predicted value is no longer needed or valid, freeing simulation memory.  Finally, if
 * possible, the model memory type is 2-state.  Despite these memory usage reduction techniques,
 * attention should be paid to the simulation memory that is used and this model should not be used
 * for very large memories.
 * 
 * PREDICT_N_BITS, RAL_N_BITS
 * --------------------------
 * This model's prediction granularity is a variable number of bits (PREDICT_N_BITS) that can be different 
 * than the RAL memories (RAL_N_BITS) it is modelling.  This is to simplify the verification model of HW by 
 * allowing it to make predictions in its natural width.  The model offsets (predict_offset) and value width
 * (predict_value) are in the units of PREDICT_N_BITS.
 * The model's RAL post_write(), and post_read() function convert the RAL operation to the update and 
 * compare the correct predict_value(s) of the model.
 * 
 * Even though PREDICT_N_BITS and RAL_N_BITS can be different they are each expected to be contiguous.
 * For example, a memory with RAL_N_BITS=32 (typical) but stores 7 bit sample data in each byte (upper bit
 * unused) should be modeled with PREDICT_N_BITS=8.   The upper bit can always be predicted as 1'b0, in
 * an extension's implementation of post_write().
 * 
 * The following diagram shows how the RAL and Model view correlate for this example, for the RAL location 0.
 * 
 * 
 * bit                       31       23       15        7
 *                           -------------------------------------     
 * RAL (RAL_N_BITS=32)       |                 0                 | 
 *                           -------------------------------------
 * Model (PREDICT_N_BITS=8)  |    3   |    2   |    1   |    0   |
 *                           ------------------------------------- 
 *  
 * PREDICT_MEM_TYPE
 * ----------------
 * A 2-state (bit) type for predicted memory is used by default but this should be set to logic based
 * on the following PREDICT_N_BITS and RAL RAL_N_BITS relationship.  
 * 
 * IF RAL RAL_N_BITS is equal to or greater than PREDICT_N_BITS, and RAL_N_BITS is an integer multiple of 
 * PREDICT_N_BITS it means that every RAL write updates an integer number of m_p_mem_locations AND every 
 * RAL read compares an integer number of predicted locations.  This means 2-state (bit) logic can and
 * should be used, for simulation memory efficiency.   
 * 
 * Note: this holds true in the previous example, with RAL_N_BITS=32 and PREDICT_N_BITS=8.  It is also 
 * worth noting that if model locations 0 and 2 were predicted, when RAL location 0 was read, only the 
 * corresponding bits from model location 0 and 2 would be checked.   RAL bits corresponding to model 
 * location 1 and 3 would be treated as do not care AND they would NOT BE PREDICTED as a side-effect 
 * of the RAL read.
 * 
 * Otherwise, a RAL write can set a partial m_p_mem location and PREDICT_MEM_TYPE should be set to a logic 
 * type.  The unsed bits not set by the RAL write are predicted X and not compared on a read.
 * 
 */
class ral_mem_mirror#(int  PREDICT_N_BITS = 8, int RAL_N_BITS = 32, type PREDICT_MEM_TYPE=bit) extends ral_mem_mirror_base;

    typedef ral_mem_mirror#(PREDICT_N_BITS, RAL_N_BITS, PREDICT_MEM_TYPE) this_type;

    typedef PREDICT_MEM_TYPE [ ( PREDICT_N_BITS - 1) : 0 ] p_mem_t; ///< Predicted memory value type (bit or logic vector)

    `uvm_object_param_utils(this_type)

    `uvm_type_name_decl( $sformatf("ral_mem_mirror#(%0d, %0d, %s)", PREDICT_N_BITS, RAL_N_BITS, $typename(PREDICT_MEM_TYPE) ) )

    protected p_mem_t            m_p_mem[uvm_reg_addr_t];   ///< Predicted Memory Values

    function new(string name = get_type_name() );
        super.new(name);
    endfunction: new

    /** \brief connect memory
     * 
     * Checks if RAL_N_BITS matches ral_mem.get_n_bits() and fatal error if it does not
     * 
     * Checks it's PREDICT_N_BITS versus the RAL_N_BITS and 
     * - raises a fatal error if this should be a logic type for the given ral_mem and is not
     * - raises a warning if this could be a bit type for the given ral_mem and is not
     * 
     * Can be overridden if an application does not want to heed the m_p_mem advice for logic or
     * bit type.
    */
    extern virtual function void connect_mem(uvm_mem           ral_mem,
                                             uvm_report_object report_object=null);


    /** \brief Predict
     * 
     * Implements prediction on HW update.  This is the method that should be called by a HW model to 
     * predict the contents of memory independant of RAL.  Sets m_p_mem[predict_offset] = predict_value;
     */                                             
    extern virtual function void predict(uvm_reg_addr_t predict_offset,
                                         p_mem_t        predict_value);

    /** \brief Clear a prediction
     * 
     * This is the method that should be used to clear a memory prediction at the given predict_offset.
     */                                             
    extern virtual function void clear_prediction(uvm_reg_addr_t predict_offset);

    /** \brief Inject error into the design memory
     * 
     * Injects an error into the design memory itself by a read-modify-write (bit flip) thru the backdoor to
     * the predict_offset location.
     * Requires the memory to have a correct backdoor (i.e. one that matches frontdoor).
     */
    extern virtual task          inject_design_error(uvm_reg_addr_t predict_offset);
    
    /** \brief post_write
     * 
     * Implements the prediction on RAL write.  Updates m_p_mem[] according to the uvm_reg_item, treating
     * all bits as r/w.  Automatically called when the memory is written thru RAL.
     */
    extern virtual task          post_write(uvm_reg_item rw);

    /** post_read
     * 
     * Implements the check on RAL read.  Compares the expected contents in m_p_mem[] to the actual
     * contents in the design, in the uvm_reg_item.  Only contents in the sparse m_p_mem[] that exist
     * and are non-X are compared.
     * On mismatch reports match, and all m_p_mem[] locations compared, on UVM_DEBUG.  Just match and 
     * number of locations compared on UVM_HIGH.
     * Reports a UVM_ERROR on mismatch and full comparison information on mismatch.
    */
    extern virtual task          post_read(uvm_reg_item rw);


    /** \brief RAL to prediction
     * 
     * Given a uvm_reg_item (rw) converts it to an array of p_mem and predict_offset.  X's at the 
     * upper and lower bits if the RAL and p_mem are not bit aligned.  The rw.offset and
     * rw.values[] are assumed populated and valid, for a write OR a completed read.
     */
    extern protected virtual function void ral2predict(uvm_reg_item       rw, 
                                                       ref uvm_reg_addr_t predict_offset,
                                                       ref p_mem_t        p_mem[$], 
                                                       ref p_mem_t        ls_mask,
                                                       ref p_mem_t        ms_mask);  

    /** \brief Prediction to RAL 
     * 
     * Given an array of predicted values (possibly empty) and predict_offset, this method 
     * converts it into a uvm_reg_item with offset and value[] array populated and sized 
     * appropriately to encompass the predicted arguments.  
     * The rw.value[] is an array of bit (not logic) vectors.  Therefore, it is 0 (not x)
     * filled in the case of p_mem[] to rw.value[] alignment mismatch.
     */
    extern protected virtual function void predict2ral(uvm_reg_addr_t     predict_offset,
                                                       p_mem_t            p_mem[$],
                                                       ref uvm_reg_item   rw,
                                                       ref uvm_reg_data_t ls_mask,
                                                       ref uvm_reg_data_t ms_mask);  


    /** String representation of the p_mem array */                                                       
    extern protected virtual function string p_mem2string(p_mem_t p_mem[$]);

    /** \brief Get report delegation object */                                                       
    function uvm_report_object uvm_get_report_object();
        if( m_report_object ) begin
            return m_report_object;
        end else begin
            return uvm_coreservice_t::get().get_root();
        end
    endfunction

    `EVM_REPORT_DELEGATION_FUNCTIONS

endclass: ral_mem_mirror

function void ral_mem_mirror::connect_mem(uvm_mem           ral_mem,
                                          uvm_report_object report_object = null);
    super.connect_mem(ral_mem, report_object);                                      
    if ( RAL_N_BITS != m_mem.get_n_bits() ) begin
        `uvm_fatal( get_type_name(), $sformatf("connect_mem(): m_mem.get_n_bits()=%0d and RAL_N_BITS=%0d", m_mem.get_n_bits(), RAL_N_BITS));
    end
    // If RAL memory RAL_N_BITS is less than PREDICT_N_BITS OR RAL memory RAL_N_BITS is greater and not an integer multiple of PREDICT_N_BITS 
    // raise a fatal error if the memory model is not 4-state logic.  It must be logic to allow X's in the predicted values for RAL writes that
    // update a portion of a predicted location.
    if( ( ( RAL_N_BITS < PREDICT_N_BITS ) || ( ( RAL_N_BITS > PREDICT_N_BITS) && ( (RAL_N_BITS%PREDICT_N_BITS) != 0 ) ) ) && ( type(PREDICT_MEM_TYPE) != type(logic) ) ) begin
        `uvm_fatal( get_type_name() , $sformatf("connect_mem(): RAL_N_BITS=%0d, PREDICT_N_BITS=%0d, and PREDICT_MEM_TYPE is %s, not logic, as required", 
                                                RAL_N_BITS, PREDICT_N_BITS, $typename(PREDICT_MEM_TYPE) ) );
    end
    // If RAL memory RAL_N_BITS is greater than or equal PREDICT_N_BITS and an integer multiple and memory model is not 2-state logic
    // as allowed, raise a warning.
    if( ( RAL_N_BITS >= PREDICT_N_BITS ) && ( (m_mem.get_n_bits()%PREDICT_N_BITS) == 0 ) && ( type(PREDICT_MEM_TYPE) != type(bit) ) ) begin
        `uvm_warning( get_type_name() , $sformatf("connect_mem(): RAL_N_BITS=%0d, PREDICT_N_BITS=%0d, and PREDICT_MEM_TYPE is not a bit, as allowd.", RAL_N_BITS, PREDICT_N_BITS) );
    end
endfunction: connect_mem

function void ral_mem_mirror::predict(uvm_reg_addr_t        predict_offset,
                                      uvm_reg_data_logic_t  predict_value);
    if( predict_value > {PREDICT_N_BITS{1'b1}} ) begin
        `uvm_fatal( get_type_name(), $sformatf("predict(): predict_value 'h%0h exceeds maximum for PREDICT_N_BITS=%0d", predict_value, PREDICT_N_BITS) );
    end
    m_p_mem[predict_offset] = predict_value;
endfunction: predict

function void ral_mem_mirror::clear_prediction(uvm_reg_addr_t predict_offset);
    m_p_mem.delete(predict_offset);
endfunction: clear_prediction

task ral_mem_mirror::inject_design_error(uvm_reg_addr_t predict_offset);
    p_mem_t          p_mem[$];
    uvm_reg_item     rw;
    uvm_reg_data_t   ls_mask;
    uvm_reg_data_t   ms_mask;  

    uvm_reg_backdoor bkdr = m_mem.get_backdoor();

    if( bkdr == null ) begin
        `uvm_error( get_type_name(), "inject_design_error(): Requires memory backdoor ");
    end

    // Error is being injected that SHOULD raise a UVM_ERROR.  Test should fail due to errors 
    // if its a unit-type test it should expect this warning + just the injected errors to pass.
    `uvm_warning( get_type_name(), $sformatf("inject_design_error(): predict_offset = %0d'h%0h", $size(predict_offset), predict_offset ) );

    // Error single p_mem location.
    p_mem.push_back(p_mem_t'(0));
    
    // Turn the errored predict_offset into a umv_reg_item (offset, value and masks)
    predict2ral(predict_offset,p_mem,rw,ls_mask,ms_mask);

    // Execute the bkdr read.    
    bkdr.read(rw);
    rw.kind = (rw.value.size()==1)?UVM_READ:UVM_BURST_READ;
    `uvm_info( get_type_name(), $sformatf("inject_design_error(): read %s", rw.convert2string() ), UVM_DEBUG );

    // Flip the appropriate bits
    foreach(rw.value[i]) begin
        bit [RAL_N_BITS-1:0] mask = {RAL_N_BITS{1'b1}};
        if(i==0) begin
            mask = ls_mask;
        end
        if( i == ( rw.value.size()-1 ) ) begin
            mask = ms_mask;
        end
        rw.value[i] = rw.value[i] ^ mask;
    end

    rw.kind = (rw.value.size()==1)?UVM_WRITE:UVM_BURST_WRITE;
    `uvm_info( get_type_name(), $sformatf("inject_design_error(): write %s", rw.convert2string() ), UVM_DEBUG );
    bkdr.write(rw);
                                                 
endtask: inject_design_error

task ral_mem_mirror::post_write(uvm_reg_item rw);
    p_mem_t        p_mem[$];
    uvm_reg_addr_t predict_offset;
    p_mem_t        ls_mask;
    p_mem_t        ms_mask;
    uvm_reg_addr_t last_predict_offset;
    `uvm_info( get_type_name(), $sformatf("post_write(): rw %s",rw.convert2string()),UVM_DEBUG);

    ral2predict( rw, predict_offset, p_mem, ls_mask, ms_mask );
    last_predict_offset = predict_offset + p_mem.size() - 1;

    // For first and last, possibly partially updated locations
    // - keep the existing m_p_mem bits outside the write mask
    // - overwrite bits within the mask 
    if( m_p_mem.exists(predict_offset) ) begin
        m_p_mem[predict_offset] = ( m_p_mem[predict_offset] & ~ls_mask ) | ( p_mem[0] & ls_mask );
    end
    if( m_p_mem.exists( last_predict_offset ) ) begin
        m_p_mem[last_predict_offset] = ( m_p_mem[last_predict_offset] & ~ms_mask )  | ( p_mem[$] & ms_mask );
    end

    foreach(p_mem[i]) begin
        m_p_mem[predict_offset + i] = p_mem[i];
    end

    `uvm_info( get_type_name(), $sformatf("post_write(): Predicted m_p_mem[%0d:%0d]", last_predict_offset, predict_offset), UVM_HIGH );
    
endtask: post_write

task ral_mem_mirror::post_read(uvm_reg_item rw);
    p_mem_t        p_mem[$];
    uvm_reg_addr_t predict_offset;
    p_mem_t        ls_mask;
    p_mem_t        ms_mask;
    uvm_reg_addr_t last_predict_offset;
    boolean_t      pass=TRUE;
    string         cmp;
    int            cmp_cnt;
    `uvm_info( get_type_name(), $sformatf("post_read(): rw %s",rw.convert2string()),UVM_DEBUG);
    ral2predict( rw, predict_offset, p_mem, ls_mask, ms_mask );
    last_predict_offset = predict_offset + p_mem.size() - 1;

    foreach( p_mem[i] ) begin
        if( m_p_mem.exists(predict_offset+i) ) begin
            cmp_cnt++;
            if( i==0 || i==(p_mem.size()-1) ) begin
                p_mem_t mask = (i==0) ? ls_mask : ms_mask;
                if( (p_mem[i] & mask) !=? (m_p_mem[predict_offset+i] & mask) ) begin
                    pass=FALSE;
                end
                cmp = $sformatf("%s\n\tpredict_offset='h%h, act='h%h, exp='h%h, act mask='h%h", cmp, predict_offset+i, p_mem[i], m_p_mem[predict_offset+i], mask);
            end else begin
                if( p_mem[i] !=? m_p_mem[predict_offset+i] ) begin
                    pass=FALSE;
                end
                cmp = $sformatf("%s\n\tpredict_offset='h%h, act='h%h, exp='h%h", cmp, predict_offset+i, p_mem[i], m_p_mem[predict_offset+i]);
            end
        end
    end

    if(pass) begin
        // UVM_DEBUG: match, comparison count, and all comparisons
        // UVM_HIGH: just match and comparison count
        if(uvm_report_enabled(UVM_DEBUG, UVM_INFO, get_type_name() ) ) begin
            cmp=$sformatf(": %0d predictions compared%s",cmp_cnt,cmp);
        end else begin
            cmp=$sformatf(": %0d predictions compared",cmp_cnt);
        end
        `uvm_info( get_type_name(), $sformatf("post_read(): Read m_p_mem[%0d:%0d] matched%s", last_predict_offset, predict_offset, cmp), UVM_HIGH );
    end else begin
        // Print full comparison details on mismatch
        `uvm_error( get_type_name(), $sformatf("post_read(): Read m_p_mem[%0d:%0d] did not match rw (%s)%s", last_predict_offset, predict_offset, rw.convert2string(), cmp) );
    end
    
endtask: post_read

function void ral_mem_mirror::ral2predict(uvm_reg_item       rw, 
                                          ref uvm_reg_addr_t predict_offset,
                                          ref p_mem_t        p_mem[$], 
                                          ref p_mem_t        ls_mask,
                                          ref p_mem_t        ms_mask);

    int                  ral_lsb;      // Least sig RAL bit written
    int                  ral_msb;      // Most sig RAL bit written
    bit [RAL_N_BITS-1:0] ral_data[$];  // rw.value[] Order reversed and truncated to the used bits
    logic                lsx_fill[$];  // Least signficant fill 1'bx
    logic                msx_fill[$];  // Most significant fill 1'bx

    p_mem.delete(); // Clear the converted memory

    ral_lsb = rw.offset * RAL_N_BITS;                       // RAL Least sig bit
    ral_msb = ral_lsb + rw.value.size() * RAL_N_BITS - 1;   // RAL Most sig bit

    predict_offset = ral_lsb / PREDICT_N_BITS;              // Predicted array least sig offset
    ls_mask = {PREDICT_N_BITS{1'b1}};                       // Default mask of 1's
    ms_mask = {PREDICT_N_BITS{1'b1}};   

    repeat ( (ral_lsb % PREDICT_N_BITS) ) begin             // For each predicted bit below RAL LSB, add an X and push a 1 in the mask from right
        lsx_fill.push_back(1'bx);
        ls_mask<<=1;
    end 
                                                                                                                                                                                                                     
    repeat ( (PREDICT_N_BITS - 1 - (ral_msb % PREDICT_N_BITS) ) ) begin     // For each predicted bit above RAL MSB, add an X and push a 1 in the mask from left
        msx_fill.push_back(1'bx);
        ms_mask>>=1;
    end

    foreach(rw.value[i]) begin                                  // Truncate rw.values to used bits only, and reverse for packing
        ral_data.push_front(rw.value[i][RAL_N_BITS-1:0]);
    end

    p_mem = { << PREDICT_N_BITS { msx_fill, ral_data, lsx_fill } };   // Pack the upper x's, ral data, and lsx into p_mem

    if( rw.value.size()==1 ) begin
        ls_mask = ls_mask & ms_mask;
        ms_mask = ls_mask;
    end


    `uvm_info( get_type_name(), $sformatf("ral2predict(): RAL rw (%s).  predict_offset=%0d'h%0h, ls_mask=%0d'b%b, ms_mask=%0d'b%b, %s",
                                           rw.convert2string(), $size(predict_offset), predict_offset, PREDICT_N_BITS, ls_mask, PREDICT_N_BITS, ms_mask, p_mem2string(p_mem) ), UVM_DEBUG );

    /* Example: 
     * 
     * - RAL_N_BITS = 3, PREDICT_N_BITS =4
     * - rw.offset=2, rw.value.size()=4 
     * 
     * ral_lsb =  2 * 3 = 6
     * ral_msb =  6 + 4 * 3 -1 = 17
     * 
     *                          MSb                              LSb
     *                           |                                |
     *                           V                                V  
     * Raw bits      : 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
     *                 -------------------------------------------------------------- 
     * RAL offset    :     6   |    5   |    4   |    3   |    2   |    1   |    0   
     *                 --------------------------------------------------------------
     * Predict offset:   |     4     |     3     |     2     |     1     |     0      
     * (mask)            | 0  0  1  1|           |           | 1  1  0  0|                                
     *                 --------------------------------------------------------------
     * predict_offset = 6 / 4 = 1
     * lsx_fill = 6 % 4 = 2          (bits 4 and 5)
     * msx_fill = 4 - 1 - (17%4) = 2 (bits 18 and 19)
     * ls_mask = 4'b1100;
     * ms_mask = 4'b0011;
     * 
     */

endfunction: ral2predict

function void ral_mem_mirror::predict2ral(uvm_reg_addr_t     predict_offset,
                                                    p_mem_t            p_mem[$],
                                                    ref uvm_reg_item   rw,
                                                    ref uvm_reg_data_t ls_mask,
                                                    ref uvm_reg_data_t ms_mask);
    int     p_lsb;             // Least sig predict bit accessed
    int     p_msb;             // Most sig predict bit accessed
    p_mem_t p_mem_reversed[$]; // p_mem in reveres order
    bit     ls0_fill[$];       // Least significant 0 fill
    bit     ms0_fill[$];       // Most significant 0 fill

    `uvm_info( get_type_name(), $sformatf("predict2ral(): predict_offset = %0d'h%0h, p_mem.size() = %0d", $size(predict_offset), predict_offset, p_mem.size() ), UVM_DEBUG )
    
    p_lsb = predict_offset * PREDICT_N_BITS;                  // Predict least sig bit
    p_msb = p_lsb + ( p_mem.size() * PREDICT_N_BITS ) - 1 ;   // Predict most sig bit
    
    rw = uvm_reg_item::type_id::create("rw");
    rw.offset = p_lsb / RAL_N_BITS;
    rw.element_kind = UVM_MEM;
    rw.element = m_mem;
    ls_mask = {RAL_N_BITS{1'b1}};
    ms_mask = {RAL_N_BITS{1'b1}};

    repeat ( ( p_lsb % RAL_N_BITS ) ) begin
        ls0_fill.push_back(1'b0);
        ls_mask<<=1;
    end

    repeat ( ( RAL_N_BITS - 1 - (p_msb % RAL_N_BITS ) ) ) begin
        ms0_fill.push_back(1'b0);
        ms_mask>>=1;
    end

    foreach(p_mem[i]) begin
        p_mem_reversed.push_front(p_mem[i]);
    end

    rw.value = { << RAL_N_BITS { ms0_fill, p_mem_reversed, ls0_fill } };

    if( rw.value.size()==1 ) begin
        ls_mask = ls_mask & ms_mask;
        ms_mask = ls_mask;
    end

    `uvm_info( get_type_name(), $sformatf("predict2ral(): predict_offset = %0d'h%0h, %s, ls_mask=%0d'h%0h, ms_mask=%0d'h%0h, RAL rw (%s)",
                                           $size(predict_offset), predict_offset, p_mem2string(p_mem), RAL_N_BITS, ls_mask, RAL_N_BITS, ms_mask, rw.convert2string() ), UVM_DEBUG ); 
                                             
endfunction: predict2ral

function string ral_mem_mirror::p_mem2string(p_mem_t p_mem[$]);    
    if( p_mem.size() > 4 ) begin
        p_mem2string = $sformatf("p_mem[0, 1, .. %0d, %0d] = %0h'h(%0h, %0h,.., %0h, %0h)", p_mem.size()-2, p_mem.size()-1, PREDICT_N_BITS, p_mem[0], p_mem[1], p_mem[$-1], p_mem[$]);
    end else begin       
        string idx_str = "p_mem[0";
        string val_str = $sformatf("%0h'h(%0h", PREDICT_N_BITS, p_mem[0]);
        for(int i = 1; i < p_mem.size(); i++) begin
            idx_str = $sformatf("%s, %0d", idx_str, i);
            val_str = $sformatf("%s, %0h", val_str, p_mem[i]);
        end
        p_mem2string = $sformatf("%s] = %s)", idx_str, val_str);
    end
endfunction: p_mem2string     
    
