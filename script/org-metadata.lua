-- 创建模块级局部变量存储临时数据
local collected_tags = pandoc.List:new()
local collected_categories = pandoc.List:new()

function RawBlock(el)
    -- 兼容特殊变量，存储到全局变量中, pandoc默认是不识别的
    if el.text:match("^#%+TAGS:") then
        local tags_str = el.text:gsub("#%+TAGS:%s*", "")
        tags_str = tags_str:gsub("[%[%]]", ""):gsub("，", ",")

        -- 将解析结果存入临时列表
        for tag in tags_str:gmatch("[^,]+") do
            collected_tags:insert(pandoc.Str(tag:gsub("^%s*(.-)%s*$", "%1,")))
        end
        return {}  -- 过滤原始元数据行
    end
    if el.text:match("^#%+CATEGORIES:") then
        local categories_str = el.text:gsub("#%+CATEGORIES:%s*", "")
        -- 转换成标准形式
        categories_str = categories_str:gsub("[%[%]]", ""):gsub("，", ",")

        -- 将解析结果存入临时列表
        for category in categories_str:gmatch("[^,]+") do
            collected_categories:insert(pandoc.Str(category:gsub("^%s*(.-)%s*$", "%1,")))
        end
        return {}  -- 过滤原始元数据行
    end
    -- 过滤其他原生元数据
    if el.text:match("^#%+") then return {} end
end

function Meta(meta)
    -- 日期格式优化（支持Org-mode带星期的日期）
    if meta.date then
        local raw_date = pandoc.utils.stringify(meta.date)
        print("[DEBUG] Raw DATE:", raw_date)
        meta.date = raw_date:gsub("%[?(%d+-%d+-%d+)%s*%a*%]?", "%1")
        print("[DEBUG] Processed DATE:", meta.date)
    end

    -- TAGS 解析增强
    if collected_tags then
        print("[DEBUG] Raw TAGS:", pandoc.utils.stringify(collected_tags))
        local tags_str = pandoc.utils.stringify(collected_tags)
        print("[DEBUG] TAGS string:", tags_str)

        tags_str = tags_str:sub(1, -2)
        print("[DEBUG] Cleaned TAGS:", tags_str)

        meta.tags = {}
        table.insert(meta.tags, pandoc.Str(tags_str))
    end

    -- CATEGORIES 解析增强
    if collected_categories then
        print("[DEBUG] Raw COTEGORIES:", pandoc.utils.stringify(collected_categories))
        local categories_str = pandoc.utils.stringify(collected_categories)

        categories_str = categories_str:sub(1, -2)

        meta.categories = {}
        table.insert(meta.categories, pandoc.Str(categories_str))
    end

    return meta
end
