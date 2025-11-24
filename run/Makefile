.phony: all build_uvm build clean


all: clean build run

build:
	@echo "Building unit_test..."
	@mkdir -p ../build/unit_test
	verilator -Wno-fatal -Wno-WIDTHEXPAND --Wno-WIDTHTRUNC --Wno-COVERIGN -Wno-CASTCONST -Wno-ZERODLY \
	--binary --exe --vpi --timescale 1ns/1ns -j 4 -Mdir ../build/unit_test  ${CMP_OPTS} \
	+define+UVM_REG_ADDR_WIDTH=32 +define+UVM_REG_DATA_WIDTH=32 +incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm.sv ${VERILATOR_UVM_DPI_HOME}/uvm_dpi.cc \
	+incdir+${CL_HOME}/src ${CL_HOME}/src/cl_pkg.sv ${CL_HOME}/src/cl_dpi.cc \
	+incdir+${EVM_HOME}/src ${EVM_HOME}/evm_utils_pkg.sv \
	+incdir+${EVM_HOME}/unit_test ${EVM_HOME}/unit_test/ut_wallclock_ns.cc ${EVM_HOME}/unit_test/ut_pkg.sv \
	-o sim_verilator --top-module ut_testbench 

run: 
	@echo "Running unit_test..."
	${EVM_HOME}/build/unit_test/sim_verilator +UVM_TESTNAME=ut_testcase +EVM_RAL_LOG_NAME=${EVM_HOME}/build/uvm_reg.log ${RUN_OPTS} | tee ${EVM_HOME}/build/sim.log

clean:
	@echo "Cleaning build artifacts..."
	rm -rf ${EVM_HOME}/build/unit_test ${EVM_HOME}/build/sim.log ${EVM_HOME}/build/uvm_reg.log ${EVM_HOME}/build/uvm_sl_evm_pp.sv

ver_pp: 
	rm -rf ${EVM_HOME}/build/uvm_sl_evm_pp.sv
	slang -E --timescale 1ns/1ns -j 4   \
	+define+UVM_NO_DPI +incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm.sv \
	+incdir+${CL_HOME}/src ${CL_HOME}/src/cl_pkg.sv \
	+incdir+${EVM_HOME}/src ${EVM_HOME}/evm_utils_pkg.sv \
	+incdir+${EVM_HOME}/unit_test  ${EVM_HOME}/unit_test/ut_pkg.sv | \
	tee ${EVM_HOME}/build/uvm_sl_evm_pp.sv
