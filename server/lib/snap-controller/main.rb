puts 'Extending VirtualMachine class for snapshot listing'
class VirtualMachine
    def got_snapshot?
        self.info!
        return !self.to_hash['VM']['TEMPLATE']['SNAPSHOT'].nil?
    end
    def list_snapshots
        out = self.info! || self.to_hash['VM']['TEMPLATE']['SNAPSHOT']
        return out.class == Array ? out : [ out ]
    end
end

puts 'Starting SnapController Thread'
begin
    Thread.new do 
        LOG 'Snapshot Controller has been initialized', 'SnapController'
        while true do
            begin
                proc_id = proc_id_gen('SnapController')                
                vm_pool = VirtualMachinePool.new($client)
                vm_pool.info_all
                target_vms, out, iter, found = [], "", -1, true
                while found do
                    iter += 1
                    found = false
                    vm_pool.each do | vm |
                        target_vms << vm if vm.got_snapshot?
                    end
                    target_vms.each do | vm |
                        active_state = IONe.new($client).LCM_STATE(vm.id) == 3
                        LOG "Collecting snaps from #{vm.id}", 'SnapController'
                        vm.list_snapshots.each do | snap |
                            break if snap.class == Array || snap.nil?
                            age = ((Time.now.to_i - snap['TIME'].to_i) / 3600.0).round(2)
                            out += "\t\t\t\t|  #{age >= 24 ? 'V' : 'X'}  |  #{active_state ? 'V' : 'X'}  |  #{vm.id} |   #{' ' if age < 10}#{age}  | #{snap['NAME']}\n"
                            IONe.new($client).RMSnapshot(vm.id, snap['SNAPSHOT_ID'], false)  || found if age >= 24 && active_state
                        end
                    end
                    sleep(300) if found
                end
                LOG "Detected snapshots:\n\t\t\t\t| rm? | del | vmid |   age   |          name          \n#{out}\nDeleting snapshots, which marked with 'V'", 'SnapController'
                kill_proc(proc_id)
                sleep(3600 - iter * 300)
            rescue => e
                LOG "SnapController Error, code: #{e.message}\nSnapController is down now", 'SnapController'
                sleep(30)
            end
        end
    end
rescue => e
    LOG "SnapController fatal error, service is crashed", 'SnapControllerThread'
end

puts 'Extending Handler class by Snapshot control-methods'
class IONe
    def GetSnapshotList(vmid)
        LOG_STAT(__method__.to_s, time())        
        return onblock(VirtualMachine, vmid).list_snapshots
    end
    def RMSnapshot(vmid, snapid, log = true)
        LOG_STAT(__method__.to_s, time())
        LOG "Deleting snapshot(ID: #{snapid.to_s}) for VM#{vmid.to_s}", "SnapController" if log
        onblock(VirtualMachine, vmid.to_i).snapshot_delete(snapid.to_i)
    end
    def MKSnapshot(vmid, name, log = true)
        LOG_STAT(__method__.to_s, time())
        LOG "Snapshot create-query accepted", 'SnapController' if log
        return onblock(VirtualMachine, vmid.to_i).snapshot_create(name)
    end
    def RevSnapshot(vmid, snapid, log = true)
        LOG_STAT(__method__.to_s, time())
        LOG "Snapshot revert-query accepted", 'SnapController' if log
        return onblock(VirtualMachine, vmid.to_i).snapshot_revert(snapid.to_i)
    end
end