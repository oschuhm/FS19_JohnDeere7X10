--
-- InteractiveControl v2.0
-- Specialization for an interactive control
--
-- SFM-Modding
-- @author:  	Manuel Leithner
-- @date:		17/10/10
-- @version:	v2.0
-- @history:	v1.0 - initial implementation
--				v2.0 - convert to LS2011 and some bugfixes
--
-- free for noncommerical-usage
--

InteractiveControl = {};

local ICModName = g_currentModName

function InteractiveControl.prerequisitesPresent(specializations)
    return true
end;

function InteractiveControl.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", InteractiveControl);
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", InteractiveControl)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", InteractiveControl)
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", InteractiveControl)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", InteractiveControl)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", InteractiveControl)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", InteractiveControl)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", InteractiveControl)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", InteractiveControl)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", InteractiveControl)
end

function InteractiveControl:onRegisterActionEvents(isActiveForInput)
    if self.isClient then
		local spec = self.actionEventScript;
		self:clearActionEventsTable(spec.actionEvents);
		spec.actionEventIds = {};			
		if self:getIsActiveForInput(true, true) then
            eventAdded, actionEventId = self:addActionEvent(spec.actionEvents, "IC_SPACE", self, InteractiveControl.onInputAction, false, false, true, true, nil);
			eventAdded1, actionEventId1 = self:addActionEvent(spec.actionEvents, "IC_MOUSE", self, InteractiveControl.onInputAction, false, true, false, true, nil);
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH);
			g_inputBinding:setActionEventTextPriority(actionEventId1, GS_PRIO_HIGH);
			--g_inputBinding.events[actionEventId].actionEventId = 1
			g_inputBinding.events[actionEventId1].displayPriority = 1
		end;
    end;
end;

function InteractiveControl.onInputAction(self, actionName, inputValue, callbackState, isAnalog)
	if self.isClient and not g_gui:getIsGuiVisible() and self:getIsActiveForInput(true, true) then	
		if actionName == "IC_SPACE" then
			if inputValue > 0 then
				self.isMouseActive = true
			else
				self.isMouseActive = false
			end;
		end;
		if actionName == "IC_MOUSE" and self.foundInteractiveObject ~= nil then	
			self:doActionOnObject(self.foundInteractiveObject);					
		end;
	end;
end;

function InteractiveControl:onLoad(vehicle)
	self.actionEventScript = {};
	self.actionEventScript.actionEvents = {};	
	source(Utils.getFilename("specializations/InteractiveComponentInterface.lua", self.baseDirectory));
	self.doActionOnObject = InteractiveControl.doActionOnObject
	self.setPanelOverlay = InteractiveControl.setPanelOverlay
	self.interactiveObjects = {};	
	self.indoorCamIndex = 2;
	self.outdoorCamIndex = 1;
	self.lastMouseXPos = 0;
	self.lastMouseYPos = 0;					
	self.panelOverlay = nil;
	self.foundInteractiveObject = nil;
	self.isMouseActive = false;
end;

function InteractiveControl:onPostLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		for id, iObj in pairs(self.interactiveObjects) do
			local key = savegame.key.."."..ICModName..".interactiveControl"..string.format(".interactiveObject%d", id)
			local iObj = self.interactiveObjects[id]
			state = Utils.getNoNil(getXMLBool(savegame.xmlFile, key.."#state"), false);
			if iObj ~= nil then
				iObj:doAction(true, state);
			end;
		end;
	end;
end

function InteractiveControl:saveToXMLFile(xmlFile, key)
	for id, iObj in pairs(self.interactiveObjects) do
		local state = string.format("%s.interactiveObject" .. id, key, id)
		setXMLBool(xmlFile, state.."#state", iObj.isOpen)
	end;
end

function InteractiveControl:onDelete()
end;

function InteractiveControl:onReadStream(streamId, connection)
	local icCount = streamReadInt8(streamId);
	for i=1, icCount do
		local isOpen = streamReadBool(streamId);
		if self.interactiveObjects[i] ~= nil then
			if self.interactiveObjects[i].synch then
				self.interactiveObjects[i]:doAction(true, isOpen);	
			end;
		end;
	end;
end;

function InteractiveControl:onWriteStream(streamId, connection)
	streamWriteInt8(streamId, table.getn(self.interactiveObjects));
	for k,v in pairs(self.interactiveObjects) do
		streamWriteBool(streamId, v.isOpen);
	end;
end;

