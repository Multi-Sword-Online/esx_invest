--------------------------------------------------
-- 				Don't edit anything here		--
--					Made by Tazio				--
--------------------------------------------------


ESX = nil
Cache = {}
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Get balance of invested companies
RegisterServerEvent("invest:balance")
AddEventHandler("invest:balance", function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    local user = MySQL.Sync.fetchAll('SELECT `amount` FROM `invest` WHERE `identifier`=@id AND active=1', {["@id"] = xPlayer.getIdentifier()})
    local invested = 0
    for k, v in pairs(user) do
        -- print(k, v.identifier, v.amount, v.job)
        invested = math.floor(invested + v.amount)
    end
    TriggerClientEvent("invest:nui", _source, {
        type = "balance",
        player = xPlayer.getName(),
        balance = invested
    })
end)

-- Get available companies
RegisterServerEvent("invest:list")
AddEventHandler("invest:list", function()
    TriggerClientEvent("invest:nui", source, {
        type = "list",
        cache = Cache
    })
end)

-- Get all invested companies
RegisterServerEvent("invest:all")
AddEventHandler("invest:all", function(special)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local sql = 'SELECT `invest`.*, `companies`.`name`,`companies`.`price`,`companies`.`label` FROM `invest` '..
                'INNER JOIN `companies` ON `invest`.`job` = `companies`.`label` '..
                'WHERE `invest`.`identifier`=@id'

    if(special) then 
        sql = sql .. " AND `invest`.`active`=1"
    end

    local user = MySQL.Sync.fetchAll(sql, {["@id"] = xPlayer.getIdentifier()})

    if(special) then
        TriggerClientEvent("invest:nui", _source, {
            type = "sell",
            cache = user
        })
    else 
        TriggerClientEvent("invest:nui", _source, {
            type = "all",
            cache = user
        })
    end
end)

-- Invest into a job
RegisterServerEvent("invest:buy")
AddEventHandler("invest:buy", function(job, amount, rate)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local bank = xPlayer.getAccount('bank').money
    local id = xPlayer.getIdentifier()
    amount = tonumber(amount)
	rate = tonumber(rate)
	purchasePrice = amount * rate

    local inf = MySQL.Sync.fetchAll('SELECT * FROM `invest` WHERE `identifier`=@id AND active=1 AND job=@job LIMIT 1', {["@id"] = id, ['@job'] = job})
    for k, v in pairs(inf) do inf = v end

    if(amount == nil or amount <= 0) then
        return TriggerClientEvent('esx:showNotification', _source, _U('invalid_amount'))
    elseif(Config.Stock.Limit ~= 0 and amount > Config.Stock.Limit) then
        return TriggerClientEvent('esx:showNotification', _source, string.gsub(_U('to_much'), "{limit}", format_int(Config.Stock.Limit)))
    else
        if(bank < purchasePrice) then
            return TriggerClientEvent('esx:showNotification', _source, _U('broke_amount'))
        end
        xPlayer.removeAccountMoney('bank', tonumber(purchasePrice))
    end

    if(type(inf) == "table" and inf.job ~= nil) then
        if Config.Debug then
            print("[esx_invest] Purchasing additional stocks")
        end

        MySQL.Sync.execute("UPDATE `invest` SET amount=amount+@amount, rate=@rate WHERE `identifier`=@id AND active=1 AND job=@job AND totalInvestment=totalInvestment+@purchasePrice", 
            {
                ["@id"] = xPlayer.getIdentifier(), 
                ["@amount"]=amount, 
                ['@job'] = job, 
                ["@purchasePrice"]=purchasePrice,
                ["@rate"]=(((inf.amount * inf.rate) + (amount * rate)) / (inf.amount + amount)) --Average the rate
            })
        
        TriggerClientEvent('esx:showNotification', _source, _U('added'))
    else
        if Config.Debug then
            print("[esx_invest] User new investment")
        end

        if rate == nil then
            return TriggerClientEvent('esx:showNotification', _source, _U('unexpected_error'))
        end

        MySQL.Sync.execute("INSERT INTO `invest` (identifier, job, amount, rate, totalInvestment) VALUES (@id, @job, @amount, @rate, @totalInvestment)", {
            ["@id"] = id,
            ["@job"] = job,
            ["@amount"] = amount,
            ["@rate"] = rate,
			["@totalInvestment"] = purchasePrice,
        })
        
        TriggerClientEvent('esx:showNotification', _source, _U('buy'))
    end

    TriggerEvent(_source, "invest:balance")
end)

