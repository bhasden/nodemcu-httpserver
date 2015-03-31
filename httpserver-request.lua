-- httpserver-request
-- Part of nodemcu-httpserver, parses incoming client requests.
-- Author: Marcos Kirsch

local function validateMethod(method)
   local httpMethods = {GET=true, HEAD=true, POST=true, PUT=true, DELETE=true, TRACE=true, OPTIONS=true, CONNECT=true, PATCH=true}
   if httpMethods[method] then return true else return false end
end

local function uriToFilename(uri)
   return "http/" .. string.sub(uri, 2, -1)
end

local function parseArgs(args)
   local r = {}; i=1
   if args == nil or args == "" then return r end
   for arg in string.gmatch(args, "([^&]+)") do
      local name, value = string.match(arg, "(.*)=(.*)")
      if name ~= nil then r[name] = value end
      i = i + 1
   end
   return r
end

local function parseHeaders(content)
    local r = {}

    for line in content:gmatch("[^\n]+") do 
        local _, _, name, value = line:find("^([^:]+)%s*:%s*(.+)")
        
        if name ~= nil then
            r[name] = value
        end
    end

    return r
end

local function parseForm(content, headers)
    local contentType = headers["Content-Type"]
    local r = {}

    if contentType ~= nil and contentType:find("x-www-form-urlencoded", 1, true) then
        local length = headers["Content-Length"]

        if length ~= nil then
            r = parseArgs(content:sub(content:len() - length):match("^%s*(.-)%s*$"))
        end
    end

    return r
end

local function parseUri(uri)
    local r = {}
    if uri == nil then return r end
    if uri == "/" then uri = "/index.html" end
    questionMarkPos, b, c, d, e, f = uri:find("?")
    if questionMarkPos == nil then
        r.file = uri:sub(1, questionMarkPos)
        r.args = {}
    else
        r.file = uri:sub(1, questionMarkPos - 1)
        r.args = parseArgs(uri:sub(questionMarkPos+1, #uri))
    end
    _, r.ext = r.file:match("(.+)%.(.+)")

    r.file = uriToFilename(r.file)

    if r.ext == nil then
        local supportedExtensions = {"lua", "lc", "html"}
    
        for i,extension in pairs(supportedExtensions) do
            local fileExists = file.open(r.file .. "." .. extension, "r")
            file.close()
            
            if fileExists then
                r.ext = extension
                r.file = r.file .. "." .. extension
                break
            end
        end
    end
   
    r.isScript = r.ext == "lua" or r.ext == "lc"
    return r
end

-- Parses the client's request. Returns a dictionary containing pretty much everything
-- the server needs to know about the uri.
return function (request)
   local e = request:find("\n", 1, true)
   if not e then return nil end
   local line = request:sub(1, e - 1):match("^%s*(.-)%s*$")
   local r = {}
   _, i, r.method, r.request = line:find("^([A-Z]+) (.-) HTTP/[1-9]+.[0-9]+$")
   r.methodIsValid = validateMethod(r.method)
   r.uri = parseUri(r.request)
   r.headers = parseHeaders(request)
   r.form = parseForm(request, r.headers)
   return r
end
