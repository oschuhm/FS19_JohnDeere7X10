--[[
ExtendedAnimationSounds

Specialization for extended sounds at animations

Author:		Ifko[nator]
Datum:		05.10.2019

Version:	v1.0

History:	v1.0 @ 05.10.2019 - initial implementation in FS 19

PERMISSION ONLY FOR AHRAN MODDING!
]]

ExtendedAnimationSounds = {}

function ExtendedAnimationSounds.prerequisitesPresent(specializations) 
    return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations); 
end;

function ExtendedAnimationSounds.registerEventListeners(vehicleType)
	local functionNames = {
		"onLoad",
		"onDelete"
	};

	for _, functionName in ipairs(functionNames) do
		SpecializationUtil.registerEventListener(vehicleType, functionName, ExtendedAnimationSounds);
	end;
end;

function ExtendedAnimationSounds.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAnimation", ExtendedAnimationSounds.loadAnimation);
end;

function ExtendedAnimationSounds:onLoad(savegame)
	local functionNames = {
		"playAnimation",
		"stopAnimation"
	};

	for _, functionName in ipairs(functionNames) do
		self[functionName] = Utils.overwrittenFunction(self[functionName], ExtendedAnimationSounds[functionName]);
	end;

	AnimatedVehicle.updateAnimation = Utils.overwrittenFunction(AnimatedVehicle.updateAnimation, ExtendedAnimationSounds.updateAnimation);
end;

function ExtendedAnimationSounds:onDelete()
	local spec = self.spec_animatedVehicle;
	
    for _, animation in pairs(spec.animations) do
        if self.isClient then
			g_soundManager:deleteSample(animation.openSound);
			g_soundManager:deleteSample(animation.closeSound);
        end;
    end;
end;

