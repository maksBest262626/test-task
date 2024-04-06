local utils = {}

function utils.return_forbidden(message)
    ngx.status = ngx.HTTP_FORBIDDEN
    ngx.header["Content-type"] = 'text/html'
    ngx.say(message or "permission denied!")
    ngx.exit(0)
end

function utils.return_not_found(msg)
    ngx.status = ngx.HTTP_NOT_FOUND
    ngx.header["Content-type"] = "text/html"
    ngx.say(msg or "file not found")
    ngx.exit(0)
end

function utils.is_empty(s)
    return s == nil or s == ''
end

function utils.fsize (file_name)
    local file = assert(io.open(file_name, "r"))   -- open file
    local current = file:seek()                    -- get current position
    local size = file:seek("end")                  -- get file size
    file:seek("set", current)                      -- restore position
    assert(file:close())                           -- close file
    return size
end

function utils.output_file(filepath, mime_type)
    --ngx.header["Cache-Control"] = "no-cache"
    ngx.header["Content-type"] = mime_type
    ngx.header["X-File-Path"] = filepath
    --ngx.header["Content-length"] = helpers.fsize(file_metadata.real_path)

    local file, err = io.open(filepath, 'r')
    assert(file and not err)

    -- first version of reading file, its not suitable for big files
    --data = file:read('*a')
    --io.close(file)
    --ngx.print(data)

    local success = false;
    while true do
        local data, err = file:read(512)
        if err ~= nil then
            ngx.log(ngx.ERR, "file:read() error: ", err)
            break
        end

        if data == nil then
            success = true;
            break
        end

        ngx.print(data)
    end

    local ok, err = file:close()
    assert(ok and not err)

    if success == false then
        utils.return_not_found();
    end

end

return utils;