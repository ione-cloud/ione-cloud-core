puts 'Extending Handler class by IMPORT func'
class WHMHandler
    def IMPORT(params)
        LOG params, 'DEBUG'
        return nil
        if params.class == Hash
            LOG params, 'DEBUG'
            userid = UserCreate(params['username'], params['password'], nil, @client)
            if userid == 0 then
                up = UserPool.new(@client)
                up.info_all!
                up.each do |u|
                    if u.name == params['username'] then
                        userid = u.id
                        break
                    end
                end
            end
            params['vmid'] = GetVMIDbyIP(params['ip']) if params['vmid'].nil?
            vm = get_pool_element(VirtualMachine, params['vmid'], @client)
            vm.chown(userid, USERS_GROUP)
            user = User.new(User.build_xml(userid), @client)
            used = (vm.info! || vm.to_hash)['VM']['TEMPLATE']
            user_quota = (user.info! || user.to_hash)['USER']['VM_QUOTA']
            begin
                user.set_quota(
                    "VM=[
                    CPU=\"#{(used['CPU'].to_i + user_quota['CPU_USED'].to_i).to_s}\", 
                    MEMORY=\"#{(used['MEMORY'].to_i + user_quota['MEMORY_USED'].to_i).to_s}\", 
                    SYSTEM_DISK_SIZE=\"-1\", 
                    VMS=\"#{(user_quota['VMS_USED'].to_i + 1).to_s}\" ]")
            rescue
            end
            vm.rename("user_#{params['serviceid']}_vm")
            return { params['serviceid'] => [userid, params['vmid']] }
        end
        return params.map! do |el|
            el = IMPORT(el)
        end
    end
end