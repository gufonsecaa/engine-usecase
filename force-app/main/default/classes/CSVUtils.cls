public with sharing class CSVUtils {
    public static ContentVersion getContentVersionById(String contentVersionId) {
        ContentVersion contentVersion = [
            SELECT
                Title,
                FileExtension,
                VersionData,
                ContentSize,
                ContentDocumentId
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

    public static Integer getNumberOfLines(ContentVersion contentVersion) {
        CSVReader csv = new CSVReader(contentVersion.VersionData.toString());
        Integer numberOfLines = csv.countLineBreaks();
        return numberOfLines;
    }

    public static ContentDocumentLink createDocumentLink(Id contentDocumentId, Id importRecordId) {
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId.toString(),
            LinkedEntityId = importRecordId.toString()
        );

        return link;
    }
}
