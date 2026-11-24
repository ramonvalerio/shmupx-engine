-- Estado inicial da partida ranked (states/<jogo>/shmupx_ranked.sta): liga o jogo com NVRAM e
-- configurações novas, põe 1 ficha e, na tela de start com CREDIT 01, salva o estado e fecha.
--
--   shmupx-engine <rom> -rompath <roms> -skip_gameinfo -nvram_directory <vazia> -cfg_directory <vazia> \
--     -state_directory states -autoboot_script tools/mapping/start-state.lua
--
-- SHMUPX_STATE_COIN: quadro da ficha (padrão 600, depois do boot); SHMUPX_STATE_SAVE: quadro do save
-- (padrão ficha + 240). Conferir a foto (snap) antes de publicar: tela de start, 1 crédito.
-- O MAME roda o autoboot de novo em cada reset da máquina: uma cópia só, senão entram 2 fichas.
if SHMUPX_STATE_SUB then return end
local coin_at = tonumber(os.getenv('SHMUPX_STATE_COIN') or '600')
local save_at = tonumber(os.getenv('SHMUPX_STATE_SAVE') or tostring(coin_at + 240))
local coin
for _, port in pairs(manager.machine.ioport.ports) do
	coin = coin or port.fields['Coin 1']
end
assert(coin, 'start-state: sem o campo Coin 1')
local frame = 0
SHMUPX_STATE_SUB = emu.add_machine_frame_notifier(function()
	frame = frame + 1
	if frame == coin_at then coin:set_value(1) elseif frame == coin_at + 6 then coin:set_value(0) end
	if frame == save_at then
		manager.machine:save('shmupx_ranked')
		manager.machine.video:snapshot()
	elseif frame == save_at + 10 then
		manager.machine:exit()
	end
end)
