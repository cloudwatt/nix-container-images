docs:
	nix-build default.nix \
		--attr docs.optionsMarkdownWellSuppored \
		--out-link ./options-well-supported-generated.md
	cp  --no-preserve=mode \
		options-well-supported-generated.md \
		docs/options-well-supported-generated.md

clean:
	rm -f ./options-well-supported-generated.md

.PHONY: clean docs
