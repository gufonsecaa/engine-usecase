import { api, LightningElement, track } from 'lwc';

import { recordsMock } from './records-mock';

export default class PreviewImport extends LightningElement {
  @api columnMapping;

  @track previewData = recordsMock;

  get totalColumns() {
    return this.columnMapping.length;
  }

  get totalMappedColumns() {
    return this.columnMapping.filter(column => column.field).length;
  }

  get previewColumns() {
    return this.columnMapping
      .filter(column => !!column.field)
      .map(column => ({
        label: column.field.label,
        fieldName: column.field.apiName
      }));
  }

  handlePreviewImportFinished() {
    this.dispatchEvent(new CustomEvent('previewimportfinished', {}));
  }
}
