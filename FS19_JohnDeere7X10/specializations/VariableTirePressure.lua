--[[
	VariableTirePressure
	Specialization to allow an variable tire pressure for an tractor with vario grip

	@author:    Ifko[nator]
	@date:      08.02.2020
	@version:	1.0
	
	PERMISSION ONLY FOR AHRAN MODDING!
]]

VariableTirePressure = {};
VariableTirePressure.currentModName = g_currentModName;

local function getSpecByName(self, specName, currentModName)
    local spec = self["spec_" .. Utils.getNoNil(currentModName, VariableTirePressure.currentModName) .. "." .. specName];

	if spec ~= nil then
        return spec;
    end;

    return self["spec_" .. specName];
end;

function VariableTirePressure.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Motorized, specializations);
end;

function VariableTirePressure.registerFunctions(vehicleType)
	local functionNames = {
		"setTirePressure",
		"getCurrentTirePressure"
	};
	
	for _, functionName in ipairs(functionNames) do
		SpecializationUtil.registerFunction(vehicleType, functionName, VariableTirePressure[functionName]);
	end;
end;

function VariableTirePressure.registerEventListeners(vehicleType)
	local functionNames = {
		"onLoad",
		"saveToXMLFile",
		"onDraw",
		"onDelete",
		"onUpdate",
		"onRegisterActionEvents",
		"onWriteStream",
		"onReadStream"
	};
	
	for _, functionName in ipairs(functionNames) do
		SpecializationUtil.registerEventListener(vehicleType, functionName, VariableTirePressure);
	end;
end;

function VariableTirePressure:onLoad(savegame)
	local specVariableTirePressure = getSpecByName(self, "variableTirePressure");
	
	print("JD RDA -> run onLoad(savegame)");
	
	specVariableTirePressure.configName = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.variableTirePressure#configName"), "");
	specVariableTirePressure.activeConfigs = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.variableTirePressure#activeConfigs"), "");
	specVariableTirePressure.isBought = false;
   
    if specVariableTirePressure.configName ~= "" and specVariableTirePressure.activeConfig ~= "" then
        local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName);

        if storeItem ~= nil and storeItem.configurations ~= nil and storeItem.configurations[specVariableTirePressure.configName] ~= nil then
			local activeConfigs = StringUtil.splitString(" ", specVariableTirePressure.activeConfigs);
            local configurations = storeItem.configurations[specVariableTirePressure.configName];
            local config = configurations[self.configurations[specVariableTirePressure.configName]];
               
            for _, activeConfig in pairs(activeConfigs) do
				if config.name == g_i18n:getText(activeConfig) then	
					specVariableTirePressure.isBought = true;
					
					break;
				end;
            end;
        end;
    end;
	
	if specVariableTirePressure.isBought then	
		local specWheels = getSpecByName(self, "wheels");
		
		specVariableTirePressure.updatePressure = false;
		specVariableTirePressure.deform = 1;
		
		specVariableTirePressure.isActive = false;
		specVariableTirePressure.showTurnOnMotorWarning = false;

		specVariableTirePressure.deformFront = specWheels.wheels[1].maxDeformation;
		specVariableTirePressure.deformBack = specWheels.wheels[3].maxDeformation;
		
		specVariableTirePressure.frictionFront = specWheels.wheels[1].frictionScale;
		specVariableTirePressure.frictionBack = specWheels.wheels[3].frictionScale;
		
		specVariableTirePressure.maxPressure = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.variableTirePressure.pressures.max"), 2.5);
		specVariableTirePressure.minPressure = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.variableTirePressure.pressures.min"), 0.8);
		specVariableTirePressure.pressure = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.variableTirePressure.pressures.default"), specVariableTirePressure.maxPressure);

		specVariableTirePressure.emptySpeedFactor = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.variableTirePressure.speeds.empty"), 0.55);
		specVariableTirePressure.fillSpeedFactor = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.variableTirePressure.speeds.fill"), 0.8);

		specVariableTirePressure.pressureSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.variableTirePressure#pressureSpeed"), 0.00005);
		
		if self.isClient then
			specVariableTirePressure.sampleEmptyAirSound = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.variableTirePressure", "emptySound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self);
			specVariableTirePressure.sampleFillAirSound = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.variableTirePressure", "fillSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self);
			specVariableTirePressure.sampleStopAirSound = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.variableTirePressure", "stopSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self);	
		end;
	end;

	if self.loadDashboardsFromXML ~= nil then
		self:loadDashboardsFromXML(
			self.xmlFile, 
			"vehicle.variableTirePressure.dashboards", 
			{
				valueTypeToLoad = "currentTirePressureFront",
				valueObject = self,
				valueFunc = "getCurrentTirePressure",
				minFunc = 0,
				maxFunc = 9
			}
		);

		self:loadDashboardsFromXML(
			self.xmlFile, 
			"vehicle.variableTirePressure.dashboards", 
			{
				valueTypeToLoad = "currentTirePressureBack",
				valueObject = self,
				valueFunc = "getCurrentTirePressure",
				minFunc = 0,
				maxFunc = 9
			}
		);
	end;
	
	--DebugUtil.printTableRecursively(specVariableTirePressure, "RDA_onLoad>>", 0, 2)
	
