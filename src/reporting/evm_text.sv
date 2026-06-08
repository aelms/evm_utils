/** \brief EVM extension to cl_pkg::txt
 *
 * This file provides an extension to cl_pkg::txt for additional text utilities.
 */ 
virtual class evm_text extends cl::text;

    /* \brief Returns the longest common prefix in a queue of strings */
    static function string longest_common_prefix(string strs[$]);

        string first;
        string last;
    
        if( strs.size() == 0 ) begin
            return "";
        end 
        
        // Sort strings.  First and last are the most different and can be 
        // compared to find the longest common prefix.  
        strs.sort();
        first = strs[0];
        last = strs[strs.size()-1];
        
        for( int i=0; i<first.len() && i<last.len(); i++ )  begin
            if( first[i] == last[i] ) begin
                longest_common_prefix = {longest_common_prefix, string'(first[i]) };
            end else begin
                break;
            end
        end

    endfunction: longest_common_prefix
    
endclass: evm_text
