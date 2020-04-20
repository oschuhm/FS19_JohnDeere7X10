--
-- InteractiveComponent Interface
-- Specifies an interactive component
--
-- @author  	Manuel Leithner (SFM-Modding)
-- @version 	v2.0
-- @date  		15/10/10
-- @history:	v1.0 - Initial version
--				v2.0 - converted to ls2011
--
-- free for noncommerical-usage
--

InteractiveComponentInterface = {};

function InteractiveComponentInterface.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", InteractiveComponentInterface)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", InteractiveComponentInterface)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", InteractiveComponentInterface)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", InteractiveComponentInterface)
end

function InteractiveComponentInterface:new(node, highlight, name, mark, size, onMessage, offMessage, soundIC, mt)
	local mTable = mt;
	if mTable == nil then
		mTable = Class(InteractiveComponentInterface);
	end;
    local instance = {};
    setmetatable(instance, mTable);
	instance.node = node;
	instance.highlight = highlight;
	instance.scaleX, instance.scaleY, instance.scaleZ = getScale(instance.highlight);
	instance.name = name;
	instance.mark = mark;
	setVisibility(mark,false);
	instance.scale = 0.01;
	instance.size = size;
	instance.isActive = true;
	instance.isMouseOver = false;
	instance.isOpen = false;
	instance.onMessage = Utils.getNoNil(onMessage, g_i18n:getText("ic_component_open"));
	instance.offMessage = Utils.getNoNil(offMessage, g_i18n:getText("ic_component_close"));
	instance.synch = true;
	instance.soundIC = soundIC;
	return instance;	
end;

function InteractiveComponentInterface:onUpdate(dt)	
	if self.isActive then
		if self.highlight ~= nil then
			if self.isMouseOver then	
				self.scale = self.scale - 0.0002 * dt;
				setScale(self.highlight, self.scaleX + self.scale, self.scaleY + self.scale, self.scaleZ + self.scale);				
				if self.scaleX + self.scale <= 0.95 then
					self.scale = 0.05;
				end;				
			end;
		end;
	end;
end;

function InteractiveComponentInterface:onDraw()
	if self.isMouseOver then
		if self.isOpen then
			g_inputBinding:setActionEventText(actionEventId1, string.format(self.offMessage, self.name))
		else
			g_inputBinding:setActionEventText(actionEventId1, string.format(self.onMessage, self.name))
		end;
	end;
end;

function InteractiveComponentInterface:doAction(forceValue)
	if forceValue ~= nil then
		self.isOpen = forceValue;
	else
		self.isOpen = not self.isOpen;
	end;
end;

function InteractiveComponentInterface:onEnterVehicle(dt)
	self.isMouseOver = true;
end;

function InteractiveComponentInterface:onLeaveVehicle(dt)
	self.isMouseOver = false;
end;

function InteractiveComponentInterface:setActive(isActive)
	self.isActive = isActive;
end;

function InteractiveComponentInterface:setVisible(isVisible)
	if self.mark ~= nil then
		setVisibility(self.mark, isVisible);
	end;
end;