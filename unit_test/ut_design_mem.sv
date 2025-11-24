/** \brief Design Memory
  * 
  * A simple parameterized design memory model for unit testing.
  * 
  */
class ut_design_mem#(int unsigned WIDTH, int unsigned SIZE) extends uvm_object;

    typedef ut_design_mem#(WIDTH, SIZE) this_type;

    typedef bit [WIDTH-1:0] mem_data_t;
 
    `uvm_object_param_utils(this_type);

    mem_data_t data [SIZE];

    `uvm_type_name_decl( $sformatf("ut_design_mem#(%0d,%0d)", WIDTH, SIZE) )
 
    function new(string name = get_type_name() );
        super.new(name);
    endfunction: new
 
    function void write(uvm_reg_addr_t addr, mem_data_t value);
        if (addr < SIZE) begin
            data[addr] = value;
        end
    endfunction: write  

    function mem_data_t read(uvm_reg_addr_t addr);
        mem_data_t value;
        value = '0;
        if (addr < SIZE) begin
            value = data[addr];
        end
        return value;
    endfunction: read

 endclass: ut_design_mem