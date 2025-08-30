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
}
