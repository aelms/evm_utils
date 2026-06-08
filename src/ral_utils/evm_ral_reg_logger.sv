typedef class evm_ral_reg_logger_cb;
typedef class evm_ral_reg_logger_bd;

/** \brief RAL Register Logger
 * 
 * This component logs all register accesses to a single, dedicated csv log file.  This includes read(), write(), mirror(), 
 * update(), (thru any path or map), peek(), and poke().  It logs the returned read value and the provided write value.  
 * Both access types log the final *mirror* value for all fields; this is verification's expected value for the design 
 * after the access completes.  The logged transactions reflect the RAL layer, not the physical layer timing.  In additon,
 * modifications that could occur between the RAL and physical layer are not visible to this component
 *
 * It is not possible to directly use the uvm_reg_cbs to log all accesses because of the call stack.  Specific issues in 
 * the UVM implementation preventing this are:
 * - peek and poke do not call any uvm_reg callbacks
 * - uvm_reg::write()/update() to the backdoor execute a bacdoor read that overwrites the value.
 *
 * The evm_ral_reg_logger_bd (logger backdoor) and evm_ral_reg_logger_cb (logger callback) work in tandem to address these
 * issues and log all uvm_reg transactions as issued.  
 *
 * Note: The logger does not log access to individual fields  
 */
class evm_ral_reg_logger extends uvm_component;

    string                   m_file_name = "uvm_reg.log";   ///< Register log file name

    typedef enum {
                   OMIT_PREFIX,  ///< rg.get_full_name() minus common prefix
                   FULL_NAME,    ///< rg.get_full_name() 
                   SHORT_NAME    ///< rg.get_name() is logged
                 } reg_name_cfg_t; ///< Register name logging options

    reg_name_cfg_t           m_reg_name_cfg;              ///< Register name logging configuration

    evm_ral_reg_logger_cb    m_reg_logger_cb;             ///< Logger callback for all registers
    evm_ral_reg_logger_bd    m_reg_logger_bd;             ///< Logger backdoor wrapper for all registers
 
    protected int            m_file_handle;               ///< Register log file handle
    protected realtime       m_start_time[uvm_reg];       ///< Start time by register
    protected uvm_reg_data_t m_start_val[uvm_reg];        ///< uvm_reg_item::value[0] on start (i.e. write value)
    protected int unsigned   m_common_prefix_len;         ///< Length of common prefix to omit from register names

    `uvm_component_utils_begin(evm_ral_reg_logger)  
        `uvm_field_string(m_file_name, UVM_STRING|UVM_ALL_ON)
        `uvm_field_enum(reg_name_cfg_t, m_reg_name_cfg, UVM_ALL_ON|UVM_STRING)
    `uvm_component_utils_end

    extern function new(string name = "evm_ral_reg_logger", uvm_component parent = null);
   
    extern virtual function void build_phase(uvm_phase phase);  ///< Instantiate the logger cb and bd

    extern virtual function void connect( uvm_reg_block reg_block ); ///< Register the logger cb and bd and open the log file

    extern virtual function void print_header(); ///< Print the log file header

    extern virtual function void start_access( uvm_reg_item rw ); ///< Capture the start time and write value

    extern virtual function void end_access( uvm_reg_item rw ); ///< Log a transaction

    extern virtual function string reg_log_name_str( uvm_reg rg ); ///< Get the register name for logging

    extern virtual function string field_str( uvm_reg rg ); ///< Turn register fields into a log string

