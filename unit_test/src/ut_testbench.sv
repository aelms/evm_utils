module automatic ut_testbench();

    `include "uvm_macros.svh"

    import uvm_pkg::*;
    import cl::*;
    import evm_utils_pkg::*;
    import ut_pkg::*;

    initial begin
        run_test();
    end

endmodule: ut_testbench
