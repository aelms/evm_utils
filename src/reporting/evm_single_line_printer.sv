/** \brief Single line printer
 * 
 * uvm_line_printer with the extra \n added by uvm_tree_printer::emit() removed.  This 
 * allows a uvm_sequence_item::convert2string() method to be implemented as follows:
 * 
 * \code
 * 
 *  virtual function string convert2string();
 *      return sprint( real_line_printer::get_default() );
 *  endfunction: convert2string
 * 
 * \endcode
 */
class evm_single_line_printer extends uvm_line_printer;

    `uvm_object_utils(evm_single_line_printer)

    local static evm_single_line_printer m_default_evm_single_line_printer;

    function new(string name="");
        super.new(name);
    endfunction: new

    static function evm_single_line_printer get_default();
        if( m_default_evm_single_line_printer == null ) begin
            m_default_evm_single_line_printer = new("single_default_line_printer");
        end
        return m_default_evm_single_line_printer;
    endfunction: get_default

    virtual function string emit();
        return text::chomp( super.emit() );
    endfunction: emit

endclass: evm_single_line_printer

`define EVM_SLP_CONVERT2STRING \
virtual function string convert2string(); \
    return sprint( evm_single_line_printer::get_default() ); \
endfunction: convert2string
