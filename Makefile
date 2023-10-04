LOCAL_FOLDER=./backups/$(env)/$(dbid)
DUMPS_FOLDER=$(LOCAL_FOLDER)/dumps/
BATCHES_FOLDER=$(LOCAL_FOLDER)/batches/

REMOTE_DB=/app/home_dir/data/kwild.db/$(dbid).sqlite
LOCAL_DB=$(LOCAL_FOLDER)/$(dbid).sqlite

OLD_SCHEMA_FILE=$(LOCAL_FOLDER)/old_schema.json
NEW_SCHEMA_FILE=$(LOCAL_FOLDER)/new_schema.json

.PHONY: prepare deploy import dump-tables convert-json-files-to-csv save-current-schema save-new-schema deploy-schema drop-db generate-batches import-batches

prepare: fetch-db save-current-schema dump-tables

deploy: drop-db deploy-schema save-new-schema

import: generate-batches import-batches

check-variables:
ifndef dbid
	$(error 'dbid' is not set)
endif
ifndef env
	$(error 'env' is not set)
endif

ensure-folders-exist:
	mkdir -p $(LOCAL_FOLDER) $(DUMPS_FOLDER) $(BATCHES_FOLDER)

fetch-db: check-variables ensure-folders-exist
	./scripts/scp.sh $(env) $(REMOTE_DB) $(LOCAL_DB)

dump-tables: check-variables ensure-folders-exist
	ruby ./scripts/dump_tables.rb $(LOCAL_DB) $(DUMPS_FOLDER) $(OLD_SCHEMA_FILE)

convert-json-files-to-csv: check-variables ensure-folders-exist
	ruby ./scripts/json_to_csv.rb $(DUMPS_FOLDER) $(BATCHES_FOLDER)

# TODO: no need to have duplicates of the save schema recipes
save-current-schema: check-variables ensure-folders-exist
	kwil-cli database read-schema --dbid=$(dbid) --output=json | jq .result.tables > $(OLD_SCHEMA_FILE)

save-new-schema: check-variables ensure-folders-exist
	kwil-cli database read-schema --dbid=$(dbid) --output=json | jq .result.tables > $(NEW_SCHEMA_FILE)

deploy-schema:
	kwil-cli database deploy --path=./schema.kf
	sleep 3s

drop-db: check-variables
	kwil-cli database drop idos # no support for `--dbid=$(dbid)` here

generate-batches: check-variables ensure-folders-exist
	ruby ./scripts/prepare_batches.rb $(OLD_SCHEMA_FILE) $(NEW_SCHEMA_FILE) $(DUMPS_FOLDER) $(BATCHES_FOLDER)

import-batches: check-variables ensure-folders-exist
	ruby ./scripts/import_batches.rb $(BATCHES_FOLDER)
