local AttributeSchema = require(script.Parent.AttributeSchema)

local Migration = {
	CurrentVersion = AttributeSchema.Version,
}

function Migration.Classify(instance)
	if instance:IsA("ParticleEmitter") then return "ParticleEmitter" end
	if instance:IsA("Beam") then return "Beam" end
	if instance:IsA("Trail") then return "Trail" end
	if (instance:IsA("Model") or instance:IsA("Folder")) and instance:FindFirstChild("Start") and instance:FindFirstChild("End") then
		return "StructuredMeshVFX"
	end
	if instance:GetAttribute("IsMeshEmitter") == true then
		return "LegacyMeshVFX"
	end
	return nil
end

function Migration.Inspect(instance)
	local legacyAliases = {}
	local unknownAttributes = {}
	local typeIssues = {}

	for name, definition in pairs(AttributeSchema.Definitions) do
		if instance:GetAttribute(name) == nil then
			for _, alias in ipairs(definition.Aliases) do
				if instance:GetAttribute(alias) ~= nil then
					legacyAliases[name] = alias
					break
				end
			end
		end
	end

	for attributeName, value in pairs(instance:GetAttributes()) do
		local definition = AttributeSchema.GetDefinition(attributeName)
		if not definition then
			table.insert(unknownAttributes, attributeName)
		else
			local valid, message = AttributeSchema.Validate(attributeName, value)
			if not valid then
				table.insert(typeIssues, {
					Name = attributeName,
					Message = message,
					ActualType = typeof(value),
					ExpectedType = definition.Type,
				})
			end
		end
	end

	table.sort(unknownAttributes)
	table.sort(typeIssues, function(a, b)
		return a.Name < b.Name
	end)

	return {
		Kind = Migration.Classify(instance),
		Version = instance:GetAttribute("VisualXVersion") or 0,
		LegacyAliases = legacyAliases,
		UnknownAttributes = unknownAttributes,
		TypeIssues = typeIssues,
		IsCompatible = #typeIssues == 0,
	}
end

function Migration.Migrate(instance, options)
	options = options or {}
	local report = Migration.Inspect(instance)
	if not report.Kind then
		return report
	end
	if options.PromoteAliases then
		for canonical, alias in pairs(report.LegacyAliases) do
			if instance:GetAttribute(canonical) == nil then
				instance:SetAttribute(canonical, instance:GetAttribute(alias))
			end
		end
	end
	instance:SetAttribute("VisualXVersion", Migration.CurrentVersion)
	report.Version = Migration.CurrentVersion
	return report
end

function Migration.MigrateTree(root, options)
	local reports = {}
	local candidates = {root}
	for _, descendant in ipairs(root:GetDescendants()) do
		table.insert(candidates, descendant)
	end
	for _, instance in ipairs(candidates) do
		if Migration.Classify(instance) then
			table.insert(reports, Migration.Migrate(instance, options))
		end
	end
	return reports
end

return Migration