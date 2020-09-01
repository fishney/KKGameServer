--
-- Author: mazhun
-- Date: 2019-02-28
--提供语言工具

local langTool = {}

--将语言表的key翻译成对应的语言
--@param key 语言表中的key
--@lang 语言id 在PDEFINE.LANGUAGE这个table中的index
--@return 执行结果(true表示找到了翻译  false表示没有找到),返回翻译后的字符串,如果key找不到对应的翻译内容 则原样返回
function langTool.trans( key, lang )
    local langtable = PDEFINE.LANGUAGE[lang]
    if langtable == nil then
        return false,key
    end
    local str = langtable.LANG[key]
    if str == nil then
        return false,key 
    end
    return true,str
end

--将语言表的key翻译成所有的语言
--@param key 语言表中的key
--@return 执行结果(true表示找到了翻译  false表示没有找到),返回翻译后的字符串list 如果key找不到对应的翻译内容则返回nil
function langTool.alltranslist( key )
    local translist = {}
    for i,langtable in ipairs(PDEFINE.LANGUAGE) do
        local str = langtable.LANG[key]
        if str == nil then
            return false,nil 
        end
        table.insert(translist, str)
    end
    return true,translist
end

return langTool