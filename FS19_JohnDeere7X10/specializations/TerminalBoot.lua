----------------------------------------------------------------------------------------------------------------------
-- @date: 		Initial Release Unknown
-- @history: 	Unknown
-- @author:		Unknown

-- @version: 	1.4 	-- 	EditDate 03.06.2017 Edit by Marc-Modding & Blacky_BPG
-- @version: 	1.3a 	-- 	Convert to FS17 / EditDate 27.05.2017 Edit by Marc-Modding & Blacky_BPG
-- @version: 	1.1 	-- 	Convert to FS15 / EditDate 20.02.2016 Edit by Marc-Modding & Blacky_BPG

-- @version     1.4a    --  EditDate 09.06.2019 Edit by Ahran Modding
-- @version     2.0     --  EditDate 30.12.2019 Edit by Ifkonator

-- @version     2.0a    --  EditDate 04.01.2020 Edit by Ahran Modding

-- PERMISSION ONLY FOR AHRAN MODDING!

----------------------------------------------------------------------------------------------------------------------

TerminalBoot = {}
TerminalBoot.currentModName = g_currentModName;

local function getSpecName(self, specName, currentModName)
	local spec = self["spec_" .. Utils.getNoNil(currentModName, TerminalBoot.currentModName) .. "." .. specName];

	if spec ~= nil then
        return spec;
    end;

    return self["spec_" .. specName];
end;

function TerminalBoot.prerequisitesPresent(specializations) 
    return true;
end;

function TerminalBoot.registerEventListeners(vehicleType)
	local functionNames = {
		"onPreLoad",
		"onLoad",
		"onUpdate",
	};

	for _, functionName in ipairs(functionNames) do
		SpecializationUtil.registerEventListener(vehicleType, functionName, TerminalBoot);
	end;
end;

function TerminalBoot:onPreLoad(savegame)
    self.setLightsTypesMask = Utils.prependedFunction(self.setLightsTypesMask, TerminalBoot.setLightsTypesMask);
end;

function TerminalBoot:onLoad(savegame)
	local specTerminalBoot = getSpecName(self, "terminalBoot");

	specTerminalBoot.configName = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.terminalBootLoader.challengerSound#configName"), "");
    specTerminalBoot.activeConfigs = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.terminalBootLoader.challengerSound#activeConfigs"), "");
	specTerminalBoot.isChallangerIsBought = false;

	specTerminalBoot.lightsAreOn = false;

	if specTerminalBoot.configName ~= "" and specTerminalBoot.activeConfigs ~= "" then
		local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName);

		if storeItem ~= nil then
			if storeItem.configurations ~= nil and storeItem.configurations[specTerminalBoot.configName] ~= nil then
				local configurations = storeItem.configurations[specTerminalBoot.configName];
    	        local config = configurations[self.configurations[specTerminalBoot.configName]];
				local activeConfigs = StringUtil.splitString(" ", specTerminalBoot.activeConfigs);

				for _, activeConfig in pairs(activeConfigs) do
					if g_i18n:hasText(activeConfig) then
						activeConfig = g_i18n:getText(activeConfig);
					end;

					if config.name == activeConfig then	
						specTerminalBoot.isChallangerIsBought = true;

						break;
					end;
				end;
			end;
		end;
	end;

	specTerminalBoot.speedWaitingMaxTimeHud = 1400;
	specTerminalBoot.speedWaitingTimerBoot = 0;
	specTerminalBoot.bootScreen = 1;
	specTerminalBoot.animName = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.terminalBootLoader#animName"), "terminalBoot");

	local bootTime = 0;

	if hasXMLProperty(self.xmlFile, "vehicle.terminalBootLoader") then
		specTerminalBoot.bootLoader = {};
		specTerminalBoot.speedWaitingMaxTimeHud = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.terminalBootLoader#defaultTime"), specTerminalBoot.speedWaitingMaxTimeHud);

		local screenNumber = 0;

		while true do
			local screenKey = string.format("vehicle.terminalBootLoader.screen(%d)", screenNumber);

			if not hasXMLProperty(self.xmlFile, screenKey) then
				break;
			end;
			
			specTerminalBoot.bootLoader[screenNumber] = {};
			specTerminalBoot.bootLoader[screenNumber].wasSet = false;
			specTerminalBoot.bootLoader[screenNumber].time = math.max(Utils.getNoNil(getXMLFloat(self.xmlFile, screenKey .. "#showTime"), specTerminalBoot.speedWaitingMaxTimeHud), 60) + bootTime;
			specTerminalBoot.bootLoader[screenNumber].stayOn = Utils.getNoNil(getXMLBool(self.xmlFile, screenKey .. "#stayOn"), false);
			bootTime = specTerminalBoot.bootLoader[screenNumber].time;
			
			local soundFile = getXMLString(self.xmlFile, screenKey .. "#file");
			local soundFileChallenger = getXMLString(self.xmlFile, screenKey .. "#fileChallenger");

			if soundFile ~= nil then
				if specTerminalBoot.isChallangerIsBought and soundFileChallenger ~= nil then
					setXMLString(self.xmlFile, screenKey .. "#file", soundFileChallenger);
				end;

				specTerminalBoot.bootLoader[screenNumber].soundSample = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.terminalBootLoader", "screen(" .. screenNumber .. ")", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self);
			end;

			screenNumber = screenNumber + 1;
		end;
	end;

	local lightNumber = 0;

	specTerminalBoot.lights = {};

	while true do
		local lightKey = string.format("vehicle.terminalBootLoader.lights.light(%d)", lightNumber);

		if not hasXMLProperty(self.xmlFile, lightKey) then
			break;
		end;

		local light = {};

		light.node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, lightKey .. "#node"), self.i3dMappings);

		if light.node ~= nil then
			table.insert(specTerminalBoot.lights, light);
		end;

		lightNumber = lightNumber + 1;
	end;
