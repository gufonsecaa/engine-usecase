import { api, LightningElement, track } from 'lwc';

import getPreviewRows from '@salesforce/apex/DataImporterController.getPreviewRows';

export default class PreviewImport extends LightningElement {
  @api contentVersionId;
  @api columnMapping;
  @api fileInfo;

  @track previewData = [];

  get previewColumns() {
    return this.columnMapping
      .filter(column => !!column.field)
      .map(column => ({
        label: column.field.label,
        fieldName: column.field.apiName
      }));
  }

  connectedCallback() {
    this.fetchPreviewRows();
  }

  async fetchPreviewRows() {
    try {
      const results = await getPreviewRows({
        contentVersionId: this.contentVersionId
      });

      this.previewData = this.preparePreviewData(JSON.parse(results));
    } catch (error) {
      this.previewData = null;
      console.error(error);
    }
  }

  handlePreviewImportFinished() {
    this.dispatchEvent(new CustomEvent('previewimportfinished', {}));
  }

  preparePreviewData(rows) {
    let previewData = [];

    rows.forEach((row) => {
      let rowData = {};
      row.forEach((columnValue, index) => {
        const mappedColumn = this.columnMapping[index];
        if (mappedColumn.field) {
          rowData = {
            ...rowData,
            [mappedColumn.field.apiName]: columnValue
          };
        }
      })
      previewData.push(rowData);
    });

    return previewData;
  }
}
