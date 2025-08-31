public with sharing class ImportProcessBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Id importRecordId;

    private Integer totalProcessed = 0;
    private Integer totalSuccess = 0;
    private Integer totalErrors = 0;

    public ImportProcessBatch(Id importRecordId) {
        this.importRecordId = importRecordId;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Import__c, Payload__c, RowStartIndex__c, Status__c
            FROM ImportChunk__c
            WHERE Import__c = :this.importRecordId
            AND Status__c = 'Pending'
            ORDER BY CreatedDate ASC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<ImportChunk__c> scope) {
        System.debug('scope.size():: ' + scope.size());
        if (scope.isEmpty()) return;

        ImportChunk__c currentChunk = scope[0];
        Import__c importRecord = [
            SELECT
                Id, TargetObject__c, ColumnMap__c, Status__c,
                TotalRows__c, ProcessedRows__c,SuccessRows__c, ErrorRows__c
            FROM Import__c
            WHERE Id = :currentChunk.Import__c
            LIMIT 1
            FOR UPDATE
        ];

        if (importRecord.Status__c == 'Queued') {
            importRecord.Status__c = 'Processing';
            update importRecord;

            ImportProgress__e progressEvent = new ImportProgress__e();
            progressEvent.Status__c = importRecord.Status__c;
            progressEvent.ImportId__c = importRecord.Id;
            EventBus.publish(progressEvent);
        }

        String targetObjectName = importRecord.TargetObject__c;
        String externalIdFieldName = 'Id';

        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(targetObjectName);
        Map<String, Schema.SObjectField> sObjectFields = sObjectType.getDescribe().fields.getMap();
        // trativa de erro:
        Schema.SObjectField externalIdField = sObjectFields.get(externalIdFieldName);

        List<List<String>> fieldsList = (List<List<String>>) JSON.deserialize(
            importRecord.ColumnMap__c,
            List<List<String>>.class
        );

        String payload = currentChunk.Payload__c;
        if (String.isEmpty(payload)) {
            currentChunk.Status__c = 'Done';
            update currentChunk;
            return;
        }

        currentChunk.Status__c = 'Processing';
        update currentChunk;

        CSVReader reader = new CSVReader(payload);

        Integer rowsInPayload = reader.countLineBreaks();
        List<List<String>> rows = CSVReader.read(payload, rowsInPayload, 0);

        List<SObject> records = new List<SObject>();
        for (Integer i=0; i < rows.size(); i++) {
            SObject record = transformRow(rows[i], importRecord.TargetObject__c, fieldsList);
            records.add(record);
        }

        Integer successRowsCount = 0;
        Integer errorRowsCount = 0;

        if (!records.isEmpty()) {
            SObjectAccessDecision accessDecision = Security.stripInaccessible(AccessType.UPSERTABLE, records);
            List<SObject> safeRecords = (List<SObject>) accessDecision.getRecords();

            Database.UpsertResult[] upsertResult = Database.upsert(safeRecords, externalIdField, false); // check if externalIdField is setted.

            for (Integer i = 0; i < upsertResult.size(); i++) {
                if (upsertResult[i].isSuccess()) {
                    successRowsCount++;
                } else {
                    errorRowsCount++;
                }
            }

            importRecord.ProcessedRows__c = (importRecord.ProcessedRows__c == null ? 0 : importRecord.ProcessedRows__c) + rows.size();
            importRecord.SuccessRows__c = (importRecord.SuccessRows__c == null ? 0 : importRecord.SuccessRows__c) + successRowsCount;
            importRecord.ErrorRows__c = (importRecord.ErrorRows__c == null ? 0 : importRecord.ErrorRows__c) + errorRowsCount;
            update importRecord;

            currentChunk.Status__c = 'Done';
            update currentChunk;

            totalProcessed += rows.size();
            totalSuccess += successRowsCount;
            totalErrors += errorRowsCount;

            publishProgress(importRecord, totalProcessed, totalSuccess, totalErrors);
        }
    }

    public void finish(Database.BatchableContext bc) {
        Import__c importRecord = [
            SELECT
                Id, Status__c,
                TotalRows__c, ProcessedRows__c,SuccessRows__c, ErrorRows__c
            FROM Import__c
            WHERE Id = :this.importRecordId
            LIMIT 1
        ];

        String finalStatus = 'Completed';
        if (importRecord.ErrorRows__c != null && importRecord.ErrorRows__c > 0) {
            finalStatus = 'CompletedWithErrors';
        }

        importRecord.Status__c = finalStatus;
        update importRecord;

        ImportProgress__e progressEvent = new ImportProgress__e();
        progressEvent.ImportId__c = importRecord.Id;
        progressEvent.Status__c = finalStatus;
        EventBus.publish(progressEvent);
    }

    private static SObject transformRow(List<String> row, String targetObjectName, List<List<String>> fieldsList) {
        SObject rowRecord = (SObject) Type.forName(targetObjectName).newInstance();
        rowRecord.put('Id', null);

        for (Integer i=0; i < row.size(); i++) {
            List<String> fieldMap = fieldsList[i];
            if (fieldMap.size() == 1) continue;

            String fieldName = fieldMap[1]; // get field api name;
            rowRecord.put(fieldName, row[i]);
        }

        return rowRecord;
    }

    private static void publishProgress(Import__c importRecord, Integer totalProcessed, Integer totalSuccess, Integer totalErrors) {
        ImportProgress__e progressEvent = new ImportProgress__e();
        progressEvent.ImportId__c = importRecord.Id;
        progressEvent.TotalProcessed__c = totalProcessed;
        progressEvent.TotalSuccess__c = totalSuccess;
        progressEvent.TotalErrors__c = totalErrors;
        EventBus.publish(progressEvent);
    }
}
