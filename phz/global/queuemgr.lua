--
-- Author: mz
-- Date: 2019-03-23
-- 队列table

--队列集合 key,queue
local queuetable = {}

return function()
    local queuemgr = {}

    --清除掉一个队列
    --@param key 队列的key
    function queuemgr.freeQueue( key )
        -- LOG_DEBUG("queuemgr.freeQueue:", key)
        queuetable[key] = nil
    end

    --获取一个已经设置的队列
    --@param key 队列的key
    --@param uncreatewhilenil 没有数据的时候是否创建
    --@return 队列，如果不存在则返回nil
    function queuemgr.getQueue( key, uncreatewhilenil )
        -- LOG_DEBUG("queuemgr.getQueue:", key)
        local q = queuetable[key]
        if not uncreatewhilenil then
            if q == nil then
                queuemgr.setQueue( key )
                q = queuetable[key]
            end
        end
        return q
    end

    --设置队列，如果已经设置过了就不做修改 没有设置过就会新创建一个queue
    --@param key 队列的key
    function queuemgr.setQueue( key )
        LOG_DEBUG("queuemgr.setQueue:", key)
        local queuetemp = queuemgr.getQueue(key, true)
        if queuetemp == nil then
            LOG_DEBUG("queuemgr.newsetQueue:", key)
            queuetemp = require "skynet.queue"()
            queuetable[key] = queuetemp
        end
        LOG_DEBUG("queuemgr.setQueue end")
    end

    return queuemgr
end