function InteractiveControl:onUpdate(dt)
	local currentCam = self.spec_enterable.cameras[self.spec_enterable.camIndex];
	if self:getIsActive() then	
		g_inputBinding:setActionEventActive(actionEventId1, self.foundInteractiveObject ~= nil)
		self.foundInteractiveObject = nil;
		local icObject = nil;
		for k,v in pairs(self.interactiveObjects) do
			v:onUpdate(dt);
			if self.isMouseActive then
				v:onLeaveVehicle(dt);
				if icObject == nil and self.spec_enterable.camIndex == self.indoorCamIndex then
					local worldX,worldY,worldZ = getWorldTranslation(v.mark);
					local x,y,z = project(worldX,worldY,worldZ);
					if z <= 1 then	
						if g_lastMousePosX > (x-v.size/6) and g_lastMousePosX < (x+v.size/6) then
							if g_lastMousePosY > (y-v.size/6) and g_lastMousePosY < (y+v.size/6) then
								local isOverlapped = false;
								if self.panelOverlay ~= nil then								
									local overlay = self.panelOverlay.mainBackground;
									isOverlapped = g_lastMousePosX >= overlay.x and g_lastMousePosX <= overlay.x+overlay.width and g_lastMousePosY >= overlay.y and g_lastMousePosY <= overlay.y+overlay.height;
								end;
								if not isOverlapped then
									icObject = v;
									self.foundInteractiveObject = k;
									break;
								end;
							end;
						end;
					end;
				end;				
			end;
		end;
		if icObject ~= nil then
			icObject:onEnterVehicle(dt);
		end;
		if self.isClient and not g_gui:getIsGuiVisible() and self:getIsActiveForInput(true, true) then
			if not self.isMouseActive then
				g_inputBinding:setShowMouseCursor(false);
				self.spec_enterable.cameras[self.spec_enterable.camIndex].isActivated = true;
				for _,v in pairs(self.interactiveObjects) do
					v:onLeaveVehicle(dt);
				end;
			end;
			for _,v in pairs(self.interactiveObjects) do
				v:setVisible(self.isMouseActive);
			end;
			if self.isMouseActive then
				local currentCam = self.spec_enterable.cameras[self.spec_enterable.camIndex];
				self.mouseDirectionY = 0;
				self.mouseDirectionX = 0;
				self.spec_enterable.cameras[self.indoorCamIndex].isActivated = self.spec_enterable.camIndex ~= self.indoorCamIndex;
				self.spec_enterable.cameras[self.outdoorCamIndex].isActivated = self.spec_enterable.camIndex ~= self.outdoorCamIndex;
				g_inputBinding:setShowMouseCursor(true);
			else
				self.foundInteractiveObject = nil;
			end;
		else
			self.foundInteractiveObject = nil;
		end;
	end;	
end;

function InteractiveControl:doActionOnObject(id, noEventSend)
	if self.interactiveObjects[id].isLocalOnly == nil or not self.interactiveObjects[id].isLocalOnly then
		InteractiveControlEvent.sendEvent(self, id, noEventSend);	
	end;
	self.interactiveObjects[id]:doAction(noEventSend);	
end;

function InteractiveControl:onDraw()	
	for _,v in pairs(self.interactiveObjects) do
		v:onDraw();
	end;
	if self.isMouseActive then
		g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("InteractiveControl_Off"))
	else
		g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("InteractiveControl_On"))
	end;
end;

function InteractiveControl:onLeaveVehicle()
	self.spec_enterable.cameras[self.indoorCamIndex].isActivated = true;
	if g_gui.currentGui == nil then
		g_inputBinding:setShowMouseCursor(false);
	end;
	if self.isMouseActive then
		self.isMouseActive = false
	end;
end;

function InteractiveControl:setPanelOverlay(panel)
	if self.panelOverlay ~= nil then
		if self.panelOverlay.setActive ~= nil then
			self.panelOverlay:setActive(false);
		end;
	end;
	self.panelOverlay = panel;

	if panel ~= nil then
		if panel.setActive ~= nil then
			panel:setActive(true);
		end;
	end;
end;

--
-- InteractiveControlEvent 
-- Specialization for an interactive control
--
-- SFM-Modding
-- @author:  	Manuel Leithner
-- @date:		14/12/11
-- @version:	v2.0
-- @history:	v1.0 - initial implementation
--				v2.0 - convert to LS2011 and some bugfixes
--
InteractiveControlEvent = {};
InteractiveControlEvent_mt = Class(InteractiveControlEvent, Event);

InitEventClass(InteractiveControlEvent, "InteractiveControlEvent");

function InteractiveControlEvent:emptyNew()
    local self = Event:new(InteractiveControlEvent_mt);
    return self;
end;

function InteractiveControlEvent:new(vehicle, interactiveControlID)
    local self = InteractiveControlEvent:emptyNew()
    self.vehicle = vehicle;
	self.interactiveControlID = interactiveControlID;
    return self;
end;

function InteractiveControlEvent:readStream(streamId, connection)
    local id = streamReadInt32(streamId);
	self.interactiveControlID = streamReadInt8(streamId);
    self.vehicle = NetworkUtil.getObject(id);
    self:run(connection);
end;

function InteractiveControlEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, NetworkUtil.getObjectId(self.vehicle));	
	streamWriteInt8(streamId, self.interactiveControlID);
end;

function InteractiveControlEvent:run(connection)
	self.vehicle:doActionOnObject(self.interactiveControlID, true);
	if not connection:getIsServer() then
		g_server:broadcastEvent(InteractiveControlEvent:new(self.vehicle, self.interactiveControlID), nil, connection, self.vehicle);
	end;
end;

function InteractiveControlEvent.sendEvent(vehicle, icObject, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(InteractiveControlEvent:new(vehicle, icObject), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(InteractiveControlEvent:new(vehicle, icObject));
		end;
	end;
end;