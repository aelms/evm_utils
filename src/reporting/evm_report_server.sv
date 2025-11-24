/** \brief EVM Report Server
 * 
 * Custom report server that prints the uvm_default_report_server::report_summarize() message plus
 * a custom pass/fail message with ASCII art.
*/

class evm_report_server extends uvm_default_report_server;

    `uvm_object_utils(evm_report_server)

    string m_pass_str = {"\033[32m\n",
"$$$$$$$\\    $$$$$$\\    $$$$$$\\    $$$$$$\\\n",  
"$$  __$$\\  $$  __$$\\  $$  __$$\\  $$  __$$\\\n", 
"$$ |  $$ | $$ /  $$ | $$ /  \\__| $$ /  \\__|\n",
"$$$$$$$  | $$$$$$$$ | \\$$$$$$\\   \\$$$$$$\\\n",  
"$$  ____/  $$  __$$ |  \\____$$\\   \\____$$\\\n", 
"$$ |       $$ |  $$ | $$\\   $$ | $$\\   $$ |\n",
"$$ |       $$ |  $$ | \\$$$$$$  | \\$$$$$$  |\n",
"\\__|       \\__|  \\__|  \\______/   \\______/\n\033[0m"};

    string m_fail_str = {"\033[31m\n",
"$$$$$$$$\\   $$$$$$\\   $$$$$$\\  $$\\\n",       
"$$  _____| $$  __$$\\  \\_$$  _| $$ |\n",      
"$$ |       $$ /  $$ |   $$ |   $$ |\n",     
"$$$$$\\     $$$$$$$$ |   $$ |   $$ |\n",      
"$$  __|    $$  __$$ |   $$ |   $$ |\n",      
"$$ |       $$ |  $$ |   $$ |   $$ |\n",      
"$$ |       $$ |  $$ | $$$$$$\\  $$$$$$$$\\\n", 
"\\__|       \\__|  \\__| \\______| \\________|\n\033[0m"};

    function new(string name = "evm_report_server");
        super.new(name);
    endfunction: new

    virtual function void report_summarize( UVM_FILE file = UVM_STDOUT );
        super.report_summarize(file);
        if (get_severity_count(UVM_ERROR) > 0 || get_severity_count(UVM_FATAL) > 0) begin
            `uvm_info(get_type_name(), $sformatf("Test FAILED:\n%s", m_fail_str), UVM_NONE);
        end else begin
            `uvm_info(get_type_name(), $sformatf("Test PASSED:\n%s", m_pass_str), UVM_NONE);
        end
    endfunction: report_summarize

endclass: evm_report_server