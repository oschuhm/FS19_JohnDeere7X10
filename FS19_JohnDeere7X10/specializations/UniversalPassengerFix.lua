--[[
	UniversalPassengerFix
	Specialization to fix the UniversalPassenger by GTX Andy to remove the requirement of "UniversalPassenger" in the Mod name, when you use an global xml file
	
	@author:    Ifko[nator]
	@date:      07.09.2019
	@version:	1.0
]]

UniversalPassengerFix = {};

UniversalPassengerFix.modName = ""

function UniversalPassengerFix:loadMap(name)
	local activeMods = g_modManager:getActiveMods()

	for _, mod in pairs(activeMods) do
		if _G[tostring(mod.modName)].UniversalPassenger ~= nil then		
			if g_modIsLoaded[tostring(mod.modName)] then	
				UniversalPassengerFix.modName = _G[tostring(mod.modName)];
			end;
        end; 
	end;

    if UniversalPassengerFix.modName ~= "" then
		UniversalPassengerFix.modName.UniversalPassenger.loadVehiclesFromXML = Utils.prependedFunction(UniversalPassengerFix.modName.UniversalPassenger.loadVehiclesFromXML, UniversalPassengerFix.loadVehiclesFromXMLFix);
	end;
end;

function UniversalPassengerFix:loadVehiclesFromXMLFix(loadAddons, isReload)
	if isReload == true then
		self.universalPassengerVehicles = {};
	end;

	if loadAddons then
		local activeMods = g_modManager:getActiveMods();

		for _, mod in pairs (activeMods) do
			local modName = mod.modName;

			if modName ~= "FS19_UniversalPassenger" then
				--local start, _ = string.find(modName, "UniversalPassenger") --## WHY GTX Andy, why??????
				--if start ~= nil then
					local modDesc = loadXMLFile("tempModDesc", mod.modFile);
	
					if hasXMLProperty(modDesc, "modDesc.universalPassenger") then
						local xmlFilename = getXMLString(modDesc, "modDesc.universalPassenger#xmlFile");

						if xmlFilename ~= nil then
							xmlFilename = mod.modDir .. xmlFilename;
	
							if fileExists(xmlFilename) then
								xmlHasBeenAdded = false;

								for _, globalXmlFile in pairs(self.globalXmlFiles) do
									if globalXmlFile == xmlFilename then
										xmlHasBeenAdded = true;

										break;
									end;
								end;

								if not xmlHasBeenAdded then
									table.insert(self.globalXmlFiles, xmlFilename);
								end;
							else
								self:logPrint(UniversalPassengerFix.modName.UniversalPassenger.LOG_ERROR, "File '%s' does not exist in '%s'. Please check path in modDesc.", xmlFilename, modName);
							end;
						else
							self:logPrint(UniversalPassengerFix.modName.UniversalPassenger.LOG_ERROR, "No XML filename path given at 'modDesc.universalPassenger#xmlFile' in '%s'", modName);
						end;
					end;
	
					delete(modDesc);
				--end;
			end;
		end;
	end;
end;

function UniversalPassengerFix:draw()end;
function UniversalPassengerFix:deleteMap()end;
function UniversalPassengerFix:keyEvent(unicode, sym, modifier, isDown)end;
function UniversalPassengerFix:mouseEvent(posX, posY, isDown, isUp, button)end;
function UniversalPassengerFix:update(dt)end;

addModEventListener(UniversalPassengerFix);