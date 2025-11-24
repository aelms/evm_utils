/** \brief Unit test UVM register
 *
 * Simple register with two fields, used for UVM register unit tests.
 */
class ut_reg extends uvm_reg;

    `uvm_object_utils(ut_reg)

    rand uvm_reg_field one_bit_rw;

    rand uvm_reg_field eight_bits_rw;

    function new(string name="ut_reg");
        super.new(name,32,0);
        one_bit_rw = uvm_reg_field::type_id::create("one_bit_rw");
        one_bit_rw.configure(this,1,0,"RW",0,0,1,1,1);
        eight_bits_rw = uvm_reg_field::type_id::create("eight_bits_rw");
        eight_bits_rw.configure(this,8,1,"RW",0,127,1,1,1);
    endfunction: new

endclass: ut_reg