endclass: evm_ral_reg_logger


 /** \brief Logger backdoor and callback classes
 *
 * The logger uses a backdoor and callback extension to in the flow as described in the following
 * descriptions of the uvm_reg callstack.
 *
 * uvm_reg::read(UVM_FRONTDOOR): Logged via evm_ral_reg_logger_cb::pre_read() and post_read()
 *  - uvm_reg::XreadX()
 *      - uvm_reg::do_read() 
 *          - field[*].pre_read(), field_cbs*.pre_read()
 *          - uvm_reg::pre_read(), uvm_reg_cbs::pre_read()
 *          - Frontdoor read
 *          - uvm_reg_cbs::post_read(), uvm_reg::post_read()
 *          - field_cbs*.post_read(), field[*].post_read()
 *
 * uvm_reg::read(UVM_BACKDOOR): Logged via evm_ral_reg_logger_bd::read()
 *  - uvm_reg::XreadX()
 *      - uvm_reg::do_read() with map set
 *          - field[*].pre_read(), field_cbs*.pre_read()
 *          - uvm_reg::pre_read(), uvm_reg_cbs::pre_read()
 *          - Backdoor read via uvm_reg_backdoor::read() OR uvm_reg::backdoor_read().  
 *              - uvm_reg_logger_bd is attached to all registers, logs transactions and calls appropriate backdoor access function
 *          - uvm_reg_cbs::post_read(), uvm_reg::post_read()
 *          - field_cbs*.post_read(), field[*].post_read()
 *
 * uvm_reg::write(UVM_FRONTDOOR):  Logged via evm_ral_reg_logger_cb::pre_write() and post_write()
 *  - uvm_reg::do_write()
 *      - field[*].pre_write(), field_cbs*.pre_write()
 *      - uvm_reg::pre_write(), uvm_reg_cbs::pre_write()
 *      - Frontdoor write
 *      - uvm_reg_cbs::post_write(), uvm_reg::post_write()
 *      - field_cbs*::post_read(), field[*].post_read
 *      
 * uvm_reg::write(UVM_BACKDOOR):  Logged via evm_ral_reg_logger_bd::read() to start, evm_ral_reg_logger_bd::write() to end
 *  - uvm_reg::do_write() with map set
 *      - field[*].pre_write(), field_cbs*.pre_write()
 *      - uvm_reg::pre_write(), uvm_reg_cbs::pre_write()
 *      - Backdoor read via uvm_reg_backdoor::read() OR uvm_reg::backdoor_read().  
 *      - Backdoor write via uvm_reg_backdoor::write() OR uvm_reg::backdoor_write().  
 *              - uvm_reg_logger_bd is attached to all registers, logs transactions and calls appropriate backdoor access function
 *      - uvm_reg_cbs::post_write(), uvm_reg::post_write()
 *      - field_cbs*::post_read(), field[*].post_read
 *
 * uvm_reg::mirror(): Same as uvm_reg::read() via XreadX()..
 *  - uvm_reg::XreadX()
 *
 * uvm_reg::update(): Same as uvm_reg::write()
 *  - uvm_reg::write()
 *
 * uvm_reg::peek(): Logged in evm_ral_reg_logger_bd::read()
 *  - Backdoor read via uvm_reg_backdoor::read() OR uvm_reg::backdoor_read().  
 * 
 * uvm_reg::poke(): Logged in evm_ral_reg_logger_bd::write()
 *  - Backdoor write via uvm_reg_backdoor::write() OR uvm_reg::backdoor_write().  
 */
class evm_ral_reg_logger_bd extends uvm_reg_backdoor;

    `uvm_object_utils(evm_ral_reg_logger_bd)

    bit in_backdoor_write;

    evm_ral_reg_logger         m_logger;
    protected uvm_reg_backdoor m_reg_bd;
    protected uvm_reg          m_reg;

    extern function new(string name = "evm_ral_reg_logger_bd");
    extern function void wrap_reg_bd(uvm_reg rg);
    extern virtual task write(uvm_reg_item rw);
    extern virtual task read(uvm_reg_item rw);

endclass: evm_ral_reg_logger_bd

class evm_ral_reg_logger_cb extends uvm_reg_cbs;

    evm_ral_reg_logger             m_logger;

    `uvm_object_utils(evm_ral_reg_logger_cb)

    extern function new(string name = "evm_ral_reg_logger_cb");
    extern virtual function void update_logger_bd_write(bit is_pre_write, uvm_reg_item rw);
    extern virtual function void pre_write(uvm_reg_item rw);
    extern virtual function void pre_read(uvm_reg_item rw);
    extern virtual function void post_write(uvm_reg_item rw);
    extern virtual function void post_read(uvm_reg_item rw);