end;

function VariableTirePressure:onDelete()
	local specVariableTirePressure = getSpecByName(self, "variableTirePressure");

	if self.isClient and specVariableTirePressure.isBought then
        g_soundManager.deleteSample(specVariableTirePressure.sampleEmptyAirSound);
        g_soundManager.deleteSample(specVariableTirePressure.sampleFillAirSound);
        g_soundManager.deleteSample(specVariableTirePressure.sampleStopAirSound);
    end;
end;

function VariableTirePressure:onWriteStream(streamId, connection)
	if not connection:getIsServer() then 
		local specVariableTirePressure = getSpecByName(self, "variableTirePressure");
		
		if specVariableTirePressure.isBought then
			streamWriteBool(streamId, specVariableTirePressure.isActive);
		end;
	end;
end;

function VariableTirePressure:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local specVariableTirePressure = getSpecByName(self, "variableTirePressure");
		
		if specVariableTirePressure.isBought then
			specVariableTirePressure.isActive = streamReadBool(streamId);
		end;
	end;
end;

function VariableTirePressure:onRegisterActionEvents(isActiveForInput)
	if self.isClient then
		local specVariableTirePressure = getSpecByName(self, "variableTirePressure");
		
		self:clearActionEventsTable(specVariableTirePressure.actionEvents);
        
		if self:getIsActiveForInput(true) then
			local _, actionEventId = self:addActionEvent(specVariableTirePressure.actionEvents, InputAction.SET_TIRE_PRESSURE, self, VariableTirePressure.actionEventSetTirePressure, false, true, false, true, nil);

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL);
			g_inputBinding:setActionEventTextVisibility(actionEventId, true);
			g_inputBinding:setActionEventActive(actionEventId, false);
		end;
	end;
end;

function VariableTirePressure.actionEventSetTirePressure(self, actionName, inputValue, callbackState, isAnalog)
	local specVariableTirePressure = getSpecByName(self, "variableTirePressure");
		
	if specVariableTirePressure.isBought then
		self:setTirePressure(not specVariableTirePressure.isActive);
	end;
end;

function VariableTirePressure:setTirePressure(isActive, noEventSend)
    local specVariableTirePressure = getSpecByName(self, "variableTirePressure");

	if isActive ~= specVariableTirePressure.isActive then
		specVariableTirePressure.updatePressure = true;
		
		if self:getIsMotorStarted() then
			specVariableTirePressure.isActive = isActive;

			if not noEventSend then
				if g_server ~= nil then
					g_server:broadcastEvent(VariableTirePressureEvent:new(self, isActive), nil, nil, self);
				else
					g_client:getServerConnection():sendEvent(VariableTirePressureEvent:new(self, isActive));
				end;
			end;
		end;
	end;
end;

