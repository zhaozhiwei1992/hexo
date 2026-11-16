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
        io.stderr:write("[DEBUG] Raw DATE: " .. raw_date .. "\n")
        meta.date = raw_date:gsub("%[?(%d+-%d+-%d+)%s*%a*%]?", "%1")
        io.stderr:write("[DEBUG] Processed DATE: " .. meta.date .. "\n")
    end

    -- TAGS 解析增强
    if collected_tags then
        io.stderr:write("[DEBUG] Raw TAGS: " .. pandoc.utils.stringify(collected_tags) .. "\n")
        local tags_str = pandoc.utils.stringify(collected_tags)
        io.stderr:write("[DEBUG] TAGS string: " .. tags_str .. "\n")

        tags_str = tags_str:sub(1, -2)
        io.stderr:write("[DEBUG] Cleaned TAGS: " .. tags_str .. "\n")

        meta.tags = {}
        table.insert(meta.tags, pandoc.Str(tags_str))
    end

    -- CATEGORIES 解析增强
    if collected_categories then
        io.stderr:write("[DEBUG] Raw COTEGORIES: " .. pandoc.utils.stringify(collected_categories) .. "\n")
        local categories_str = pandoc.utils.stringify(collected_categories)

        categories_str = categories_str:sub(1, -2)

        meta.categories = {}
        table.insert(meta.categories, pandoc.Str(categories_str))
    end

    return meta
end

-- org 的 =verbatim= 会带 {.verbatim} class, markdown writer 会输出
-- `x`{.verbatim} —— hexo 不认识属性语法, 会把 {.verbatim} 当正文显示。
-- 去掉 class 变成普通 `code`。
function Code(c)
    if c.classes:includes('verbatim') then
        c.classes = {}
        c.attributes = {}
    end
    return c
end
