local metadata_url = "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token"
local refresh_margin = 225
local retry_delay = 5

local token = nil
local expires_at = 0
local refresh_after = 0
local retry_after = 0
local refreshing = false

local function valid_token(now)
    return token ~= nil and now < expires_at
end

local function cached_token()
    local now = os.time()

    if token ~= nil and now < refresh_after then
        return token
    end

    if refreshing or now < retry_after then
        if valid_token(now) then
            return token
        end

        return nil
    end

    refreshing = true

    local ok, response = pcall(function()
        local client = core.httpclient()

        return client:get({
            url = metadata_url,
            headers = {
                ["Metadata-Flavor"] = { "Google" },
            },
            timeout = 2000,
        })
    end)

    refreshing = false

    if not ok or response == nil or response.status ~= 200 or response.body == nil then
        retry_after = os.time() + retry_delay
        core.Warning("Failed to obtain Google access token from metadata server")

        if valid_token(os.time()) then
            return token
        end

        return nil
    end

    local access_token = response.body:match('"access_token"%s*:%s*"([^"]+)"')
    local expires_in = tonumber(response.body:match('"expires_in"%s*:%s*(%d+)'))

    if access_token == nil or expires_in == nil then
        retry_after = os.time() + retry_delay
        core.Warning("Invalid Google metadata token response")

        if valid_token(os.time()) then
            return token
        end

        return nil
    end

    local now_after_refresh = os.time()

    token = access_token
    expires_at = now_after_refresh + expires_in
    refresh_after = math.max(now_after_refresh, expires_at - refresh_margin)
    retry_after = 0

    return token
end

local function authenticate(txn)
    local access_token = cached_token()

    if access_token == nil then
        return
    end

    txn.http:req_set_header("Authorization", "Bearer " .. access_token)
    txn:set_var("txn.gcp_auth_ok", "1")
end

core.register_action("gcp-auth", { "http-req" }, authenticate)