function VariableTirePressure:onUpdate(dt)
	local specVariableTirePressure = getSpecByName(self, "variableTirePressure");
	local specWheels = getSpecByName(self, "wheels");
	
	--print("RDA -> onUpdate; specVariableTirePressure.isBought: "..tostring(specVariableTirePressure.isBought));
	
	if specVariableTirePressure.isBought then		
		local pressureSpeed = specVariableTirePressure.pressureSpeed * dt;
		local pressureSpeedFactor = specVariableTirePressure.isActive and specVariableTirePressure.emptySpeedFactor or specVariableTirePressure.fillSpeedFactor;
		
		specVariableTirePressure.showTurnOnMotorWarning = false;
	
		if specVariableTirePressure.updatePressure then
			for i, wheel in ipairs(specWheels.wheels) do
				if wheel.suspTravelBackUp == nil then	
					wheel.suspTravelBackUp = wheel.suspTravel;
					wheel.maxDeformationBackUp = wheel.maxDeformation;
					wheel.frictionScaleBackUp = wheel.frictionScale;
				end;
				
				if self:getIsMotorStarted() then
					if specVariableTirePressure.isActive then
						specVariableTirePressure.pressure = MathUtil.clamp(specVariableTirePressure.pressure - (pressureSpeed * pressureSpeedFactor), specVariableTirePressure.minPressure, specVariableTirePressure.maxPressure);
					
						if self.isClient then	
							if specVariableTirePressure.pressure > specVariableTirePressure.minPressure then
								if not g_soundManager:getIsSamplePlaying(specVariableTirePressure.sampleEmptyAirSound) then	
									g_soundManager:playSample(specVariableTirePressure.sampleEmptyAirSound);
									g_soundManager:stopSample(specVariableTirePressure.sampleStopAirSound);
								end;

								specVariableTirePressure.deform = specVariableTirePressure.deform + pressureSpeed * pressureSpeedFactor;
							
								if i == 1 or i == 2 then
									wheel.maxDeformation = specVariableTirePressure.deformFront * specVariableTirePressure.deform;
									wheel.frictionScale = specVariableTirePressure.frictionFront * specVariableTirePressure.deform;
								else 
									wheel.maxDeformation = specVariableTirePressure.deformBack * specVariableTirePressure.deform;
									wheel.frictionScale = specVariableTirePressure.frictionBack * specVariableTirePressure.deform;
								end;

								wheel.suspTravel = wheel.suspTravel - (specVariableTirePressure.deform / 17000);

								self:updateWheelTireFriction(wheel);
								self:updateWheelBase(wheel);
							else
								specVariableTirePressure.updatePressure = false;

								if g_soundManager:getIsSamplePlaying(specVariableTirePressure.sampleEmptyAirSound) then	
									g_soundManager:stopSample(specVariableTirePressure.sampleEmptyAirSound);
									g_soundManager:playSample(specVariableTirePressure.sampleStopAirSound);
								end;
							end;
						end;
					else
						specVariableTirePressure.pressure = MathUtil.clamp(specVariableTirePressure.pressure + (pressureSpeed * pressureSpeedFactor), specVariableTirePressure.minPressure, specVariableTirePressure.maxPressure);
					
						if self.isClient then	
							if specVariableTirePressure.pressure < specVariableTirePressure.maxPressure then
								if not g_soundManager:getIsSamplePlaying(specVariableTirePressure.sampleFillAirSound) then	
									g_soundManager:playSample(specVariableTirePressure.sampleFillAirSound);
									g_soundManager:stopSample(specVariableTirePressure.sampleStopAirSound);
								end;

								specVariableTirePressure.deform = specVariableTirePressure.deform - pressureSpeed * pressureSpeedFactor;
							
								if i == 1 or i == 2 then
									wheel.maxDeformation = specVariableTirePressure.deformFront * specVariableTirePressure.deform;
									wheel.frictionScale = specVariableTirePressure.frictionFront * specVariableTirePressure.deform;
								else 
									wheel.maxDeformation = specVariableTirePressure.deformBack * specVariableTirePressure.deform;
									wheel.frictionScale = specVariableTirePressure.frictionBack * specVariableTirePressure.deform;
								end;

								wheel.suspTravel = wheel.suspTravel + (specVariableTirePressure.deform / 12000);

								self:updateWheelTireFriction(wheel);
								self:updateWheelBase(wheel);
							else 
								wheel.maxDeformation = wheel.maxDeformationBackUp;
								wheel.frictionScale = wheel.frictionScaleBackUp;
								wheel.suspTravel = wheel.suspTravelBackUp;

								self:updateWheelTireFriction(wheel);
								self:updateWheelBase(wheel);

								specVariableTirePressure.updatePressure = false;

								if g_soundManager:getIsSamplePlaying(specVariableTirePressure.sampleFillAirSound) then	
									g_soundManager:stopSample(specVariableTirePressure.sampleFillAirSound);
									g_soundManager:playSample(specVariableTirePressure.sampleStopAirSound);
								end;
							end;
						end;
					end;
				else
					specVariableTirePressure.showTurnOnMotorWarning = true;
					specVariableTirePressure.updatePressure = false;
				end;
			end;
		else
			g_soundManager:stopSample(specVariableTirePressure.sampleFillAirSound);
			g_soundManager:stopSample(specVariableTirePressure.sampleEmptyAirSound);
		end;
	end;
