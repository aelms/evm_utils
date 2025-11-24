/** \brief Unit test design queue 
 *
 * Simple mock design that receives, stores and sends out items.
 * Can reorder, drop, duplicate, and modify items to test the comparer's 
 * ability to handle these cases.   
*/
class ut_design_queue extends uvm_component;

    boolean_t m_wait_for_last;
    int       m_drop_item_cnt;
    boolean_t m_reorder_items;

    uvm_analysis_imp#(ut_sequence_item, ut_design_queue) input_imp;
    uvm_analysis_port#(ut_sequence_item)                 output_ap;

    ut_sequence_item item_q[$]; // Queue to store incoming items
    
    `uvm_component_utils(ut_design_queue)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        input_imp = new("input_imp", this);
        output_ap = new("output_ap", this);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    virtual function void write(ut_sequence_item item);
        `uvm_info(get_type_name(), $sformatf("write(): Received item: %s", item.convert2string()), UVM_HIGH)
        
        if(m_wait_for_last) begin
            item_q.push_back(item);
            if(item.m_last) begin
                rx_last_item();
            end             
        end else begin
            output_ap.write(item);
        end
        
    endfunction: write
    
    virtual function void rx_last_item();
        `uvm_info(get_type_name(), "rx_last_item(): Received last item, sending out all items in queue", UVM_HIGH)

        // Drop items
        repeat( m_drop_item_cnt ) begin
            int idx = $urandom_range(0, item_q.size()-1 );
            item_q.delete(idx);
        end

        // Reorder items
        if(m_reorder_items) begin
            item_q.shuffle();
        end

        // Write items out
        while( item_q.size() ) begin
            output_ap.write(item_q.pop_front());
        end
    endfunction: rx_last_item   

endclass: ut_design_queue
