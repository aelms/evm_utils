/** \brief Unit Test Report Catcher
 *
 * Demotes a set of UVM warning messages that are just noise in the unit test
 */
class ut_report_catcher extends uvm_report_catcher;

    `uvm_object_utils(ut_report_catcher)

    function new(string name="ut_report_catcher");
        super.new(name);
    endfunction: new

    virtual function action_e catch();
        if( get_severity() == UVM_WARNING && ( msg_ends_on("is not contained within map 'Backdoor'") ||
                                               msg_ends_on("violates the uvm component name constraints") ||
                                               msg_ends_on(".default_map, skipping") ||
                                               msg_ends_on("sequence not found.  Probable cause: sequence exited or has been killed") ||
                                               msg_ends_on("may not reflect the actual current value.") ) ) begin

            return CAUGHT;
        end
        return THROW;
    endfunction

    virtual function bit msg_ends_on(string end_msg);
        int msg_len = get_message().len();
        if( msg_len < end_msg.len() ) begin
            return 0;
        end
        return ( get_message().substr(msg_len-end_msg.len(),msg_len-1) == end_msg );
    endfunction: msg_ends_on

endclass: ut_report_catcher