# Alvos do banco de governança. A análise em R roda por targets::tar_make().
#
#   make validar   schema + integridade do grafo
#   make build     YAML -> DuckDB
#   make site      gera _site/
#   make serve     serve _site/ em http://localhost:8000
#   make tudo      validar + build + site
#   make limpar    apaga os artefatos

DATA   := governanca/data
SCHEMA := governanca/schema/grafo.schema.json
DB     := governanca/build/grafo.duckdb
SITE   := _site

.PHONY: tudo validar build site serve limpar

tudo: site

validar:
	uv run python governanca/tools/validar.py $(DATA) $(SCHEMA)

build: validar
	uv run python governanca/tools/build.py --src $(DATA) --schema $(SCHEMA) --out $(DB)

site: build
	uv run python governanca/tools/site.py --db $(DB) --out $(SITE) --repo .

serve: site
	@echo "  http://localhost:8000"
	@cd $(SITE) && python3 -m http.server 8000

limpar:
	rm -rf governanca/build $(SITE)
