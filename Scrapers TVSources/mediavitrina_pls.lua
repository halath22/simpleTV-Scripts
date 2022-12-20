-- скрапер TVS для загрузки плейлиста "Витрина ТВ" https://vitrina.tv (20/12/22)
-- Copyright © 2017-2022 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- видоскрипт: mediavitrina.lua
-- ## переименовать каналы ##
local filter = {
	{'Звезда - RU', 'Звезда'},
	}
	module('mediavitrina_pls', package.seeall)
	local my_src_name = 'Витрина ТВ'
	local function ProcessFilterTableLocal(t)
		if not type(t) == 'table' then return end
		for i = 1, #t do
			t[i].name = tvs_core.tvs_clear_double_space(t[i].name)
			for _, ff in ipairs(filter) do
				if (type(ff) == 'table' and t[i].name == ff[1]) then
					t[i].name = ff[2]
				end
			end
		end
	 return t
	end
	function GetSettings()
	 return {name = my_src_name, sortname = '', scraper = '', m3u = 'out_' .. my_src_name .. '.m3u', logo = '..\\Channel\\logo\\Icons\\mediavitrina.png', TypeSource = 1, TypeCoding = 1, DeleteM3U = 1, RefreshButton = 1, show_progress = 0, AutoBuild = 0, AutoBuildDay = {0, 0, 0, 0, 0, 0, 0}, LastStart = 0, TVS = {add = 1, FilterCH = 1, FilterGR = 1, GetGroup = 1, LogoTVG = 1}, STV = {add = 1, ExtFilter = 1, FilterCH = 1, FilterGR = 1, GetGroup = 1, HDGroup = 0, AutoSearch = 1, AutoNumber = 0, NumberM3U = 0, GetSettings = 1, NotDeleteCH = 0, TypeSkip = 1, TypeFind = 1, TypeMedia = 0, RemoveDupCH = 1}}
	end
	function GetVersion()
	 return 2, 'UTF-8'
	end
	function LoadFromSite()
		local session = m_simpleTV.Http.New('Mozilla/5.0 (Windows NT 10.0; rv:102.0) Gecko/20100101 Firefox/102.0')
			if not session then return end
		m_simpleTV.Http.SetTimeout(session, 8000)
		local url = decode64('aHR0cHM6Ly9zdGF0aWMtYXBpLm1lZGlhdml0cmluYS5ydS92MS92aXRyaW5hdHZfYXBwL3dlYi8zL2NvbmZpZy5qc29u')
		local rc, answer = m_simpleTV.Http.Request(session, {url = url})
			if rc ~= 200 then return end
		answer = answer:gsub('\\', '\\\\')
		answer = answer:gsub('\\"', '\\\\"')
		answer = answer:gsub('\\/', '/')
		answer = answer:gsub('%[%]', '""')
		answer = unescape3(answer)
		require 'json'
		local err, tab = pcall(json.decode, answer)
			if not tab
				or not tab.result
				or not tab.result.channels
			then
			 return
			end
		local t = {}
			for i = 1, #tab.result.channels do
				t[#t + 1] = {}
				t[#t].name = tab.result.channels[i].channel_title
				t[#t].address = tab.result.channels[i].web_player_url
				t[#t].logo = tab.result.channels[i].channel_img.active
			end
		local t1 = {}
			for i = 1, #t do
				local plusCh = nil
				local rc, answer = m_simpleTV.Http.Request(session, {url = t[i].address})
				if rc == 200 then
					for title, adr in answer:gmatch('{%s*"title":%s*"([^"]+)"%s*,%s*"streams_api_url":%s*"([^"]+)') do
						t1[#t1 + 1] = {}
						title = unescape3(title)
						title = title:gsub('МСК', ''):gsub('Часовые пояса', ''):gsub('%.', ''):gsub('Ext', ''):gsub('%+0', '')
						t1[#t1].name = title
						t1[#t1].address = adr:gsub('\\/', '/')
						t1[#t1].logo = t[i].logo
						plusCh = true
					end
				end
				if not plusCh then
					t1[#t1 + 1] = {}
					t1[#t1] = t[i]
				end
			end
	 return t1
	end
	function GetList(UpdateID, m3u_file)
			if not UpdateID then return end
			if not m3u_file then return end
			if not TVSources_var.tmp.source[UpdateID] then return end
		local Source = TVSources_var.tmp.source[UpdateID]
		local t_pls = LoadFromSite()
			if not t_pls or #t_pls == 0 then return end
		t_pls = ProcessFilterTableLocal(t_pls)
		local m3ustr = tvs_core.ProcessFilterTable(UpdateID, Source, t_pls)
		local handle = io.open(m3u_file, 'w+')
			if not handle then return end
		handle:write(m3ustr)
		handle:close()
	 return 'ok'
	end
-- debug_in_file(#t_pls .. '\n')