end;

function VariableTirePressure:onDraw()
	local specVariableTirePressure = getSpecByName(self, "variableTirePressure");
	
	if specVariableTirePressure.isBought then
		local text = "";
		local textAllowed = false;
		
		if specVariableTirePressure.updatePressure then
			if g_i18n:hasText("info_tireFilling") and g_i18n:hasText("info_tireEmptying") and g_i18n:hasText("info_tireCurrentPressure") then
				local targetText = not specVariableTirePressure.isActive and g_i18n:getText("info_tireFilling") or g_i18n:getText("info_tireEmptying");
	
				g_currentMission:addExtraPrintText(g_i18n:getText("info_tireCurrentPressure"):format(targetText, MathUtil.round(specVariableTirePressure.pressure, 2)));
			end;
		else
			if g_i18n:hasText("action_tireChangeTarget") then
				local targetVariogrip = not specVariableTirePressure.isActive and MathUtil.round(specVariableTirePressure.minPressure, 2) or MathUtil.round(specVariableTirePressure.maxPressure, 2);
			
				textAllowed = true;
				text = g_i18n:getText("action_tireChangeTarget"):format(targetVariogrip);
			end;
		end;

		if specVariableTirePressure.showTurnOnMotorWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_motorNotStarted"), 2000);
		end;

		local setTirePressureButton = specVariableTirePressure.actionEvents[InputAction.SET_TIRE_PRESSURE];
	
		if setTirePressureButton ~= nil then
			g_inputBinding:setActionEventActive(setTirePressureButton.actionEventId, textAllowed);
			g_inputBinding:setActionEventTextVisibility(actionEventId, textAllowed);
			g_inputBinding:setActionEventText(setTirePressureButton.actionEventId, text);
		end;
	end;
end;

function VariableTirePressure:getCurrentTirePressure()
	local specVariableTirePressure = getSpecByName(self, "variableTirePressure");
	
	if specVariableTirePressure.isBought then
		return MathUtil.round(specVariableTirePressure.pressure, 2);
	else
		return 0;
	end;
end;

VariableTirePressureEvent = {};
VariableTirePressureEvent_mt = Class(VariableTirePressureEvent, Event);

InitEventClass(VariableTirePressureEvent, "VariableTirePressureEvent");

function VariableTirePressureEvent:emptyNew()
	local self = Event:new(VariableTirePressureEvent_mt);
    
	return self;
end;

function VariableTirePressureEvent:new(tractor, isActive)
	local self = VariableTirePressureEvent:emptyNew();
	
	self.tractor = tractor;
	self.isActive = isActive;
	
	return self;
end;

function VariableTirePressureEvent:readStream(streamId, connection)
	self.tractor = NetworkUtil.readNodeObject(streamId);
	self.isActive = streamReadBool(streamId);
    
	self:run(connection);
end;

function VariableTirePressureEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.tractor);
	streamWriteBool(streamId, self.isActive);
end;

function VariableTirePressureEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(VariableTirePressureEvent:new(self.tractor, self.isActive), nil, connection, self.tractor);
	end;
	
    if self.tractor ~= nil then
        self.tractor:setTirePressure(self.isActive, true);
	end;
end;