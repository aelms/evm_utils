
/** \brief RAL field Edge Event
 * 
 * UVM Ral field callback that triggers event member m_posedge_e or m_negedge_e as appropriate
 * after a prediction update to the field.
 * 
 * NOTE: The post_predict() callback method this class relies on is NOT called on a 
 *       uvm_reg_field::predict(.kind(UVM_PREDICT_DIRECT)) 
 */
class ral_field_edge_event extends uvm_reg_cbs;

    `uvm_object_utils(ral_field_edge_event)

    event m_posedge_e; ///< Triggered when posedge on field has been observed

    event m_negedge_e; ///< Triggered when negedge on field has been observed

    function new(string name = "ral_field_edge_event");
        super.new(name);
    endfunction: new

    virtual function void connect(uvm_reg_field fld);
        if( fld.get_n_bits() != 1 ) begin
            `uvm_warning( get_type_name(), $sformatf("connect(): Supplied fld %s is %0d bits in size, expected 1.", fld.get_full_name(), fld.get_n_bits() ) );
        end else begin
            uvm_callbacks#(uvm_reg_field)::add(fld,this);
        end
    endfunction: connect

    virtual function void post_predict(input uvm_reg_field  fld,
                                       input uvm_reg_data_t previous,
                                       inout uvm_reg_data_t value,
                                       input uvm_predict_e  kind,
                                       input uvm_door_e     path,
                                       input uvm_reg_map    map);
        if( previous==0 && value==1 ) begin
            -> m_posedge_e;
        end
        if(  previous==1 && value==0 ) begin
            -> m_negedge_e;
        end
    endfunction: post_predict

endclass: ral_field_edge_event
