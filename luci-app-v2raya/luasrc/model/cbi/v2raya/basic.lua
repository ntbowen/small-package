-- Copyright 2008 Yanira <forum-2008@email.de>
-- Licensed to the public under the Apache License 2.0.

local uci = luci.model.uci.cursor()
local m, o, s
require("nixio.fs")

local v2raya_bin = "/usr/bin/v2raya"
	v2raya_version="<b><font style=\"color:red\">"..luci.sys.exec(v2raya_bin.." --version  2>/dev/null").."</font></b>"

m = Map("v2raya")
m.title = translate("v2rayA Client")
m.description = translate("v2rayA is a V2Ray Linux client supporting global transparent proxy, compatible with SS, SSR, Trojan(trojan-go), PingTunnel protocols.")

m:section(SimpleSection).template = "v2raya/v2raya_status"

s = m:section(TypedSection, "v2raya")
s:tab("settings", translate("Basic Setting"))
s:tab("log", translate("Logs"))
s.addremove = false
s.anonymous = true

o = s:taboption("settings", Flag, "enabled", translate("Enabled"))
o.default = o.disabled
o.rmempty = false

o = s:taboption("settings", DummyValue,"v2raya_version",translate("v2rayA Version"))
o.rawhtml  = true
o.value = v2raya_version

o = s:taboption("settings", Value, "address", translate("GUI access address"))
o.description = translate("Use 0.0.0.0:2017 to monitor all access.")
--[[o.datatype = 'ipaddrport(1)']]--
o.default = "http://0.0.0.0:2017"
o.rmempty = false

o = s:taboption("settings", Value, "config", translate("v2rayA configuration directory"))
o.rmempty = '/etc/v2raya'
o.rmempty = false;

o = s:taboption("settings", ListValue, "ipv6_support", translate("Ipv6 Support"))
o.description = translate("Make sure your IPv6 network works fine before you turn it on.")
o:value("auto", translate("AUTO"))
o:value("on", translate("ON"))
o:value("off", translate("OFF"))
o.default = auto
o.rmempty = false

o = s:taboption("settings", Value, "log_file", translate("Log file"))
o.default = "/var/log/v2raya/v2raya.log"
o.rmempty = false
o.readonly = true

o = s:taboption("settings", ListValue, "log_level", translate("Log Level"))
o:value("trace",translate("Trace"))
o:value("debug",translate("Debug"))
o:value("info",translate("Info"))
o:value("warn",translate("Warning"))
o:value("error",translate("Error"))
o.default = "Info"
o.rmempty = false

o = s:taboption("settings", ListValue, "log_max_days", translate("Log Keepd Max Days"))
o.description = translate("Maximum number of days to keep log files is 3 day.")
o.datatype = "uinteger"
o:value("1", translate("1"))
o:value("2", translate("2"))
o:value("3", translate("3"))
o.default = 3
o.rmempty = false

o = s:taboption("settings", Flag, "log_disable_color", translate("Disable log color"))
o.default = o.enabled
o.rmempty = false

o = s:taboption("settings", Flag, "log_disable_timestamp", translate("Log disable timestamp"))
o.default = o.disabled
o.rmempty = false

o = s:taboption("settings", Value, "v2ray_bin", translate("v2ray binary path"))
o.description = translate("Executable v2ray binary path. Auto-detect if put it empty (recommended).")
o.datatype = 'path'

o = s:taboption("settings", Value, "v2ray_confdir", translate("Extra config directory"))
o.description = translate("Additional v2ray config directory, files in it will be combined with config generated by v2rayA.")
o.datatype = 'path'

o = s:taboption("settings", Value, "vless_grpc_inbound_cert_key", translate("Upload certificate"))
o.description = translate("Specify the certification path instead of automatically generating a self-signed certificate.")
o.template = "v2raya/v2raya_certupload"

cert_dir = "/etc/v2raya/"
local path

luci.http.setfilehandler(function(meta, chunk, eof)
	if not fd then
		if (not meta) or (not meta.name) or (not meta.file) then
			return
		end
		fd = nixio.open(cert_dir .. meta.file, "w")
		if not fd then
			path = translate("Create upload file error.")
			return
		end
	end
	if chunk and fd then
		fd:write(chunk)
	end
	if eof and fd then
		fd:close()
		fd = nil
		path = '/etc/v2raya/' .. meta.file .. ''
	end
end)
if luci.http.formvalue("upload") then
	local f = luci.http.formvalue("ulfile")
	if #f <= 0 then
		path = translate("No specify upload file.")
	end
end

o = s:taboption("settings", Value, "vless_grpc_inbound_cert_key", translate("Upload Certificate Path"))
o.description = translate("This is the path where the certificate resides after the certificate is uploaded.")
o.default = "/etc/v2raya/cert.crt,/etc/v2raya/cert.key"

o = s:taboption("log", Value, "log", translate("Logs"))
o.template = "v2raya/v2raya_log"
--[[o.rows = 50]]--

o.inputstyle = "reload"
    luci.sys.exec("/etc/init.d/v2raya start >/dev/null 2>&1 &")

return m