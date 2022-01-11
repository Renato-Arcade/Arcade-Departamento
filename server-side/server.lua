-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local Tools = module("vrp","lib/Tools")
vRP = Proxy.getInterface("vRP")
vRPC = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONEXÃO
-----------------------------------------------------------------------------------------------------------------------------------------
vCLIENT = {}
Tunnel.bindInterface("arcade-departamento",vCLIENT)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local machineGlobal = 3600 -- Tempo para poder assaltar um Departamento novamente
local machineStart = false
local machineGlobal = 0
local idgens = Tools.newIDGenerator()
local blips = {}

local policiaisMin = -1 -- Numero minimo de policiais em serviço para poder assaltar
local pagamentoMin = 15000 -- Valor minimo que recebe ao assaltar o Departamento
local pagamentoMax = 25000 -- Valor maximo que recebe ao assaltar o Departamento
local tempoRoubo = 3600 -- Tempo para poder assaltar um Departamento novamente
local recompensa = "dinheirosujo" -- Item dropado quando o Departamento for explodido
-----------------------------------------------------------------------------------------------------------------------------------------
-- VERIFICAÇÃO PARA O INICIO DO ROUBO
-----------------------------------------------------------------------------------------------------------------------------------------
function vCLIENT.startVault()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local policia = vRP.getUsersByPermission("policia.permissao")
		if parseInt(#policia) <= policiaisMin then
			TriggerClientEvent("Notify",source,"aviso","Numero insuficiente de policiais no momentos.",5000)
			return false
		elseif (os.time()-machineGlobal) <= tempoRoubo then
			TriggerClientEvent("Notify",source,"aviso","Os caixas estão vazios, aguarde <b>"..vRP.format(parseInt((tempoRoubo-(os.time()-machineGlobal)))).." segundos</b> até que os civis depositem dinheiro.",8000)
			return false
		else
			if not machineStart then
				machineStart = true
				machineGlobal = os.time()
				vRP.upgradeStress(user_id,10)
				vRP.tryGetInventoryItem(user_id,"c4",1)
				return true
			end
		end
	end
	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHAMADO PARA A POLICIA
-----------------------------------------------------------------------------------------------------------------------------------------
function vCLIENT.callPolice(x,y,z)
	local policia = vRP.getUsersByPermission("policia.permissao")
	for l,w in pairs(policia) do
		local player = vRP.getUserSource(parseInt(w))
		if player then
			async(function()
				local ids = idgens:gen()
				vRPC.playSound(player,"Oneshot_Final","MP_MISSION_COUNTDOWN_SOUNDSET")
				blips[ids] = vRPC.addBlip(player,x,y,z,1,59,"Roubo de Loja de Departamento em andamento",0.5,true)
				TriggerClientEvent('chatMessage',player,"190",{64,64,255},"O roubo começou em uma ^1 Loja de Departamento^0, dirija-se até o local e intercepte o assaltante.")
				SetTimeout(20000,function() vRPC.removeBlip(player,blips[ids]) idgens:free(ids) end)
			end)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINAL DO ROUBO / ENTREGA DE ITENS
-----------------------------------------------------------------------------------------------------------------------------------------
function vCLIENT.stopVault(x,y,z)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		if machineStart then
			machineStart = false
			-- CASO NÃO ESTEJA DROPANDO, PROCURE O SISTEMA DE DROPS DO SEU INVENTARIO E SUBSTITUA NO LUGAR DESSE AQUI.
			TriggerEvent("DropSystem:create",recompensa,parseInt(math.random(pagamentoMin,pagamentoMax)),x,y,z,3600)
			porcentagem = math.random(100)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREAD DO TEMPO
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		if parseInt(machineGlobal) > 0 then
			machineGlobal = parseInt(machineGlobal) - 1
			if parseInt(machineGlobal) <= 0 then
				machineStart = false
			end
		end
		Citizen.Wait(1000)
	end
end)