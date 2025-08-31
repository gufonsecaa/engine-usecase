public with sharing class DataImporterController {
    @AuraEnabled(cacheable=false)
    public static String getAvailableSObjectOptions() {
        try {
            Map<String, String> availableSObjects = getAvailableSObjectsToPerformDML();
            List<SObjectOption> options = new List<SObjectOption>();

            for (String objectApiName : availableSObjects.keySet()) {
                SObjectOption option = new SObjectOption();
                option.value = objectApiName;
                option.label = availableSObjects.get(objectApiName);
                options.add(option);
            }

            return JSON.serialize(options);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String getCSVColumnNames(String contentVersionId) {
        return JSON.serialize(CSVUtils.getHeaderColumns(contentVersionId));
    }

    @AuraEnabled(cacheable=false)
    public static String getPreviewRows(String contentVersionId) {
        try {
            List<List<String>> first10Rows = CSVUtils.getRowsFromCSV(contentVersionId, 10);
            return JSON.serialize(first10Rows);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getFileInfo(String contentVersionId) {
        try {
            ContentVersion contentVersion = CSVUtils.getContentVersionById(contentVersionId);

            Integer numberOfLines = CSVUtils.getNumberOfLines(contentVersion);

            CSVFileInfo fileInfo = new CSVFileInfo();
            fileInfo.fileSize = contentVersion.ContentSize;
            fileInfo.fileName = contentVersion.Title + '.' + contentVersion.FileExtension;
            fileInfo.numberOfLines = numberOfLines;

            return JSON.serialize(fileInfo);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String saveImportDraft(String draftDataString) {
        try {
            ImportDraftDTO draftData = (ImportDraftDTO) JSON.deserialize(draftDataString, ImportDraftDTO.class);
            Import__c draftImport = createDraftImport(draftData);
            insert draftImport;

            ContentVersion contentVersion = CSVUtils.getContentVersionById(draftData.contentVersionId);
            ContentDocumentLink csvImportLink = CSVUtils.createDocumentLink(contentVersion.ContentDocumentId, draftImport.Id);
            insert csvImportLink;

            return draftImport.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static string getImportRecordData(String importRecordId) {
        try {
            Import__c importRecord = [
                SELECT Id, Name, Status__c, TotalRows__c, ProcessedRows__c, SuccessRows__c, ErrorRows__c
                FROM Import__c
                WHERE Id = :importRecordId LIMIT 1
            ];

            ImportRecord importData = new ImportRecord();
            importData.id = importRecord.Id;
            importData.name = importRecord.Name;
            importData.status = importRecord.Status__c;
            importData.numberOfLines = (Integer) importRecord.TotalRows__c;
            importData.processedRows = (Integer) importRecord.ProcessedRows__c;
            importData.successRows = (Integer) importRecord.SuccessRows__c;
            importData.errorRows = (Integer) importRecord.ErrorRows__c;

            return JSON.serialize(importData);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void startImport(String importRecordId) {
        try {
            Import__c importData = new Import__c(
                Id = importRecordId,
                Status__c = 'Queued'
            );
            update importData;

            PreprocessImportQueueable queueable = new PreprocessImportQueueable(importRecordId);
            System.enqueueJob(queueable);

            ImportProgress__e progressEvent = new ImportProgress__e();
            progressEvent.Status__c = importData.Status__c;
            progressEvent.ImportId__c = importRecordId;
            EventBus.publish(progressEvent);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Import__c createDraftImport(ImportDraftDTO data) {
        Import__c importData = new Import__c();
        importData.Name = data.targetObjectName + ' | ' + data.fileName;
        importData.ContentVersionId__c = data.contentVersionId;
        importData.TargetObject__c = data.targetObjectName;
        importData.ColumnMap__c = data.columnMapping;
        importData.TotalRows__c = data.numberOfLines;
        importData.Status__c = 'Draft';

        return importData;
    }

    // DML Utils
    public static Map<String, String> getAvailableSObjectsToPerformDML() {
        Map<String, SObjectType> allSObjectTypes = Schema.getGlobalDescribe();
        Map<String, String> results = new Map<String, String>();

        for (SObjectType type : allSObjectTypes.values()) {
            Schema.DescribeSObjectResult objectResult = type.getDescribe();

            Boolean shouldIgnoreObjectType = objectResult.isCustomSetting() || objectResult.isDeprecatedAndHidden();
            Boolean isAvailableToPerformDML = !shouldIgnoreObjectType && objectResult.isCreateable() && objectResult.isUpdateable();

            if (shouldIgnoreObjectType) continue;

            if (isAvailableToPerformDML) {
                results.put(objectResult.getName(), objectResult.getLabel());
            }
        }

        return results;
    }

    public class SObjectOption {
        String label;
        String value;
    }

    public class CSVFileInfo {
        public String fileName;
        public Integer fileSize;
        public Integer numberOfLines;
    }

    public class ImportDraftDTO {
        public String fileName;
        public String contentVersionId;
        public String targetObjectName;
        public String columnMapping;
        public String upsertExternalIdField;
        public Integer numberOfLines;
    }

    public class ImportRecord {
        public String id;
        public String name;
        public String status;
        public Integer numberOfLines;
        public Integer processedRows;
        public Integer successRows;
        public Integer errorRows;
    }
}
