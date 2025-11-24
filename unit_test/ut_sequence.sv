/** \brief Unit test sequence
*
* Sequence of ut_sequence_items
*/
class ut_random_sequence extends uvm_sequence#(ut_sequence_item);

    `uvm_object_utils(ut_random_sequence)

    rand int num_items;

    constraint num_items_c {
        num_items inside {[50:100]};
    }

    function new(string name = "ut_random_sequence");
        super.new(name);
        set_automatic_phase_objection(1);
    endfunction : new

    virtual task pre_start();
        if(!randomize()) begin
            `uvm_error(get_type_name(), "Failed to randomize sequence")
        end
    endtask : pre_start 

    virtual task body();
        ut_sequence_item item;

        repeat ( (num_items-1) ) begin
            `uvm_do(item)
        end
        `uvm_do_with(item, { m_last == 1'b1; }) // Set last item m_last to 1

    endtask : body

endclass : ut_random_sequence