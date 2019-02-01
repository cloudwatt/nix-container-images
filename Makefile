clean:
	rm -f ./options-well-supported-generated.md

doc:
	nix-build default.nix \
		--attr lib.makeImageDocumentation.optionsMarkdown \
		--out-link ./options-well-supported-generated.md
	cp  --no-preserve=mode \
		options-well-supported-generated.md \
		docs/options-well-supported-generated.md
