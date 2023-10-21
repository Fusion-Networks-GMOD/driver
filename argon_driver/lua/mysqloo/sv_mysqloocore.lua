local string_StartWith = string.StartWith
local string_sub = string.sub
local pairs = pairs
local table_insert = table.insert
local sql_Query = sql.Query
local sql_SQLStr = sql.SQLStr
local string_format = string.format
local tobool = tobool
local net_Start = net.Start
local net_WriteTable = net.WriteTable
local net_WriteInt = net.WriteInt
local net_Send = net.Send
local net_ReadString = net.ReadString
ARGON.Driver = ARGON.Driver or {}
ARGON.Driver.Queue = {}

ARGON.Driver.MySQL = {}
ARGON.Driver.MySQL.Enabled		= true 	-- MYSQLOO or SQLITE [API NEEDS MYSQLOO!]
ARGON.Driver.MySQL.Server		= ''	-- Your MySQL server address.
ARGON.Driver.MySQL.Username		= ''	-- Your MySQL username.
ARGON.Driver.MySQL.Password		= ''	-- Your MySQL password.
ARGON.Driver.MySQL.Database		= ''	-- Your MySQL database. (If you're using MySQL then you will need to make this database)
ARGON.Driver.MySQL.Port			= 3306	-- Your MySQL port. Most likely is 3306 (default).

ARGON.Driver.Prefix = "Argon-Driver"
ARGON.Driver.Color = Color( 0 , 255 , 0)

function ARGON.Driver:AddLog(sqltype, log)
	MsgC(self.Color, "[" .. self.Prefix .. " " .. sqltype .. "] ")
	
	local len = #log
	local count = len / 1023 - (len / 1023) % 1 + 1
	local color = string_StartWith(log, "Error!") and Color(255, 0, 0) or color_white

	for i=1, count do
		MsgC(color, string_sub(log, (i - 1) * 1023, i * 1023))
	end

	MsgC("\n")
end

function ARGON.Driver:ConnectMySql()
	require('mysqloo')
	
	if not mysqloo then
		ARGON.Driver:AddLog("MySQL", "MySQLoo is not installed")
		return nil
	end

	ARGON.Driver.MySQL.DB = mysqloo.connect(ARGON.Driver.MySQL.Server == "localhost" and "127.0.0.1" or ARGON.Driver.MySQL.Server, ARGON.Driver.MySQL.Username, ARGON.Driver.MySQL.Password, ARGON.Driver.MySQL.Database, ARGON.Driver.MySQL.Port)
	
	function ARGON.Driver.MySQL.DB:onConnected()
		ARGON.Driver:AddLog("MySQL", "Connected")

		for k,v in pairs(ARGON.Driver.Queue) do
			ARGON.Driver:Query(v[1], v[2])
		end
		
		ARGON.Driver.Queue = {}
	end

	function ARGON.Driver.MySQL.DB:onConnectionFailed(err)
		ARGON.Driver:AddLog("MySQL", "Error! Connection Failed, please check your settings: " .. err .. "\n")
	end

	ARGON.Driver.MySQL.DB:connect();
	ARGON.Driver.MySQL.DB:wait();
end

if ARGON.Driver.MySQL.Enabled then
	ARGON.Driver:ConnectMySql()
end

function ARGON.Driver:Query(str, func)
	if ARGON.Driver.MySQL.Enabled then
		if ARGON.Driver.MySQL.DB then
			local q = ARGON.Driver.MySQL.DB:query(str)
			if not q then
				if func then
					table_insert(ARGON.Driver.Queue, {str, func})
					ARGON.Driver.MySQL.DB:connect()
				end
				return
			end
			function q:onSuccess(data)
				if func then
					func(data)
				end
				result = data
			end
			function q:onError(err)
				if ARGON.Driver.MySQL.DB:status() == mysqloo.DATABASE_NOT_CONNECTED then
					table_insert(ARGON.Driver.Queue, {str, func})
					ARGON.Driver.MySQL.DB:connect()
					return
				end
				ARGON.Driver:AddLog("MySQL", "Error! The query \"" .. (str or "") .. "\" failed: " .. (err or ""))
			end
			q:start();
			q:wait();
			return result
		else
			table_insert(ARGON.Driver.Queue, {str, func})
		end
	else
		local result = sql_Query(str)
		if (sql.LastError() ~= nil) and (sql.LastError() ~= "") then
			ARGON.Driver:AddLog("SQLite", "Error! The query \"" .. (str ~= nil and str or "") .. "\" failed: " .. (sql.LastError() ~= nil and sql.LastError() or ""))
			return
		end
		if func then
			func(result)
		end
		return result
	end
end

hook.Run("ArgonDriver::Ready" , true)
