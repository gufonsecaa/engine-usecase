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
    public static String getCSVColumnNames() {
        return JSON.serialize(getColumnNames());
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

    // CSV Utils
    public static List<String> getColumnNames() {
        return new List<String>{'Company-name', 'Phone', 'Account Identification'};
    }

    public class SObjectOption {
        String label;
        String value;
    }
}