endclass: evm_ral_reg_logger_cb 

function evm_ral_reg_logger::new(string name = "evm_ral_reg_logger", uvm_component parent);
    super.new( name, parent );
endfunction: new

function void evm_ral_reg_logger::build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_reg_logger_cb = evm_ral_reg_logger_cb::type_id::create("m_reg_logger_cb");
    m_reg_logger_cb.m_logger = this;

    m_reg_logger_bd = evm_ral_reg_logger_bd::type_id::create("m_reg_logger_bd");
    m_reg_logger_bd.m_logger = this;
endfunction: build_phase

function void evm_ral_reg_logger::connect( uvm_reg_block reg_block );
    string            names[$];
    uvm_reg           regs[$];
    reg_block.get_registers(regs);
    foreach( regs[i] ) begin
        m_reg_logger_bd.wrap_reg_bd(regs[i]);
    end
    uvm_callbacks#(uvm_reg)::add(null, m_reg_logger_cb);
    uvm_callbacks#(uvm_reg_backdoor)::add(null, m_reg_logger_cb);

    if( m_reg_name_cfg == OMIT_PREFIX ) begin
        string reg_names[$];    
        foreach( regs[i] ) reg_names.push_back( regs[i].get_full_name() );
        m_common_prefix_len = evm_text::longest_common_prefix(reg_names).len();
    end

    m_file_handle = $fopen( m_file_name, "w");
    print_header();
endfunction: connect

function void evm_ral_reg_logger::print_header();
    $fwrite(m_file_handle, "start, end, op, name, map, path, value, mirror\n");
endfunction: print_header

function void evm_ral_reg_logger::start_access( uvm_reg_item rw );
    uvm_reg rg;
    if( $cast( rg, rw.element ) && rg != null ) begin
        uvm_reg_data_t val;
        if( rw.value.size() ) val = rw.value[0];
        m_start_time[rg] = $realtime;
        m_start_val[rg] = val;
    end else begin
        `uvm_warning( get_type_name(), $sformatf("start_access(): No uvm_reg rw.element:%s", rw.convert2string() ) );
    end
endfunction: start_access

function void evm_ral_reg_logger::end_access( uvm_reg_item rw );
    uvm_reg rg;
    if( $cast( rg, rw.element ) && rg != null) begin
        realtime       start_time = $realtime;
        string         map_name = "backdoor";
        uvm_reg_data_t val;

        if( m_start_time.exists(rg) )  begin
            start_time = m_start_time[rg];
            m_start_time.delete(rg);
        end
        if(rw.map != null) map_name=rw.map.get_name();
        if(map_name=="default_map") map_name="default";
        if( rw.kind == UVM_READ ) begin
            if( rw.value.size() ) begin
                val = rw.value[0];
            end else begin
                `uvm_warning( get_type_name(), $sformatf("end_access(): rw READ missing value: %s", rw.convert2string()));
            end
        end else begin
            if( m_start_val.exists(rg) ) begin
                val = m_start_val[rg];
                m_start_val.delete(rg);
            end else begin
                 `uvm_warning( get_type_name(), $sformatf("end_access(): rw WRITE m_start_val missing: %s", rw.convert2string()));               
            end
        end

        $fwrite(m_file_handle, "%0t, %0t, %s, %s, %s, %s, %h, %s\n", start_time, $realtime, rw.kind==UVM_READ?"R":"W", reg_log_name_str(rg), map_name, rw.path==UVM_FRONTDOOR?"FD":"BD", val, field_str(rg) );
    end else begin
        `uvm_warning( get_type_name(), $sformatf("end_access(): No uvm_reg rw.element:%s", rw.convert2string() ) );
    end
endfunction: end_access

