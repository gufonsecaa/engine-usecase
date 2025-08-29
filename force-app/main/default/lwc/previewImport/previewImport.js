import { LightningElement, track } from 'lwc';

import { recordsMock } from './records-mock';

export default class PreviewImport extends LightningElement {
  @track previewColumns = [
    { label: "Account Name", fieldName: "Name" },
    { label: "Account Number", fieldName: "AccountNumber" },
    { label: "Phone", fieldName: "Phone" },
  ];
  @track previewData = recordsMock;

  handlePreviewImportFinished() {
    this.dispatchEvent(new CustomEvent('previewimportfinished', {}));
  }
}
