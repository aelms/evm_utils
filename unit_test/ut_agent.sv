/** \brief Unit test agent
*
* Contains the driver and sequencer for the unit test
*/
class ut_agent extends uvm_agent;

    uvm_sequencer#(ut_sequence_item) m_sqr;
    ut_driver                        m_drv;

    `uvm_component_utils(ut_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_drv = ut_driver::type_id::create("m_drv", this);
        m_sqr = uvm_sequencer#(ut_sequence_item)::type_id::create("m_sqr", this);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_drv.seq_item_port.connect(m_sqr.seq_item_export);
    endfunction: connect_phase

endclass: ut_agent