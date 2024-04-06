---------------------------------------------------
-- Backend part for FileManager component
-- required for getting files from cache with checking permissions
--
-- Additional links:
-- https://www.nginx.com/resources/wiki/modules/lua/
-- https://openresty-reference.readthedocs.io/en/latest/Lua_Nginx_API/
-- https://www.gakhov.com/articles/implementing-api-based-fileserver-with-nginx-and-lua.html
-- https://github.com/utix/lua-resty-cookie
-- https://www.tutorialspoint.com/lua/lua_file_io.htm
-- https://www.lua.org/pil/8.3.html
-- http://www.troubleshooters.com/codecorn/lua/luaif.htm

local helpers = require("utils")
local cjson = require "cjson"

--helpers.return_forbidden(os.getenv("REDIS_HOST"))
--helpers.return_forbidden(ngx.var.REDIS_HOST)

if helpers.is_empty(ngx.var.cache_key) then
    helpers.return_forbidden("incorrect link")
end

local cookie_reader = require "resty.cookie"
local cookie, err = cookie_reader:new()
if not cookie then
    ngx.log(ngx.ERR, err);
    helpers.return_forbidden();
end

local function get_cookie_var(name)
    local field, err = cookie:get(name)
    if not field then
        ngx.log(ngx.ERR, err);
        helpers.return_forbidden();
    end

    return field
end

local redis_connector = require("resty.redis.connector").new({
    connect_timeout = 50,
    send_timeout = 5000,
    read_timeout = 5000,
    keepalive_timeout = 30000,

    host = ngx.var.REDIS_HOST,
    port = ngx.var.REDIS_PORT,
    db = ngx.var.REDIS_DB,
    password = "",
})

local redis, err = redis_connector:connect()
if err then
    ngx.log(ngx.ERR, "failed to connect with redis", err);
    helpers.return_forbidden();
end

local file_data, err = redis:get(ngx.var.REDIS_CACHE_PREFIX .. ngx.var.cache_key)
if not file_data then
    ngx.log(ngx.ERR, "failed to get file info by hash", err);
    helpers.return_forbidden();
end

if helpers.is_empty(file_data) then
    ngx.log(ngx.ERR, "data by hash not exist", ngx.var.cache_key);
    helpers.return_forbidden();
end

-- output based on src/Dto/FileManager/File/FileDto.php
-- example:
-- {
--    "owner_token": "lkf3lnkv5qia4i9qkvigqp4ukm",
--    "permissions": "15|0|0",
--    "group": "personal",
--    "real_path": "/var/www/var/media/products/e4/04/e4048da600f3edf03e6e54d8a46c520451576c3836aca614987f8cc4625d619f.jpg",
--    "mime_type": "image/jpeg"
--}
file_metadata = cjson.decode(file_data)
if helpers.is_empty(file_metadata) then
    ngx.log(ngx.ERR, "bad file metadata", ngx.var.cache_key);
    helpers.return_forbidden();
end

local function check_permissions(token, file_metadata)
    -- TODO add additional checks for "permissions" data
    -- TODO also need rules for special users like: admins, managers we can use user groups getting info from user cache
    -- TODO and if they have group "admin" for example they can do everything
    return token == file_metadata.owner_token
end

-- file_metadata created by src/Service/DataStorage/FileDataStorage.php
-- based on src/Dto/FileManager/File/FileDto.php
-- so this encrypt/decrypt logic MUST be equal to each other
if check_permissions(get_cookie_var("PHPSESSID"), file_metadata) == false then
    helpers.return_forbidden()
end

helpers.output_file(file_metadata.real_path, file_metadata.mime_type)