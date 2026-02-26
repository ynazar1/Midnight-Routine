local SHARD_CAP = 600
local SHARD_CURRENCY_ID = 3310

MR:RegisterModule({
    key         = "coffer_key_shards",
    currencyTracked = true,
    label       = "Coffer Key Shards",
    labelColor  = "#e8c96e",
    resetType   = "weekly",
    defaultOpen = true,

    onScan = function(mod)
        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end
        local info = C_CurrencyInfo.GetCurrencyInfo(SHARD_CURRENCY_ID)
        if info then
            db[mod.key]["shards"] = math.min(info.quantity, SHARD_CAP)
        end
    end,

    rows = {
        {
            key          = "shards",
            label        = "|cffe8c96eCoffer Key Shards:|r",
            max          = SHARD_CAP,
            note         = "Earned from Delves & Zekvir encounters\nCap: 600 — used to craft Restored Coffer Keys",
            spellTracked = true,
        },
    },
})

