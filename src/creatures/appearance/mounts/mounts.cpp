/**
 * Canary - A free and open-source MMORPG server emulator
 * Copyright (©) 2019-2022 OpenTibiaBR <opentibiabr@outlook.com>
 * Repository: https://github.com/opentibiabr/canary
 * License: https://github.com/opentibiabr/canary/blob/main/LICENSE
 * Contributors: https://github.com/opentibiabr/canary/graphs/contributors
 * Website: https://docs.opentibiabr.org/
*/

#include "pch.hpp"

#include "creatures/appearance/mounts/mounts.h"
#include "game/game.h"
#include "utils/pugicast.h"
#include "utils/tools.h"

bool Mounts::reload()
{
	mounts.clear();
	return loadFromXml();
}

bool Mounts::loadFromXml()
{
	pugi::xml_document doc;
	auto folder = g_configManager.getString(CORE_DIRECTORY) + "/XML/mounts.xml";
	pugi::xml_parse_result result = doc.load_file(folder.c_str());
	if (!result) {
		printXMLError(__FUNCTION__, folder, result);
		return false;
	}

	for (auto mountNode : doc.child("mounts").children()) {
		uint16_t lookType = pugi::cast<uint16_t>(mountNode.attribute("clientid").value());
		if (g_configManager.getBoolean(WARN_UNSAFE_SCRIPTS) && lookType != 0 && !g_game().isLookTypeRegistered(lookType)) {
			SPDLOG_WARN("{} - An unregistered creature looktype type with id '{}' was blocked to prevent client crash.", __FUNCTION__, lookType);
			continue;
		}

		mounts.emplace_back(
			static_cast<uint8_t>(pugi::cast<uint16_t>(mountNode.attribute("id").value())),
			lookType,
			mountNode.attribute("name").as_string(),
			pugi::cast<int32_t>(mountNode.attribute("speed").value()),
			mountNode.attribute("premium").as_bool(),
			mountNode.attribute("type").as_string()
		);
	}
	mounts.shrink_to_fit();
	return true;
}

Mount* Mounts::getMountByID(uint8_t id)
{
	auto it = std::ranges::find_if(mounts, [id](const Mount& mount) {
		return mount.id == id;
	});

	return it != mounts.end() ? std::to_address(it) : nullptr;
}

Mount* Mounts::getMountByName(const std::string& name) {
	auto mountName = name.c_str();
	for (auto& it : mounts) {
		if (strcasecmp(mountName, it.name.c_str()) == 0) {
			return &it;
		}
	}

	return nullptr;
}

Mount* Mounts::getMountByClientID(uint16_t clientId)
{
	auto it = std::ranges::find_if(mounts, [clientId](const Mount& mount) {
		return mount.clientId == clientId;
	});

	return it != mounts.end() ? std::to_address(it) : nullptr;
}
