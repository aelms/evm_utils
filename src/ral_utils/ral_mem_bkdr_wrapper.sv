
/** \brief RAL memory backdoor wrapper
 * 
 * Extension of the uvm_reg_backdoor that wraps and replaces a script generated backdoor to
 * allow pre and post access callbacks to be called even on mem.read/write with path of UVM_BACKDOOR
 * Wraps the generated snakenado backdoor's uvm_reg_backdoor::read() and write() method to
 * optionally call the uvm_reg_cbs pre and post, read and write methods attached to the memory.
 *
 * When uvm_mem::peek(), and uvm_mem::poke() are used to access memory thru the backdoor (implicitly)
 * the uvm_reg_cbs methods registered with the uvm_mem are NOT called at the uvm_mem OR uvm_reg_backdoor
 * layer by default.  This wrapper ensures they are in the following hierarchy.
 *
 * 1) mem.poke/peek()
 *  1.1) ral_mem_bkdr_wrapper::write/read()
 *      1.1.1) if(m_cbks_en) uvm_reg_cbs::pre_write/read()
 *      1.1.2) m_gen_bkdr sets memory
 *      1.1.3) if(m_cbks_en) uvm_reg_cbs::post_write/read()
 *
 * If uvm_mem::read() OR uvm_mem::write() with path=UVM_BACKDOOR are used to access memory,
 * the appropriate uvm_reg_cbs methods are called by default.  
 *
 * 1) mem.write/read( .path(UVM_BACKDOOR) )
 *    1.1) uvm_reg_cbs::pre_write/read() callbacks
 *    1.2) ral_mem_bkdr_wrapper::write/read()
 *      1.2.1) if(m_cbks_en) uvm_reg_cbs::pre_write/read() callbacks again
 *      1.2.2) m_gen_bkdr sets memory
 *      1.2.3) if(m_cbks_en) uvm_reg_cbs::post_write/read() callbacks
 *    1.3) uvm_reg_cbs::post_write/read() callbacks again
 *
 * By default, the callbacks are disabled and never called.  They can be always enabled which
 * would call them twice in the mem.write/read backdoor. They can also be selectively enabled 
 * as needed.
 */
class ral_mem_bkdr_wrapper extends uvm_reg_backdoor;

    `uvm_object_utils(ral_mem_bkdr_wrapper)

    protected uvm_reg_backdoor m_gen_bkdr;         ///< Generated backdoor being wrapped
    protected boolean_t        m_cbks_en = FALSE;  ///< Allow callbacks to be called


    extern         function new(string name="ral_mem_bkdr_wrapper");

    /** \brief Wrap Generated Memory Backdoor
     * Given a memory instance, assigns its generated backdoor to m_bkdr and replaces it with
     * this class.    
     * 
     * The uvm_post_reset_phase() task is recommended.
     */
    extern virtual function void wrap_mem_gen_backdoor(uvm_mem mem);

    /** \brief Enable callback execution
     *
     * Control whether callbacks are called in the read() and write() method.  Can be used 
     * in a memory extension to allow them to be called in peek(), poke() and avoid calling 
     * them twice in read()/write() with path = UVM_BACKOOR.
     */
    extern virtual function void set_mem_cbks_en(boolean_t mem_cbks_en);

    /** \brief Post read callback
     *
     * Empty callback hook that can be implemented in an extension to modify backdoor read 
     * data to match RAL Frontdoor for rw.value[0] only.
     */
    virtual task post_read_cb(uvm_reg_item rw); endtask


    /** \brief Post read callback
     *
     * Empty callback hook that can be implemented in an extension to modify backdoor write 
     * data to match RAL Frontdoor for rw.value[0] only.
     */
    virtual task pre_write_cb(uvm_reg_item rw); endtask

    /** \brief write
     *
     * Calls memory pre_write() callbacks, pre_write_cb() then generated backdoor write, and
     * memory post_write callbacks.  Allows rw.value.size()>1 (burst backdoor write)
     */
    extern virtual task write(uvm_reg_item rw);


    /** \brief read
     *
     * Calls memory pre_read() callbacks, generated backdoor read, and then the post_read_cb()
     * and memory post_read callbacks.  Allows rw.value.size()>1 (burst backdoor read)
     */
    extern virtual task read(uvm_reg_item rw);

endclass: ral_mem_bkdr_wrapper

function ral_mem_bkdr_wrapper::new(string name="ral_mem_bkdr_wrapper");
    super.new(name);
endfunction: new

function void ral_mem_bkdr_wrapper::wrap_mem_gen_backdoor(uvm_mem mem);
    m_gen_bkdr = mem.get_backdoor();
    mem.set_backdoor(this);
endfunction: wrap_mem_gen_backdoor

function void ral_mem_bkdr_wrapper::set_mem_cbks_en(boolean_t mem_cbks_en);
    m_cbks_en = mem_cbks_en;
endfunction: set_mem_cbks_en

task ral_mem_bkdr_wrapper::write(uvm_reg_item rw);
    uvm_mem mem;
    `uvm_info( get_type_name(), $sformatf("write(): rw %s",rw.convert2string()), UVM_DEBUG);
    
    if(!$cast(mem,rw.element)) begin
        `uvm_fatal( get_type_name(), $sformatf("write(): rw.element is not uvm_mem.  %s", $typename(rw.element)));
    end
    
    if( m_cbks_en ) begin
        `uvm_do_obj_callbacks(uvm_mem,uvm_reg_cbs,mem,pre_write(rw))
    end
        
    m_gen_bkdr.write(rw);

    if( m_cbks_en ) begin
        `uvm_do_obj_callbacks(uvm_mem,uvm_reg_cbs,mem,post_write(rw))
    end
endtask: write

task ral_mem_bkdr_wrapper::read(uvm_reg_item rw);
    uvm_mem mem;
    if(!$cast(mem,rw.element)) begin
        `uvm_fatal( get_type_name(), $sformatf("read(): rw.element is not uvm_mem.  %s", $typename(rw.element)));
    end

    if( m_cbks_en ) begin
        `uvm_do_obj_callbacks(uvm_mem,uvm_reg_cbs,mem,pre_read(rw))
    end
    
    m_gen_bkdr.read(rw);

    if( m_cbks_en ) begin
        `uvm_do_obj_callbacks(uvm_mem,uvm_reg_cbs,mem,post_read(rw))
    end

    `uvm_info( get_type_name(), $sformatf("read(): rw %s",rw.convert2string()), UVM_DEBUG);

endtask: read
