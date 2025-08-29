public with sharing class CSVUtils {
    public static ContentVersion getContentVersionById(String contentVersionId) {
        ContentVersion contentVersion = [
            SELECT VersionData, FileExtension, ContentSize
            FROM ContentVersion
            WHERE Id = :contentVersionId
            LIMIT 1
        ];

        return contentVersion;
    }

    public static List<String> getHeaderColumns(String contentVersionId) {
        ContentVersion contentVersion = getContentVersionById(contentVersionId);
        List<List<String>> rows = CSVReader.read(contentVersion.VersionData.toString(), 1, null);
        List<String> header = rows[0];

        return header;
    }

    public static List<List<String>> getRowsFromCSV(String contentVersionId, Integer numberOfRows) {
        ContentVersion contentVersion = getContentVersionById(contentVersionId);
        List<List<String>> rows = CSVReader.read(contentVersion.VersionData.toString(), numberOfRows, 1);

        return rows;
    }
}
