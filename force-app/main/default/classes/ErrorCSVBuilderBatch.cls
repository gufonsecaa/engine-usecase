public with sharing class ErrorCSVBuilderBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Id importRecordId;
    private String originalCSVFileName;

    private static final Integer MAX_CHARS   = 2000000; // ~2MB
    private static final Integer MAX_ROWS   = 50000;   // row numbers limit

    private List<String> buffer = new List<String>();
    private Integer bufferChars = 0;
    private Integer partIndex = 0;
    private String headerRow = '';

    public ErrorCSVBuilderBatch(Id importRecordId) {
        this.importRecordId = importRecordId;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        Import__c importRecord = [
            SELECT Id, ColumnMap__c, ContentVersionId__c
            FROM Import__c
            WHERE Id = :this.importRecordId
            LIMIT 1
        ];

        ContentVersion originalCSVFile = [
            SELECT Id, Title
            FROM ContentVersion
            WHERE Id = :importRecord.ContentVersionId__c
            LIMIT 1
        ];
        this.originalCSVFileName = originalCSVFile.Title;

        List<List<String>> fieldsList = (List<List<String>>) JSON.deserialize(
            importRecord.ColumnMap__c,
            List<List<String>>.class
        );

        List<String> defaultColumns = new List<String>{'OriginalRowNumber'};
        List<String> originalColumns = new List<String>();
        for (List<String> columnMap : fieldsList) {
            originalColumns.add(columnMap[0]);
        }

        List<String> csvColumns = new List<String>();
        csvColumns.addAll(defaultColumns);
        csvColumns.addAll(originalColumns);
        csvColumns.add('Error');

        this.headerRow = String.join(csvColumns, ',');

        return Database.getQueryLocator([
            SELECT Id, RowNumber__c, Message__c, RawRow__c
            FROM ImportRowError__c
            WHERE Import__c = :this.importRecordId
            ORDER BY RowNumber__c ASC
        ]);
    }

    public void execute(Database.BatchableContext context, List<ImportRowError__c> scope) {
        if (scope.isEmpty()) return;

        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for (ImportRowError__c rowErrorRecord : scope) {
            String csvRow = buildCSVRow(rowErrorRecord);
            this.buffer.add(csvRow);
            this.bufferChars = csvRow.length() + 1;

            Boolean reachSize = bufferChars >= MAX_CHARS;
            Boolean reachRowsLimit = buffer.size() >= MAX_ROWS;

            if (reachSize || reachRowsLimit) {
                contentVersions.add(createErrorDocument());
                this.buffer.clear();
                this.bufferChars = 0;
            }
        }

        if (contentVersions.size() > 0) {
            insert contentVersions;

            Map<Id, ContentVersion> contentVersionsById = new Map<Id, ContentVersion>(contentVersions);
            linkErrorDocuments(contentVersionsById.keySet());
        }
    }

    public void finish(Database.BatchableContext context) {
        if (!buffer.isEmpty()) {
            ContentVersion contentVersion = createErrorDocument();
            insert contentVersion;
            linkErrorDocuments(new Set<Id>{ contentVersion.Id });
        }
    }

    private String buildCSVRow(ImportRowError__c rowErrorRecord) {
        String rowNumber = rowErrorRecord.RowNumber__c.toString();
        String raw = rowErrorRecord.RawRow__c;
        String error = rowErrorRecord.Message__c;

        return String.join(new List<String>{rowNumber, raw, error}, ',');
    }

    private ContentVersion createErrorDocument() {
        this.partIndex ++;

        List<String> rows = new List<String>();
        rows.add(this.headerRow);
        rows.addAll(this.buffer);

        String content = String.join(rows, '\n');
        String contentWithBom = '\uFEFF' + content;

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = '[failures - part ' + String.valueOf(this.partIndex) + '] ' + this.originalCSVFileName + '.csv';
        contentVersion.PathOnClient = '[failures - part ' + String.valueOf(this.partIndex) + '] ' + this.originalCSVFileName + '.csv';
        contentVersion.VersionData  = Blob.valueOf(contentWithBom);

        return contentVersion;
    }

    private void linkErrorDocuments(Set<Id> contentVersionsIds) {
        List<ContentVersion> contentVersions = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersionsIds
        ];

        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        for (ContentVersion documentVersion : contentVersions) {
            ContentDocumentLink documentLink = new ContentDocumentLink(
                ContentDocumentId = documentVersion.contentDocumentId,
                LinkedEntityId = this.importRecordId
            );

            documentLinks.add(documentLink);
        }

        insert documentLinks;
    }
}
