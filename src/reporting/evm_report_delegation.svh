
// Macro: EVM_REPORT_DELEGATION_FUNCTIONS
//
// Overview
// --------
// Macro that provides the ability for NON uvm_component objects to delegate 
// uvm_messaging to a uvm_component.  
// 
// Example Output
// --------------
// A message from a uvm_object that is delegated to a component includes the 
// *hierarchy of the component*, the non-component member, and type.  All this is
// important information to debug:
//
// UVM_ERROR @ 5376.495 ns: uvm_test_top.m_env.m_model[1]@@m_comp_model [comp_model] post_read(): ....
//
// The same UVM message without delegation only has the non-component type.  It does
// not have the important hierarchy information required to debug. 
// 
// UVM_ERROR @ 5376.495 ns: reporter [comp_model] post_read(): ...
//
// Details
// -------
// uvm_object extensions do not have direct access to the reporting class hieararchy
// because they are not children of uvm_report_objects nor do they encapsulate an 
// instance of uvm_report_object
// https://verificationacademy.com/verification-methodology-reference/uvm/docs_1.2/html/files/overviews/reporting-txt.html
//
// By default, extensions of uvm_object use the UVM coreservice uvm_report_object 
// instance when issuing messages.  Messages are under global verbosity and severity 
// control AND do not have any information about where they are being issued in the 
// component hierarchy.  
//
// This is a signficant limitation to their messages.  
// - it is necessary to set the global verbosity to get the msg from a single 
//   object or object type adding signficant noise to the log and runtime overhead
// - there is no context info in uvm_object msgs.  Where a uvm_component msgs
//   includes the context or full hiearchical path of the component issuing the msg 
//   a uvm_object msg simply includes the type name. 
//
// This applies to uvm_sequence_item instances but they work around this limitation by
// delegating messaging to the uvm_sequencer they are executing on.  This delegation 
// is provided by duplicating a set of messaging functions locally, so they are 
// available to the UVM messaging macro's (i.e `uvm_info, `uvm_warning, `uvm_error). 
//
// This file provides these functions to ANY uvm_object that is NOT a uvm_report_object
// or child; i.e. anything that is NOT a uvm_component.  Messaging is delegated 
// to a uvm_report_object (normally a related uvm_component).  
// 
// NOTE: The uvm_get_report_object method *MUST* be implemented in the class that
//       wishes to used this macro to delegate messaging.  The following example is
//       a default implementation.
//       This implementation is NOT provided in the macro as it allows delegation to 
//       a uvm_report_object to be setup in another way in a uvm_object that wishes 
//       to delegate.  For example, it may already have an appropriate uvm_report_object
//       available to delegate messaging to.
// 
// \code
// protected uvm_report_object            m_report_object;      ///< Report object for report delegation
//
// virtual function void uvm_set_report_object(uvm_report_object report_object);
//   m_report_object=report_object;
// endfunction
// 
// function uvm_report_object uvm_get_report_object();
//   if( m_report_object ) begin
//      return m_report_object;
//   end else begin
//      return uvm_coreservice_t::get().get_root();
//   end
// endfunction
// \endcode
//
// Note: This code was copied from the uvm_sequence_item implementation (from
//       IEEE-1800.2) with line 153 changed in uvm_process_report_message() to 
//       set_context() with get_name().
//
//****************************************************************************
`define EVM_REPORT_DELEGATION_FUNCTIONS \
function int uvm_report_enabled(int verbosity, \
    uvm_severity severity=UVM_INFO, string id=""); \
    uvm_report_object l_report_object = uvm_get_report_object(); \
    if (l_report_object.get_report_verbosity_level(severity, id) < verbosity) \
        return 0; \
    return 1; \
endfunction \
 \
virtual function void uvm_report( uvm_severity severity, \
        string id, \
        string message, \
        int verbosity = (severity == uvm_severity'(UVM_ERROR)) ? UVM_NONE : \
                        (severity == uvm_severity'(UVM_FATAL)) ? UVM_NONE :  \
                        (severity == uvm_severity'(UVM_WARNING)) ? UVM_NONE : UVM_MEDIUM, \
        string filename = "", \
        int line = 0, \
        string context_name = "", \
        bit report_enabled_checked = 0); \
    uvm_report_message l_report_message; \
    if ((severity == UVM_INFO) && (report_enabled_checked == 0)) begin \
        if (!uvm_report_enabled(verbosity, severity, id)) \
            return; \
    end \
    l_report_message = uvm_report_message::new_report_message(); \
    l_report_message.set_report_message(severity, id, message, \
        verbosity, filename, line, context_name); \
    uvm_process_report_message(l_report_message); \
 \
endfunction \
 \
virtual function void uvm_report_info( string id, \
        string message, \
        int verbosity = UVM_MEDIUM, \
        string filename = "", \
        int line = 0, \
        string context_name = "", \
        bit report_enabled_checked = 0); \
 \
    this.uvm_report(UVM_INFO, id, message, verbosity, filename, line, \
        context_name, report_enabled_checked); \
endfunction \
 \
virtual function void uvm_report_warning( string id, \
        string message, \
        int verbosity = UVM_NONE, \
        string filename = "", \
        int line = 0, \
        string context_name = "", \
        bit report_enabled_checked = 0); \
 \
    this.uvm_report(UVM_WARNING, id, message, verbosity, filename, line, \
        context_name, report_enabled_checked); \
endfunction \
 \
virtual function void uvm_report_error( string id, \
        string message, \
        int verbosity = UVM_NONE, \
        string filename = "", \
        int line = 0, \
        string context_name = "", \
        bit report_enabled_checked = 0); \
 \
    this.uvm_report(UVM_ERROR, id, message, verbosity, filename, line, \
        context_name, report_enabled_checked); \
endfunction \
 \
virtual function void uvm_report_fatal( string id, \
        string message, \
        int verbosity = UVM_NONE, \
        string filename = "", \
        int line = 0, \
        string context_name = "", \
        bit report_enabled_checked = 0); \
 \
    this.uvm_report(UVM_FATAL, id, message, verbosity, filename, line, \
        context_name, report_enabled_checked); \
endfunction \
 \
virtual function void uvm_process_report_message (uvm_report_message report_message); \
    uvm_report_object l_report_object = uvm_get_report_object(); \
    report_message.set_report_object(l_report_object); \
    if (report_message.get_context() == "") \
        report_message.set_context(get_name()); \
    l_report_object.m_rh.process_report_message(report_message); \
endfunction
