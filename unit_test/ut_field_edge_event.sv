class ut_field_edge_event extends ral_field_edge_event;

    `uvm_object_utils(ut_field_edge_event); 

    protected uvm_reg_field m_fld;

    function new(string name="ut_field_edge_event");
        super.new(name);
    endfunction: new

    virtual function void connect(uvm_reg_field fld);
        m_fld = fld;
        super.connect(fld);
    endfunction: connect    

    virtual task self_test();

        // Test posedge
        void'( m_fld.predict(0) );
        fork 
            begin
                fork

                    begin
                        @(m_posedge_e);
                        `uvm_info( get_type_name(), "self_test(): Had m_posedge_e as expected", UVM_NONE );
                    end

                    begin
                        @(m_negedge_e);
                        `uvm_error( get_type_name(), "self_test(): Unexpected m_negedge_e");
                    end

                    begin
                        #2ns;
                        `uvm_error( get_type_name(), "self_test(): Timeout waiting for m_posedge_e");
                    end

                join_any
                disable fork;
            end
        join_none
        #1ns;            
        void'( m_fld.predict(1,,UVM_PREDICT_WRITE) );
        #2ns;

        // Test negedge
        void'( m_fld.predict(1) );
        fork 
            begin
                fork

                    begin
                        @(m_negedge_e);
                        `uvm_info( get_type_name(), "self_test(): Had m_negedge_e as expected", UVM_NONE );
                    end

                    begin
                        @(m_posedge_e);
                        `uvm_error( get_type_name(), "self_test(): Unexpected m_posedge_e");
                    end

                    begin
                        #2ns;
                        `uvm_error( get_type_name(), "self_test(): Timeout waiting for m_negedge_e");
                    end

                join_any
                disable fork;
            end
        join_none
        #1ns;            
        void'( m_fld.predict(0,,UVM_PREDICT_WRITE) );
        #2ns;

        // Test noedge
        void'( m_fld.predict(1) );
        fork 
            begin
                fork

                    begin
                        @(m_negedge_e);
                        `uvm_error( get_type_name(), "self_test(): Unexpected m_negedge" );
                    end

                    begin
                        @(m_posedge_e);
                        `uvm_error( get_type_name(), "self_test(): Unexpected m_posedge_e");
                    end

                    begin
                        #2ns;
                        `uvm_info( get_type_name(), "self_test(): Had no edge as expected", UVM_NONE);
                    end

                join_any
                disable fork;
            end
        join_none
        #1ns;            
        void'( m_fld.predict(1,,UVM_PREDICT_WRITE) );
        #2ns;

    endtask: self_test

endclass: ut_field_edge_event
