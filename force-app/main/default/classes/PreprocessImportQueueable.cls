public with sharing class PreprocessImportQueueable implements Queueable {

    private static final Integer MAX_CHUNK_CHARS = 120000;
    private static final Integer TARGET_LINES_PER_CHUNK = 200;

    private Id importRecordId;

    public PreprocessImportQueueable(Id importRecordId) {
        this.importRecordId = importRecordId;
    }

    public void execute(QueueableContext context) {
        Import__c importRecord = [
            SELECT
                Id, ContentVersionId__c, Status__c, TotalRows__c, ProcessedRows__c
            FROM Import__c
            WHERE Id = :importRecordId
            FOR UPDATE
        ];

        if (importRecord == null) {
            failImport(importRecord, 'Import Setup not found.');
            return;
        }

        if (importRecord.ContentVersionId__c == null) {
            failImport(importRecord, 'Missing ContentVersionId on import record.');
            return;
        }

        ContentVersion contentVersion = CSVUtils.getContentVersionById(importRecord.ContentVersionId__c);
        String raw = contentVersion.VersionData.toString();
        CSVReader reader = new CSVReader(raw);

        Integer totalLines = (Integer) importRecord.TotalRows__c;
        Integer totalDataLines = totalLines - 1;

        List<ImportChunk__c> chunks = new List<ImportChunk__c>();

        Integer made = 0;
        while (made < totalDataLines) {
            List<String> lines = reader.sliceRawLines(TARGET_LINES_PER_CHUNK, 1 + made);
            CSVReader.JoinResult joinResult = reader.joinUntilLimit(lines, MAX_CHUNK_CHARS);

            ImportChunk__c chunk = new ImportChunk__c();
            chunk.Import__c = importRecord.Id;
            chunk.Payload__c = joinResult.payload;
            chunk.RowStartIndex__c = 2 + made;
            chunk.Status__c = 'Pending';
            chunks.add(chunk);

            made += joinResult.linesUsed;
        }

        insert chunks;

        Database.executeBatch(new ImportProcessBatch(importRecord.Id), 1);
    }

    private static void failImport(Import__c importRecord, String message) {
        importRecord.Status__c = 'Failed';
        update importRecord;

        ImportProgress__e progressEvent = new ImportProgress__e();
        progressEvent.Status__c = importRecord.Status__c;
        progressEvent.ImportId__c = importRecord.Id;
        EventBus.publish(progressEvent);
    }
}
