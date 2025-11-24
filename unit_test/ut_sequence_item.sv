/** \brief Unit test sequence item 
 *
 * Simple sequence item with two randomizable fields ( m_byte and m_word ),
 * field automation, and convert2string() using single_line_printer.
 * Used for scoreboard unit tests.
*/
class ut_sequence_item extends uvm_sequence_item;

    rand bit   [7:0] m_byte;
    rand bit  [31:0] m_word;
    rand bit [127:0] m_dlword;
         string      m_str;
    rand bit         m_last;

    `uvm_object_utils_begin( ut_sequence_item )
        `uvm_field_int(m_byte, UVM_ALL_ON|UVM_HEX)
        `uvm_field_int(m_word, UVM_ALL_ON|UVM_HEX)
        `uvm_field_int(m_dlword, UVM_ALL_ON|UVM_HEX)
        `uvm_field_string(m_str, UVM_ALL_ON|UVM_HEX)
        `uvm_field_int(m_last, UVM_ALL_ON|UVM_HEX)
    `uvm_object_utils_end

    constraint m_last_c {
        soft m_last == 1'b0;
    }

    function new( string name="ut_sequence_item");
        super.new(name);
    endfunction: new

    function void post_randomize();
        bit [7:0] char;
        for( int i=0; i<16; i++ ) begin
            char = $urandom_range( 32, 126 );
            m_str = { m_str, string'(char) };
        end
    endfunction: post_randomize

    `EVM_SLP_CONVERT2STRING

endclass: ut_sequence_item 