function ExtendedAnimationSounds:loadAnimation(superFunc, xmlFile, key, animation)
	local name = getXMLString(xmlFile, key .. "#name");

	if name ~= nil then
        animation.name = name;
        animation.parts = {};
        animation.currentTime = 0;
        animation.currentSpeed = 1;
        animation.looping = Utils.getNoNil(getXMLBool(xmlFile, key .. "#looping"), false);
		animation.resetOnStart = Utils.getNoNil(getXMLBool(xmlFile, key .. "#resetOnStart"), true);
		
		local partI = 0;
		
        while true do
			local partKey = key .. string.format(".part(%d)", partI);
			
            if not hasXMLProperty(xmlFile, partKey) then
                break;
			end;
			
			local animationPart = {};
			
            if self:loadAnimationPart(xmlFile, partKey, animationPart) then
                table.insert(animation.parts, animationPart);
			end;
			
            partI = partI + 1;
		end;
		
        -- sort parts by start/end time
		animation.partsReverse = {};
		
        for _, part in ipairs(animation.parts) do
            table.insert(animation.partsReverse, part);
		end;
		
        table.sort(animation.parts, AnimatedVehicle.animPartSorter);
		table.sort(animation.partsReverse, AnimatedVehicle.animPartSorterReverse);
		
		self:initializeAnimationParts(animation);
		
        animation.currentPartIndex = 1;
		animation.duration = 0;
		
        for _, part in ipairs(animation.parts) do
            animation.duration = math.max(animation.duration, part.startTime + part.duration);
		end;
		
        if self.isClient then
			animation.sample = g_soundManager:loadSampleFromXML(self.xmlFile, key, "sound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self);
			animation.openSound = g_soundManager:loadSampleFromXML(xmlFile, key, "openSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self);
			animation.closeSound = g_soundManager:loadSampleFromXML(xmlFile, key, "closeSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self);
		end;
		
        return true;
	end;
	
    return false;
end;

function ExtendedAnimationSounds:playAnimation(superFunc, name, speed, animTime, noEventSend)
	local spec = self.spec_animatedVehicle;
	local animation = spec.animations[name];
	
    if animation ~= nil then
		SpecializationUtil.raiseEvent(self, "onPlayAnimation", name);
		
        if speed == nil then
            speed = animation.currentSpeed;
		end;
		
        -- skip animation if speed is not set or 0 to allow skipping animations per xml speed attribute set to 0
        if speed == nil or speed == 0 then
            return;
		end;
		
        if animTime == nil then
            if self:getIsAnimationPlaying(name) then
                animTime = self:getAnimationTime(name);
            elseif speed > 0 then
                animTime = 0;
            else
                animTime = 1;
            end;
		end;
		
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(AnimatedVehicleStartEvent:new(self, name, speed, animTime), nil, nil, self);
            else
                g_client:getServerConnection():sendEvent(AnimatedVehicleStartEvent:new(self, name, speed, animTime));
            end;
		end;
		
        if spec.activeAnimations[name] == nil then
            spec.activeAnimations[name] = animation;
			spec.numActiveAnimations = spec.numActiveAnimations + 1;
			
            SpecializationUtil.raiseEvent(self, "onStartAnimation", name);
		end;
		
        animation.currentSpeed = speed;
		animation.currentTime = animTime * animation.duration;
		
		self:resetAnimationValues(animation);
		
        if self.isClient then
			g_soundManager:playSample(animation.sample);
			
			if animTime < 1 then
				g_soundManager:playSample(animation.openSound);
			else
				g_soundManager:playSample(animation.closeSound);
			end;
		end;
		
        self:raiseActive();
    end;
end;

function ExtendedAnimationSounds:stopAnimation(superFunc, name, noEventSend)
	local spec = self.spec_animatedVehicle;
	local animation = spec.animations[name];
	
	if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AnimatedVehicleStopEvent:new(self, name), nil, nil, self);
        else
            g_client:getServerConnection():sendEvent(AnimatedVehicleStopEvent:new(self, name));
        end;
	end;
	
	local animation = spec.animations[name];
	
    if animation ~= nil then
		SpecializationUtil.raiseEvent(self, "onStopAnimation", name);
		
		animation.stopTime = nil;
		
        if self.isClient then
			g_soundManager:stopSample(animation.sample);
			g_soundManager:stopSample(animation.openSound);
			g_soundManager:stopSample(animation.closeSound);
        end;
	end;
	
    if spec.activeAnimations[name] ~= nil then
        spec.numActiveAnimations = spec.numActiveAnimations - 1;
		spec.activeAnimations[name] = nil;
		
        SpecializationUtil.raiseEvent(self, "onFinishAnimation", name);
    end;
end;

function ExtendedAnimationSounds.updateAnimation(self, superFunc, anim, dtToUse, stopAnim, allowRestart)
	local spec = self.spec_animatedVehicle;
    local numParts = table.getn(anim.parts);
	local parts = anim.parts;
	
    if anim.currentSpeed < 0 then
        parts = anim.partsReverse;
	end;
	
    if dtToUse > 0 then
        local hasChanged = false;
		local nothingToChangeYet = false;
		
        for partI=anim.currentPartIndex, numParts do
            local part = parts[partI];
			local isInRange = true;
			
            if part.requiredAnimation ~= nil then
				local time = self:getAnimationTime(part.requiredAnimation);
				
                if time < part.requiredAnimationRange[1] or time > part.requiredAnimationRange[2] then
                    isInRange = false;
                end;
			end;
			
            if (part.direction == 0 or ((part.direction > 0) == (anim.currentSpeed >= 0))) and isInRange then
				local durationToEnd = AnimatedVehicle.getDurationToEndOfPart(part, anim);
				
                -- is this part not playing yet?
                if durationToEnd > part.duration then
					nothingToChangeYet = true;
					
                    break;
				end;
				
				local realDt = dtToUse
				
                if anim.currentSpeed > 0 then
					local startT = anim.currentTime - dtToUse;
					
                    if startT < part.startTime then
                        realDt = dtToUse - part.startTime + startT;
                    end;
                else
                    local startT = anim.currentTime + dtToUse;
					local endTime = part.startTime + part.duration;
					
                    if startT > endTime then
                        realDt = dtToUse - (startT - endTime);
                    end;
				end;
				
				durationToEnd = durationToEnd+realDt;
				
                if self:updateAnimationPart(anim, part, durationToEnd, dtToUse, realDt) then
                    if self.setMovingToolDirty ~= nil then
                        self:setMovingToolDirty(part.node);
					end;
					
                    hasChanged = true;
                end;
			end;
			
            if partI == anim.currentPartIndex then
                -- is this part finished?
                if (anim.currentSpeed > 0 and part.startTime + part.duration < anim.currentTime) or
                   (anim.currentSpeed <= 0 and part.startTime > anim.currentTime)
                then
                    self:resetAnimationPartValues(part);
                    anim.currentPartIndex = anim.currentPartIndex + 1;
                end;
            end;
		end;
		
        if not nothingToChangeYet and not hasChanged and anim.currentPartIndex >= numParts then
            -- end the animation
            if anim.currentSpeed > 0 then
                anim.currentTime = anim.duration;
            else
                anim.currentTime = 0;
			end;
			
            stopAnim = true;
        end;
	end;
	
    if stopAnim or anim.currentPartIndex > numParts or anim.currentPartIndex < 1 then
        if not stopAnim then
            if anim.currentSpeed > 0 then
                anim.currentTime = anim.duration;
            else
                anim.currentTime = 0;
            end;
		end;
		
        anim.currentTime = math.min(math.max(anim.currentTime, 0), anim.duration);
		anim.stopTime = nil;
		
        if spec.activeAnimations[anim.name] ~= nil then
			spec.numActiveAnimations = spec.numActiveAnimations - 1;
			
            if self.isClient then
				g_soundManager:stopSample(spec.activeAnimations[anim.name].sample);
				g_soundManager:stopSample(spec.activeAnimations[anim.name].openSound);
				g_soundManager:stopSample(spec.activeAnimations[anim.name].closeSound);
			end;
			
			spec.activeAnimations[anim.name] = nil;
			
            SpecializationUtil.raiseEvent(self, "onFinishAnimation", anim.name);
		end;
		
        if allowRestart == nil or allowRestart then
            if anim.looping then
                -- restart animation
                self:setAnimationTime(anim.name, math.abs((anim.duration-anim.currentTime) - 1), true);
                self:playAnimation(anim.name, anim.currentSpeed, nil, true);
            end;
        end;
    end;
end;