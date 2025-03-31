# Playbook

The migration can take about 5 minutes of downtime
- Down the KGW (LB). To prevent a transaction where a credential is created to be processed after the transaction with migration in one block.
- Run 1.migration.sql. It will create a new table, field and migrate the data.
```bash
kwil-cli exec-sql --provider http://localhost:8090 --private-key ca0829ed00079941f70e354d781b6b42bfd4c1ec6546694e3f1ff2682871d8c1 --sync -f ./migrations/public_notes/1.migration.sql
```

- Be sure the data migrated and accessible. Old field public_notes with the data still in place on `credentials` table
- When ready, run 2.cleanup. This step can be executed after enabling KGW
```bash
kwil-cli exec-sql --provider http://localhost:8090 --private-key ca0829ed00079941f70e354d781b6b42bfd4c1ec6546694e3f1ff2682871d8c1 --sync -f ./migrations/public_notes/2.cleanup.sql
```
- Up KGW (LB)

## Rollback

If something goes wrong it is possible to migrate back the structure. If cleanup script wasn't run, the data also will be in place.
To do this run `_rollback.sql`
