ContentVersion contentVersion = [SELECT VersionData FROM ContentVersion WHERE Id = '068gL000003NcHPQA0' LIMIT 1];
// List<List<String>> header = CSVReader.read(contentVersion.VersionData.toString(), 1, null);

// System.debug('header.size(): ' + header.size());
// System.debug('header: ' + header[0]);


List<List<String>> first10Rows = CSVReader.read(contentVersion.VersionData.toString(), 10, 1);

System.debug('first10Rows.size(): ' + first10Rows.size());
System.debug('first10Rows: ' + first10Rows);
