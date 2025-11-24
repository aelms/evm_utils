/** \brief Unit test driver
*
* Sends items to the analysis port.
*/
class ut_driver extends uvm_driver#(ut_sequence_item);

    uvm_analysis_port#(ut_sequence_item) item_ap;

    `uvm_component_utils(ut_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_ap = new("item_ap", this);
    endfunction: new

    virtual task run_phase(uvm_phase phase);
        forever begin
            ut_sequence_item item;
            seq_item_port.get_next_item(item);
            `uvm_info(get_type_name(), $sformatf("run_phase(): Next item: %s", item.convert2string()), UVM_HIGH)
            item_ap.write(item);
            seq_item_port.item_done();
        end
    endtask: run_phase

endclass: ut_driver
