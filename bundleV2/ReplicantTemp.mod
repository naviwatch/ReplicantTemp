return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ReplicantTemp` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("ReplicantTemp", {
			mod_script       = "scripts/mods/ReplicantTemp/ReplicantTemp",
			mod_data         = "scripts/mods/ReplicantTemp/ReplicantTemp_data",
			mod_localization = "scripts/mods/ReplicantTemp/ReplicantTemp_localization",
		})
	end,
	packages = {
		"resource_packages/ReplicantTemp/ReplicantTemp",
	},
}