end;

function TerminalBoot:onUpdate(dt)
	local specTerminalBoot = getSpecName(self, "terminalBoot");

	if #specTerminalBoot.lights > 0 then
		for _, light in pairs(specTerminalBoot.lights) do
			setVisibility(light.node, specTerminalBoot.lightsAreOn and self:getIsMotorStarted());
		end;
	end;

	if self:getIsMotorStarted() then
		if specTerminalBoot.bootLoader ~= nil then
			if specTerminalBoot.bootLoader[specTerminalBoot.bootScreen] ~= nil then
				if specTerminalBoot.speedWaitingTimerBoot < specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].time then
					if not specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].wasSet then
						self:playAnimation(specTerminalBoot.animName, 1, nil, true);

						local activeCamera = self:getActiveCamera();

						if g_currentMission.controlledVehicle == self and activeCamera.isInside then
							if specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].soundSample ~= nil then
								g_soundManager:playSample(specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].soundSample);
							end;
						end;
						
						specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].wasSet = true;
					end;
				else
					if specTerminalBoot.speedWaitingTimerBoot >= specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].time then
						if specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].wasSet then
							if not specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].stayOn then
								if specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].soundSample ~= nil then
									g_soundManager:stopSample(specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].soundSample);
								end;
							end;

							specTerminalBoot.bootLoader[specTerminalBoot.bootScreen].wasSet = false;
						end;

						specTerminalBoot.bootScreen = specTerminalBoot.bootScreen + 1;
					end;
				end;
			end;
		end;

		specTerminalBoot.speedWaitingTimerBoot = specTerminalBoot.speedWaitingTimerBoot + dt;
	else
		for bootLoaderNumber = 1, #specTerminalBoot.bootLoader do
			if specTerminalBoot.bootLoader[bootLoaderNumber] ~= nil then
				if specTerminalBoot.bootLoader[bootLoaderNumber].soundSample ~= nil then
					g_soundManager:stopSample(specTerminalBoot.bootLoader[bootLoaderNumber].soundSample);
				end;

				specTerminalBoot.bootLoader[bootLoaderNumber].wasSet = false;
			end;
		end;

		self:playAnimation(specTerminalBoot.animName, -1, nil, true);
		AnimatedVehicle.updateAnimationByName(self, specTerminalBoot.animName, 9999999);
		
		specTerminalBoot.speedWaitingTimerBoot = 0;
		specTerminalBoot.bootScreen = 0;
	end;
end;

function TerminalBoot:delete()
	local specTerminalBoot = getSpecName(self, "terminalBoot");

	if specTerminalBoot.bootLoader ~= nil then
		for bootLoaderNumber = 1, #specTerminalBoot.bootLoader do
			if specTerminalBoot.bootLoader[bootLoaderNumber] ~= nil then
				if specTerminalBoot.bootLoader[bootLoaderNumber].soundSample ~= nil then
					g_soundManager:stopSample(specTerminalBoot.bootLoader[bootLoaderNumber].soundSample);
					g_soundManager:delete(specTerminalBoot.bootLoader[bootLoaderNumber].soundSample);
				end;
			end;
		end;
	end;
end;

function TerminalBoot:setLightsTypesMask(lightsTypesMask, force, noEventSend)
    local specTerminalBoot = getSpecName(self, "terminalBoot");

    specTerminalBoot.lightsAreOn = bitAND(lightsTypesMask, 1) ~= 0;
end;