#!/usr/bin/env lua

-- Steam Offline Mode Manager
-- Программа для переключения офлайн режима Steam аккаунтов
-- A program for switching Steam accounts offline mode

local io = require("io")
local os = require("os")

-- Terminal colors
local colors = {
    reset = "\027[0m",
    red = "\027[31m",
    green = "\027[32m",
    yellow = "\027[33m",
    blue = "\027[34m",
    cyan = "\027[36m",
    white = "\027[37m"
}

-- Translation dictionaries
local translations = {
    ru = {
        language_select = "Select language / Выберите язык:",
        language_ru = "Русский",
        language_en = "English",
        invalid_choice = "Неверный выбор. Попробуйте снова.",
        reading_file = "Чтение файла:",
        checking_backup = "Проверка резервной копии...",
        backup_exists = "Резервная копия уже существует:",
        backup_created = "Резервная копия создана:",
        backup_warning = "Предупреждение: не удалось создать резервную копию:",
        no_users_found = "Ошибка: не найдено ни одного пользователя в файле",
        accounts_list = "=== Список Steam аккаунтов ===",
        offline_mode = "Офлайн режим:",
        enabled = "ВКЛЮЧЕН",
        disabled = "ОТКЛЮЧЕН",
        last_user = " (последний)",
        exit = "Выход",
        select_account = "Выберите аккаунт (0 для выхода):",
        exiting = "Выход из программы",
        user = "Пользователь:",
        currently = "Офлайн режим сейчас:",
        enabled_lower = "включен",
        disabled_lower = "отключен",
        enable = "включить",
        disable = "отключить",
        enable_offline = "включить офлайн режим",
        disable_offline = "отключить офлайн режим",
        back = "Назад",
        select_action = "Выберите действие:",
        success_enabled = "включен",
        success_disabled = "отключен",
        save_error = "✗ Ошибка сохранения:",
        continue_prompt = "Нажмите Enter для продолжения...",
        error_prefix = "Ошибка:",
        offline_for = "Офлайн режим для",
        home_dir_error = "Ошибка: не удалось определить домашнюю директорию"
    },
    en = {
        language_select = "Select language / Выберите язык:",
        language_ru = "Русский",
        language_en = "English",
        invalid_choice = "Invalid choice. Please try again.",
        reading_file = "Reading file:",
        checking_backup = "Checking backup...",
        backup_exists = "Backup already exists:",
        backup_created = "Backup created:",
        backup_warning = "Warning: could not create backup:",
        no_users_found = "Error: no users found in file",
        accounts_list = "=== Steam Accounts List ===",
        offline_mode = "Offline mode:",
        enabled = "ENABLED",
        disabled = "DISABLED",
        last_user = " (last)",
        exit = "Exit",
        select_account = "Select account (0 to exit):",
        exiting = "Exiting program",
        user = "User:",
        currently = "Offline mode currently:",
        enabled_lower = "enabled",
        disabled_lower = "disabled",
        enable = "enable",
        disable = "disable",
        enable_offline = "enable offline mode",
        disable_offline = "disable offline mode",
        back = "Back",
        select_action = "Select action:",
        success_enabled = "enabled",
        success_disabled = "disabled",
        save_error = "✗ Save error:",
        continue_prompt = "Press Enter to continue...",
        error_prefix = "Error:",
        offline_for = "Offline mode for",
        home_dir_error = "Error: could not determine home directory"
    }
}

-- Current language
local current_lang
local t

-- Function for language selection
local function select_language()
    print(colors.cyan .. "\n" .. translations.ru.language_select .. colors.reset)
    print(colors.white .. "[1]" .. colors.reset .. " " .. translations.ru.language_en)
    print(colors.white .. "[2]" .. colors.reset .. " " .. translations.ru.language_ru)
    
    while true do
        io.write(colors.white .. "\nSelect/Выберите (1-2): " .. colors.reset)
        local choice = io.read()
        
        if choice == "1" then
            current_lang = "en"
            t = translations[current_lang]
            break
        elseif choice == "2" then
            current_lang = "ru"
            t = translations[current_lang]
            break
        else
            print(colors.red .. "Invalid choice / Неверный выбор" .. colors.reset)
        end
    end
end

-- Function for reading file
local function read_file(filepath)
    local file = io.open(filepath, "r")
    if not file then
        return nil, "Could not open file / Не удалось открыть файл: " .. filepath
    end
    
    local content = file:read("*all")
    file:close()
    return content
end

-- Function for writing file
local function write_file(filepath, content)
    local file = io.open(filepath, "w")
    if not file then
        return false, "Could not open file for writing / Не удалось открыть файл для записи: " .. filepath
    end
    
    file:write(content)
    file:close()
    return true
end

-- Function for creating backup
local function create_backup(filepath)
    local backup_path = filepath .. ".backup"
    
    -- Check if backup already exists
    local backup_file = io.open(backup_path, "r")
    if backup_file then
        backup_file:close()
        return true, backup_path, true -- true means file already existed
    end
    
    local content, err = read_file(filepath)
    if not content then
        return false, err
    end
    
    local success, write_err = write_file(backup_path, content)
    if success then
        return true, backup_path, false -- false means new file was created
    else
        return false, write_err
    end
end

