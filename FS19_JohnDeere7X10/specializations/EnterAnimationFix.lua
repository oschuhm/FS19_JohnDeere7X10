--[[
	EnterAnimationFix
	Specialization to stop playing the enter animation if helper is active an no player in the vehicle
	
	@author:    Ifko[nator]
	@date:      27.10.2019
	@version:	1.0
]]

EnterAnimationFix = {};

function EnterAnimationFix.prerequisitesPresent(specializations)
	return true;
end;

function EnterAnimationFix.registerEventListeners(vehicleType)
	local functionNames = {
		"onLoad"
	};
	
	for _, functionName in ipairs(functionNames) do
		SpecializationUtil.registerEventListener(vehicleType, functionName, EnterAnimationFix);
	end;
end;

function EnterAnimationFix:onLoad(savegame)
    self.leaveVehicle = Utils.overwrittenFunction(self.leaveVehicle, EnterAnimationFix.leaveVehicleFix);
end;

function EnterAnimationFix:leaveVehicleFix(superFunc)
	local specEnterable = self.spec_enterable;

	g_currentMission:removePauseListeners(self);
	
    if specEnterable.activeCamera ~= nil and specEnterable.isEntered then
        specEnterable.activeCamera:onDeactivate();
        g_soundManager:setIsIndoor(false);
        g_depthOfFieldManager:reset();
	end;
	
    if self.spec_rideable ~= nil then
        -- To be called before "spec.vehicleCharacter:delete()"
        self:setEquipmentVisibility(false);
        self:unlinkReins();
	end;
	
    specEnterable.isControlled = false;
    specEnterable.isEntered = false;
    specEnterable.playerIndex = 0;
    specEnterable.playerColorIndex = 0;
    specEnterable.canUseEnter = true;
    specEnterable.controllerFarmId = 0;
    g_currentMission.controlledVehicles[self] = nil;
	g_currentMission:setLastInteractionTime(200);
	
    if specEnterable.vehicleCharacter ~= nil and self:getDisableVehicleCharacterOnLeave() then
        specEnterable.vehicleCharacter:delete();
	end;
	
    if specEnterable.enterAnimation ~= nil and self.playAnimation ~= nil and not self:getIsAIActive() then
        self:playAnimation(specEnterable.enterAnimation, -1, nil, true);
	end;
	
    self:setMirrorVisible(false);
	SpecializationUtil.raiseEvent(self, "onLeaveVehicle");
	
    --## deactivate actionEvents
    if self.isClient then
        g_messageCenter:unsubscribe(MessageType.INPUT_BINDINGS_CHANGED, self);
        self:requestActionEventUpdate();
	end;
	
    if self.isServer and not specEnterable.isEntered and g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.trafficSystemId ~= 0 then
        removeTrafficSystemPlayer(g_currentMission.trafficSystem.trafficSystemId, self.components[1].node);
	end;
	
    if self:getDeactivateOnLeave() then
        self:deactivate();
    end;
end;