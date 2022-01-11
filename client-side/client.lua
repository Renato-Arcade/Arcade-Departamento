-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONEXÃO
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = {}
Tunnel.bindInterface("arcade-departamento",vSERVER)
vSERVER = Tunnel.getInterface("arcade-departamento")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local vaultStart = false
local vaultTimer = 0
local vaultPosX = 0.0
local vaultPosY = 0.0
local vaultPosZ = 0.0
local objectBomb = nil
local vaultExplosionMin = 15 -- Tempo minimo para explodir o cofre da Ammunation
local vaultExplosionMax = 20 -- Tempo maximo para explodir o cofre da Ammunation
-----------------------------------------------------------------------------------------------------------------------------------------
-- ATMS
-----------------------------------------------------------------------------------------------------------------------------------------
local vaults = {
	{ 28.17,-1339.13,29.5,356.42 },
	{ 2549.22,384.87,108.63,90.20 },
	{ 1159.47,-314.01,69.21,101.52 },
	{ -709.77, -904.09,19.22,92.93 },
	{ -1829.26, 798.77,138.2,134.74 },
	{ 378.18, 333.44,103.57,351.84 },
	{ -3250.07, 1004.42,12.84,83.57 },
	{ 1734.86, 6420.88,35.04,336.77 },
	{ 546.43, 2662.74,42.16,188.84 },
	{ 1959.27, 3748.99,32.35,39.54 },
	{ 2672.74, 3286.66,55.25,61.32 },
	{ 1707.94, 4920.45,42.07,330.34 },
	{ -43.42, -1748.31,29.43,53.29 },
	{ -3047.9, 585.64,7.91,109.46 }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREAD DAS ATMS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("arcade-departamento:rouboDepartamento")
AddEventHandler("arcade-departamento:rouboDepartamento",function()
	local ped = PlayerPedId()
	if not vaultStart then
		if not IsPedInAnyVehicle(ped) then
			local coords = GetEntityCoords(ped)
			for k,v in pairs(vaults) do
				local distance = #(coords - vector3(v[1],v[2],v[3]))
				if distance <= 0.6 then
					if vSERVER.startVault() then
						vaultPosX = v[1]
						vaultPosY = v[2]
						vaultPosZ = v[3]
						SetEntityHeading(ped,v[4])
						TriggerEvent("cancelando",true)
						SetEntityCoords(ped,v[1],v[2],v[3]-1)
						vRP._playAnim(false,{{"anim@amb@clubhouse@tutorial@bkr_tut_ig3@","machinic_loop_mechandplayer"}},true)

						Citizen.Wait(10000)
						startthreadvaultstart()
						vaultStart = true
						vRP.removeObjects()
						TriggerEvent("cancelando",false)
						vRP._stopAnim(source,false)
						vaultTimer = math.random(vaultExplosionMin,vaultExplosionMax)
						vSERVER.callPolice(vaultPosX,vaultPosY,vaultPosZ)

						local mHash = GetHashKey("prop_c4_final_green")

						RequestModel(mHash)
						while not HasModelLoaded(mHash) do
							RequestModel(mHash)
							Citizen.Wait(10)
						end

						local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.23,0.0)
						objectBomb = CreateObjectNoOffset(mHash,coords.x,coords.y,coords.z-0.23,true,false,false)
						SetEntityAsMissionEntity(objectBomb,true,true)
						FreezeEntityPosition(objectBomb,true)
						SetEntityHeading(objectBomb,v[4])
						SetModelAsNoLongerNeeded(mHash)
					end
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MACHINE DO TEMPO
-----------------------------------------------------------------------------------------------------------------------------------------
function startthreadvaultstart()
	Citizen.CreateThread(function()
		while true do
			if vaultStart and vaultTimer > 0 then
				vaultTimer = vaultTimer - 1
				if vaultTimer <= 0 then
					vaultStart = false
					DeleteEntity(objectBomb)
					AddExplosion(vaultPosX,vaultPosY,vaultPosZ,2,100.0,true,false,true)
					vSERVER.stopVault(vaultPosX,vaultPosY,vaultPosZ)
				end
			end
			Citizen.Wait(1000)
		end
	end)
end