function string evm_ral_reg_logger::reg_log_name_str( uvm_reg rg );
    case ( m_reg_name_cfg )
        FULL_NAME   : return rg.get_full_name();
        OMIT_PREFIX : return rg.get_full_name().substr(m_common_prefix_len, rg.get_full_name().len()-1);
        SHORT_NAME  : return rg.get_name();
    endcase
endfunction: reg_log_name_str

function string evm_ral_reg_logger::field_str( uvm_reg rg );
    uvm_reg_field fields[$];
    rg.get_fields(fields);
    for( int i=0; i<fields.size(); i++ ) begin
        $sformat(field_str, "%s%s  ",field_str, fields[ fields.size()-1-i ].convert2string());
    end
endfunction: field_str

function evm_ral_reg_logger_bd::new(string name = "evm_ral_reg_logger_bd");
    super.new(name);
endfunction: new

function void evm_ral_reg_logger_bd::wrap_reg_bd(uvm_reg rg);
    m_reg = rg;
    m_reg_bd = m_reg.get_backdoor();
    if( m_reg_bd != null || m_reg.has_hdl_path() == 0 ) begin
        m_reg.set_backdoor(this);
    end
endfunction: wrap_reg_bd

task evm_ral_reg_logger_bd::write(uvm_reg_item rw);
    // A backdoor write starts with a read that overwites val, so the access must be logged there.
    // A poke is started with a write that is uniquely mapless.  So if this access is mapless we log it here
    if( rw.get_name().substr(0,12) == "reg_poke_item" ) begin
        m_logger.start_access(rw);
    end
    if( m_reg_bd == null ) begin
        m_reg.backdoor_write( rw ); 
    end else begin
        m_reg_bd.write(rw);
    end
    m_logger.end_access(rw);
endtask: write

task evm_ral_reg_logger_bd::read(uvm_reg_item rw);
    // A backdoor write of any kind but poke() starts with a read that overwites val, so the access
    // is logged here.  A read also always starts here.  So both types are logged.
    m_logger.start_access(rw);
    if( m_reg_bd == null ) begin
        m_reg.backdoor_read( rw );
    end else begin
        m_reg_bd.read( rw );
    end
    // A backdoor write of any kind but poke() starts with a read.  Writes should end in write(), so
    // only reads end here.
    if(!in_backdoor_write) begin
        m_logger.end_access(rw);
    end
endtask: read

function evm_ral_reg_logger_cb::new(string name = "evm_ral_reg_logger_cb");
    super.new(name);
endfunction: new

function void evm_ral_reg_logger_cb::update_logger_bd_write(bit is_pre_write, uvm_reg_item rw);
    evm_ral_reg_logger_bd bd;
    uvm_reg           rg;
    if( $cast( rg , rw.element ) && rw.path == UVM_BACKDOOR ) begin
        if ( $cast( bd, rg.get_backdoor() ) && bd != null ) begin
            bd.in_backdoor_write = is_pre_write;
        end
    end
endfunction: update_logger_bd_write

function void evm_ral_reg_logger_cb::pre_write(uvm_reg_item rw);
    if(rw.path == UVM_FRONTDOOR) begin
        m_logger.start_access(rw);
    end
    update_logger_bd_write(1'b1, rw);
endfunction: pre_write

function void evm_ral_reg_logger_cb::pre_read(uvm_reg_item rw);
    if(rw.path == UVM_FRONTDOOR) begin
        m_logger.start_access(rw);
    end
endfunction: pre_read   

function void evm_ral_reg_logger_cb::post_write(uvm_reg_item rw);
    if(rw.path == UVM_FRONTDOOR) begin
        m_logger.end_access(rw);
    end
    update_logger_bd_write(1'b0, rw);
endfunction: post_write

function void evm_ral_reg_logger_cb::post_read(uvm_reg_item rw);
    if(rw.path == UVM_FRONTDOOR) begin
        m_logger.end_access(rw);
    end 
endfunction: post_read    

