.phony: all build_uvm build clean

all: clean build run

# Failed experiment to build UVM as a library. Verilator does not support lib-create with timing, which is required for UVM.
# https://github.com/verilator/verilator/issues/4410
build_uvm:
	@echo "Building UVM..."
	@mkdir -p ../build/uvm
	verilator -Wno-fatal --cc --build --lib-create UVM -j 4 -Mdir ../build/uvm \
	+define+UVM_NO_DPI +define+UVM_REPORT_DISABLE_FILE_LINE +incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm.sv


build:
	@echo "Building unit_test..."
	@mkdir -p ../build/unit_test
	verilator -Wno-fatal --binary --exe --timescale 1ns/1ns -j 2 -Mdir ../build/unit_test  \
	+define+UVM_NO_DPI +define+UVM_REPORT_DISABLE_FILE_LINE +incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm.sv \
	+incdir+${CLUELIB_HOME}/src ${CLUELIB_HOME}/src/cl_pkg.sv ${CLUELIB_HOME}/src/cl_dpi.cc \
	-f ${EVM_UTILS_HOME}/unit_test/ut.f ${EVM_UTILS_HOME}/unit_test/ut_wallclock_ns.cc --top-module ut_testbench

run: 
	@echo "Running unit_test..."
	../build/unit_test/Vut_testbench +UVM_TESTNAME=ut_testcase | tee ../build/sim.log

clean:
	@echo "Cleaning build artifacts..."
	rm -rf ../build/unit_test ../build/sim.log
