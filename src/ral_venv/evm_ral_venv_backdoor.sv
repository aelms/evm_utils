/** \brief RAL Virtual Environment Backdoor
 * 
 * RAL register backdoor for RAL only virtual environment.  Executes backdoor accesses
 * directly on the RAL model it is attached to.  The default value for the read/write()
 * task uvm_reg_item::status is UVM_IS_OK.  Writes are already applied to the mirror by
 * RAL access.  Therefore, it is only necessary to return the read() value from the mirror.
 */
class evm_ral_venv_backdoor extends uvm_reg_backdoor;

    protected uvm_reg_block m_reg_blk;

    `uvm_object_utils(evm_ral_venv_backdoor)

    extern function new(string name = "evm_ral_venv_backdoor");
    extern virtual function void build_backdoor( uvm_reg_block reg_blk );
    extern virtual task read(uvm_reg_item rw);
    extern virtual task write(uvm_reg_item rw);

endclass: evm_ral_venv_backdoor

function evm_ral_venv_backdoor::new(string name = "evm_ral_venv_backdoor");
    super.new(name);
endfunction: new

function void evm_ral_venv_backdoor::build_backdoor( uvm_reg_block reg_blk );
    uvm_reg regs[$];
    m_reg_blk = reg_blk;
    m_reg_blk.get_registers(regs);
    foreach( regs[i] ) begin
        regs[i].set_backdoor(this);
    end
endfunction: build_backdoor

task evm_ral_venv_backdoor::read(uvm_reg_item rw);
    uvm_reg target_reg;
    $cast(target_reg, rw.element);
    rw.value = new[1];
    rw.value[0] = target_reg.get_mirrored_value();
    wait(0);
endtask: read

task evm_ral_venv_backdoor::write(uvm_reg_item rw);
    wait(0);
endtask: write   