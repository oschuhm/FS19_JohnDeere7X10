--
-- InteractiveWindows
-- Specialization for InteractiveWindows
--
-- @author  	Manuel Leithner (SFM-Modding)
-- @version 	v3.0
-- @date  		24/10/12
-- @history:	v1.0 - Initial version
--				v2.0 - converted to ls2011
--				v3.0 - converted to ls2013
--
-- free for noncommerical-usage
--

InteractiveWindows = {};

function InteractiveWindows.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(InteractiveControl, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations);
end;

function InteractiveWindows.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", InteractiveWindows)
end

function InteractiveWindows:onLoad(savegame)
	local i=0;
	while true do
		local windowName = string.format("vehicle.interactiveComponents.windows.window(%d)", i);	
		if not hasXMLProperty(self.xmlFile, windowName) then
			break;
		end;
		local animation = getXMLString(self.xmlFile, windowName .. "#animName");
		local name = Utils.getNoNil(g_i18n:getText(getXMLString(self.xmlFile, windowName .. "#name")), "ERROR");			
		local mark = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, windowName .. "#mark"), self.i3dMappings);
		local highlight = getChildAt(mark, 0);
		local size = Utils.getNoNil(getXMLFloat(self.xmlFile, windowName .. "#size"), 0.1);
		local onMessage = g_i18n:getText(Utils.getNoNil(getXMLString(self.xmlFile, windowName .. "#onMessage"), "ic_button_on"));
		local offMessage =  g_i18n:getText(Utils.getNoNil(getXMLString(self.xmlFile, windowName .. "#offMessage") , "ic_button_off"));	
		local sound = getXMLString(self.xmlFile, windowName .. ".soundFile" .. "#file")
		if sound ~= nil then
			soundIC = g_soundManager:loadSampleFromXML(self.xmlFile, windowName, "soundFile", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, nil, nil)
		else 
			soundIC = nil
		end;
		local window = Window:new(highlight, name, animation, mark, size, self, onMessage, offMessage, soundIC);
		window.synch = Utils.getNoNil(getXMLBool(self.xmlFile, windowName .. "#synch"), true);
		table.insert(self.interactiveObjects, window);
		i = i + 1;
	end;
end;

--
-- Window Class
-- Specifies an interactive window
--
-- SFM-Modding
-- @author  Manuel Leithner
-- @date  26/12/09
--

Window = {};

function Window.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Window)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Window)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Window)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Window)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Window)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Window)
end

function Window:new(highlight, name, animation, mark, size, vehicle, onMessage, offMessage, soundIC)
	local Window_mt = Class(Window, InteractiveComponentInterface);	
    local instance = InteractiveComponentInterface:new(nil, highlight, name, mark, size, onMessage, offMessage, soundIC, Window_mt);
	instance.vehicle = vehicle;
	instance.animation = animation;
	instance.soundIC = soundIC;
	return instance;
end;

function Window:onDelete()
end;

function Window:onUpdate(dt)
	InteractiveComponentInterface.onUpdate(self, dt);
end;

function Window:onDraw()
	InteractiveComponentInterface.onDraw(self);
end;

function Window:doAction(noEventSend, forceAction)
	InteractiveComponentInterface.doAction(self, forceAction);
	local dir = 1;
	if not self.isOpen  then
		dir = -1;
	end;
	if self.soundIC ~= nil then
		g_soundManager:playSample(self.soundIC)
	end;
	self.vehicle:playAnimation(self.animation, dir, MathUtil.clamp(self.vehicle:getAnimationTime(self.animation), 0, 1), true);
end;

function Window:onEnterVehicle(dt)
	InteractiveComponentInterface.onEnterVehicle(self, dt);
end;

function Window:onLeaveVehicle(dt)
	InteractiveComponentInterface.onLeaveVehicle(self, dt);
end;

function Window:setActive()
	InteractiveComponentInterface.setActive(self, isActive);
end;

function Window:setVisible(isVisible)
	InteractiveComponentInterface.setVisible(self, isVisible);
end;