-- Function for parsing VDF file and extracting users
local function parse_vdf_users(content)
    local users = {}
    
    -- Split content into lines
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line:match("^%s*(.-)%s*$")) -- trim whitespace
    end
    
    -- Go through all lines and look for PersonaName
    for i, line in ipairs(lines) do
        local persona_name = line:match('"PersonaName"%s*"([^"]*)"')
        if persona_name then
            -- Found PersonaName, now look for related data
            local user_id, account_name, wants_offline, most_recent
            
            -- Search backwards for Steam ID
            for j = i - 1, math.max(1, i - 20), -1 do
                if not user_id then
                    user_id = lines[j]:match('"(%d%d%d%d%d%d%d%d%d%d%d%d%d+)"')
                end
                if not account_name then
                    account_name = lines[j]:match('"AccountName"%s*"([^"]*)"')
                end
            end
            
            -- Search forward for WantsOfflineMode and MostRecent
            for j = i + 1, math.min(#lines, i + 20) do
                if not wants_offline then
                    wants_offline = lines[j]:match('"WantsOfflineMode"%s*"([01])"')
                end
                if not most_recent then
                    most_recent = lines[j]:match('"MostRecent"%s*"([01])"')
                end
            end
            
            -- If all necessary data is found, add user
            if user_id and account_name and persona_name then
                local user = {
                    id = user_id,
                    account_name = account_name,
                    persona_name = persona_name,
                    wants_offline_mode = wants_offline or "0",
                    most_recent = most_recent or "0"
                }
                users[#users + 1] = user
            end
        end
    end
    
    return users
end

-- Function for updating WantsOfflineMode value in content
local function update_offline_mode(content, user_id, new_value)
    -- Search for user block
    local user_pattern = '("' .. user_id .. '"%s*%{.-"WantsOfflineMode"%s*)"[^"]*"'
    local replacement = '%1"' .. new_value .. '"'
    
    local new_content = content:gsub(user_pattern, replacement)
    return new_content
end

-- Function for displaying users list
local function display_users(users)
    print(colors.cyan .. "\n" .. t.accounts_list .. colors.reset)
    
    for i, user in ipairs(users) do
        local status_color = user.wants_offline_mode == "1" and colors.green or colors.red
        local status_text = user.wants_offline_mode == "1" and t.enabled or t.disabled
        local recent_mark = user.most_recent == "1" and t.last_user or ""
        
        print(string.format("%s[%d]%s %s%s%s%s", 
            colors.white, i, colors.reset,
            colors.yellow, user.persona_name, colors.reset,
            colors.blue, recent_mark, colors.reset))
        
        print(string.format("    %s%s %s%s", 
            status_color, t.offline_mode, status_text, colors.reset))
    end
    
    print(colors.white .. "\n[0] " .. t.exit .. colors.reset)
end

-- Function for choosing action
local function choose_action(user)
    local current_status = user.wants_offline_mode == "1" and t.enabled_lower or t.disabled_lower
    local action_text = user.wants_offline_mode == "1" and t.disable_offline or t.enable_offline
    
    print(string.format("\n%s %s%s%s", t.user, colors.yellow, user.persona_name, colors.reset))
    print(string.format("%s %s%s%s", t.currently,
        user.wants_offline_mode == "1" and colors.green or colors.red, 
        current_status, colors.reset))
    
    print(string.format("\n%s[1]%s %s", colors.white, colors.reset, action_text:gsub("^%l", string.upper)))
    print(string.format("%s[0]%s %s", colors.white, colors.reset, t.back))
    
    io.write("\n" .. t.select_action .. " ")
    local choice = io.read()
    
    if choice == "1" then
        return user.wants_offline_mode == "1" and "0" or "1"
    else
        return nil
    end
end

-- Main program function
local function main()
    -- Select language
    select_language()
    
    -- Determine file path
    local home = os.getenv("HOME")
    if not home then
        print(colors.red .. t.home_dir_error .. colors.reset)
        return 1
    end
    
    local vdf_path = home .. "/.local/share/Steam/config/loginusers.vdf"
    
    -- Read file
    print(colors.blue .. t.reading_file .. " " .. vdf_path .. colors.reset)
    local content, err = read_file(vdf_path)
    if not content then
        print(colors.red .. t.error_prefix .. " " .. err .. colors.reset)
        return 1
    end
    
    -- Create backup
    print(colors.blue .. t.checking_backup .. colors.reset)
    local backup_success, backup_path, already_exists = create_backup(vdf_path)
    if backup_success then
        if already_exists then
            print(colors.yellow .. t.backup_exists .. " " .. backup_path .. colors.reset)
        else
            print(colors.green .. t.backup_created .. " " .. backup_path .. colors.reset)
        end
    else
        print(colors.yellow .. t.backup_warning .. " " .. backup_path .. colors.reset)
    end
    
    -- Parse users
    local users = parse_vdf_users(content)
    if #users == 0 then
        print(colors.red .. t.no_users_found .. colors.reset)
        return 1
    end
    
    while true do
        -- Show users list
        display_users(users)
        
        io.write(colors.white .. "\n" .. t.select_account .. " " .. colors.reset)
        local choice = io.read()
        local user_index = tonumber(choice)
        
        if user_index == 0 then
            print(colors.green .. t.exiting .. colors.reset)
            break
        elseif user_index and user_index >= 1 and user_index <= #users then
            local selected_user = users[user_index]
            local new_value = choose_action(selected_user)
            
            if new_value then
                -- Update content
                content = update_offline_mode(content, selected_user.id, new_value)
                
                -- Save file
                local success, write_err = write_file(vdf_path, content)
                if success then
                    selected_user.wants_offline_mode = new_value
                    local status = new_value == "1" and t.success_enabled or t.success_disabled
                    print(colors.green .. string.format("\n✓ %s '%s' %s", 
                        t.offline_for, selected_user.persona_name, status) .. colors.reset)
                else
                    print(colors.red .. "\n" .. t.save_error .. " " .. write_err .. colors.reset)
                end
                
                io.write("\n" .. t.continue_prompt)
                io.read()
            end
        else
            print(colors.red .. t.invalid_choice .. colors.reset)
            io.write(t.continue_prompt)
            io.read()
        end
    end
    
    return 0
end

-- Run program
os.exit(main()) 