-- Sell an investment
RegisterServerEvent("invest:sell")
AddEventHandler("invest:sell", function(job)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    local id = xPlayer.getIdentifier()

    local result = MySQL.Sync.fetchAll( 'SELECT `invest`.*, `companies`.`price` FROM `invest` '..
                                            'INNER JOIN `companies` ON `invest`.`job` = `companies`.`label` '..
                                            'WHERE `identifier`=@id AND active=1 AND job=@job', {["@id"] = id, ['@job'] = job})
    for k, v in pairs(result) do result = v end
	
	sellRate = result.price
	addMoney = sellRate * result.amount
	
        if Config.Debug then
            print("[esx_invest] Selling an investment. Price - Ammount - Money")
			print(sellRate)
			print(result.amount)
			print(addMoney)
        end
	
    MySQL.Sync.execute("UPDATE `invest` SET active=0, sold=now(), soldAmount=@money, rate=@rate WHERE `id`=@id", {["@id"] = result.id, ["@money"] = addMoney, ["@rate"] =  sellRate})

    xPlayer.addAccountMoney('bank', addMoney)
    
    TriggerClientEvent('esx:showNotification', _source, _U('sold'))
    TriggerEvent(_source, "invest:balance")
end)

-- Loop invest rates
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    function loopUpdate()
        Citizen.Wait(60000*Config.Stock.Time)

        if Config.Debug then
            print("[esx_invest] Creating new investments")
        end

        local companies = MySQL.Sync.fetchAll("SELECT * FROM `companies`")
        for k, v in pairs(companies) do

            v.rate = math.random() / 3;
            if((math.random() * 100) < 50) then
                v.rate = v.rate * -1;
            end

            if((math.random() * 100) < Config.Stock.ZeroChance) then
                v.rate = 0;
            end
            
            --Update company share price
            MySQL.Sync.execute("UPDATE `companies` SET price=ROUND(price*(1+@rate), 2), rate=@rate WHERE label=@label", {
                ["@label"] = v.label,
                ["@rate"] = v.rate
            })
            Cache[v.label] = {stock = price, rate = v.rate, label = v.label, name = v.name}
        end
        loopUpdate()
    end

    Citizen.Wait(0) --Don't remove, crashes SQL

    if Config.Debug then
        print("[esx_invest] Powering Up")
    end

    local companies = MySQL.Sync.fetchAll("SELECT * FROM `companies`")
    for k, v in pairs(companies) do
        if(v.rate == nil) then
            v.rate = math.random() / 3;
            if((math.random() * 100) < 50) then
                v.rate = v.rate * -1;
            end

            if((math.random() * 100) < 25) then
                v.rate = 0;
            end

            MySQL.Sync.execute("UPDATE companies SET rate=ROUND(@rate, 2) WHERE label=@label", {
                ["@rate"] = v.rate,
                ["@label"] = v.label
            })
        end

        Cache[v.label] = {stock = v.price, rate = v.rate, label = v.label, name = v.name}
    end
    loopUpdate()
end)

function format_int(number)
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- v1.2 >
-- print(genRand(0, 2, 2)) -- from 0.00 to 2.00
-- print(genRand(1, 2, 2)) -- from 1.00 to 2.00

-- v1.2 <
-- print(genRand(-5, 5, 2)) -- from -5% to 5%
-- print(math.abs(-1 - -2.95)) -- difference between -1% and -2.95%