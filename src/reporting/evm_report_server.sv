/** \brief EVM Report Server
 * 
 * Custom report server 
 * - optionally prints filename without path in messages
 * - prints a custom pass/fail message with ASCII art (plus base message) 
*/
class evm_report_server extends uvm_default_report_server;

    bit              m_short_filename = 1;
    protected string m_dir_sep = "/";

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

    extern function new(string name = "evm_report_server");

`ifndef UVM_REPORT_DISABLE_FILE
    extern virtual function string compose_report_message(uvm_report_message 	report_message,	  	
   	                                                      string 	            report_object_name	 = 	"");
`endif

    extern virtual function void report_summarize( UVM_FILE file = UVM_STDOUT );

endclass: evm_report_server

`ifdef UVM_REPORT_DISABLE_FILE

// Filename is disabled, no need to set seperator or override compose_report_message
function evm_report_server::new(string name = "evm_report_server");
    super.new(name);
endfunction: new  

`else 

function evm_report_server::new(string name = "evm_report_server");
    super.new(name);
    if( text::contains(`__FILE__, "\\") ) begin
        m_dir_sep = "\\";
    end
endfunction: new

function string evm_report_server::compose_report_message(uvm_report_message 	report_message,	  	
   	                                                      string 	            report_object_name	 = 	"");
    if( m_short_filename ) begin
        string filename;
        filename = report_message.get_filename();
        if( text::contains(filename, m_dir_sep) ) begin
            string str[3];
            str = text::rpartition(filename, m_dir_sep);
            report_message.set_filename(str[2]);
        end
    end
    return super.compose_report_message(report_message, report_object_name);
endfunction: compose_report_message
`endif

function void evm_report_server::report_summarize( UVM_FILE file = UVM_STDOUT );
    super.report_summarize(file);
    if (get_severity_count(UVM_ERROR) > 0 || get_severity_count(UVM_FATAL) > 0) begin
        `uvm_info(get_type_name(), $sformatf("Test FAILED:\n%s", m_fail_str), UVM_NONE);
    end else begin
        `uvm_info(get_type_name(), $sformatf("Test PASSED:\n%s", m_pass_str), UVM_NONE);
    end
endfunction: report_summarize
